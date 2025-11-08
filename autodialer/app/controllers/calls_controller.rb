class CallsController < ApplicationController
  protect_from_forgery with: :exception

  # show UI and list
  def index
    @numbers = PhoneNumber.order(created_at: :desc).limit(200)
  end

  # upload numbers via textarea or file
  def upload
    raw = params[:numbers].to_s
    if params[:file].present?
      raw += "\n" + params[:file].read.to_s
    end
    numbers = parse_numbers(raw).uniq.first(100)  # limit 100 per upload to follow brief
    numbers.each do |num|
      PhoneNumber.find_or_create_by(number: num) do |pn|
        pn.status = :pending
        pn.last_log = "uploaded"
      end
    end
    redirect_to root_path, notice: "#{numbers.size} numbers queued (pending)."
  end

  # start dialing pending/failed numbers (background job)
  def start_batch
    message = params[:message].presence || "Hello from Autodialer demo."
    # pick up to 100 pending or failed numbers
    numbers = PhoneNumber.where(status: [:pending, :failed]).limit(100).pluck(:number)
    if numbers.empty?
      redirect_to root_path, alert: "No pending/failed numbers to call."
      return
    end

    numbers.each do |n|
      PhoneNumber.find_by(number: n).update(status: :queued, last_log: "enqueued at #{Time.current}")
    end

    CallJob.perform_later(numbers, message)
    redirect_to root_path, notice: "Started call batch: #{numbers.count} numbers."
  end

  # small endpoint to accept an AI prompt: "make a call to 18001234567 and say 'Hello'"
  def ai_prompt
    prompt = params[:prompt].to_s
    if prompt.blank?
      redirect_to root_path, alert: "Prompt empty"
      return
    end

    # 1) try quick regex parse for phone numbers
    numbers = extract_numbers_from_text(prompt)
    # 2) extract quoted message if any
    message = extract_quoted_message(prompt) || "Hello from Autodialer demo."

    if numbers.empty? && ENV['OPENAI_API_KEY'].present?
      # call OpenAI to interpret natural language (optional)
      interpreted = AiPromptParser.new(ENV['OPENAI_API_KEY']).parse(prompt)
      numbers = interpreted[:numbers]
      message = interpreted[:message] if interpreted[:message].present?
    end

    if numbers.blank?
      redirect_to root_path, alert: "Could not parse any numbers from prompt."
      return
    end

    numbers.each do |n|
      pn = PhoneNumber.find_or_initialize_by(number: n)
      pn.status = :queued
      pn.last_log = "enqueued via AI prompt"
      pn.save!
    end
    CallJob.perform_later(numbers, message)
    redirect_to root_path, notice: "AI prompt accepted. Enqueued calls to #{numbers.join(', ')}"
  end

  private

  def parse_numbers(raw)
    raw.to_s.split(/\r?\n|,|;/).map(&:strip).map { |s| normalize(s) }.compact
  end

  def normalize(s)
    return nil if s.blank?
    digits = s.gsub(/\D/, "")
    # support 10-digit Indian numbers -> add +91
    if digits.length == 10
      return "+91" + digits
    elsif digits.length == 11 && digits.start_with?("0")
      return "+91" + digits[1..-1]
    elsif digits.length > 10 && digits.length <= 15
      return "+" + digits
    else
      nil
    end
  end

  def extract_numbers_from_text(text)
    found = text.scan(/(\+?\d[\d\-\s]{6,}\d)/).flatten
    found.map { |f| normalize(f) }.compact
  end

  def extract_quoted_message(text)
    m = text.match(/["'](.+?)["']/)
    m && m[1]
  end
end

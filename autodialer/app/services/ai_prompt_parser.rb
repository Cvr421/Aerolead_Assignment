# optional service - call OpenAI to interpret ambiguous prompts
require 'net/http'
require 'json'

class AiPromptParser
 PERPLEXITY_URL = "https://api.perplexity.ai/chat/completions"

  def initialize(api_key)
    @api_key = api_key
  end

  # returns { numbers: [...], message: "..." }
  def parse(prompt_text)
    return { numbers: [], message: nil } if @api_key.blank?

    system = "You are a helpful parser. Extract phone numbers (in any format) and a short message to say if present from the user's prompt. Reply in JSON: {\"numbers\": [\"+911234...\"], \"message\": \"...\"}. If none found, numbers should be []."
    body = {
      model: "sonar-pro",
      messages: [
        { role: "system", content: system },
        { role: "user", content: prompt_text }
      ],
      temperature: 0.0,
      max_tokens: 300
    }

    uri = URI(PERPLEXITY_URL)
    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "application/json"
    req["Authorization"] = "Bearer #{PERPLEXITY_API_KEY}"
    req.body = body.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    parsed = JSON.parse(res.body) rescue nil
    content = parsed.dig("choices", 0, "message", "content") rescue nil
    json = JSON.parse(content) rescue nil
    return { numbers: [], message: nil } unless json

    # normalize numbers similarly to controller
    numbers = (json["numbers"] || []).map { |n| normalize_number(n) }.compact
    { numbers: numbers, message: json["message"] }
  rescue => e
    Rails.logger.error "AI parse error: #{e.message}"
    { numbers: [], message: nil }
  end

  private
  def normalize_number(s)
    return nil if s.blank?
    digits = s.gsub(/\D/, "")
    if digits.length == 10
      "+91" + digits
    elsif digits.length == 11 && digits.start_with?("0")
      "+91" + digits[1..-1]
    elsif digits.length > 10 && digits.length <= 15
      "+" + digits
    else
      nil
    end
  end
end

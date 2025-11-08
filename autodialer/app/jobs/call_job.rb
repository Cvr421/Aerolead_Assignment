class CallJob < ApplicationJob
  queue_as :default

  # numbers: array of normalized numbers like +911234567890
  def perform(numbers, message)
    client = twilio_client
    numbers.each do |num|
      pn = PhoneNumber.find_by(number: num) || PhoneNumber.create!(number: num)
      begin
        pn.update!(status: :queued, last_log: "calling started at #{Time.current}")

        if client.nil?
          pn.update!(status: :failed, last_log: "Twilio not configured - simulated run")
          next
        end

        # TwiML URL where Twilio will GET TwiML to speak the message. We pass message as param.
        twiml_url = "#{public_host}/twilio/voice?message=#{CGI.escape(message)}"

        call = client.calls.create(
          to: num,
          from: defined?(TWILIO_FROM) && TWILIO_FROM.present? ? TWILIO_FROM : ENV['TWILIO_FROM'],
          url: twiml_url,
          status_callback: "#{public_host}/twilio/status",
          status_callback_method: "POST",
          status_callback_event: ["initiated", "ringing", "answered", "completed"]
        )

        pn.update!(status: :calling, twilio_sid: call.sid, last_log: "initiated call sid=#{call.sid}")
        # For robust solution: trust Twilio status callbacks to update final status.
      rescue StandardError => e
        pn.update!(status: :failed, last_log: "error: #{e.message}")
      end

      # Wait a short pause between calls to avoid rate limits and appear sequential
      sleep 2
    end
  end

  private

  def twilio_client
    return TWILIO_CLIENT if defined?(TWILIO_CLIENT)

    sid = ENV['TWILIO_ACCOUNT_SID']
    token = ENV['TWILIO_AUTH_TOKEN']
    from = ENV['TWILIO_FROM'].presence || ENV['TWILIO_PHONE_NUMBER'].presence
    return nil if sid.blank? || token.blank? || from.blank?
    Twilio::REST::Client.new(sid, token)
  rescue
    nil
  end

  def public_host
    ENV['PUBLIC_HOST'] || "http://localhost:3000"
  end
end

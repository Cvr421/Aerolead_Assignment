class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Twilio will request this to get TwiML
  def voice
    msg = params[:message].presence || "Hello, this is a demo call from Autodialer. This is a test only."
    response = Twilio::TwiML::VoiceResponse.new
    response.say(voice: "alice", language: "en-US") do |s|
      s.text msg
    end
    # optionally include <Pause> or <Hangup>
    render xml: response.to_s
  end

  # status callback to update DB when Twilio reports updates
  def status
    sid = params[:CallSid]
    call_status = params[:CallStatus] # "queued", "ringing", "in-progress", "completed", "failed", etc.
    pn = PhoneNumber.find_by(twilio_sid: sid)
    if pn
      case call_status
      when "queued"
        pn.update(status: :queued, last_log: "twilio: queued")
      when "ringing"
        pn.update(status: :calling, last_log: "twilio: ringing")
      when "in-progress"
        pn.update(status: :calling, last_log: "twilio: in-progress")
      when "completed"
        pn.update(status: :completed, last_log: "twilio: completed")
      else
        pn.update(status: :failed, last_log: "twilio: #{call_status}")
      end
    end
    head :ok
  end
end

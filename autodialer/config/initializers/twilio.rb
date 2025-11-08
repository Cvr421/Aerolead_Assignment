# Initialize Twilio client
require 'twilio-ruby'

TWILIO_CLIENT = Twilio::REST::Client.new(
  ENV['TWILIO_ACCOUNT_SID'],
  ENV['TWILIO_AUTH_TOKEN']
)

# Support either TWILIO_FROM (used in README/controllers) or TWILIO_PHONE_NUMBER
# (older variable). Prefer TWILIO_FROM if present.
TWILIO_FROM = ENV['TWILIO_FROM'].presence || ENV['TWILIO_PHONE_NUMBER'].presence
ELEVEN_LABS_API_KEY = ENV['ELEVEN_LABS_API_KEY']

unless Rails.env.test?
  missing_keys = []
  missing_keys << 'TWILIO_ACCOUNT_SID' unless ENV['TWILIO_ACCOUNT_SID'].present?
  missing_keys << 'TWILIO_AUTH_TOKEN' unless ENV['TWILIO_AUTH_TOKEN'].present?
  missing_keys << 'TWILIO_FROM or TWILIO_PHONE_NUMBER' unless TWILIO_FROM.present?

  if missing_keys.any?
    puts "Warning: Missing required environment variables: #{missing_keys.join(', ')}"
    puts "Please set these in your .env file"
  end
end
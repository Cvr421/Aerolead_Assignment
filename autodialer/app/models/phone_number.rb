class PhoneNumber < ApplicationRecord
  validates :number, presence: true, uniqueness: true
  # By default restrict phone validation to Indian numbers.
  # Set the env var ALLOW_NON_INDIAN=1 to allow any possible phone number
  # (useful for testing toll-free / international numbers locally).
  if ENV['ALLOW_NON_INDIAN'] == '1'
    validates :number, phone: { possible: true }
  else
    validates :number, phone: { possible: true, countries: [:in] }
  end

  enum status: {
    pending: 0,
    queued: 1, 
    calling: 2,
    completed: 3,
    failed: 4,
    no_answer: 5
  }

  scope :not_called, -> { where(status: :pending) }
  scope :called, -> { where.not(status: :pending) }
  scope :failed_calls, -> { where(status: [:failed, :no_answer]) }
  scope :successful_calls, -> { where(status: :completed) }

  def as_json(options = {})
    super(only: [:id, :number, :status, :last_log, :twilio_sid, :created_at, :updated_at])
  end

  def mark_call_started(sid)
    update(
      status: :calling,
      twilio_sid: sid,
      last_called_at: Time.current,
      call_attempts: call_attempts + 1
    )
  end

  def mark_call_completed(duration, status)
    update(
      status: status == "completed" ? :completed : :failed,
      call_duration: duration,
      call_status: status,
      last_log: "Call #{status} after #{duration} seconds"
    )
  end

  def format_for_twilio
    return number if number.start_with?('+')
    "+91#{number.gsub(/\D/, '')}"
  end
end

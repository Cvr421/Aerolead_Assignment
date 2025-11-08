class CreatePhoneNumbers < ActiveRecord::Migration[6.1]
  def change
    create_table :phone_numbers do |t|
      t.string :number, null: false
      t.integer :status, default: 0
      t.text :last_log
      t.string :twilio_sid
      t.datetime :last_called_at
      t.integer :call_attempts, default: 0
      t.string :call_duration
      t.string :call_status
      t.timestamps
    end

    add_index :phone_numbers, :number
  end
end

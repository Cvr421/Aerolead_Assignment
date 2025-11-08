# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2025_11_08_000000) do

  create_table "blog_posts", force: :cascade do |t|
    t.string "title", null: false
    t.text "body", null: false
    t.string "source", default: "ai"
    t.string "slug"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_blog_posts_on_created_at"
    t.index ["slug"], name: "index_blog_posts_on_slug"
  end

  create_table "phone_numbers", force: :cascade do |t|
    t.string "number", null: false
    t.integer "status", default: 0
    t.text "last_log"
    t.string "twilio_sid"
    t.datetime "last_called_at"
    t.integer "call_attempts", default: 0
    t.string "call_duration"
    t.string "call_status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["number"], name: "index_phone_numbers_on_number"
  end

end

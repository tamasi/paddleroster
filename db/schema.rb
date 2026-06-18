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

ActiveRecord::Schema[8.1].define(version: 2026_06_18_144321) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "canchas", force: :cascade do |t|
    t.bigint "complejo_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "sport", null: false
    t.datetime "updated_at", null: false
    t.index ["complejo_id"], name: "index_canchas_on_complejo_id"
  end

  create_table "complejos", force: :cascade do |t|
    t.string "contact_info"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "complex_players", force: :cascade do |t|
    t.bigint "complejo_id", null: false
    t.datetime "created_at", null: false
    t.bigint "player_id", null: false
    t.datetime "updated_at", null: false
    t.index ["complejo_id"], name: "index_complex_players_on_complejo_id"
    t.index ["player_id", "complejo_id"], name: "index_complex_players_on_player_id_and_complejo_id", unique: true
    t.index ["player_id"], name: "index_complex_players_on_player_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "complejo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "invited_by_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["complejo_id"], name: "index_invitations_on_complejo_id"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "paid_at", null: false
    t.bigint "registered_by_id"
    t.bigint "turno_id", null: false
    t.datetime "updated_at", null: false
    t.index ["paid_at"], name: "index_payments_on_paid_at"
    t.index ["registered_by_id"], name: "index_payments_on_registered_by_id"
    t.index ["turno_id"], name: "index_payments_on_turno_id"
  end

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.datetime "updated_at", null: false
    t.index ["phone"], name: "index_players_on_phone", unique: true
  end

  create_table "roster_entries", force: :cascade do |t|
    t.integer "confirmation_status", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "offered_at"
    t.bigint "player_id"
    t.integer "position", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.bigint "turno_id", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_roster_entries_on_player_id"
    t.index ["turno_id"], name: "index_roster_entries_on_turno_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "turnos", force: :cascade do |t|
    t.bigint "cancha_id", null: false
    t.datetime "created_at", null: false
    t.integer "origin", default: 0, null: false
    t.integer "payment_status", default: 0, null: false
    t.decimal "price", precision: 10, scale: 2
    t.boolean "recurring", default: false, null: false
    t.bigint "recurring_rule_id"
    t.string "reservation_name"
    t.datetime "start_time", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["cancha_id", "start_time"], name: "index_turnos_on_cancha_id_and_start_time_active", unique: true, where: "(status = 0)"
    t.index ["cancha_id"], name: "index_turnos_on_cancha_id"
    t.index ["recurring_rule_id"], name: "index_turnos_on_recurring_rule_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "complejo_id"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["complejo_id"], name: "index_users_on_complejo_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "whatsapp_inbox", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "phone", null: false
    t.boolean "processed", default: false, null: false
    t.text "raw_body", null: false
    t.datetime "updated_at", null: false
    t.index ["processed"], name: "index_whatsapp_inbox_on_processed"
  end

  create_table "whatsapp_outbox", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "phone", null: false
    t.integer "retry_count", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_whatsapp_outbox_on_status"
  end

  add_foreign_key "canchas", "complejos"
  add_foreign_key "complex_players", "complejos"
  add_foreign_key "complex_players", "players"
  add_foreign_key "invitations", "complejos"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "payments", "turnos"
  add_foreign_key "payments", "users", column: "registered_by_id"
  add_foreign_key "roster_entries", "players"
  add_foreign_key "roster_entries", "turnos"
  add_foreign_key "sessions", "users"
  add_foreign_key "turnos", "canchas"
  add_foreign_key "turnos", "turnos", column: "recurring_rule_id"
  add_foreign_key "users", "complejos"
end

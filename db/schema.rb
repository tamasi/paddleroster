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

ActiveRecord::Schema[8.1].define(version: 2026_06_12_220000) do
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

  create_table "roster_entries", force: :cascade do |t|
    t.integer "confirmation_status", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.bigint "turno_id", null: false
    t.datetime "updated_at", null: false
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

  add_foreign_key "canchas", "complejos"
  add_foreign_key "invitations", "complejos"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "roster_entries", "turnos"
  add_foreign_key "sessions", "users"
  add_foreign_key "turnos", "canchas"
  add_foreign_key "turnos", "turnos", column: "recurring_rule_id"
  add_foreign_key "users", "complejos"
end

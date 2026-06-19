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

ActiveRecord::Schema[8.1].define(version: 2026_06_19_194456) do
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

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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

  create_table "whatsapp_connections", force: :cascade do |t|
    t.bigint "complejo_id", null: false
    t.datetime "created_at", null: false
    t.string "phone"
    t.text "qr_code"
    t.string "requested_action"
    t.string "status", default: "disconnected", null: false
    t.datetime "updated_at", null: false
    t.index ["complejo_id"], name: "index_whatsapp_connections_on_complejo_id", unique: true
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
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "turnos", "canchas"
  add_foreign_key "turnos", "turnos", column: "recurring_rule_id"
  add_foreign_key "users", "complejos"
  add_foreign_key "whatsapp_connections", "complejos"
end

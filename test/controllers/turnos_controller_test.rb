require "test_helper"

class TurnosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @cancha = canchas(:one)
  end

  test "index requires authentication" do
    get calendario_path

    assert_redirected_to new_session_path
  end

  test "index renders for an authenticated user" do
    sign_in_as(@user)

    get calendario_path

    assert_response :success
  end

  test "index with specific date" do
    sign_in_as(@user)
    target_date = "2026-06-15"

    get calendario_path(date: target_date)

    assert_response :success
  end

  test "new renders form with cancha/horario pre-loaded" do
    sign_in_as(@user)

    get new_turno_path(cancha_id: @cancha.id, date: "2026-06-15", hour: 18)

    assert_response :success
    assert_select "span", text: /#{@cancha.name}/
  end

  test "new shows 'Marcar como recurrente' checkbox for owner" do
    sign_in_as(@user)

    get new_turno_path(cancha_id: @cancha.id, date: "2026-06-15", hour: 18)

    assert_response :success
    assert_select "input#turno_recurring[type=checkbox]"
  end

  test "new does not show 'Marcar como recurrente' checkbox for employee" do
    sign_in_as(users(:two))

    get new_turno_path(cancha_id: @cancha.id, date: "2026-06-15", hour: 18)

    assert_response :success
    assert_select "input#turno_recurring", count: 0
  end

  test "new redirects to calendario when cancha does not exist" do
    sign_in_as(@user)

    get new_turno_path(cancha_id: 0, date: "2026-06-15", hour: 18)

    assert_redirected_to calendario_path
  end

  test "create with valid data creates turno with roster entries and redirects to calendario" do
    sign_in_as(@user)

    assert_difference [ "Turno.count", "RosterEntry.count" ], 1 do
      post turnos_path, params: {
        cancha_id: @cancha.id, date: "2026-06-15", hour: 18,
        turno: {
          reservation_name: "Marcela",
          roster_entries_attributes: {
            "0" => { name: "Juan", position: 0 },
            "1" => { name: "", position: 1 }
          }
        }
      }
    end

    assert_redirected_to calendario_path(date: "2026-06-15")

    turno = Turno.order(:created_at).last
    assert_equal "Marcela", turno.reservation_name
    assert turno.manual?
    assert turno.pending?
    assert_equal 1, turno.roster_entries.count
    assert_equal "Juan", turno.roster_entries.first.name
  end

  test "create with recurring: 1 as owner marks turno recurring and enqueues job (AC1)" do
    sign_in_as(@user)

    assert_enqueued_with(job: GenerateRecurringTurnosJob) do
      post turnos_path, params: {
        cancha_id: @cancha.id, date: "2026-06-15", hour: 18,
        turno: { reservation_name: "Marcela", recurring: "1" }
      }
    end

    turno = Turno.order(:created_at).last
    assert turno.recurring?
    assert_enqueued_with(job: GenerateRecurringTurnosJob, args: [ turno.id ])
  end

  test "create with recurring: 1 as employee does not mark turno recurring and does not enqueue job (AC2)" do
    sign_in_as(users(:two))

    assert_no_enqueued_jobs only: GenerateRecurringTurnosJob do
      post turnos_path, params: {
        cancha_id: @cancha.id, date: "2026-06-15", hour: 18,
        turno: { reservation_name: "Marcela", recurring: "1" }
      }
    end

    turno = Turno.order(:created_at).last
    assert_not turno.recurring?
  end

  test "create without reservation_name is invalid and re-renders the form" do
    sign_in_as(@user)

    assert_no_difference "Turno.count" do
      post turnos_path, params: { cancha_id: @cancha.id, date: "2026-06-15", hour: 18, turno: { reservation_name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "create on an already occupied slot is rejected (AC5)" do
    sign_in_as(@user)
    Turno.create!(cancha: @cancha, start_time: Date.parse("2026-06-15").to_time.change(hour: 18), reservation_name: "Existente")

    assert_no_difference "Turno.count" do
      post turnos_path, params: { cancha_id: @cancha.id, date: "2026-06-15", hour: 18, turno: { reservation_name: "Marcela" } }
    end

    assert_response :unprocessable_entity
  end

  test "show renders detalle de turno with empty roster message" do
    sign_in_as(@user)
    turno = Turno.create!(cancha: @cancha, start_time: Time.current, reservation_name: "Marcela")

    get turno_path(turno)

    assert_response :success
    assert_select "p", text: /Todavía no cargaste el roster/
  end

  test "show renders existing roster entries without empty message" do
    sign_in_as(@user)
    turno = Turno.create!(cancha: @cancha, start_time: Time.current, reservation_name: "Marcela")
    turno.roster_entries.create!(name: "Juan", position: 0)

    get turno_path(turno)

    assert_response :success
    assert_select "p", text: /Todavía no cargaste el roster/, count: 0
  end

  test "cancel marks turno as cancelled and redirects to calendario with notice" do
    sign_in_as(@user)
    # Ensure start_time is in the future
    turno = Turno.create!(cancha: @cancha, start_time: 1.hour.from_now, reservation_name: "Marcela")

    patch cancel_turno_path(turno)

    assert_redirected_to calendario_path(date: turno.start_time.to_date)
    assert_equal "Turno cancelado", flash[:notice]
    assert turno.reload.cancelled?
  end

  test "cancel is idempotent when turno is already cancelled" do
    sign_in_as(@user)
    # Ensure start_time is in the future
    turno = Turno.create!(cancha: @cancha, start_time: 1.hour.from_now, reservation_name: "Marcela", status: :cancelled)

    patch cancel_turno_path(turno)

    assert_redirected_to calendario_path(date: turno.start_time.to_date)
    assert turno.reload.cancelled?
  end

  test "cannot cancel a past turno" do
    sign_in_as(@user)
    turno = Turno.create!(cancha: @cancha, start_time: 1.hour.ago, reservation_name: "Marcela")

    patch cancel_turno_path(turno)

    assert_redirected_to turno_path(turno)
    assert_equal "No se puede cancelar un turno pasado", flash[:alert]
    assert_not turno.reload.cancelled?
  end

  test "cancelled turno frees its slot in the calendario (AC1)" do
    sign_in_as(@user)
    target_date = Date.tomorrow
    turno = Turno.create!(cancha: @cancha, start_time: target_date.to_time.change(hour: 18), reservation_name: "Marcela")

    patch cancel_turno_path(turno)
    get calendario_path(date: target_date.to_s)

    assert_response :success
    assert_select "h3", text: "Marcela", count: 0
  end

  test "cancelling a bot turno does not modify its roster entries (AC2)" do
    sign_in_as(@user)
    turno = Turno.create!(cancha: @cancha, start_time: 1.hour.from_now, reservation_name: "Marcela", origin: :bot)
    turno.roster_entries.create!(name: "Juan", position: 0)

    patch cancel_turno_path(turno)

    assert_equal [ "Juan" ], turno.reload.roster_entries.order(:position).pluck(:name)
  end

  test "show renders Cancelar Turno button with confirmation only for future active turnos" do
    sign_in_as(@user)
    turno = Turno.create!(cancha: @cancha, start_time: 1.hour.from_now, reservation_name: "Marcela")

    get turno_path(turno)

    assert_response :success
    assert_select "form[action=?][data-turbo-confirm]", cancel_turno_path(turno)
  end

  test "show does not render Cancelar Turno button for past turnos" do
    sign_in_as(@user)
    turno = Turno.create!(cancha: @cancha, start_time: 1.hour.ago, reservation_name: "Marcela")

    get turno_path(turno)

    assert_response :success
    assert_select "form[action=?]", cancel_turno_path(turno), count: 0
  end

  test "recurring turno generates independent instances visible in future calendarios (AC3)" do
    sign_in_as(@user)
    target_date = Date.tomorrow

    assert_enqueued_with(job: GenerateRecurringTurnosJob) do
      post turnos_path, params: {
        cancha_id: @cancha.id, date: target_date.to_s, hour: 18,
        turno: { reservation_name: "Marcela", recurring: "1" }
      }
    end

    perform_enqueued_jobs

    instance = Turno.find_by(recurring_rule: Turno.order(:created_at).first, start_time: target_date.to_time.change(hour: 18) + 1.week)
    assert_not_nil instance
    assert instance.pending?

    get calendario_path(date: (target_date + 1.week).to_s)

    assert_response :success
    assert_select "h3", text: "Marcela"
  end

  test "cancelling a recurring instance does not affect the original turno nor other instances (AC4)" do
    sign_in_as(@user)
    target_date = Date.tomorrow

    post turnos_path, params: {
      cancha_id: @cancha.id, date: target_date.to_s, hour: 18,
      turno: { reservation_name: "Marcela", recurring: "1" }
    }

    perform_enqueued_jobs

    original = Turno.order(:created_at).first
    instances = original.recurring_instances.order(:start_time).to_a
    first_instance, second_instance = instances[0], instances[1]

    patch cancel_turno_path(first_instance)

    assert first_instance.reload.cancelled?
    assert original.reload.active?
    assert second_instance.reload.active?
  end

  test "update edits reservation_name and roster entries" do
    sign_in_as(@user)
    turno = Turno.create!(cancha: @cancha, start_time: Time.current, reservation_name: "Marcela")
    entry = turno.roster_entries.create!(name: "Juan", position: 0)

    patch turno_path(turno), params: {
      turno: {
        reservation_name: "Marcela Actualizada",
        roster_entries_attributes: {
          "0" => { id: entry.id, name: "Juan Actualizado", position: 0 }
        }
      }
    }

    assert_redirected_to turno_path(turno)
    turno.reload
    assert_equal "Marcela Actualizada", turno.reservation_name
    assert_equal "Juan Actualizado", turno.roster_entries.first.name
  end

  test "update ignores recurring param and does not enqueue the generator job" do
    sign_in_as(@user)
    turno = Turno.create!(cancha: @cancha, start_time: Time.current, reservation_name: "Marcela")

    assert_no_enqueued_jobs only: GenerateRecurringTurnosJob do
      patch turno_path(turno), params: { turno: { reservation_name: "Marcela", recurring: "1" } }
    end

    assert_not turno.reload.recurring?
  end
end

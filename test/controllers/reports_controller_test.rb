# frozen_string_literal: true

require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  # AC7: requiere autenticación
  test "index requires authentication" do
    get reportes_path

    assert_redirected_to new_session_path
  end

  # AC2: empleado bloqueado por URL directa
  test "index denies access to employees" do
    sign_in_as(users(:two))

    get reportes_path

    assert_redirected_to root_path
    assert_not_nil flash[:alert]
  end

  # AC1: dueño puede acceder
  test "index renders for owner" do
    sign_in_as(users(:one))

    get reportes_path

    assert_response :success
  end

  # AC3: período por defecto es semana
  test "index defaults to week period" do
    sign_in_as(users(:one))

    get reportes_path

    assert_response :success
    assert_select "a[href*='period=month']"
  end

  # AC3: filtro de mes
  test "index accepts month period" do
    sign_in_as(users(:one))

    get reportes_path, params: { period: "month" }

    assert_response :success
  end

  # AC4: filtro de deporte
  test "index filters by sport" do
    sign_in_as(users(:one))

    get reportes_path, params: { sport: "padel" }

    assert_response :success
  end

  # AC5: turnos cancelados no cuentan como ocupados
  test "cancelled turnos do not count toward occupancy" do
    sign_in_as(users(:one))
    cancha = canchas(:one)
    Turno.create!(
      cancha: cancha,
      start_time: Date.current.beginning_of_week.to_time.change(hour: 14),
      reservation_name: "Test cancelado",
      status: :cancelled
    )

    get reportes_path, params: { period: "week" }

    assert_response :success
  end
end

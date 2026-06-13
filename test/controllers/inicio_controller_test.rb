require "test_helper"

class InicioControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @employee = users(:two)
    @cancha = canchas(:one)
  end

  test "index requires authentication" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "index renders for owner" do
    sign_in_as(@owner)

    get root_path

    assert_response :success
  end

  test "index renders for employee with the same information (AC4)" do
    sign_in_as(@employee)

    get root_path

    assert_response :success
    assert_select "[data-testid='occupancy-bar']", count: @owner.complejo.canchas.count
  end

  test "index shows an occupancy bar per cancha with percentage (AC1)" do
    sign_in_as(@owner)
    Turno.create!(cancha: @cancha, start_time: Time.zone.now.change(hour: 14), reservation_name: "Turno A", status: :active)

    get root_path

    assert_response :success
    assert_select "[data-testid='occupancy-bar']", count: @owner.complejo.canchas.count
    assert_select "[data-testid='occupancy-bar']", text: /10%/
  end

  test "index shows 'No hay turnos para hoy' and 0% bars when there are no turnos (AC2)" do
    sign_in_as(@owner)

    get root_path

    assert_response :success
    assert_select "p", text: "No hay turnos para hoy"
    assert_select "[data-testid='occupancy-bar']", text: /0%/, count: @owner.complejo.canchas.count
  end

  test "index excludes cancelled turnos from occupancy" do
    sign_in_as(@owner)
    Turno.create!(cancha: @cancha, start_time: Time.zone.now.change(hour: 14), reservation_name: "Turno A", status: :cancelled)

    get root_path

    assert_response :success
    assert_select "p", text: "No hay turnos para hoy"
  end

  test "index shows 'No hay canchas configuradas' for a complejo without canchas" do
    complejo = Complejo.create!(name: "Complejo Vacío")
    owner = User.create!(email_address: "vacio@example.com", password: "password", role: :owner, complejo: complejo)
    sign_in_as(owner)

    get root_path

    assert_response :success
    assert_select "p", text: /No hay canchas configuradas/
    assert_select "[data-testid='occupancy-bar']", count: 0
  end
end

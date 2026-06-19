require_relative "application_system_test_case"

class CalendarioTest < ApplicationSystemTestCase
  setup do
    @user = users(:one) # owner associated with complejo_piloto
    @cancha = canchas(:one)

    visit new_session_path
    fill_in "email_address", with: @user.email_address
    fill_in "password", with: "password"
    click_on "Ingresar"
  end

  test "visiting the calendario shows canchas and empty slots" do
    visit calendario_url

    assert_selector "h1", text: /#{I18n.l(Date.current, format: "%A %d de %B", locale: :es)}/i

    # Check headers
    assert_text @cancha.name

    # Check empty slots
    assert_selector "button", text: /Cancha libre/i
  end

  test "visiting the calendario shows turnos" do
    # Create a turno for today at 15:00
    Turno.create!(start_time: Date.current.change(hour: 15), cancha: @cancha, reservation_name: "Marcela", origin: :manual, payment_status: :pending)

    visit calendario_url

    # Should see the turno card
    assert_selector "span", text: "15:00"
    assert_selector "span", text: /Pago Pendiente/i
  end
end

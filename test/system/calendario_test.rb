require_relative "application_system_test_case"

class CalendarioTest < ApplicationSystemTestCase
  setup do
    @user = users(:one) # owner associated with complejo_piloto
    @cancha = canchas(:one)

    visit new_session_path
    fill_in "email_address", with: @user.email_address
    fill_in "password", with: "password"
    click_on "Ingresar"

    # Esperar a que termine la navegación (Turbo, asíncrona) antes de que los
    # tests hagan su propio `visit` — si no, ese `visit` puede cancelar en
    # pleno vuelo el POST de login y la sesión nunca llega a establecerse.
    # El email del usuario está en el header de toda página autenticada
    # (AppHeaderComponent), a diferencia de "ausencia del h1 de login": eso
    # podía pasar de forma trivial en cualquier página sin h1, sin probar
    # realmente que la sesión quedó establecida.
    assert_text @user.email_address
  end

  test "visiting the calendario shows canchas and empty slots" do
    visit calendario_url

    assert_selector "h1", text: /#{I18n.l(Date.current, format: "%A %d de %B", locale: :es)}/i

    # Check headers
    assert_text @cancha.name

    # Check empty slots (son links estilizados como botón, no <button>)
    assert_selector "a", text: /Cancha libre/i
  end

  test "visiting the calendario shows turnos" do
    # Create a turno for today at 15:00 — Date#change ignora :hour (un Date no
    # tiene componente de hora); hace falta Time.current para que surta efecto.
    Turno.create!(start_time: Time.current.change(hour: 15, min: 0, sec: 0), cancha: @cancha, reservation_name: "Marcela", origin: :manual, payment_status: :pending)

    visit calendario_url

    # Should see the turno card
    assert_selector "span", text: "15:00"
    assert_selector "span", text: /Pago Pendiente/i
  end
end

require "test_helper"

class CardTurnoComponentTest < ViewComponent::TestCase
  test "renders turno information" do
    cancha = canchas(:one)
    turno = Turno.create!(start_time: Time.current.change(hour: 18), cancha: cancha, payment_status: :pending, reservation_name: "Marcela")

    render_inline(CardTurnoComponent.new(turno: turno))

    assert_selector "span", text: /Cancha de Padel 1/
    assert_selector "span", text: "18:00"
    assert_selector "span", text: /Pago Pendiente/i
    assert_selector "h3", text: "Marcela"
    assert_selector "p", text: "Sin roster cargado"
  end

  test "shows roster count when roster entries are present" do
    cancha = canchas(:one)
    turno = Turno.create!(start_time: Time.current.change(hour: 19), cancha: cancha, reservation_name: "Marcela")
    turno.roster_entries.create!(name: "Juan", position: 0)
    turno.roster_entries.create!(name: "Pedro", position: 1)

    render_inline(CardTurnoComponent.new(turno: turno))

    assert_selector "p", text: "2 jugadores cargados"
  end
end

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

  test "bot-origin turno shows X/Y confirmados among titulares" do
    cancha = canchas(:one)
    turno = Turno.create!(start_time: Time.current.change(hour: 19), cancha: cancha, reservation_name: "Marcela", origin: :bot)
    turno.roster_entries.create!(name: "Juan", role: :titular, confirmation_status: :confirmed, position: 0)
    turno.roster_entries.create!(name: "Pedro", role: :titular, confirmation_status: :pending, position: 1)
    turno.roster_entries.create!(name: "Suplente", role: :suplente, confirmation_status: :pending, position: 2)

    render_inline(CardTurnoComponent.new(turno: turno))

    assert_selector "p", text: "1/2 confirmados"
  end

  test "bot-origin turno without roster shows Sin roster cargado" do
    cancha = canchas(:one)
    turno = Turno.create!(start_time: Time.current.change(hour: 19), cancha: cancha, reservation_name: "Marcela", origin: :bot)

    render_inline(CardTurnoComponent.new(turno: turno))

    assert_selector "p", text: "Sin roster cargado"
  end

  test "shows amount paid alongside status-pill when payment is partial" do
    cancha = canchas(:one)
    turno = Turno.create!(start_time: Time.current.change(hour: 20), cancha: cancha, payment_status: :partial, reservation_name: "Marcela")
    turno.payments.create!(amount: 5000, paid_at: Time.current)

    render_inline(CardTurnoComponent.new(turno: turno))

    assert_selector "span", text: /Pago Parcial/i
    assert_text "$5.000"
  end

  test "does not show amount when payment is pending" do
    cancha = canchas(:one)
    turno = Turno.create!(start_time: Time.current.change(hour: 21), cancha: cancha, payment_status: :pending, reservation_name: "Marcela")

    render_inline(CardTurnoComponent.new(turno: turno))

    assert_no_text "$"
  end

  test "does not show amount when payment is paid" do
    cancha = canchas(:one)
    turno = Turno.create!(start_time: Time.current.change(hour: 22), cancha: cancha, payment_status: :paid, reservation_name: "Marcela")
    turno.payments.create!(amount: 10000, paid_at: Time.current)

    render_inline(CardTurnoComponent.new(turno: turno))

    assert_no_text "$"
  end
end

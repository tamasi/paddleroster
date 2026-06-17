# frozen_string_literal: true

require "test_helper"

class BotTurnoCreationServiceTest < ActiveSupport::TestCase
  CAPTAIN_PHONE = "+5491199990000"

  def valid_message(cancha: "Cancha de Padel 1", fecha: nil, jugadores: nil)
    fecha ||= (Date.current + 1).strftime("%d/%m/%Y")
    jugadores ||= "Carlos Pérez +5491155551111\nAna García +5491155552222"
    <<~MSG
      TURNO
      cancha: #{cancha}
      fecha: #{fecha}
      horario: 18:00
      jugadores:
      #{jugadores}
    MSG
  end

  # ── Happy path ────────────────────────────────────────────────────────────────

  test "creates turno with titulares" do
    result = BotTurnoCreationService.new(CAPTAIN_PHONE, valid_message).call
    assert result.success?, result.errors.inspect
    turno = result.turno
    assert_equal :bot, turno.origin.to_sym
    assert_equal 2, turno.roster_entries.titular.count
    assert turno.roster_entries.all?(&:pending?)
  end

  test "creates players and complex_players on first message" do
    phone = "+5491100000001"
    msg = valid_message(jugadores: "Nuevo Jugador #{phone}")
    assert_difference("Player.count", 1) do
      assert_difference("ComplexPlayer.count", 1) do
        BotTurnoCreationService.new(CAPTAIN_PHONE, msg).call
      end
    end
  end

  test "reuses existing player by phone" do
    player = players(:carlos)
    msg = valid_message(jugadores: "Nombre Diferente #{player.phone}")
    assert_no_difference("Player.count") do
      BotTurnoCreationService.new(CAPTAIN_PHONE, msg).call
    end
    entry = Turno.last.roster_entries.first
    assert_equal player.name, entry.name
  end

  test "creates suplentes with suplente role" do
    fecha = (Date.current + 1).strftime("%d/%m/%Y")
    msg = <<~MSG
      TURNO
      cancha: Cancha de Padel 1
      fecha: #{fecha}
      horario: 20:00
      jugadores:
      Titular Uno +5491100000011
      suplentes:
      Suplente Dos +5491100000022
    MSG
    result = BotTurnoCreationService.new(CAPTAIN_PHONE, msg).call
    assert result.success?, result.errors.inspect
    assert_equal 1, result.turno.roster_entries.titular.count
    assert_equal 1, result.turno.roster_entries.suplente.count
  end

  test "reservation_name is first titular name" do
    result = BotTurnoCreationService.new(CAPTAIN_PHONE, valid_message).call
    assert result.success?
    assert_equal "Carlos Pérez", result.turno.reservation_name
  end

  test "turno has active status and pending payment_status" do
    result = BotTurnoCreationService.new(CAPTAIN_PHONE, valid_message).call
    assert result.success?
    assert result.turno.active?
    assert_equal "pending", result.turno.payment_status
  end

  # ── Validation errors ─────────────────────────────────────────────────────────

  test "fails when cancha field missing" do
    msg = valid_message.sub(/cancha:.*\n/, "")
    result = BotTurnoCreationService.new(CAPTAIN_PHONE, msg).call
    assert_not result.success?
    assert_includes result.errors.first, "cancha"
  end

  test "fails when cancha not found" do
    result = BotTurnoCreationService.new(CAPTAIN_PHONE, valid_message(cancha: "Cancha Inexistente")).call
    assert_not result.success?
    assert result.errors.any? { |e| e.include?("no encontrada") }
  end

  test "fails when fecha missing" do
    msg = valid_message.sub(/fecha:.*\n/, "")
    result = BotTurnoCreationService.new(CAPTAIN_PHONE, msg).call
    assert_not result.success?
    assert_includes result.errors.first, "fecha"
  end

  test "fails for past date" do
    result = BotTurnoCreationService.new(CAPTAIN_PHONE, valid_message(fecha: "01/01/2020")).call
    assert_not result.success?
    assert result.errors.any? { |e| e.include?("pasó") }
  end

  test "fails for invalid date format" do
    result = BotTurnoCreationService.new(CAPTAIN_PHONE, valid_message(fecha: "2026-12-01")).call
    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Fecha inválida") }
  end

  test "fails when horario out of operating hours" do
    fecha = (Date.current + 1).strftime("%d/%m/%Y")
    msg = <<~MSG
      TURNO
      cancha: Cancha de Padel 1
      fecha: #{fecha}
      horario: 08:00
      jugadores:
      Carlos +5491100000099
    MSG
    result = BotTurnoCreationService.new(CAPTAIN_PHONE, msg).call
    assert_not result.success?
    assert result.errors.any? { |e| e.include?("horario operativo") }
  end

  test "fails when no jugadores provided" do
    fecha = (Date.current + 1).strftime("%d/%m/%Y")
    msg = <<~MSG
      TURNO
      cancha: Cancha de Padel 1
      fecha: #{fecha}
      horario: 18:00
      jugadores:
    MSG
    result = BotTurnoCreationService.new(CAPTAIN_PHONE, msg).call
    assert_not result.success?
    assert result.errors.any? { |e| e.include?("al menos 1 jugador") }
  end

  test "fails with duplicate phones" do
    phone = "+5491155551111"
    msg = valid_message(jugadores: "Jugador A #{phone}\nJugador B #{phone}")
    result = BotTurnoCreationService.new(CAPTAIN_PHONE, msg).call
    assert_not result.success?
    assert result.errors.any? { |e| e.include?("duplicado") }
  end
end

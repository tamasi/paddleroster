# frozen_string_literal: true

require "test_helper"

class BotConfirmationServiceTest < ActiveSupport::TestCase
  def create_turno(start_time: 1.day.from_now.change(min: 0), status: :active, origin: :bot)
    Turno.create!(cancha: canchas(:one), start_time: start_time, reservation_name: "Test", origin: origin, status: status)
  end

  def create_entry(turno:, phone:, role: :titular, confirmation_status: :pending, name: "Jugador", offered_at: nil)
    player = Player.find_or_create_by!(phone: phone) { |p| p.name = name }
    turno.roster_entries.create!(player: player, name: name, role: role, confirmation_status: confirmation_status, position: turno.roster_entries.count, offered_at: offered_at)
  end

  # ── Respuesta afirmativa (AC2) ────────────────────────────────────────────────

  test "SI confirms the pending entry" do
    phone = "+5491100001001"
    turno = create_turno
    entry = create_entry(turno: turno, phone: phone)

    result = BotConfirmationService.new(phone, "SI").call

    assert result.handled?
    assert entry.reload.confirmed?
    assert_includes result.reply_text, "Confirm"
  end

  test "sí (lowercase, accented) confirms the pending entry" do
    phone = "+5491100001002"
    turno = create_turno
    entry = create_entry(turno: turno, phone: phone)

    result = BotConfirmationService.new(phone, "sí").call

    assert result.handled?
    assert entry.reload.confirmed?
  end

  test "Confirmo confirms the pending entry" do
    phone = "+5491100001003"
    turno = create_turno
    entry = create_entry(turno: turno, phone: phone)

    result = BotConfirmationService.new(phone, "Confirmo").call

    assert result.handled?
    assert entry.reload.confirmed?
  end

  # ── Respuesta negativa (AC3) ──────────────────────────────────────────────────

  test "NO marks the entry as uncovered" do
    phone = "+5491100001004"
    turno = create_turno
    entry = create_entry(turno: turno, phone: phone)

    result = BotConfirmationService.new(phone, "NO").call

    assert result.handled?
    assert entry.reload.uncovered?
    assert result.reply_text.present?
  end

  test "no puedo marks the entry as uncovered" do
    phone = "+5491100001005"
    turno = create_turno
    entry = create_entry(turno: turno, phone: phone)

    result = BotConfirmationService.new(phone, "no puedo").call

    assert result.handled?
    assert entry.reload.uncovered?
  end

  # ── Respuesta ambigua (AC4) ───────────────────────────────────────────────────

  test "ambiguous reply does not change confirmation_status and re-sends options" do
    phone = "+5491100001006"
    turno = create_turno
    entry = create_entry(turno: turno, phone: phone)

    result = BotConfirmationService.new(phone, "no sé, tal vez").call

    assert result.handled?
    assert entry.reload.pending?
    assert_includes result.reply_text, "SI"
    assert_includes result.reply_text, "NO"
  end

  # ── Sin pending_entry ─────────────────────────────────────────────────────────

  test "no pending entry for phone returns handled? false" do
    result = BotConfirmationService.new("+5491100009999", "SI").call

    assert_not result.handled?
  end

  test "suplente pending entry does not match" do
    phone = "+5491100001007"
    turno = create_turno
    create_entry(turno: turno, phone: phone, role: :suplente)

    result = BotConfirmationService.new(phone, "SI").call

    assert_not result.handled?
  end

  test "pending entry of a cancelled turno does not match" do
    phone = "+5491100001008"
    turno = create_turno(start_time: 2.days.from_now.change(min: 0), status: :cancelled)
    create_entry(turno: turno, phone: phone)

    result = BotConfirmationService.new(phone, "SI").call

    assert_not result.handled?
  end

  # ── Selección del turno más próximo ──────────────────────────────────────────

  test "prioritizes the closest upcoming turno when multiple pending entries exist" do
    phone = "+5491100001009"
    near_turno = create_turno(start_time: 1.day.from_now.change(min: 0))
    far_turno = create_turno(start_time: 5.days.from_now.change(min: 0))
    near_entry = create_entry(turno: near_turno, phone: phone)
    create_entry(turno: far_turno, phone: phone)

    result = BotConfirmationService.new(phone, "SI").call

    assert_equal near_entry, result.roster_entry
  end

  test "ignores a past pending entry and answers the future one" do
    phone = "+5491100001010"
    past_turno = create_turno(start_time: 1.day.ago.change(min: 0))
    future_turno = create_turno(start_time: 3.days.from_now.change(min: 0))
    create_entry(turno: past_turno, phone: phone)
    future_entry = create_entry(turno: future_turno, phone: phone)

    result = BotConfirmationService.new(phone, "SI").call

    assert_equal future_entry, result.roster_entry
  end

  test "uses a deterministic tiebreak when two pending turnos share the exact same start_time" do
    phone = "+5491100001012"
    shared_time = 2.days.from_now.change(min: 0)
    turno_a = create_turno(start_time: shared_time)
    turno_b = Turno.create!(cancha: canchas(:two), start_time: shared_time, reservation_name: "Test", origin: :bot, status: :active)
    entry_a = create_entry(turno: turno_a, phone: phone)
    create_entry(turno: turno_b, phone: phone)

    result = BotConfirmationService.new(phone, "SI").call

    assert_equal entry_a, result.roster_entry
  end

  # ── Scope a Turnos de Origen Bot ─────────────────────────────────────────────

  test "manual-origin turno's roster entry does not match even if linked to a player" do
    phone = "+5491100001011"
    turno = create_turno(origin: :manual)
    create_entry(turno: turno, phone: phone)

    result = BotConfirmationService.new(phone, "SI").call

    assert_not result.handled?
  end

  # ── Suplentes con oferta activa (Story 5.4) ──────────────────────────────────

  test "SI from a suplente with an active offer marks the entry as replacement and notifies the captain" do
    captain_phone  = "+5491100001013"
    suplente_phone = "+5491100001014"
    turno    = create_turno
    captain  = create_entry(turno: turno, phone: captain_phone, name: "Capitan")
    suplente = create_entry(turno: turno, phone: suplente_phone, role: :suplente, name: "Suplente Uno", offered_at: 10.minutes.ago)

    result = BotConfirmationService.new(suplente_phone, "SI").call

    assert result.handled?
    assert suplente.reload.replacement?
    assert_equal suplente, result.roster_entry

    captain_msg = WhatsappOutboxMessage.where(phone: captain.player.phone).last
    assert_includes captain_msg.body, "cubierto"
    assert_includes captain_msg.body, "Suplente Uno"
  end

  test "NO from a suplente with an active offer marks it uncovered and triggers the replacement flow" do
    captain_phone   = "+5491100001015"
    suplente1_phone = "+5491100001016"
    turno     = create_turno
    create_entry(turno: turno, phone: captain_phone, name: "Capitan")
    suplente1 = create_entry(turno: turno, phone: suplente1_phone, role: :suplente, name: "Suplente Uno", offered_at: 10.minutes.ago)
    suplente2 = create_entry(turno: turno, phone: "+5491100001017", role: :suplente, name: "Suplente Dos")

    result = BotConfirmationService.new(suplente1_phone, "NO").call

    assert result.handled?
    assert suplente1.reload.uncovered?
    assert suplente2.reload.offered_at.present?, "debe ofrecerse el cupo al siguiente suplente"
  end

  test "SI from a suplente without an active offer is ignored (handled? false)" do
    phone = "+5491100001018"
    turno = create_turno
    create_entry(turno: turno, phone: phone, role: :suplente)

    result = BotConfirmationService.new(phone, "SI").call

    assert_not result.handled?
  end
end

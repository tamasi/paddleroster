# frozen_string_literal: true

require "test_helper"

class RosterReplacementServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def create_turno(start_time: 1.day.from_now.change(min: 0))
    Turno.create!(cancha: canchas(:one), start_time: start_time, reservation_name: "Test", origin: :bot, status: :active)
  end

  def create_entry(turno:, role:, position:, phone:, name:, confirmation_status: :pending, offered_at: nil)
    player = Player.find_or_create_by!(phone: phone) { |p| p.name = name }
    turno.roster_entries.create!(
      player: player, name: name, role: role, position: position,
      confirmation_status: confirmation_status, offered_at: offered_at
    )
  end

  # ── AC1 / AC2: ofrecimiento al siguiente suplente ──────────────────────────────

  test "offers the slot to the first pending suplente without offered_at, in position order" do
    turno     = create_turno
    captain   = create_entry(turno: turno, role: :titular, position: 0, phone: "+5491100002001", name: "Capitan")
    titular   = create_entry(turno: turno, role: :titular, position: 1, phone: "+5491100002002", name: "Titular Uno", confirmation_status: :uncovered)
    suplente1 = create_entry(turno: turno, role: :suplente, position: 2, phone: "+5491100002003", name: "Suplente Uno")
    suplente2 = create_entry(turno: turno, role: :suplente, position: 3, phone: "+5491100002004", name: "Suplente Dos")

    RosterReplacementService.new(titular).call

    assert suplente1.reload.offered_at.present?
    assert_nil suplente2.reload.offered_at

    offer_msg = WhatsappOutboxMessage.find_by(phone: suplente1.player.phone)
    assert offer_msg
    assert_includes offer_msg.body, "Suplente Uno"

    captain_msg = WhatsappOutboxMessage.where(phone: captain.player.phone).last
    assert_includes captain_msg.body, "Titular Uno"
    assert_includes captain_msg.body, "Suplente Uno"
  end

  test "skips suplentes that already have an offer in progress" do
    turno     = create_turno
    create_entry(turno: turno, role: :titular, position: 0, phone: "+5491100002005", name: "Capitan")
    titular   = create_entry(turno: turno, role: :titular, position: 1, phone: "+5491100002006", name: "Titular", confirmation_status: :uncovered)
    original_offer_time = 5.minutes.ago
    suplente1 = create_entry(turno: turno, role: :suplente, position: 2, phone: "+5491100002007", name: "Suplente Ya Ofrecido", offered_at: original_offer_time)
    suplente2 = create_entry(turno: turno, role: :suplente, position: 3, phone: "+5491100002008", name: "Suplente Libre")

    RosterReplacementService.new(titular).call

    assert suplente2.reload.offered_at.present?
    assert_in_delta original_offer_time.to_i, suplente1.reload.offered_at.to_i, 2
  end

  # ── AC3: plazo de respuesta ─────────────────────────────────────────────────────

  test "schedules the timeout job with a 2 hour wait when the turno starts in more than 2 hours" do
    turno     = create_turno(start_time: 5.hours.from_now.change(min: 0))
    create_entry(turno: turno, role: :titular, position: 0, phone: "+5491100002009", name: "Capitan")
    titular   = create_entry(turno: turno, role: :titular, position: 1, phone: "+5491100002010", name: "Titular", confirmation_status: :uncovered)
    suplente  = create_entry(turno: turno, role: :suplente, position: 2, phone: "+5491100002011", name: "Suplente")

    assert_enqueued_with(job: CheckReplacementTimeoutJob, args: [ suplente.id ]) do
      RosterReplacementService.new(titular).call
    end

    enqueued = enqueued_jobs.find { |j| j[:job] == CheckReplacementTimeoutJob }
    assert_in_delta 2.hours.from_now.to_i, enqueued[:at], 5
  end

  test "schedules the timeout job with a 15 minute wait when the turno starts in less than 2 hours" do
    turno     = create_turno(start_time: 1.hour.from_now)
    create_entry(turno: turno, role: :titular, position: 0, phone: "+5491100002012", name: "Capitan")
    titular   = create_entry(turno: turno, role: :titular, position: 1, phone: "+5491100002013", name: "Titular", confirmation_status: :uncovered)
    suplente  = create_entry(turno: turno, role: :suplente, position: 2, phone: "+5491100002014", name: "Suplente")

    assert_enqueued_with(job: CheckReplacementTimeoutJob, args: [ suplente.id ]) do
      RosterReplacementService.new(titular).call
    end

    enqueued = enqueued_jobs.find { |j| j[:job] == CheckReplacementTimeoutJob }
    assert_in_delta 15.minutes.from_now.to_i, enqueued[:at], 5
  end

  # ── AC5: sin suplentes disponibles ──────────────────────────────────────────────

  test "notifies the captain that no replacement was found when there are no suplentes left" do
    turno   = create_turno
    captain = create_entry(turno: turno, role: :titular, position: 0, phone: "+5491100002015", name: "Capitan")
    titular = create_entry(turno: turno, role: :titular, position: 1, phone: "+5491100002016", name: "Titular Sin Cupo", confirmation_status: :uncovered)

    RosterReplacementService.new(titular).call

    captain_msg = WhatsappOutboxMessage.where(phone: captain.player.phone).last
    assert_includes captain_msg.body, "⚠️"
    assert_includes captain_msg.body, "Titular Sin Cupo"
  end

  # ── Flujo completo end-to-end (decline -> oferta -> timeout -> oferta -> confirma) ──

  test "full flow: decline titular -> offers suplente 1 -> timeout -> offers suplente 2 -> suplente 2 confirms -> done" do
    turno     = create_turno
    captain   = create_entry(turno: turno, role: :titular, position: 0, phone: "+5491100002017", name: "Capitan")
    titular   = create_entry(turno: turno, role: :titular, position: 1, phone: "+5491100002018", name: "Titular", confirmation_status: :uncovered)
    suplente1 = create_entry(turno: turno, role: :suplente, position: 2, phone: "+5491100002019", name: "Suplente Uno")
    suplente2 = create_entry(turno: turno, role: :suplente, position: 3, phone: "+5491100002020", name: "Suplente Dos")

    RosterReplacementService.new(titular).call
    assert suplente1.reload.offered_at.present?
    assert_nil suplente2.reload.offered_at

    # Vence el plazo del suplente 1 sin respuesta
    CheckReplacementTimeoutJob.perform_now(suplente1.id)
    assert suplente1.reload.uncovered?
    assert suplente2.reload.offered_at.present?

    # Suplente 2 confirma vía el Bot
    result = BotConfirmationService.new(suplente2.player.phone, "SI").call
    assert result.handled?
    assert suplente2.reload.replacement?

    success_msg = WhatsappOutboxMessage.where(phone: captain.player.phone).order(:created_at).last
    assert_includes success_msg.body, "cubierto"
    assert_includes success_msg.body, "Suplente Dos"
  end
end

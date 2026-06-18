# frozen_string_literal: true

require "test_helper"

class CheckReplacementTimeoutJobTest < ActiveSupport::TestCase
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

  test "marks the entry as uncovered and re-triggers RosterReplacementService when the offer expired" do
    turno     = create_turno
    create_entry(turno: turno, role: :titular, position: 0, phone: "+5491100003001", name: "Capitan")
    suplente1 = create_entry(turno: turno, role: :suplente, position: 1, phone: "+5491100003002", name: "Suplente Uno", offered_at: 3.hours.ago)
    suplente2 = create_entry(turno: turno, role: :suplente, position: 2, phone: "+5491100003003", name: "Suplente Dos")

    CheckReplacementTimeoutJob.perform_now(suplente1.id)

    assert suplente1.reload.uncovered?
    assert suplente2.reload.offered_at.present?
  end

  test "does nothing when the entry already confirmed before the timeout fired" do
    turno    = create_turno
    create_entry(turno: turno, role: :titular, position: 0, phone: "+5491100003004", name: "Capitan")
    suplente = create_entry(turno: turno, role: :suplente, position: 1, phone: "+5491100003005", name: "Suplente",
                             confirmation_status: :replacement, offered_at: 20.minutes.ago)

    CheckReplacementTimeoutJob.perform_now(suplente.id)

    assert suplente.reload.replacement?
  end

  test "does nothing when the entry no longer exists" do
    assert_nothing_raised do
      CheckReplacementTimeoutJob.perform_now(0)
    end
  end

  test "does nothing when the entry is pending but was never offered" do
    turno    = create_turno
    create_entry(turno: turno, role: :titular, position: 0, phone: "+5491100003006", name: "Capitan")
    suplente = create_entry(turno: turno, role: :suplente, position: 1, phone: "+5491100003007", name: "Suplente")

    CheckReplacementTimeoutJob.perform_now(suplente.id)

    assert suplente.reload.pending?
    assert_nil suplente.offered_at
  end

  test "does nothing yet when the offer was made recently and the deadline has not passed" do
    turno    = create_turno
    create_entry(turno: turno, role: :titular, position: 0, phone: "+5491100003008", name: "Capitan")
    suplente = create_entry(turno: turno, role: :suplente, position: 1, phone: "+5491100003009", name: "Suplente", offered_at: 5.minutes.ago)

    CheckReplacementTimeoutJob.perform_now(suplente.id)

    assert suplente.reload.pending?
  end
end

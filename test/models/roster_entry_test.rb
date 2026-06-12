require "test_helper"

class RosterEntryTest < ActiveSupport::TestCase
  setup do
    @turno = Turno.create!(start_time: Time.current, cancha: canchas(:one), reservation_name: "Marcela")
  end

  test "requires name" do
    entry = RosterEntry.new(turno: @turno)
    assert_not entry.valid?
    assert_not_empty entry.errors[:name]
  end

  test "belongs to a turno" do
    entry = RosterEntry.new(name: "Juan")
    assert_not entry.valid?
    assert_not_empty entry.errors[:turno]
  end

  test "has default role titular and confirmation_status pending" do
    entry = RosterEntry.new(turno: @turno, name: "Juan")
    assert entry.titular?
    assert entry.pending?
  end

  test "is valid with required attributes" do
    entry = RosterEntry.new(turno: @turno, name: "Juan")
    assert entry.valid?
  end
end

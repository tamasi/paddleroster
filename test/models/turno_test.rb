require "test_helper"

class TurnoTest < ActiveSupport::TestCase
  setup do
    @cancha = canchas(:one)
  end

  test "requires start_time" do
    turno = Turno.new(cancha: @cancha)
    assert_not turno.valid?
    assert_not_empty turno.errors[:start_time]
  end

  test "has default origin manual" do
    turno = Turno.new(start_time: Time.current, cancha: @cancha, reservation_name: "Marcela")
    assert turno.manual?
  end

  test "has default payment_status pending" do
    turno = Turno.new(start_time: Time.current, cancha: @cancha, reservation_name: "Marcela")
    assert turno.pending?
  end

  test "is valid with required attributes" do
    turno = Turno.new(start_time: Time.current, cancha: @cancha, reservation_name: "Marcela")
    assert turno.valid?
  end

  test "requires reservation_name" do
    turno = Turno.new(start_time: Time.current, cancha: @cancha)
    assert_not turno.valid?
    assert_not_empty turno.errors[:reservation_name]
  end

  test "does not allow two turnos for the same cancha and start_time" do
    start_time = Time.current.change(min: 0)
    Turno.create!(start_time: start_time, cancha: @cancha, reservation_name: "Marcela")

    duplicate = Turno.new(start_time: start_time, cancha: @cancha, reservation_name: "Otro")
    assert_not duplicate.valid?
    assert_not_empty duplicate.errors[:start_time]
  end

  test "has default status active" do
    turno = Turno.new(start_time: Time.current, cancha: @cancha, reservation_name: "Marcela")
    assert turno.active?
  end

  test "allows a new turno on the same slot when the previous one is cancelled" do
    start_time = Time.current.change(min: 0)
    Turno.create!(start_time: start_time, cancha: @cancha, reservation_name: "Marcela", status: :cancelled)

    nuevo = Turno.new(start_time: start_time, cancha: @cancha, reservation_name: "Otro")
    assert nuevo.valid?
  end

  test "accepts nested roster_entries attributes and rejects blank ones" do
    turno = Turno.new(
      start_time: Time.current,
      cancha: @cancha,
      reservation_name: "Marcela",
      roster_entries_attributes: [
        { name: "Juan", position: 0 },
        { name: "", position: 1 }
      ]
    )

    assert turno.valid?
    assert_equal 1, turno.roster_entries.size
    assert_equal "Juan", turno.roster_entries.first.name
  end
end

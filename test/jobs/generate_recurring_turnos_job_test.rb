require "test_helper"

class GenerateRecurringTurnosJobTest < ActiveSupport::TestCase
  setup do
    @cancha = canchas(:one)
    @turno = Turno.create!(
      cancha: @cancha,
      start_time: 1.day.from_now.change(hour: 18, min: 0, sec: 0),
      reservation_name: "Marcela",
      recurring: true
    )
  end

  test "perform_now creates the expected recurring instances" do
    assert_difference "Turno.count", RecurringTurnoGenerator::WEEKS_AHEAD do
      GenerateRecurringTurnosJob.perform_now(@turno.id)
    end
  end

  test "perform_now with non-existent turno id does not fail" do
    assert_no_difference "Turno.count" do
      GenerateRecurringTurnosJob.perform_now(0)
    end
  end
end

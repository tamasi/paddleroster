require "test_helper"

class RecurringTurnoGeneratorTest < ActiveSupport::TestCase
  setup do
    @cancha = canchas(:one)
    @turno = Turno.create!(
      cancha: @cancha,
      start_time: 1.day.from_now.change(hour: 18, min: 0, sec: 0),
      reservation_name: "Marcela",
      recurring: true
    )
    @turno.roster_entries.create!(name: "Juan", position: 0)
    @turno.roster_entries.create!(name: "Pedro", position: 1)
  end

  test "generates WEEKS_AHEAD weekly instances copying cancha, schedule and roster" do
    created = RecurringTurnoGenerator.new(@turno).call

    assert_equal RecurringTurnoGenerator::WEEKS_AHEAD, created.size

    created.each_with_index do |instance, index|
      week = index + 1
      assert_equal @turno.cancha_id, instance.cancha_id
      assert_equal @turno.start_time + week.weeks, instance.start_time
      assert_equal @turno.id, instance.recurring_rule_id
      assert_not instance.recurring?
      assert instance.manual?
      assert instance.active?
      assert instance.pending?
      assert_equal @turno.reservation_name, instance.reservation_name
      assert_equal [ "Juan", "Pedro" ], instance.roster_entries.order(:position).pluck(:name)
    end
  end

  test "skips weeks where the slot is already occupied without raising" do
    conflict_start_time = @turno.start_time + 3.weeks
    Turno.create!(cancha: @cancha, start_time: conflict_start_time, reservation_name: "Otro")

    created = RecurringTurnoGenerator.new(@turno).call

    assert_equal RecurringTurnoGenerator::WEEKS_AHEAD - 1, created.size
    assert_not created.any? { |t| t.start_time == conflict_start_time }
  end

  test "skips an instance that fails to save due to a uniqueness race without aborting the rest" do
    conflict_start_time = @turno.start_time + 3.weeks
    Turno.create!(cancha: @cancha, start_time: conflict_start_time, reservation_name: "Otro")

    # Simula una condicion de carrera: el chequeo de conflicto no detecta el slot ocupado,
    # pero la validacion de unicidad en save! si lo hace.
    fake_scope = Object.new
    def fake_scope.exists?(*) = false

    original_active = Turno.method(:active)
    Turno.define_singleton_method(:active) { fake_scope }

    created =
      begin
        RecurringTurnoGenerator.new(@turno).call
      ensure
        Turno.define_singleton_method(:active, original_active)
      end

    assert_equal RecurringTurnoGenerator::WEEKS_AHEAD - 1, created.size
    assert_not created.any? { |t| t.start_time == conflict_start_time }
  end
end

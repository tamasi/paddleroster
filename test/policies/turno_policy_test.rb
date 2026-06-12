require "test_helper"

class TurnoPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = users(:one)
    @employee = users(:two)
    @cancha = canchas(:one)
    @turno = Turno.new(cancha: @cancha)
  end

  test "owner can create, view, update and cancel turnos" do
    policy = TurnoPolicy.new(@owner, @turno)
    assert policy.new?
    assert policy.create?
    assert policy.show?
    assert policy.update?
    assert policy.cancel?
  end

  test "employee can create, view, update and cancel turnos" do
    policy = TurnoPolicy.new(@employee, @turno)
    assert policy.new?
    assert policy.create?
    assert policy.show?
    assert policy.update?
    assert policy.cancel?
  end

  test "cannot view or update turnos from another complex" do
    other_complejo = Complejo.create!(name: "Otro")
    other_cancha = Cancha.create!(complejo: other_complejo, name: "Cancha Ajena", sport: :padel)
    other_turno = Turno.new(cancha: other_cancha)

    policy = TurnoPolicy.new(@owner, other_turno)
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.cancel?
  end
end

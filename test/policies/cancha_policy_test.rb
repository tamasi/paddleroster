require "test_helper"

class CanchaPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = users(:one)
    @employee = users(:two)
  end

  test "owner can access canchas" do
    policy = CanchaPolicy.new(@owner, Cancha)
    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "employee cannot access canchas" do
    policy = CanchaPolicy.new(@employee, Cancha)
    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end
end

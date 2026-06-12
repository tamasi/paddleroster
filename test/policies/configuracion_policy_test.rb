require "test_helper"

class ConfiguracionPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = users(:one) # assuming :one is owner from previous stories
    @employee = users(:two) # assuming :two is employee
  end

  test "owner can access configuration" do
    policy = ConfiguracionPolicy.new(@owner, nil)
    assert policy.show?
    assert policy.update?
  end

  test "employee cannot access configuration" do
    policy = ConfiguracionPolicy.new(@employee, nil)
    assert_not policy.show?
    assert_not policy.update?
  end
end

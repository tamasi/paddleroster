require "test_helper"

class WhatsappConnectionPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = users(:one)
    @employee = users(:two)
  end

  test "owner can access the whatsapp connection" do
    policy = WhatsappConnectionPolicy.new(@owner, nil)
    assert policy.show?
    assert policy.update?
  end

  test "employee cannot access the whatsapp connection" do
    policy = WhatsappConnectionPolicy.new(@employee, nil)
    assert_not policy.show?
    assert_not policy.update?
  end
end

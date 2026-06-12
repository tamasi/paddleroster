require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "defaults to employee role" do
    user = User.new(email_address: "nuevo@example.com", password: "password")
    assert user.employee?
    assert_not user.owner?
  end

  test "can be assigned the owner role" do
    user = User.new(email_address: "dueno@example.com", password: "password", role: :owner)
    assert user.owner?
    assert_not user.employee?
  end

  test "requires a complejo" do
    user = User.new(email_address: "sin-complejo@example.com", password: "password")

    assert_not user.valid?
    assert_not_empty user.errors[:complejo]
  end

  test "requires a unique email_address" do
    existing = users(:one)
    user = User.new(email_address: existing.email_address.upcase, password: "password", complejo: existing.complejo)

    assert_not user.valid?
    assert_not_empty user.errors[:email_address]
  end
end

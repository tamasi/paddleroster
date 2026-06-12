require "test_helper"

class ComplejoTest < ActiveSupport::TestCase
  test "requires a name" do
    complejo = Complejo.new(name: "")

    assert_not complejo.valid?
    assert_not_empty complejo.errors[:name]
  end

  test "is valid with a name" do
    complejo = Complejo.new(name: "Complejo Piloto")

    assert complejo.valid?
  end
end

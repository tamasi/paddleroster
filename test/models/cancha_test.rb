require "test_helper"

class CanchaTest < ActiveSupport::TestCase
  setup do
    @complejo = complejos(:piloto)
  end

  test "requires a name" do
    cancha = Cancha.new(name: "", sport: :padel, complejo: @complejo)
    assert_not cancha.valid?
    assert_not_empty cancha.errors[:name]
  end

  test "requires a sport" do
    cancha = Cancha.new(name: "Cancha 1", sport: nil, complejo: @complejo)
    assert_not cancha.valid?
  end

  test "requires a complejo" do
    cancha = Cancha.new(name: "Cancha 1", sport: :padel, complejo: nil)
    assert_not cancha.valid?
  end

  test "is valid with name, sport and complejo" do
    cancha = Cancha.new(name: "Cancha 1", sport: :padel, complejo: @complejo)
    assert cancha.valid?
  end

  test "supports padel and futbol_5 sports" do
    assert_nothing_raised { Cancha.new(sport: :padel) }
    assert_nothing_raised { Cancha.new(sport: :futbol_5) }
  end
end

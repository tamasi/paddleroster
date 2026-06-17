# frozen_string_literal: true

require "test_helper"

class ComplexPlayerTest < ActiveSupport::TestCase
  test "valid complex_player" do
    cp = complex_players(:carlos_piloto)
    assert cp.valid?
  end

  test "player must be unique per complejo" do
    cp = complex_players(:carlos_piloto)
    dup = ComplexPlayer.new(player: cp.player, complejo: cp.complejo)
    assert dup.invalid?
    assert dup.errors[:player_id].present?
  end

  test "same player can belong to different complejos" do
    player = players(:carlos)
    other_complejo = Complejo.create!(name: "Otro Complejo")
    cp = ComplexPlayer.new(player: player, complejo: other_complejo)
    assert cp.valid?
  end
end

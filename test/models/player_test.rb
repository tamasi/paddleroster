# frozen_string_literal: true

require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "valid player" do
    player = Player.new(name: "Juan Pérez", phone: "+5491155556666")
    assert player.valid?
  end

  test "requires name" do
    player = Player.new(phone: "+5491155556666")
    assert player.invalid?
    assert player.errors[:name].present?
  end

  test "requires phone" do
    player = Player.new(name: "Juan Pérez")
    assert player.invalid?
    assert player.errors[:phone].present?
  end

  test "phone must be E.164 format" do
    player = Player.new(name: "Juan", phone: "1155556666")
    assert player.invalid?
    assert player.errors[:phone].present?
  end

  test "phone with country code but no plus is invalid" do
    player = Player.new(name: "Juan", phone: "5491155556666")
    assert player.invalid?
    assert player.errors[:phone].present?
  end

  test "valid E.164 phone accepted" do
    assert Player.new(name: "A", phone: "+5491155556666").valid?
    assert Player.new(name: "B", phone: "+1234567").valid?
  end

  test "phone must be unique" do
    existing = players(:carlos)
    dup = Player.new(name: "Otro", phone: existing.phone)
    assert dup.invalid?
    assert dup.errors[:phone].present?
  end

  test "has many roster_entries" do
    assert_respond_to players(:carlos), :roster_entries
  end
end

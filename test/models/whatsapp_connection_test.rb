# frozen_string_literal: true

require "test_helper"

class WhatsappConnectionTest < ActiveSupport::TestCase
  def build_connection(complejo: complejos(:piloto), status: "disconnected", requested_action: nil)
    WhatsappConnection.new(complejo: complejo, status: status, requested_action: requested_action)
  end

  test "is valid with default disconnected status" do
    connection = build_connection
    assert connection.valid?
  end

  test "rejects an invalid status" do
    connection = build_connection(status: "bogus")
    assert_not connection.valid?
    assert_not_empty connection.errors[:status]
  end

  test "rejects an invalid requested_action" do
    connection = build_connection(requested_action: "bogus")
    assert_not connection.valid?
    assert_not_empty connection.errors[:requested_action]
  end

  test "allows a nil requested_action" do
    connection = build_connection(requested_action: nil)
    assert connection.valid?
  end

  test "allows connect and disconnect as requested_action" do
    assert build_connection(requested_action: "connect").valid?
    assert build_connection(requested_action: "disconnect").valid?
  end

  test "enforces one connection per complejo" do
    build_connection.save!
    duplicate = build_connection
    assert_not duplicate.valid?
    assert_not_empty duplicate.errors[:complejo_id]
  end

  test "status predicates reflect the current status" do
    connection = build_connection(status: "connecting")
    assert connection.connecting?
    assert_not connection.connected?
    assert_not connection.disconnected?
  end

  test "for_complejo! creates the connection lazily" do
    assert_difference("WhatsappConnection.count", 1) do
      connection = WhatsappConnection.for_complejo!(complejos(:piloto))
      assert connection.persisted?
      assert connection.disconnected?
    end
  end

  test "for_complejo! returns the existing connection without creating a duplicate" do
    existing = build_connection.tap(&:save!)

    assert_no_difference("WhatsappConnection.count") do
      found = WhatsappConnection.for_complejo!(complejos(:piloto))
      assert_equal existing, found
    end
  end
end

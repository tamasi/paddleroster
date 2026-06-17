# frozen_string_literal: true

require "test_helper"

class WhatsappOutboxMessageTest < ActiveSupport::TestCase
  test "valid record with pending status" do
    msg = WhatsappOutboxMessage.new(phone: "+549111", body: "test", status: "pending")
    assert msg.valid?
  end

  test "valid record with sent status" do
    msg = WhatsappOutboxMessage.new(phone: "+549111", body: "test", status: "sent")
    assert msg.valid?
  end

  test "valid record with failed status" do
    msg = WhatsappOutboxMessage.new(phone: "+549111", body: "test", status: "failed")
    assert msg.valid?
  end

  test "phone is required" do
    msg = WhatsappOutboxMessage.new(body: "test", status: "pending")
    assert_not msg.valid?
    assert msg.errors[:phone].present?
  end

  test "body is required" do
    msg = WhatsappOutboxMessage.new(phone: "+549111", status: "pending")
    assert_not msg.valid?
    assert msg.errors[:body].present?
  end

  test "status must be valid string value" do
    msg = WhatsappOutboxMessage.new(phone: "+549111", body: "test", status: "unknown")
    assert_not msg.valid?
    assert msg.errors[:status].present?
  end

  test "retry_count must be non-negative" do
    msg = WhatsappOutboxMessage.new(phone: "+549111", body: "test", status: "pending", retry_count: -1)
    assert_not msg.valid?
  end

  test "uses whatsapp_outbox table name" do
    assert_equal "whatsapp_outbox", WhatsappOutboxMessage.table_name
  end

  test "pending scope returns only pending records" do
    sent_msg = WhatsappOutboxMessage.create!(phone: "+1", body: "x", status: "sent")
    pending_msg = WhatsappOutboxMessage.create!(phone: "+2", body: "x", status: "pending")
    assert_includes WhatsappOutboxMessage.pending, pending_msg
    assert_not_includes WhatsappOutboxMessage.pending, sent_msg
  end
end

# frozen_string_literal: true

require "test_helper"

class WhatsappInboxMessageTest < ActiveSupport::TestCase
  test "valid record" do
    msg = WhatsappInboxMessage.new(phone: "+549111", raw_body: "Hola Bot")
    assert msg.valid?
  end

  test "phone is required" do
    msg = WhatsappInboxMessage.new(raw_body: "Hola Bot")
    assert_not msg.valid?
    assert msg.errors[:phone].present?
  end

  test "raw_body is required" do
    msg = WhatsappInboxMessage.new(phone: "+549111")
    assert_not msg.valid?
    assert msg.errors[:raw_body].present?
  end

  test "defaults processed to false" do
    msg = WhatsappInboxMessage.create!(phone: "+549111", raw_body: "Hola")
    assert_equal false, msg.processed
  end

  test "uses whatsapp_inbox table name" do
    assert_equal "whatsapp_inbox", WhatsappInboxMessage.table_name
  end

  test "unprocessed scope returns only unprocessed records" do
    processed_msg   = WhatsappInboxMessage.create!(phone: "+1", raw_body: "x", processed: true)
    unprocessed_msg = WhatsappInboxMessage.create!(phone: "+2", raw_body: "x", processed: false)
    assert_includes WhatsappInboxMessage.unprocessed, unprocessed_msg
    assert_not_includes WhatsappInboxMessage.unprocessed, processed_msg
  end

  test "system SYSTEM phone is valid" do
    msg = WhatsappInboxMessage.new(phone: "SYSTEM", raw_body: "BOT_DISCONNECTED")
    assert msg.valid?
  end
end

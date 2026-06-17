# frozen_string_literal: true

require "test_helper"

class ProcessWhatsappInboxJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "marks unprocessed messages as processed" do
    msg = WhatsappInboxMessage.create!(phone: "+549111", raw_body: "Hola", processed: false)
    ProcessWhatsappInboxJob.new.perform
    assert msg.reload.processed
  end

  test "ignores already processed messages without error" do
    msg = WhatsappInboxMessage.create!(phone: "+549111", raw_body: "ya procesado", processed: true)
    assert_nothing_raised { ProcessWhatsappInboxJob.new.perform }
    assert msg.reload.processed
  end

  test "processes multiple unprocessed messages in order" do
    msg1 = WhatsappInboxMessage.create!(phone: "+1", raw_body: "primero", processed: false, created_at: 2.minutes.ago)
    msg2 = WhatsappInboxMessage.create!(phone: "+2", raw_body: "segundo", processed: false, created_at: 1.minute.ago)
    ProcessWhatsappInboxJob.new.perform
    assert msg1.reload.processed
    assert msg2.reload.processed
  end

  test "BOT_DISCONNECTED message triggers SendWhatsappAlertJob" do
    WhatsappInboxMessage.create!(phone: "SYSTEM", raw_body: "BOT_DISCONNECTED", processed: false)
    assert_enqueued_with(job: SendWhatsappAlertJob) do
      ProcessWhatsappInboxJob.new.perform
    end
  end

  test "regular message does not trigger SendWhatsappAlertJob" do
    WhatsappInboxMessage.create!(phone: "+549111", raw_body: "Hola Bot", processed: false)
    assert_no_enqueued_jobs(only: SendWhatsappAlertJob) do
      ProcessWhatsappInboxJob.new.perform
    end
  end
end

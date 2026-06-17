# frozen_string_literal: true

require "test_helper"

class WhatsappInboxProcessorTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def inbox_message(phone:, raw_body:)
    WhatsappInboxMessage.new(phone: phone, raw_body: raw_body, processed: false)
  end

  def valid_turno_body
    fecha = (Date.current + 1).strftime("%d/%m/%Y")
    <<~MSG
      TURNO
      cancha: Cancha de Padel 1
      fecha: #{fecha}
      horario: 18:00
      jugadores:
      Carlos Nuevo +5491100009901
    MSG
  end

  # ── SYSTEM alerts ─────────────────────────────────────────────────────────────

  test "BOT_DISCONNECTED enqueues SendWhatsappAlertJob" do
    msg = inbox_message(phone: "SYSTEM", raw_body: "BOT_DISCONNECTED")
    assert_enqueued_with(job: SendWhatsappAlertJob) do
      WhatsappInboxProcessor.new(msg).process
    end
  end

  test "unknown SYSTEM body does nothing" do
    msg = inbox_message(phone: "SYSTEM", raw_body: "SOME_OTHER_EVENT")
    assert_no_enqueued_jobs do
      WhatsappInboxProcessor.new(msg).process
    end
  end

  # ── TURNO command ─────────────────────────────────────────────────────────────

  test "valid TURNO message creates turno and sends success reply" do
    msg = inbox_message(phone: "+5491155550000", raw_body: valid_turno_body)
    assert_difference("Turno.count", 1) do
      assert_difference("WhatsappOutboxMessage.count", 1) do
        WhatsappInboxProcessor.new(msg).process
      end
    end
    reply = WhatsappOutboxMessage.last
    assert_includes reply.body, "✅"
    assert_equal "+5491155550000", reply.phone
  end

  test "invalid TURNO message sends error reply" do
    bad_body = "TURNO\ncancha: \nfecha: \nhorario: \njugadores:\n"
    msg = inbox_message(phone: "+5491155550001", raw_body: bad_body)
    assert_no_difference("Turno.count") do
      assert_difference("WhatsappOutboxMessage.count", 1) do
        WhatsappInboxProcessor.new(msg).process
      end
    end
    reply = WhatsappOutboxMessage.last
    assert_includes reply.body, "❌"
  end

  # ── Unknown message ───────────────────────────────────────────────────────────

  test "unknown message sends help text" do
    msg = inbox_message(phone: "+5491155550002", raw_body: "Hola! ¿Cómo reservo?")
    assert_difference("WhatsappOutboxMessage.count", 1) do
      WhatsappInboxProcessor.new(msg).process
    end
    reply = WhatsappOutboxMessage.last
    assert_includes reply.body, "TURNO"
  end

  test "turno command is case-insensitive" do
    body = valid_turno_body.sub("TURNO", "turno")
    msg = inbox_message(phone: "+5491155550003", raw_body: body)
    assert_difference("Turno.count", 1) do
      WhatsappInboxProcessor.new(msg).process
    end
  end
end

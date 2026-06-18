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
      # +1 por la respuesta "Turno creado", +1 por la solicitud de confirmación al único titular
      assert_difference("WhatsappOutboxMessage.count", 2) do
        WhatsappInboxProcessor.new(msg).process
      end
    end
    success_reply = WhatsappOutboxMessage.where(phone: "+5491155550000").last
    assert_includes success_reply.body, "✅"
  end

  test "valid TURNO message sends an individual confirmation request to each titular" do
    fecha = (Date.current + 1).strftime("%d/%m/%Y")
    body = <<~MSG
      TURNO
      cancha: Cancha de Padel 1
      fecha: #{fecha}
      horario: 18:00
      jugadores:
      Carlos Nuevo +5491100009901
      Ana Nueva +5491100009902
      suplentes:
      Pedro Suplente +5491100009903
    MSG
    msg = inbox_message(phone: "+5491155550010", raw_body: body)

    assert_difference("WhatsappOutboxMessage.count", 3) do
      WhatsappInboxProcessor.new(msg).process
    end

    titular_reply = WhatsappOutboxMessage.find_by(phone: "+5491100009901")
    assert_includes titular_reply.body, "Confirmás"
    assert_nil WhatsappOutboxMessage.find_by(phone: "+5491100009903"), "el suplente no debe recibir solicitud de confirmación"
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

  # ── Confirmación de asistencia (Story 5.3) ──────────────────────────────────

  test "phone with a pending confirmation answering SI updates roster_entry and replies" do
    phone = "+5491100009910"
    turno = Turno.create!(cancha: canchas(:one), start_time: 1.day.from_now.change(min: 0), reservation_name: "Test", origin: :bot, status: :active)
    player = Player.create!(name: "Jugador Pendiente", phone: phone)
    entry = turno.roster_entries.create!(player: player, name: player.name, role: :titular, confirmation_status: :pending, position: 0)

    msg = inbox_message(phone: phone, raw_body: "SI")
    assert_difference("WhatsappOutboxMessage.count", 1) do
      WhatsappInboxProcessor.new(msg).process
    end

    assert entry.reload.confirmed?
    reply = WhatsappOutboxMessage.last
    assert_equal phone, reply.phone
  end

  test "a pending confirmation phone sending a TURNO command is processed as turno creation, not confirmation" do
    phone = "+5491100009911"
    # cancha distinta a la de valid_turno_body ("Cancha de Padel 1"): la unicidad de start_time
    # es por cancha, así que evita una colisión espuria si el test corre justo a las 18hs.
    existing_turno = Turno.create!(cancha: canchas(:two), start_time: 1.day.from_now.change(min: 0), reservation_name: "Test", origin: :bot, status: :active)
    player = Player.create!(name: "Capitan Pendiente", phone: phone)
    entry = existing_turno.roster_entries.create!(player: player, name: player.name, role: :titular, confirmation_status: :pending, position: 0)

    msg = inbox_message(phone: phone, raw_body: valid_turno_body)
    assert_difference("Turno.count", 1) do
      WhatsappInboxProcessor.new(msg).process
    end

    assert entry.reload.pending?, "la RosterEntry pendiente previa no debe modificarse por el comando TURNO"
    success_reply = WhatsappOutboxMessage.where(phone: phone).order(:created_at).last
    assert_includes success_reply.body, "✅"
  end

  test "send_confirmation_requests tolerates a per-entry failure and still notifies the rest (review finding)" do
    turno = Turno.create!(cancha: canchas(:one), start_time: 1.day.from_now.change(min: 0), reservation_name: "Test", origin: :bot, status: :active)
    good_player = Player.create!(name: "Bueno", phone: "+5491100009920")
    turno.roster_entries.create!(player: good_player, name: good_player.name, role: :titular, confirmation_status: :pending, position: 0)
    turno.roster_entries.create!(name: "Sin jugador vinculado", role: :titular, confirmation_status: :pending, position: 1)

    msg = inbox_message(phone: "+5491100009921", raw_body: "lo que sea")
    processor = WhatsappInboxProcessor.new(msg)

    assert_difference("WhatsappOutboxMessage.count", 1) do
      processor.send(:send_confirmation_requests, turno)
    end

    assert WhatsappOutboxMessage.exists?(phone: good_player.phone)
  end
end

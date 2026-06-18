# frozen_string_literal: true

class WhatsappInboxProcessor
  TURNO_COMMAND = /\ATURNO\b/i

  def initialize(inbox_message)
    @inbox_message = inbox_message
    @phone = inbox_message.phone
    @body  = inbox_message.raw_body.strip
  end

  def process
    # Solo el sistema puede enviar mensajes con teléfono "SYSTEM"
    # Los mensajes de usuarios siempre vienen con su teléfono real
    return handle_system_alert if @phone == "SYSTEM"

    if @body.match?(TURNO_COMMAND)
      handle_turno_command
    else
      handle_confirmation_or_unknown
    end
  rescue StandardError => e
    # Decisión: Mensaje genérico para errores inesperados
    reply("❌ Ocurrió un error interno. Por favor, intenta más tarde o contacta al soporte.")
    # Opcional: Loguear el error real para debugging
    Rails.logger.error("[WhatsappInboxProcessor] Error: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  private

  def handle_system_alert
    return unless @body == "BOT_DISCONNECTED"

    SendWhatsappAlertJob.perform_later("Bot de WhatsApp desconectado — revisar el servicio.")
  end

  def handle_turno_command
    result = BotTurnoCreationService.new(@phone, @body).call
    if result.success?
      reply(turno_created_message(result.turno))
      send_confirmation_requests(result.turno)
    else
      reply("❌ No pude crear el turno:\n#{result.errors.join("\n")}")
    end
  end

  def handle_confirmation_or_unknown
    result = BotConfirmationService.new(@phone, @body).call
    if result.handled?
      reply(result.reply_text)
      broadcast_roster_update(result.roster_entry) if result.roster_entry
    else
      handle_unknown_message
    end
  end

  def handle_unknown_message
    reply(help_message)
  end

  def send_confirmation_requests(turno)
    turno.roster_entries.titular.each do |entry|
      WhatsappOutboxMessage.create!(phone: entry.player.phone, body: confirmation_request_message(turno, entry), status: "pending")
    rescue StandardError => e
      Rails.logger.error("[WhatsappInboxProcessor] No se pudo enviar solicitud de confirmación a roster_entry##{entry.id}: #{e.message}")
    end
  end

  def confirmation_request_message(turno, entry)
    fecha   = turno.start_time.strftime("%d/%m/%Y")
    horario = turno.start_time.strftime("%H:%M")
    "🏆 ¡Hola #{entry.name}! Te incluyeron en el Roster de un Turno:\n" \
      "📍 #{turno.cancha.name}, #{fecha} #{horario}\n\n" \
      "¿Confirmás tu asistencia? Respondé SI o NO."
  end

  def broadcast_roster_update(entry)
    turno = entry.turno
    Turbo::StreamsChannel.broadcast_replace_to(
      "turno_#{turno.id}_roster",
      target: "roster-section-#{turno.id}",
      partial: "turnos/roster_section",
      locals: { turno: turno }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      "complex_#{turno.cancha.complejo_id}_payments",
      target: "card-turno-#{turno.id}",
      partial: "turnos/card_turno_stream",
      locals: { turno: turno }
    )
  rescue StandardError => e
    # La confirmación del jugador ya se persistió antes de llegar acá — una falla de
    # broadcast no debe traducirse en un mensaje de error hacia el jugador.
    Rails.logger.error("[WhatsappInboxProcessor] Falló el broadcast de roster para turno##{entry.turno_id}: #{e.message}")
  end

  def reply(text)
    WhatsappOutboxMessage.create!(phone: @phone, body: text, status: "pending")
  end

  def turno_created_message(turno)
    titulares = turno.roster_entries.count(&:titular?)
    suplentes = turno.roster_entries.count(&:suplente?)
    fecha     = turno.start_time.strftime("%d/%m/%Y")
    horario   = turno.start_time.strftime("%H:%M")
    "✅ Turno creado: #{turno.cancha.name}, #{fecha} #{horario}\n" \
      "👥 #{titulares} titular(es), #{suplentes} suplente(s) cargados con estado Pendiente."
  end

  def help_message
    "No entendí tu mensaje. Para crear un turno enviá:\n\n" \
      "TURNO\n" \
      "cancha: [nombre de la cancha]\n" \
      "fecha: DD/MM/YYYY\n" \
      "horario: HH:MM\n" \
      "jugadores:\n" \
      "Nombre Apellido +549XXXXXXXXXX\n" \
      "suplentes:\n" \
      "Nombre Apellido +549XXXXXXXXXX"
  end
end

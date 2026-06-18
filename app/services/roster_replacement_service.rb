# frozen_string_literal: true

class RosterReplacementService
  IMMEDIATE_THRESHOLD = 2.hours
  LONG_TIMEOUT  = 2.hours
  SHORT_TIMEOUT = 15.minutes

  def initialize(entry)
    @entry = entry
    @turno = entry.turno
  end

  def call
    candidate = next_candidate

    if candidate
      offer_to(candidate)
    else
      notify_captain(exhausted_message)
    end

    broadcast_roster_update
  end

  private

  def next_candidate
    @turno.roster_entries.suplente.pending.where(offered_at: nil).order(:position).first
  end

  def offer_to(candidate)
    candidate.update!(offered_at: Time.current)
    send_offer_message(candidate)
    notify_captain(offer_message(candidate))
    schedule_timeout(candidate)
  end

  def schedule_timeout(candidate)
    CheckReplacementTimeoutJob.set(wait: timeout_duration).perform_later(candidate.id)
  end

  def timeout_duration
    (@turno.start_time - Time.current > IMMEDIATE_THRESHOLD) ? LONG_TIMEOUT : SHORT_TIMEOUT
  end

  def send_offer_message(candidate)
    return if candidate.player&.phone.blank?

    WhatsappOutboxMessage.create!(phone: candidate.player.phone, body: offer_to_suplente_message(candidate), status: "pending")
  end

  def notify_captain(text)
    captain_phone = @turno.roster_entries.order(:position).first&.player&.phone
    return if captain_phone.blank?

    WhatsappOutboxMessage.create!(phone: captain_phone, body: text, status: "pending")
  end

  def offer_to_suplente_message(candidate)
    plazo = (timeout_duration == LONG_TIMEOUT) ? "2 horas" : "15 minutos"
    "🏆 ¡Hola #{candidate.name}! Se liberó un lugar para el Turno del #{format_fecha} #{format_hora} en #{@turno.cancha.name}.\n" \
      "¿Querés sumarte? Respondé SI o NO.\n" \
      "(Tenés #{plazo} para responder antes de que se ofrezca al siguiente)."
  end

  def offer_message(candidate)
    "🔄 #{@entry.name} no puede asistir al Turno de las #{format_hora}.\n" \
      "Le ofrecimos el lugar a #{candidate.name}. Te aviso si alguien confirma."
  end

  def exhausted_message
    "⚠️ No logramos conseguir un reemplazo para el lugar de #{@entry.name} (lista de suplentes agotada o tiempo cumplido).\n" \
      "El cupo queda sin cubrir."
  end

  def format_fecha
    @turno.start_time.strftime("%d/%m/%Y")
  end

  def format_hora
    @turno.start_time.strftime("%H:%M")
  end

  def broadcast_roster_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "turno_#{@turno.id}_roster",
      target: "roster-section-#{@turno.id}",
      partial: "turnos/roster_section",
      locals: { turno: @turno }
    )
  rescue StandardError => e
    Rails.logger.error("[RosterReplacementService] Falló el broadcast de roster para turno##{@turno.id}: #{e.message}")
  end
end

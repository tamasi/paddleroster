# frozen_string_literal: true

class RosterReplacementService
  IMMEDIATE_THRESHOLD = 2.hours
  LONG_TIMEOUT  = 2.hours
  SHORT_TIMEOUT = 15.minutes

  def initialize(triggering_entry)
    @triggering_entry = triggering_entry
    @turno = triggering_entry.turno
  end

  def call
    return if @turno.start_time <= Time.current

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
    @turno.roster_entries.suplente.pending
         .joins(:player).where.not(players: { phone: [ nil, "" ] })
         .where(offered_at: nil).order(:position).first
  end

  def offer_to(candidate)
    timeout = timeout_duration
    return if timeout.zero?

    candidate.update!(offered_at: Time.current)
    send_offer_message(candidate, timeout)
    notify_captain(offer_message(candidate))
    schedule_timeout(candidate, timeout)
  end

  def schedule_timeout(candidate, timeout)
    CheckReplacementTimeoutJob.set(wait: timeout).perform_later(candidate.id)
  end

  def timeout_duration
    return 0.seconds if @turno.start_time <= Time.current
    (@turno.start_time - Time.current > IMMEDIATE_THRESHOLD) ? LONG_TIMEOUT : SHORT_TIMEOUT
  end

  def send_offer_message(candidate, timeout)
    return if candidate.player&.phone.blank?

    WhatsappOutboxMessage.create!(phone: candidate.player.phone, body: offer_to_suplente_message(candidate, timeout), status: "pending")
  end

  def notify_captain(text)
    captain_phone = @turno.roster_entries.order(:position).first&.player&.phone
    return if captain_phone.blank?

    WhatsappOutboxMessage.create!(phone: captain_phone, body: text, status: "pending")
  end

  def offer_to_suplente_message(candidate, timeout)
    plazo = (timeout == LONG_TIMEOUT) ? "2 horas" : "15 minutos"
    "🏆 ¡Hola #{candidate.name}! Se liberó un lugar para el Turno del #{format_fecha} #{format_hora} en #{@turno.cancha.name}.\n" \
      "¿Querés sumarte? Respondé SI o NO.\n" \
      "(Tenés #{plazo} para responder antes de que se ofrezca al siguiente)."
  end

  def original_uncovered_titular
    @original_uncovered_titular ||= @turno.roster_entries.uncovered.titular.order(:updated_at).first
  end

  def offer_message(candidate)
    vacating_name = original_uncovered_titular&.name || @triggering_entry.name
    "🔄 #{vacating_name} no puede asistir al Turno de las #{format_hora}.\n" \
      "Le ofrecimos el lugar a #{candidate.name}. Te aviso si alguien confirma."
  end

  def exhausted_message
    vacating_name = original_uncovered_titular&.name || @triggering_entry.name
    "⚠️ No logramos conseguir un reemplazo para el lugar de #{vacating_name} (lista de suplentes agotada o tiempo cumplido).\n" \
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

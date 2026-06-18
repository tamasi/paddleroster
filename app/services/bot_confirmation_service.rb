# frozen_string_literal: true

class BotConfirmationService
  Result = Struct.new(:handled?, :reply_text, :roster_entry, keyword_init: true)

  CONFIRM_RE = /\A(s[ií]|confirmo)\z/i
  DECLINE_RE = /\A(no|no puedo)\z/i

  def initialize(phone, raw_message)
    @phone = phone
    @body  = raw_message.strip
  end

  def call
    entry = pending_entry
    return Result.new(handled?: false, reply_text: nil, roster_entry: nil) unless entry

    case @body
    when CONFIRM_RE
      handle_confirm(entry)
    when DECLINE_RE
      handle_decline(entry)
    else
      Result.new(handled?: true, reply_text: ambiguous_message(entry), roster_entry: nil)
    end
  end

  private

  def handle_confirm(entry)
    if entry.suplente?
      entry.update!(confirmation_status: :replacement)
      notify_captain_success(entry)
    else
      entry.update!(confirmation_status: :confirmed)
    end
    Result.new(handled?: true, reply_text: confirmed_message(entry), roster_entry: entry)
  end

  def handle_decline(entry)
    entry.update!(confirmation_status: :uncovered)
    RosterReplacementService.new(entry).call
    Result.new(handled?: true, reply_text: declined_message(entry), roster_entry: entry)
  end

  def pending_entry
    RosterEntry.joins(:player, :turno)
               .where(players: { phone: @phone }, confirmation_status: :pending)
               .where(
                 "(roster_entries.role = :titular) OR (roster_entries.role = :suplente AND roster_entries.offered_at IS NOT NULL)",
                 titular: RosterEntry.roles[:titular], suplente: RosterEntry.roles[:suplente]
               )
               .merge(Turno.active.bot)
               .where("turnos.start_time >= ?", Time.current)
               .order("turnos.start_time ASC, roster_entries.id ASC")
               .first
  end

  def confirmed_message(entry)
    "✅ ¡Gracias! Confirmaste tu asistencia al Turno del #{format_turno(entry.turno)}."
  end

  def declined_message(entry)
    if entry.suplente?
      "👍 Entendido, gracias por responder. Le ofreceremos el lugar al siguiente suplente para el Turno del #{format_turno(entry.turno)}."
    else
      "👍 Entendido, marcamos tu lugar como liberado para el Turno del #{format_turno(entry.turno)}. " \
        "Avisaremos si conseguimos un reemplazo."
    end
  end

  def notify_captain_success(entry)
    captain_phone = entry.turno.roster_entries.order(:position).first&.player&.phone
    return if captain_phone.blank?

    text = "✅ ¡Lugar cubierto! #{entry.name} confirmó su asistencia para el Turno de las #{entry.turno.start_time.strftime('%H:%M')}.\n" \
      "El roster ya está actualizado en el Panel."
    WhatsappOutboxMessage.create!(phone: captain_phone, body: text, status: "pending")
  end

  def ambiguous_message(entry)
    "No entendí tu respuesta para el Turno del #{format_turno(entry.turno)}. Respondé SI o NO."
  end

  def format_turno(turno)
    "#{turno.start_time.strftime('%d/%m/%Y')} #{turno.start_time.strftime('%H:%M')} en #{turno.cancha.name}"
  end
end

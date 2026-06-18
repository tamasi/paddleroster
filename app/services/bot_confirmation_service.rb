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
      entry.update!(confirmation_status: :confirmed)
      Result.new(handled?: true, reply_text: confirmed_message(entry), roster_entry: entry)
    when DECLINE_RE
      entry.update!(confirmation_status: :uncovered)
      Result.new(handled?: true, reply_text: declined_message(entry), roster_entry: entry)
    else
      Result.new(handled?: true, reply_text: ambiguous_message(entry), roster_entry: nil)
    end
  end

  private

  def pending_entry
    RosterEntry.joins(:player, :turno)
               .where(players: { phone: @phone }, role: :titular, confirmation_status: :pending)
               .merge(Turno.active.bot)
               .where("turnos.start_time >= ?", Time.current)
               .order("turnos.start_time ASC, roster_entries.id ASC")
               .first
  end

  def confirmed_message(entry)
    "✅ ¡Gracias! Confirmaste tu asistencia al Turno del #{format_turno(entry.turno)}."
  end

  def declined_message(entry)
    "👍 Entendido, marcamos tu lugar como liberado para el Turno del #{format_turno(entry.turno)}. " \
      "Avisaremos si conseguimos un reemplazo."
  end

  def ambiguous_message(entry)
    "No entendí tu respuesta para el Turno del #{format_turno(entry.turno)}. Respondé SI o NO."
  end

  def format_turno(turno)
    "#{turno.start_time.strftime('%d/%m/%Y')} #{turno.start_time.strftime('%H:%M')} en #{turno.cancha.name}"
  end
end

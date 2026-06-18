# frozen_string_literal: true

class CardTurnoComponent < ViewComponent::Base
  include StatusPresentationHelper

  def initialize(turno:)
    @turno = turno
  end

  def roster_summary
    return bot_roster_summary if @turno.bot?

    count = @turno.roster_entries.size
    return "Sin roster cargado" if count.zero?

    "#{count} #{count == 1 ? "jugador cargado" : "jugadores cargados"}"
  end

  def reservee_name
    @turno.reservation_name.presence || "Sin nombre"
  end

  private

  def bot_roster_summary
    titulares = @turno.roster_entries.titular
    return "Sin roster cargado" if titulares.empty?

    confirmados = titulares.count(&:confirmed?)
    "#{confirmados}/#{titulares.size} confirmados"
  end
end

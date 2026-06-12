# frozen_string_literal: true

class CardTurnoComponent < ViewComponent::Base
  include StatusPresentationHelper

  def initialize(turno:)
    @turno = turno
  end

  def roster_summary
    count = @turno.roster_entries.size
    return "Sin roster cargado" if count.zero?

    "#{count} #{count == 1 ? "jugador cargado" : "jugadores cargados"}"
  end

  def reservee_name
    @turno.reservation_name.presence || "Sin nombre"
  end
end

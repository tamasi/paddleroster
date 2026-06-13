class InicioController < ApplicationController
  def index
    @complejo = Current.user.complejo
    @canchas = @complejo ? @complejo.canchas.order(:name) : Cancha.none
    @date = Date.current

    turnos_hoy = Turno.active.where(cancha: @canchas, start_time: @date.all_day)
    turnos_por_cancha = turnos_hoy.group_by(&:cancha_id)
    horas_operativas = Complejo::HORARIO_OPERATIVO.size

    @ocupacion_por_cancha = @canchas.index_with do |cancha|
      horas_ocupadas = turnos_por_cancha[cancha.id]&.size || 0
      (horas_ocupadas.to_f / horas_operativas * 100).round
    end

    @no_turnos_hoy = turnos_hoy.empty?
  end
end

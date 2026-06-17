# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :set_complejo

  def index
    authorize :report

    @period = params[:period].presence_in(%w[week month]) || "week"
    @sport  = params[:sport].presence_in(%w[padel futbol_5])

    start_date = @period == "month" ? Date.current.beginning_of_month : Date.current.beginning_of_week
    end_date   = @period == "month" ? Date.current.end_of_month       : Date.current.end_of_week

    canchas = @complejo.canchas.order(:name)
    canchas = canchas.where(sport: @sport) if @sport.present?
    @canchas = canchas

    horas_operativas = Complejo::HORARIO_OPERATIVO.size

    turnos = Turno.active
                  .where(cancha: @canchas, start_time: start_date.beginning_of_day..end_date.end_of_day)
                  .includes(:cancha)

    turnos_por_dia = turnos.group_by { |t| t.start_time.to_date }

    @report_days = (start_date..end_date).map do |date|
      dia_turnos = turnos_por_dia[date] || []
      turnos_por_cancha_id = dia_turnos.group_by(&:cancha_id)

      canchas_data = @canchas.map do |cancha|
        ocupados   = turnos_por_cancha_id[cancha.id]&.size || 0
        percentage = if horas_operativas.positive?
          (ocupados.to_f / horas_operativas * 100).round
        else
          0
        end
        { cancha: cancha, percentage: percentage, ocupados: ocupados }
      end

      { date: date, canchas_data: canchas_data }
    end
  end

  private

  def set_complejo
    @complejo = Current.user&.complejo
    redirect_to root_path, alert: "No tenés un complejo asignado o no has iniciado sesión." if @complejo.nil?
  end
end

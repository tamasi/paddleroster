class TurnosController < ApplicationController
  before_action :set_complejo

  def index
    @date = parse_date(params[:date]) || Date.current
    @canchas = @complejo.canchas.order(:name)

    @hours = Complejo::HORARIO_OPERATIVO.to_a

    # Recuperar los turnos del día para las canchas del complejo
    @turnos = Turno.active.where(cancha: @canchas, start_time: @date.all_day)
                   .includes(:cancha, :roster_entries, :payments)
                   .index_by { |t| [t.cancha_id, t.start_time.hour] }
  end

  def new
    authorize Turno
    @cancha = @complejo.canchas.find(params[:cancha_id])
    @date = parse_date(params[:date]) || Date.current
    @hour = params[:hour].to_i
    @turno = @cancha.turnos.build(start_time: slot_start_time(@date, @hour))
    build_blank_roster_entries(@turno)
  rescue ActiveRecord::RecordNotFound
    redirect_to calendario_path, alert: "La cancha solicitada no existe."
  end

  def create
    authorize Turno
    @cancha = @complejo.canchas.find(params[:cancha_id])
    @date = parse_date(params[:date]) || Date.current
    @hour = params[:hour].to_i

    @turno = @cancha.turnos.build(turno_params)
    @turno.origin = :manual
    @turno.start_time = slot_start_time(@date, @hour)

    if @turno.save
      GenerateRecurringTurnosJob.perform_later(@turno.id) if @turno.recurring?
      redirect_to calendario_path(date: @date), notice: "Turno creado correctamente."
    else
      build_blank_roster_entries(@turno) if @turno.roster_entries.empty?
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @turno.errors.add(:start_time, "ya tiene un turno reservado en este horario")
    build_blank_roster_entries(@turno) if @turno.roster_entries.empty?
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    redirect_to calendario_path, alert: "La cancha solicitada no existe."
  end

  def show
    @turno = turno_scope.includes(payments: :registered_by).find(params[:id])
    authorize @turno
    @roster_empty = @turno.roster_entries.empty?
    @editable = @turno.active? && @turno.manual?
    build_blank_roster_entries(@turno) if @roster_empty && @editable
  rescue ActiveRecord::RecordNotFound
    redirect_to calendario_path, alert: "El turno solicitado no existe."
  end

  def update
    @turno = turno_scope.find(params[:id])
    authorize @turno

    unless @turno.active? && @turno.manual?
      redirect_to turno_path(@turno), alert: "Este turno no puede ser modificado."
      return
    end

    if @turno.update(turno_params)
      redirect_to turno_path(@turno), notice: "Turno actualizado correctamente."
    else
      @roster_empty = @turno.roster_entries.empty?
      build_blank_roster_entries(@turno) if @roster_empty
      render :show, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to calendario_path, alert: "El turno solicitado no existe."
  end

  def cancel
    @turno = turno_scope.find(params[:id])
    authorize @turno

    if @turno.cancelled?
      redirect_to calendario_path(date: @turno.start_time.to_date), notice: "Turno ya estaba cancelado"
    elsif @turno.start_time < Time.current
      redirect_to turno_path(@turno), alert: "No se puede cancelar un turno pasado"
    else
      @turno.update!(status: :cancelled)
      redirect_to calendario_path(date: @turno.start_time.to_date), notice: "Turno cancelado"
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to calendario_path, alert: "El turno solicitado no existe."
  end

  private

  def set_complejo
    return if Current.user.nil?
    @complejo = Current.user.complejo
    redirect_to root_path, alert: "No tenés un complejo asignado." if @complejo.nil?
  end

  def parse_date(value)
    Date.parse(value) if value.present?
  rescue ArgumentError, TypeError
    nil
  end

  def turno_scope
    Turno.where(cancha: @complejo.canchas)
  end

  def slot_start_time(date, hour)
    date.to_time.change(hour: hour.to_i.clamp(0, 23))
  end

  def build_blank_roster_entries(turno, count: 4)
    count.times { |i| turno.roster_entries.build(position: turno.roster_entries.size + i) }
  end

  def turno_params
    attrs = [ :reservation_name, roster_entries_attributes: [ :id, :name, :position, :_destroy ] ]
    attrs.unshift(:recurring) if action_name == "create" && policy(Turno).mark_recurring?
    params.require(:turno).permit(*attrs)
  end
end

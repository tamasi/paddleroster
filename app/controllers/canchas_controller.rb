class CanchasController < ApplicationController
  before_action :set_complejo
  before_action :set_cancha, only: %i[ show edit update destroy ]

  rescue_from ActiveRecord::RecordNotFound, with: :cancha_not_found

  def index
    authorize Cancha
    @canchas = @complejo.canchas
  end

  def new
    authorize Cancha
    @cancha = @complejo.canchas.build
  end

  def create
    authorize Cancha
    @cancha = @complejo.canchas.build(cancha_params.except(:sport))
    @cancha.sport = cancha_params[:sport] if cancha_params.key?(:sport)

    if @cancha.save
      redirect_to configuracion_path, notice: "Cancha creada correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  rescue ArgumentError
    @cancha.errors.add(:sport, "no es válido")
    render :new, status: :unprocessable_entity
  end

  def edit
    authorize @cancha
  end

  def update
    authorize @cancha
    @cancha.assign_attributes(cancha_params.except(:sport))
    @cancha.sport = cancha_params[:sport] if cancha_params.key?(:sport)

    if @cancha.save
      redirect_to configuracion_path, notice: "Cancha actualizada correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  rescue ArgumentError
    @cancha.errors.add(:sport, "no es válido")
    render :edit, status: :unprocessable_entity
  end

  def destroy
    authorize @cancha
    @cancha.destroy
    redirect_to configuracion_path, notice: "Cancha eliminada correctamente."
  end

  private

  def set_complejo
    @complejo = Current.user.complejo
    redirect_to root_path, alert: "No tenés un complejo asignado." if @complejo.nil?
  end

  def set_cancha
    @cancha = @complejo.canchas.find(params[:id])
  end

  def cancha_params
    params.require(:cancha).permit(:name, :sport)
  end

  def cancha_not_found
    redirect_to configuracion_path, alert: "La cancha solicitada no existe."
  end
end

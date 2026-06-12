class CanchasController < ApplicationController
  before_action :set_complejo
  before_action :set_cancha, only: %i[ show edit update destroy ]

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
    @cancha = @complejo.canchas.build(cancha_params)
    if @cancha.save
      redirect_to configuracion_path, notice: "Cancha creada correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @cancha
  end

  def update
    authorize @cancha
    if @cancha.update(cancha_params)
      redirect_to configuracion_path, notice: "Cancha actualizada correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @cancha
    @cancha.destroy
    redirect_to configuracion_path, notice: "Cancha eliminada correctamente."
  end

  private

  def set_complejo
    @complejo = Current.user.complejo
  end

  def set_cancha
    @cancha = @complejo.canchas.find(params[:id])
  end

  def cancha_params
    params.require(:cancha).permit(:name, :sport)
  end
end

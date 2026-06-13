class ConfiguracionController < ApplicationController
  before_action :set_complejo

  def show
    authorize :configuracion
    @canchas = @complejo.canchas
  end

  def edit
    authorize :configuracion
  end

  def update
    authorize :configuracion
    if @complejo.update(complejo_params)
      redirect_to configuracion_path, notice: "Configuración actualizada correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_complejo
    @complejo = Current.user.complejo
    redirect_to root_path, alert: "No tenés un complejo asignado." if @complejo.nil?
  end

  def complejo_params
    params.require(:complejo).permit(:name, :contact_info)
  end
end

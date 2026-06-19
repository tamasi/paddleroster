class WhatsappConnectionsController < ApplicationController
  before_action :set_complejo
  before_action :set_whatsapp_connection

  def show
    authorize @whatsapp_connection
  end

  def connect
    authorize @whatsapp_connection, :update?
    @whatsapp_connection.update!(requested_action: "connect")
    redirect_to configuracion_path
  end

  def disconnect
    authorize @whatsapp_connection, :update?
    @whatsapp_connection.update!(requested_action: "disconnect")
    redirect_to configuracion_path
  end

  private

  def set_complejo
    @complejo = Current.user.complejo
    redirect_to root_path, alert: "No tenés un complejo asignado." if @complejo.nil?
  end

  def set_whatsapp_connection
    @whatsapp_connection = WhatsappConnection.for_complejo!(@complejo)
  end
end

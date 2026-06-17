class PaymentsController < ApplicationController
  before_action :set_complejo
  before_action :set_turno, only: [ :create ]

  def index
  end

  def create
    authorize @turno, :create_payment?

    amount = payment_params[:amount].to_d
    payment_type = payment_params[:payment_type]

    begin
      @payment = nil
      Turno.transaction do
        # Bloqueo pesimista para evitar condiciones de carrera
        @turno.lock!

        existing_total = @turno.payments.sum(:amount)
        new_total = (existing_total + amount).round(2)

        if @turno.price.present? && new_total > @turno.price.round(2)
          raise ActiveRecord::RecordInvalid.new(@turno), "El monto supera el total del turno"
        end

        @payment = @turno.payments.build(
          amount: amount,
          paid_at: Time.current,
          registered_by: Current.user
        )

        @payment.save!

        # Lógica estricta de estado: el precio manda si existe
        new_status = if @turno.price.present?
          new_total >= @turno.price.round(2) ? :paid : :partial
        else
          # Si no hay precio, el usuario elige manualmente
          payment_type == "complete" ? :paid : :partial
        end

        @turno.update!(payment_status: new_status)
      end

      @turno.reload

      Turbo::StreamsChannel.broadcast_replace_to(
        "complex_#{@complejo.id}_payments",
        target: "card-turno-#{@turno.id}",
        partial: "turnos/card_turno_stream",
        locals: { turno: @turno }
      )

      # Broadcast también para la vista de detalle
      Turbo::StreamsChannel.broadcast_replace_to(
        "complex_#{@complejo.id}_payments",
        target: "payment-status-section-#{@turno.id}",
        partial: "turnos/payment_status_section",
        locals: { turno: @turno, payment_error: nil }
      )

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "payment-status-section-#{@turno.id}",
              partial: "turnos/payment_status_section",
              locals: { turno: @turno, payment_error: nil }
            ),
            turbo_stream.replace(
              "payment-history-#{@turno.id}",
              partial: "turnos/payment_history",
              locals: { turno: @turno }
            )
          ]
        end
        format.html { redirect_to turno_path(@turno), notice: "Pago registrado" }
      end
    rescue ActiveRecord::RecordInvalid, StandardError => e
      error_msg = e.message
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "payment-status-section-#{@turno.id}",
            partial: "turnos/payment_status_section",
            locals: { turno: @turno, payment_error: error_msg }
          ), status: :unprocessable_entity
        end
        format.html { redirect_to turno_path(@turno), alert: error_msg }
      end
    end
  end

  private

  def set_complejo
    return if Current.user.nil?
    @complejo = Current.user.complejo
    redirect_to root_path, alert: "No tenés un complejo asignado." if @complejo.nil?
  end

  def set_turno
    @turno = Turno.joins(:cancha)
                   .where(canchas: { complejo_id: @complejo.id })
                   .find(params[:turno_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to calendario_path, alert: "El turno solicitado no existe."
  end

  def payment_params
    params.require(:payment).permit(:amount, :payment_type)
  end
end

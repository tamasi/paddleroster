module StatusPresentationHelper
  def humanize_payment_status(status)
    case status.to_s
    when "pending" then "Pago Pendiente"
    when "partial" then "Pago Parcial"
    when "paid" then "Pagado"
    else status.to_s.humanize
    end
  end

  def humanize_sport(sport)
    case sport.to_s
    when "padel" then "Pádel"
    when "futbol5" then "Fútbol 5"
    else sport.to_s.humanize
    end
  end

  def humanize_turno_status(status)
    case status.to_s
    when "active" then "Activo"
    when "cancelled" then "Cancelado"
    else status.to_s.humanize
    end
  end
end

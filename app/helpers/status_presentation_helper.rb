module StatusPresentationHelper
  def format_amount(amount)
    return "" if amount.blank?
    number_to_currency(amount, unit: "$", precision: 0, delimiter: ".")
  end

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

  def humanize_confirmation_status(status)
    case status.to_s
    when "pending"     then "Pendiente"
    when "confirmed"   then "Confirmado"
    when "replacement" then "Reemplazo"
    when "uncovered"   then "Sin cubrir"
    else status.to_s.humanize
    end
  end
end

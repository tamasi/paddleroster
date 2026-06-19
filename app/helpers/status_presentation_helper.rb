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
    when "futbol_5", "futbol5" then "Fútbol 5"
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

  def humanize_confirmation_status(status_or_entry)
    return "Ofrecido" if status_or_entry.respond_to?(:offered?) && status_or_entry.offered?

    status = status_or_entry.respond_to?(:confirmation_status) ? status_or_entry.confirmation_status : status_or_entry
    case status.to_s
    when "pending"     then "Pendiente"
    when "confirmed"   then "Confirmado"
    when "replacement" then "Reemplazo"
    when "uncovered"   then "Sin cubrir"
    else status.to_s.humanize
    end
  end

  def humanize_whatsapp_connection_status(status)
    case status.to_s
    when "connected"    then "Conectado"
    when "connecting"   then "Conectando"
    when "disconnected" then "Desconectado"
    else status.to_s.humanize
    end
  end

  def whatsapp_connection_badge_classes(status)
    case status.to_s
    when "connected"    then "bg-paid-bg dark:bg-paid-bg-dark text-paid-fg dark:text-paid-fg-dark"
    when "connecting"   then "bg-pending-bg dark:bg-pending-bg-dark text-pending-fg dark:text-pending-fg-dark"
    when "disconnected" then "bg-danger/10 text-danger dark:bg-danger-dark/15 dark:text-danger-dark"
    else "bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200"
    end
  end
end

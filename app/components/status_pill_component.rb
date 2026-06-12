# frozen_string_literal: true

class StatusPillComponent < ViewComponent::Base
  include StatusPresentationHelper

  def initialize(status:)
    @status = status.to_s
  end

  def wrapper_classes
    case @status
    when "paid"
      "bg-paid-bg dark:bg-paid-bg-dark text-paid-fg dark:text-paid-fg-dark"
    when "partial"
      "bg-partial-bg dark:bg-partial-bg-dark text-partial-fg dark:text-partial-fg-dark"
    when "pending"
      "bg-pending-bg dark:bg-pending-bg-dark text-pending-fg dark:text-pending-fg-dark"
    when "cancelled"
      "bg-danger/10 text-danger dark:bg-danger-dark/15 dark:text-danger-dark"
    else
      "bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200"
    end
  end

  def icon_classes
    case @status
    when "paid"
      "text-success dark:text-success-dark"
    when "partial"
      "text-warning dark:text-warning-dark"
    when "pending"
      "text-accent dark:text-accent-dark"
    when "cancelled"
      "text-danger dark:text-danger-dark"
    else
      "text-gray-500"
    end
  end

  def label
    if Turno.statuses.keys.include?(@status)
      humanize_turno_status(@status)
    else
      humanize_payment_status(@status)
    end
  end
end

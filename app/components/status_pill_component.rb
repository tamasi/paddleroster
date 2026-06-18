# frozen_string_literal: true

class StatusPillComponent < ViewComponent::Base
  include StatusPresentationHelper

  def initialize(status:, context: :payment, entry: nil)
    @status  = status.to_s
    @context = context
    @entry   = entry
  end

  def wrapper_classes
    case visual_status
    when "paid", "confirmed"
      "bg-paid-bg dark:bg-paid-bg-dark text-paid-fg dark:text-paid-fg-dark"
    when "partial", "replacement", "offered"
      "bg-partial-bg dark:bg-partial-bg-dark text-partial-fg dark:text-partial-fg-dark"
    when "pending"
      "bg-pending-bg dark:bg-pending-bg-dark text-pending-fg dark:text-pending-fg-dark"
    when "cancelled", "uncovered"
      "bg-danger/10 text-danger dark:bg-danger-dark/15 dark:text-danger-dark"
    else
      "bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200"
    end
  end

  def icon_classes
    case visual_status
    when "paid", "confirmed"
      "text-success dark:text-success-dark"
    when "partial", "replacement", "offered"
      "text-warning dark:text-warning-dark"
    when "pending"
      "text-accent dark:text-accent-dark"
    when "cancelled", "uncovered"
      "text-danger dark:text-danger-dark"
    else
      "text-gray-500"
    end
  end

  def label
    if @context == :roster
      humanize_confirmation_status(@entry || @status)
    elsif Turno.statuses.keys.include?(@status)
      humanize_turno_status(@status)
    else
      humanize_payment_status(@status)
    end
  end

  private

  def visual_status
    @entry&.offered? ? "offered" : @status
  end
end

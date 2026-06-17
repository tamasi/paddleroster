# frozen_string_literal: true

class WhatsappOutboxMessage < ApplicationRecord
  self.table_name = "whatsapp_outbox"

  VALID_STATUSES = %w[pending sent failed].freeze

  validates :phone, presence: true
  validates :body, presence: true
  validates :status, inclusion: { in: VALID_STATUSES }
  validates :retry_count, numericality: { greater_than_or_equal_to: 0 }

  scope :pending, -> { where(status: "pending") }
  scope :failed,  -> { where(status: "failed") }
end

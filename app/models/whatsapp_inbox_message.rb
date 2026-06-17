# frozen_string_literal: true

class WhatsappInboxMessage < ApplicationRecord
  self.table_name = "whatsapp_inbox"

  validates :phone, presence: true
  validates :raw_body, presence: true

  scope :unprocessed, -> { where(processed: false) }
end

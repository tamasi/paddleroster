# frozen_string_literal: true

class WhatsappConnection < ApplicationRecord
  belongs_to :complejo

  VALID_STATUSES = %w[disconnected connecting connected].freeze
  VALID_ACTIONS = %w[connect disconnect].freeze

  validates :complejo_id, uniqueness: true
  validates :status, inclusion: { in: VALID_STATUSES }
  validates :requested_action, inclusion: { in: VALID_ACTIONS }, allow_nil: true

  def self.for_complejo!(complejo)
    find_or_create_by!(complejo: complejo)
  rescue ActiveRecord::RecordNotUnique
    find_by!(complejo: complejo)
  end

  def disconnected?
    status == "disconnected"
  end

  def connecting?
    status == "connecting"
  end

  def connected?
    status == "connected"
  end
end

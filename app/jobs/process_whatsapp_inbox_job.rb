# frozen_string_literal: true

class ProcessWhatsappInboxJob < ApplicationJob
  queue_as :default

  def perform
    WhatsappInboxMessage.unprocessed.order(created_at: :asc).lock("FOR UPDATE SKIP LOCKED").find_each do |msg|
      process_message(msg)
    rescue StandardError => e
      Rails.logger.error("Error processing WhatsappInboxMessage #{msg.id}: #{e.message}")
      msg.update!(processed: true)
    end
  end

  private

  def process_message(msg)
    WhatsappInboxProcessor.new(msg).process
    msg.update!(processed: true)
  end
end

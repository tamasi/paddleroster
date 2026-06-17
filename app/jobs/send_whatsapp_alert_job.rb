# frozen_string_literal: true

require "net/http"
require "uri"

class SendWhatsappAlertJob < ApplicationJob
  queue_as :default

  def perform(message)
    token   = ENV["TELEGRAM_BOT_TOKEN"]
    chat_id = ENV["TELEGRAM_CHAT_ID"]

    unless token && chat_id
      Rails.logger.warn("SendWhatsappAlertJob: TELEGRAM_BOT_TOKEN o TELEGRAM_CHAT_ID no configurados — alerta no enviada")
      return
    end

    uri = URI("https://api.telegram.org/bot#{token}/sendMessage")
    Net::HTTP.post_form(uri, { chat_id: chat_id, text: "[retroai] #{message}" })
  end
end

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
    params = { chat_id: chat_id, text: "[retroai] #{message}" }

    begin
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
        request = Net::HTTP::Post.new(uri)
        request.set_form_data(params)
        http.request(request)
      end
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error("SendWhatsappAlertJob: Timeout enviando alerta a Telegram: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("SendWhatsappAlertJob: Error inesperado enviando alerta: #{e.message}")
    end
  end
end

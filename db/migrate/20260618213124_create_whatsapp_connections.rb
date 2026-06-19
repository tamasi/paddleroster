# frozen_string_literal: true

class CreateWhatsappConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :whatsapp_connections do |t|
      t.references :complejo, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: "disconnected"
      t.string :phone
      t.text :qr_code
      t.string :requested_action

      t.timestamps
    end
  end
end

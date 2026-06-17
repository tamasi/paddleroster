# frozen_string_literal: true

class CreateWhatsappOutbox < ActiveRecord::Migration[8.1]
  def change
    create_table :whatsapp_outbox do |t|
      t.string  :phone,       null: false
      t.text    :body,        null: false
      t.string  :status,      null: false, default: "pending"
      t.integer :retry_count, null: false, default: 0
      t.timestamps
    end

    add_index :whatsapp_outbox, :status
  end
end

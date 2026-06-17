# frozen_string_literal: true

class CreateWhatsappInbox < ActiveRecord::Migration[8.1]
  def change
    create_table :whatsapp_inbox do |t|
      t.string  :phone,    null: false
      t.text    :raw_body, null: false
      t.boolean :processed, null: false, default: false
      t.timestamps
    end

    add_index :whatsapp_inbox, :processed
  end
end

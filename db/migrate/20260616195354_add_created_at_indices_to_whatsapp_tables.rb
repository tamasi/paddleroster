class AddCreatedAtIndicesToWhatsappTables < ActiveRecord::Migration[8.1]
  def change
    add_index :whatsapp_outbox, :created_at
    add_index :whatsapp_inbox, :created_at
  end
end

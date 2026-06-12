class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.references :complejo, null: false, foreign_key: true

      t.timestamps
    end
    add_index :invitations, :token, unique: true
  end
end

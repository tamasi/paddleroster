class CreateRosterEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :roster_entries do |t|
      t.references :turno, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :role, null: false, default: 0
      t.integer :confirmation_status, null: false, default: 0
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end

class CreateCanchas < ActiveRecord::Migration[8.1]
  def change
    create_table :canchas do |t|
      t.string :name, null: false
      t.integer :sport, null: false
      t.references :complejo, null: false, foreign_key: true

      t.timestamps
    end
  end
end

class CreateTurnos < ActiveRecord::Migration[8.1]
  def change
    create_table :turnos do |t|
      t.datetime :start_time, null: false
      t.integer :origin, null: false, default: 0
      t.integer :payment_status, null: false, default: 0
      t.references :cancha, null: false, foreign_key: true

      t.timestamps
    end
  end
end

class AddReservationNameAndUniqueSlotIndexToTurnos < ActiveRecord::Migration[8.1]
  def change
    add_column :turnos, :reservation_name, :string
    add_index :turnos, [ :cancha_id, :start_time ], unique: true
  end
end

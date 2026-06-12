class AddStatusToTurnosAndScopeUniqueSlotIndex < ActiveRecord::Migration[8.1]
  def change
    add_column :turnos, :status, :integer, null: false, default: 0

    remove_index :turnos, [ :cancha_id, :start_time ], unique: true, name: "index_turnos_on_cancha_id_and_start_time"
    add_index :turnos, [ :cancha_id, :start_time ], unique: true, where: "status = 0", name: "index_turnos_on_cancha_id_and_start_time_active"
  end
end

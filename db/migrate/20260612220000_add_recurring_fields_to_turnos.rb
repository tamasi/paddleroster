class AddRecurringFieldsToTurnos < ActiveRecord::Migration[8.1]
  def change
    add_column :turnos, :recurring, :boolean, null: false, default: false
    add_reference :turnos, :recurring_rule, foreign_key: { to_table: :turnos }, null: true
  end
end

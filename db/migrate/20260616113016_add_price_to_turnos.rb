class AddPriceToTurnos < ActiveRecord::Migration[8.1]
  def change
    add_column :turnos, :price, :decimal, precision: 10, scale: 2
  end
end

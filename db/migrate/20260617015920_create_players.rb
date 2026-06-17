# frozen_string_literal: true

class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.string :name,  null: false
      t.string :phone, null: false
      t.timestamps
    end

    add_index :players, :phone, unique: true
  end
end

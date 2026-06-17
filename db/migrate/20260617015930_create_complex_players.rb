# frozen_string_literal: true

class CreateComplexPlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :complex_players do |t|
      t.references :player,  null: false, foreign_key: true
      t.references :complejo, null: false, foreign_key: true
      t.timestamps
    end

    add_index :complex_players, %i[player_id complejo_id], unique: true
  end
end

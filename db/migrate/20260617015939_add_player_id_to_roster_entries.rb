# frozen_string_literal: true

class AddPlayerIdToRosterEntries < ActiveRecord::Migration[8.1]
  def change
    add_reference :roster_entries, :player, foreign_key: true, null: true
  end
end

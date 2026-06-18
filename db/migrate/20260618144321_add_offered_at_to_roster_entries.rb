# frozen_string_literal: true

class AddOfferedAtToRosterEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :roster_entries, :offered_at, :datetime
  end
end

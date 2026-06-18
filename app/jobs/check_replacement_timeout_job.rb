# frozen_string_literal: true

class CheckReplacementTimeoutJob < ApplicationJob
  queue_as :default

  def perform(roster_entry_id)
    entry = RosterEntry.find_by(id: roster_entry_id)
    return unless entry
    return unless entry.pending? && entry.offered_at.present?

    entry.update!(confirmation_status: :uncovered)
    RosterReplacementService.new(entry).call
  end
end

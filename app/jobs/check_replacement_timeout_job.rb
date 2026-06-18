# frozen_string_literal: true

class CheckReplacementTimeoutJob < ApplicationJob
  queue_as :default

  IMMEDIATE_THRESHOLD = 2.hours
  LONG_TIMEOUT  = 2.hours
  SHORT_TIMEOUT = 15.minutes

  def perform(roster_entry_id)
    entry = RosterEntry.find_by(id: roster_entry_id)
    return unless entry
    return unless entry.pending? && entry.offered_at.present?

    timeout_duration = (entry.turno.start_time - entry.offered_at > IMMEDIATE_THRESHOLD) ? LONG_TIMEOUT : SHORT_TIMEOUT
    return if Time.current < entry.offered_at + timeout_duration

    entry.transaction do
      entry.update!(confirmation_status: :uncovered)
      RosterReplacementService.new(entry).call
    end
  end
end

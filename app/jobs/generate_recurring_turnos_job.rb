class GenerateRecurringTurnosJob < ApplicationJob
  queue_as :default

  def perform(turno_id)
    turno = Turno.find_by(id: turno_id)
    return if turno.nil?

    RecurringTurnoGenerator.new(turno).call
  end
end

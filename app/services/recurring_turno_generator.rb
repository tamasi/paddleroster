class RecurringTurnoGenerator
  WEEKS_AHEAD = 8

  def initialize(turno)
    @turno = turno
  end

  def call
    created = []

    (1..WEEKS_AHEAD).each do |n|
      start_time = @turno.start_time + n.weeks

      next if Turno.active.exists?(cancha_id: @turno.cancha_id, start_time: start_time)

      instance = Turno.new(
        cancha_id: @turno.cancha_id,
        start_time: start_time,
        reservation_name: @turno.reservation_name,
        origin: @turno.origin,
        status: :active,
        recurring: false,
        recurring_rule: @turno
      )

      @turno.roster_entries.each do |entry|
        instance.roster_entries.build(name: entry.name, position: entry.position)
      end

      begin
        instance.save!
        created << instance
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        next
      end
    end

    created
  end
end

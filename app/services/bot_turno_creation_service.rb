# frozen_string_literal: true

class BotTurnoCreationService
  Result = Struct.new(:success?, :turno, :errors, keyword_init: true)

  PHONE_RE = /\+\d{7,15}/
  DATE_RE  = /\A\d{2}\/\d{2}\/\d{4}\z/
  TIME_RE  = /\A\d{1,2}:\d{2}\z/

  def initialize(captain_phone, raw_message)
    @captain_phone = captain_phone
    @raw_message   = raw_message
    @errors        = []
  end

  def call
    parse
    validate
    return Result.new(success?: false, turno: nil, errors: @errors) if @errors.any?

    turno = create_turno
    turno ? Result.new(success?: true, turno: turno, errors: []) :
            Result.new(success?: false, turno: nil, errors: @errors)
  end

  private

  def parse
    lines = @raw_message.strip.split("\n").map(&:strip).reject(&:empty?)
    lines.shift # quita la línea "TURNO"

    @cancha_name     = nil
    @fecha_str       = nil
    @horario_str     = nil
    @titulares       = []
    @suplentes       = []
    current_section  = :header

    lines.each do |line|
      # Detección robusta de sección (case-insensitive, ignora espacios extras)
      lower_line = line.downcase
      if lower_line.start_with?("cancha:")
        @cancha_name = line.split(":", 2).last&.strip
        next
      elsif lower_line.start_with?("fecha:")
        @fecha_str = line.split(":", 2).last&.strip
        next
      elsif lower_line.start_with?("horario:")
        @horario_str = line.split(":", 2).last&.strip
        next
      elsif lower_line.start_with?("jugadores:")
        current_section = :titulares
        next
      elsif lower_line.start_with?("suplentes:")
        current_section = :suplentes
        next
      end

      # Línea de jugador: contiene un teléfono E.164
      phone_match = line.match(PHONE_RE)
      next unless phone_match

      phone = phone_match[0]
      name  = line.sub(phone, "").strip.presence || phone
      entry = { name: name, phone: phone }
      current_section == :suplentes ? @suplentes << entry : @titulares << entry
    end
  end

  def validate
    @errors << "Falta el campo 'cancha'"   if @cancha_name.blank?
    @errors << "Falta el campo 'fecha'"    if @fecha_str.blank?
    @errors << "Falta el campo 'horario'"  if @horario_str.blank?

    return if @errors.any?

    validate_cancha
    validate_fecha
    validate_horario
    validate_jugadores
  end

  def validate_cancha
    @cancha = Cancha.find_by("LOWER(name) = ?", @cancha_name.downcase)
    @errors << "Cancha '#{@cancha_name}' no encontrada" unless @cancha
  end

  def validate_fecha
    @date = Date.strptime(@fecha_str, "%d/%m/%Y")
    @errors << "La fecha #{@fecha_str} ya pasó" if @date < Date.current
  rescue Date::Error, ArgumentError
    @errors << "Fecha inválida '#{@fecha_str}'. Usá DD/MM/YYYY"
  end

  def validate_horario
    unless @horario_str.match?(TIME_RE)
      @errors << "Horario inválido '#{@horario_str}'. Usá HH:MM"
      return
    end

    h_str, m_str = @horario_str.split(":")
    hour = h_str.to_i
    min  = m_str.to_i

    if min != 0
      @errors << "Solo se permiten turnos en la hora exacta (ej: #{hour}:00)"
      return
    end

    unless Complejo::HORARIO_OPERATIVO.include?(hour)
      @errors << "El horario #{@horario_str} está fuera del horario operativo " \
                 "(#{Complejo::HORARIO_OPERATIVO.first}:00 — #{Complejo::HORARIO_OPERATIVO.last}:00)"
    end
  end

  def validate_jugadores
    if @titulares.empty?
      @errors << "Se necesita al menos 1 jugador"
      return
    end

    all    = @titulares + @suplentes
    phones = all.map { |j| j[:phone] }
    dupes  = phones.tally.select { |_, count| count > 1 }.keys
    @errors << "Teléfonos duplicados: #{dupes.join(', ')}" if dupes.any?

    invalid = all.reject { |j| j[:phone].match?(/\A\+\d{7,15}\z/) }.map { |j| j[:phone] }
    @errors << "Teléfonos inválidos: #{invalid.join(', ')}" if invalid.any?
  end

  def create_turno
    ActiveRecord::Base.transaction do
      h, m       = @horario_str.split(":").map(&:to_i)
      start_time = Time.zone.local(@date.year, @date.month, @date.day, h, m, 0)

      turno = Turno.new(
        cancha:           @cancha,
        start_time:       start_time,
        reservation_name: @titulares.first[:name],
        origin:           :bot,
        status:           :active,
        payment_status:   :pending
      )

      build_roster_entries(turno)
      turno.save!
      turno
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.record.errors.full_messages.join(", ")
    nil
  rescue ActiveRecord::RecordNotUnique
    @errors << "Ya existe un turno en esa cancha y horario"
    nil
  rescue StandardError => e
    @errors << "Error inesperado al crear el turno: #{e.message}"
    nil
  end

  def build_roster_entries(turno)
    @titulares.each_with_index do |j, i|
      player = find_or_create_player(j[:name], j[:phone])
      turno.roster_entries.build(
        player:               player,
        name:                 player.name,
        role:                 :titular,
        position:             i,
        confirmation_status:  :pending
      )
    end

    @suplentes.each_with_index do |j, i|
      player = find_or_create_player(j[:name], j[:phone])
      turno.roster_entries.build(
        player:               player,
        name:                 player.name,
        role:                 :suplente,
        position:             @titulares.size + i,
        confirmation_status:  :pending
      )
    end
  end

  def find_or_create_player(name, phone)
    player = Player.find_by(phone: phone)

    if player
      ComplexPlayer.find_or_create_by!(player: player, complejo: @cancha.complejo)
    else
      player = Player.create!(name: name, phone: phone)
      ComplexPlayer.create!(player: player, complejo: @cancha.complejo)
    end

    player
  end
end

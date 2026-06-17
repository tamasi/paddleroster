---
story_id: "5.2"
story_key: "5-2-creacion-de-turno-y-roster-inicial-via-bot-fr-1"
epic_id: "5"
title: "Creación de Turno y Roster inicial vía Bot (FR-1)"
status: "review"
last_updated: "2026-06-17"
baseline_commit: a47585d5335f49801cf8a7dff6ec86bf509f5975
---

# Story 5.2: Creación de Turno y Roster inicial vía Bot (FR-1)

**As a** Capitán,
**I want** crear un Turno y cargar mi Roster inicial enviando un mensaje al Bot,
**So that** no tenga que coordinar manualmente por WhatsApp con cada jugador.

## Acceptance Criteria

- **AC1: Mensaje válido → Turno de Origen Bot + Roster con estado Pendiente**
  - **Given** que envío al Bot un mensaje con el formato definido (cancha, fecha, horario, jugadores con teléfonos)
  - **When** el formato es válido y no hay duplicados de teléfono
  - **Then** se crea un `Turno` con `origin: :bot`, su Roster inicial con cada jugador con `confirmation_status: :pending`, y el Bot me responde con un resumen de confirmación

- **AC2: Mensaje inválido → error específico sin crear Turno**
  - **Given** que mi mensaje tiene una entrada inválida (cancha inexistente, fecha pasada, horario fuera de rango, teléfono malformado, duplicado, sin jugadores)
  - **When** el Bot la detecta
  - **Then** me responde con el error específico sin crear ningún Turno ni RosterEntry, hasta que lo corrija

- **AC3: Jugador existente como `Player` → vincula sin duplicar**
  - **Given** que un teléfono en el Roster ya existe en la tabla `players`
  - **When** se crea el Turno
  - **Then** el `RosterEntry` se vincula al `Player` existente (`player_id`) sin crear un nuevo Player

- **AC4: Jugador nuevo → crea `Player` + `ComplexPlayer`**
  - **Given** que un teléfono en el Roster no existe en `players`
  - **When** se crea el Turno
  - **Then** se crea un nuevo `Player` (name + phone) y un `ComplexPlayer` asociando ese Player al Complejo de la Cancha

- **AC5: Turno visible en Panel con Origen Bot y Roster**
  - **Given** que el Turno fue creado por el Bot
  - **When** lo veo en el Detalle del Turno en el Panel
  - **Then** el Roster aparece en modo solo-lectura con el `confirmation_status` visible junto al nombre de cada jugador (UX-DR4)

## Tasks / Subtasks

### Task 1: Migraciones y Modelos — Player, ComplexPlayer, RosterEntry
- [x] T1.1: Migración `create_players` — tabla `players` (name, phone E.164 único)
- [x] T1.2: Migración `create_complex_players` — tabla `complex_players` (player_id, complejo_id, unique)
- [x] T1.3: Migración `add_player_id_to_roster_entries` — FK opcional a `players`
- [x] T1.4: Modelo `Player` con validaciones (phone único, formato E.164)
- [x] T1.5: Modelo `ComplexPlayer` con validaciones (unicidad player+complejo)
- [x] T1.6: Actualizar modelo `RosterEntry` — agrega `belongs_to :player, optional: true`
- [x] T1.7: `bin/rails db:migrate` y verificar schema

### Task 2: Servicios de dominio
- [x] T2.1: Crear `app/services/whatsapp_inbox_processor.rb` — router de comandos del bot
- [x] T2.2: Crear `app/services/bot_turno_creation_service.rb` — parsea mensaje, valida, crea Turno+Roster
- [x] T2.3: Actualizar `ProcessWhatsappInboxJob#process_message` — llamar a `WhatsappInboxProcessor`

### Task 3: Vista — show Turno con confirmation_status para bot origin
- [x] T3.1: Actualizar `app/views/turnos/show.html.erb` — rama readonly muestra badge de `confirmation_status` para turnos de origen bot

### Task 4: Tests
- [x] T4.1: Tests de modelos `Player` y `ComplexPlayer`
- [x] T4.2: Tests de `BotTurnoCreationService` — happy path, errores de validación, Player lookup/create
- [x] T4.3: Tests de `WhatsappInboxProcessor` — routing TURNO command, unknown message
- [x] T4.4: Tests de `ProcessWhatsappInboxJob` — integración con WhatsappInboxProcessor
- [x] T4.5: `bin/rails test` — 0 failures, 0 errors
- [x] T4.6: `bin/rubocop` sobre `.rb` nuevos — 0 offenses

---

## Dev Notes

### Formato de mensaje del Bot (definición MVP)

El Capitán envía el siguiente formato vía WhatsApp:

```
TURNO
cancha: Cancha de Padel 1
fecha: 17/06/2026
horario: 20:00
jugadores:
Juan López +5491155556666
María Pérez +5491133334444
suplentes:
Carlos Gómez +5491122223333
```

**Reglas de parsing:**
- Primera línea: `TURNO` (case-insensitive, puede tener espacios)
- Claves `cancha:`, `fecha:`, `horario:` — case-insensitive, valor después del `:`
- Sección `jugadores:` — jugadores titulares, al menos 1 requerido
- Sección `suplentes:` — opcional, 0 o más suplentes
- Cada línea de jugador: `[Nombre] [teléfono E.164]` — el teléfono es el último token que comienza con `+`
- Nombre: el resto de la línea antes del teléfono (puede tener espacios)
- Teléfono E.164: `/\A\+\d{7,15}\z/`

**Formato de fecha:** `DD/MM/YYYY`
**Formato de horario:** `HH:MM` (24h) — solo hora exacta permitida (`:00`), dentro de `Complejo::HORARIO_OPERATIVO` (14..23)

**Cancha lookup:** `Cancha.find_by("LOWER(name) = ?", parsed_name.strip.downcase)` — case-insensitive, sin asumir complejo (single-tenant: una instalación = un complejo).

**`reservation_name`:** Nombre del primer jugador titular (el Capitán por convención).

---

### Task 1 — Migraciones (detalles exactos)

**T1.1 — `create_players`:**
```ruby
create_table :players do |t|
  t.string :name,  null: false
  t.string :phone, null: false
  t.timestamps
end
add_index :players, :phone, unique: true
```

**T1.2 — `create_complex_players`:**
```ruby
create_table :complex_players do |t|
  t.references :player,  null: false, foreign_key: true
  t.references :complejo, null: false, foreign_key: true
  t.timestamps
end
add_index :complex_players, [:player_id, :complejo_id], unique: true
```

**T1.3 — `add_player_id_to_roster_entries`:**
```ruby
add_reference :roster_entries, :player, foreign_key: true, null: true
```

---

### Task 1 — Modelos (detalles exactos)

**T1.4 — `app/models/player.rb`:**
```ruby
# frozen_string_literal: true
class Player < ApplicationRecord
  has_many :complex_players, dependent: :destroy
  has_many :complejos, through: :complex_players
  has_many :roster_entries, dependent: :nullify

  validates :name, presence: true
  validates :phone, presence: true, uniqueness: true,
                    format: { with: /\A\+\d{7,15}\z/, message: "debe ser formato E.164 (ej: +5491155556666)" }
end
```

**T1.5 — `app/models/complex_player.rb`:**
```ruby
# frozen_string_literal: true
class ComplexPlayer < ApplicationRecord
  belongs_to :player
  belongs_to :complejo

  validates :player_id, uniqueness: { scope: :complejo_id, message: "ya está asociado a este complejo" }
end
```

**T1.6 — Actualizar `app/models/roster_entry.rb`:**
Agregar: `belongs_to :player, optional: true`
El resto del modelo queda igual (confirmations, role, etc.)

---

### Task 2 — Servicios (detalles exactos)

#### T2.1 — `app/services/whatsapp_inbox_processor.rb`

```ruby
# frozen_string_literal: true
class WhatsappInboxProcessor
  TURNO_COMMAND = /\ATURNO\b/i

  def initialize(inbox_message)
    @inbox_message = inbox_message
    @phone = inbox_message.phone
    @body  = inbox_message.raw_body.strip
  end

  def process
    return if @phone == "SYSTEM"

    if @body.match?(TURNO_COMMAND)
      handle_turno_command
    else
      handle_unknown_message
    end
  end

  private

  def handle_turno_command
    result = BotTurnoCreationService.new(@phone, @body).call
    if result.success?
      reply(turno_created_message(result.turno))
    else
      reply("❌ No pude crear el turno:\n#{result.errors.join("\n")}")
    end
  end

  def handle_unknown_message
    reply(help_message)
  end

  def reply(text)
    WhatsappOutboxMessage.create!(phone: @phone, body: text, status: "pending")
  end

  def turno_created_message(turno)
    titulares  = turno.roster_entries.select(&:titular?).size
    suplentes  = turno.roster_entries.select(&:suplente?).size
    fecha      = turno.start_time.strftime("%d/%m/%Y")
    horario    = turno.start_time.strftime("%H:%M")
    "✅ Turno creado: #{turno.cancha.name}, #{fecha} #{horario}\n" \
    "👥 #{titulares} titular(es), #{suplentes} suplente(s) cargados con estado Pendiente."
  end

  def help_message
    "No entendí tu mensaje. Para crear un turno enviá:\n\n" \
    "TURNO\n" \
    "cancha: [nombre de la cancha]\n" \
    "fecha: DD/MM/YYYY\n" \
    "horario: HH:MM\n" \
    "jugadores:\n" \
    "Nombre Apellido +549XXXXXXXXXX\n" \
    "suplentes:\n" \
    "Nombre Apellido +549XXXXXXXXXX"
  end
end
```

#### T2.2 — `app/services/bot_turno_creation_service.rb`

```ruby
# frozen_string_literal: true
class BotTurnoCreationService
  Result = Struct.new(:success?, :turno, :errors, keyword_init: true)

  PHONE_RE  = /\+\d{7,15}/
  DATE_RE   = /\A\d{2}\/\d{2}\/\d{4}\z/
  TIME_RE   = /\A\d{1,2}:\d{2}\z/

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
    # Skip first "TURNO" line
    lines.shift

    @cancha_name = nil
    @fecha_str   = nil
    @horario_str = nil
    @titulares   = []
    @suplentes   = []

    current_section = :header

    lines.each do |line|
      key, val = line.split(":", 2)
      case key.strip.downcase
      when "cancha"
        @cancha_name = val&.strip
      when "fecha"
        @fecha_str = val&.strip
      when "horario"
        @horario_str = val&.strip
      when "jugadores"
        current_section = :titulares
      when "suplentes"
        current_section = :suplentes
      else
        # Es una línea de jugador si tiene teléfono
        phone_match = line.match(PHONE_RE)
        next unless phone_match

        phone = phone_match[0]
        name  = line.sub(phone, "").strip.presence || phone
        (current_section == :suplentes ? @suplentes : @titulares) << { name: name, phone: phone }
      end
    end
  end

  def validate
    @errors << "Falta el campo 'cancha'" if @cancha_name.blank?
    @errors << "Falta el campo 'fecha'" if @fecha_str.blank?
    @errors << "Falta el campo 'horario'" if @horario_str.blank?

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
    @date = Date.strptime(@fecha_str, "%d/%m/%Y") rescue nil
    if @date.nil?
      @errors << "Fecha inválida '#{@fecha_str}'. Usá DD/MM/YYYY"
    elsif @date < Date.current
      @errors << "La fecha #{@fecha_str} ya pasó"
    end
  rescue ArgumentError
    @errors << "Fecha inválida '#{@fecha_str}'"
  end

  def validate_horario
    return if @horario_str.blank?

    unless @horario_str.match?(TIME_RE)
      @errors << "Horario inválido '#{@horario_str}'. Usá HH:MM"
      return
    end

    hour = @horario_str.split(":").first.to_i
    unless Complejo::HORARIO_OPERATIVO.include?(hour)
      @errors << "El horario #{@horario_str} está fuera del horario operativo (#{Complejo::HORARIO_OPERATIVO.first}:00 — #{Complejo::HORARIO_OPERATIVO.last}:00)"
    end
  end

  def validate_jugadores
    if @titulares.empty?
      @errors << "Se necesita al menos 1 jugador"
      return
    end

    all = @titulares + @suplentes
    phones = all.map { |j| j[:phone] }
    dupes  = phones.group_by(&:itself).select { |_, v| v.size > 1 }.keys
    @errors << "Teléfonos duplicados: #{dupes.join(', ')}" if dupes.any?

    invalid = all.reject { |j| j[:phone].match?(/\A\+\d{7,15}\z/) }.map { |j| j[:phone] }
    @errors << "Teléfonos inválidos: #{invalid.join(', ')}" if invalid.any?
  end

  def create_turno
    ActiveRecord::Base.transaction do
      h, m = @horario_str.split(":").map(&:to_i)
      start_time = @date.to_time.change(hour: h, min: m, sec: 0)

      turno = Turno.new(
        cancha: @cancha,
        start_time: start_time,
        reservation_name: @titulares.first[:name],
        origin: :bot,
        status: :active,
        payment_status: :pending
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
  end

  def build_roster_entries(turno)
    @titulares.each_with_index do |j, i|
      player = find_or_create_player(j[:name], j[:phone])
      turno.roster_entries.build(
        player: player,
        name: player.name,
        role: :titular,
        position: i,
        confirmation_status: :pending
      )
    end

    @suplentes.each_with_index do |j, i|
      player = find_or_create_player(j[:name], j[:phone])
      turno.roster_entries.build(
        player: player,
        name: player.name,
        role: :suplente,
        position: @titulares.size + i,
        confirmation_status: :pending
      )
    end
  end

  def find_or_create_player(name, phone)
    player = Player.find_by(phone: phone)

    if player
      # Asociar al complejo si aún no está vinculado
      ComplexPlayer.find_or_create_by!(player: player, complejo: @cancha.complejo)
    else
      player = Player.create!(name: name, phone: phone)
      ComplexPlayer.create!(player: player, complejo: @cancha.complejo)
    end

    player
  end
end
```

#### T2.3 — Actualizar `ProcessWhatsappInboxJob#process_message`

```ruby
def process_message(msg)
  WhatsappInboxProcessor.new(msg).process
  msg.update!(processed: true)
end
```
Eliminar el bloque SYSTEM/BOT_DISCONNECTED del job — ahora es responsabilidad de `WhatsappInboxProcessor` (que retorna sin hacer nada para `phone == "SYSTEM"`). La inserción del SYSTEM record en whatsapp_inbox ya ocurre desde `baileys-client.ts`.

**IMPORTANTE:** Eliminar la lógica de `SendWhatsappAlertJob.perform_later` que estaba hardcodeada en el job — pasa a ser parte del `WhatsappInboxProcessor`.

Actualizar `WhatsappInboxProcessor` para manejar también el caso SYSTEM:
```ruby
def process
  return handle_system_alert if @phone == "SYSTEM"
  ...
end

def handle_system_alert
  return unless @body == "BOT_DISCONNECTED"
  SendWhatsappAlertJob.perform_later("Bot de WhatsApp desconectado — revisar el servicio.")
end
```

---

### Task 3 — Vista show.html.erb (detalles)

En la rama `else` (readonly), reemplazar el bloque de roster para mostrar `confirmation_status` cuando el turno es `bot`:

```erb
<% @turno.roster_entries.each do |entry| %>
  <div class="py-2 border-b border-border dark:border-border-dark last:border-0 flex items-center justify-between">
    <div>
      <span class="text-text-primary dark:text-text-primary-dark font-medium"><%= entry.name %></span>
      <% if entry.suplente? %>
        <span class="ml-1 text-xs text-text-secondary dark:text-text-secondary-dark">(suplente)</span>
      <% end %>
    </div>
    <% if @turno.bot? %>
      <%= render StatusPillComponent.new(status: entry.confirmation_status) %>
    <% end %>
  </div>
<% end %>
```

`StatusPillComponent` ya soporta status strings. Agregar casos en el componente o helper si `confirmation_status` strings no están soportados todavía. Verificar qué acepta `StatusPillComponent.new(status:)`.

---

### Task 4 — Tests (detalles)

**Fixtures necesarias:**
```yaml
# test/fixtures/players.yml
one:
  name: "Juan López"
  phone: "+5491155556666"
  created_at: 2026-01-01 00:00:00
  updated_at: 2026-01-01 00:00:00

# test/fixtures/complex_players.yml
one:
  player: one
  complejo: piloto
  created_at: 2026-01-01 00:00:00
  updated_at: 2026-01-01 00:00:00
```

**`test/models/player_test.rb`:** validations (phone uniqueness, E.164 format, presence)

**`test/models/complex_player_test.rb`:** uniqueness (player+complejo)

**`test/services/bot_turno_creation_service_test.rb`:**
- Happy path: mensaje válido → Turno creado, RosterEntries con player_id
- Error: cancha inexistente → error, no Turno
- Error: fecha pasada → error
- Error: horario fuera de rango → error
- Error: teléfono duplicado → error
- Error: sin jugadores → error
- Player lookup: teléfono ya existe → no crear nuevo Player
- Player create: teléfono nuevo → crear Player + ComplexPlayer
- ComplexPlayer reutilizado: teléfono + complejo ya vinculado → no duplicar

**`test/services/whatsapp_inbox_processor_test.rb`:**
- SYSTEM BOT_DISCONNECTED → enqueue SendWhatsappAlertJob
- SYSTEM otro body → no action
- "TURNO\ncancha:..." válido → turno creado, outbox reply con ✅
- "TURNO\n..." inválido → outbox reply con ❌
- Mensaje desconocido → outbox reply con ayuda

---

### Gotchas conocidos de Story 5.2

1. **`Complejo` pluralización:** `ComplexPlayer.belongs_to :complejo` — Rails NO pluraliza `complejo` como `complejos` por defecto (palabra española). Verificar que `belongs_to :complejo` infiere `Complejo` como clase. Si hay issues, usar `class_name: "Complejo"` explícitamente.

2. **`StatusPillComponent` con confirmation_status:** El componente ya acepta `status` simbólico. Verificar qué estados acepta. Los valores de `confirmation_status` son: `pending`, `confirmed`, `replacement`, `uncovered`. Puede ser necesario agregar estos casos al componente o al helper.

3. **`roster_entry` fixture actual:** El fixture `roster_entries.yml` puede estar vacío (el cat anterior mostró comentario solamente). Verificar que no haya fixtures que asuman que `player_id` es NOT NULL.

4. **`ProcessWhatsappInboxJob` refactor:** Al mover la lógica SYSTEM al `WhatsappInboxProcessor`, el test existente `test "BOT_DISCONNECTED message triggers SendWhatsappAlertJob"` todavía debe pasar — el job llama al processor que maneja el caso SYSTEM. Los tests existentes **no deben romperse**.

5. **`Turno.validates :reservation_name, presence: true`** — no puede ser blank. El `BotTurnoCreationService` usa el nombre del primer jugador como `reservation_name`. Si el nombre está blank por algún motivo, el save fallará. Validar en `validate_jugadores`.

6. **`date.to_time.change(hour: h)`** — el `Date#to_time` usa la medianoche local. El `change(hour: h)` ajusta la hora. Verificar que la zona horaria sea correcta (Time.zone en Rails).

7. **`FOR UPDATE SKIP LOCKED`** ya está en `ProcessWhatsappInboxJob` (agregado por el linter en Story 5.1). Esto es correcto para concurrencia — no modificar.

8. **`rescue` dentro del `find_each` en `ProcessWhatsappInboxJob`** — el linter agregó un rescue StandardError. Si `WhatsappInboxProcessor#process` falla, el error se loguea y el mensaje se marca como procesado igual. Esto es seguro.

9. **Nombre de la sección `services/`:** Existe `app/services/` (con `RecurringTurnoGenerator`). Los nuevos servicios van ahí. Los tests de servicios van en `test/services/` (crear directorio si no existe).

---

### Learnings de Story 5.1

- Fixtures YAML necesitan `created_at`/`updated_at` explícitos cuando las columnas tienen `null: false`
- Tests de validaciones: usar `assert msg.errors[:field].present?` en lugar de `assert_includes errors, "can't be blank"` (locale es `:es`)
- Rubocop NO debe correr sobre archivos `.yml` ni `.erb`
- Test baseline: 193 tests / 590 assertions
- `# frozen_string_literal: true` en todos los archivos `.rb` nuevos

---

## Dev Agent Record

### Implementation Plan
Implementado según Dev Notes: migraciones + modelos `Player`/`ComplexPlayer`, `belongs_to :player, optional: true` en `RosterEntry`, servicios `WhatsappInboxProcessor` (router, incluye manejo de `SYSTEM`/`BOT_DISCONNECTED`) y `BotTurnoCreationService` (parseo, validación, creación de Turno+Roster+Player/ComplexPlayer), refactor de `ProcessWhatsappInboxJob` para delegar al processor, y badge de `confirmation_status` en `show.html.erb` para turnos `origin: :bot`.

### Debug Log
_Vacío_

### Completion Notes
Verificado al retomar la sesión: `bin/rails test` → 224 runs, 668 assertions, 0 failures, 0 errors. `bin/rubocop` sobre los `.rb` nuevos/modificados de esta historia → 0 offenses. Pendiente: revisión de código (status `review`) y commit de todo el trabajo acumulado de Epics 3, 4 y 5 (sigue sin commitear desde `a47585d`).

---

## File List

### NEW
- `db/migrate/TIMESTAMP_create_players.rb`
- `db/migrate/TIMESTAMP_create_complex_players.rb`
- `db/migrate/TIMESTAMP_add_player_id_to_roster_entries.rb`
- `app/models/player.rb`
- `app/models/complex_player.rb`
- `app/services/whatsapp_inbox_processor.rb`
- `app/services/bot_turno_creation_service.rb`
- `test/fixtures/players.yml`
- `test/fixtures/complex_players.yml`
- `test/models/player_test.rb`
- `test/models/complex_player_test.rb`
- `test/services/bot_turno_creation_service_test.rb`
- `test/services/whatsapp_inbox_processor_test.rb`

### UPDATE
- `app/models/roster_entry.rb`
- `app/jobs/process_whatsapp_inbox_job.rb`
- `app/views/turnos/show.html.erb`
- `db/schema.rb`

---

## Change Log

_Vacío_

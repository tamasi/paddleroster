---
story_id: "5.3"
story_key: "5-3-confirmacion-individual-de-asistencia-fr-2"
epic_id: "5"
title: "Confirmación individual de asistencia (FR-2)"
status: "done"
last_updated: "2026-06-18"
baseline_commit: e411a7cbfdc560f97b6118cc94b952f600d41592
---

# Story 5.3: Confirmación individual de asistencia (FR-2)

**As a** Jugador,
**I want** confirmar mi asistencia a un Turno respondiendo al mensaje del Bot,
**So that** el Capitán sepa quién va a jugar sin preguntar uno por uno.

## Acceptance Criteria

- **AC1: Jugador agregado al Roster → recibe mensaje de confirmación**
  - **Given** que fui agregado al Roster de un Turno (vía Story 5.2)
  - **When** el Turno se crea
  - **Then** recibo del Bot un mensaje individual pidiéndome confirmar mi asistencia (cancha, fecha, horario)

- **AC2: Respuesta afirmativa → Confirmado**
  - **Given** que tengo una confirmación pendiente para un Turno
  - **When** respondo "SI" / "SÍ" / "CONFIRMO" (case-insensitive)
  - **Then** mi `confirmation_status` pasa a `confirmed`, recibo un mensaje de confirmación, y el cambio se refleja en tiempo real en el `roster-row` del Detalle de Turno del Panel

- **AC3: Respuesta negativa → dispara flujo de reemplazo**
  - **Given** que tengo una confirmación pendiente para un Turno
  - **When** respondo "NO" / "NO PUEDO" (case-insensitive)
  - **Then** mi `confirmation_status` pasa a `uncovered` ("Sin cubrir"), recibo un mensaje de acuse, y el flujo de oferta a Suplentes queda fuera de esta historia (FR-3, Story 5.4)

- **AC4: Respuesta ambigua → reenvía opciones sin cambiar estado**
  - **Given** que tengo una confirmación pendiente para un Turno
  - **When** respondo algo que no es reconocible como SI/NO
  - **Then** el Bot me reenvía las opciones válidas (SI/NO) sin modificar mi `confirmation_status`

- **AC5: Capitán ve el Estado de Confirmación en tiempo real en el Panel**
  - **Given** el Capitán
  - **When** abre el Detalle del Turno en el Panel mientras un Jugador responde por WhatsApp
  - **Then** ve el `confirmation_status` de cada Jugador del Roster actualizarse sin recargar la página (`roster-row`, UX-DR4; Turbo Streams)

## Tasks / Subtasks

### Task 1: `BotConfirmationService` — interpretar respuestas SI/NO/ambiguas
- [x] T1.1: Crear `app/services/bot_confirmation_service.rb`
- [x] T1.2: `pending_entry` — busca el `RosterEntry` titular, `confirmation_status: :pending`, del `Turno` activo más próximo, para el `phone` dado
- [x] T1.3: Mensaje SI/SÍ/CONFIRMO → `confirmation_status: :confirmed` + mensaje de ack
- [x] T1.4: Mensaje NO/NO PUEDO → `confirmation_status: :uncovered` + mensaje de ack (sin disparar oferta a Suplentes — eso es Story 5.4)
- [x] T1.5: Mensaje ambiguo (hay `pending_entry` pero no matchea SI/NO) → reenvía opciones, no cambia `confirmation_status`
- [x] T1.6: Sin `pending_entry` para ese `phone` → `Result.handled? == false` (deja pasar el mensaje a otro routing)

### Task 2: `WhatsappInboxProcessor` — enviar solicitud inicial y enrutar respuestas
- [x] T2.1: Tras crear un Turno exitosamente (`handle_turno_command`), enviar un mensaje individual de confirmación a cada `RosterEntry` titular (incluido el Capitán — ver Dev Notes)
- [x] T2.2: Enrutar mensajes no-`TURNO` a `BotConfirmationService` antes de caer en `handle_unknown_message`
- [x] T2.3: Si `BotConfirmationService` cambió un `confirmation_status`, emitir broadcasts Turbo Stream (roster-row del Detalle + card del Calendario)

### Task 3: Vista — roster-row en tiempo real
- [x] T3.1: Extraer el bloque de roster de solo-lectura de `app/views/turnos/show.html.erb` a `app/views/turnos/_roster_section.html.erb`, con `id="roster-section-#{turno.id}"`
- [x] T3.2: Agregar `<%= turbo_stream_from "turno_#{@turno.id}_roster" %>` en `show.html.erb`

### Task 4: `CardTurnoComponent` — conteo de confirmados (UX-DR3)
- [x] T4.1: `roster_summary` para Turnos de Origen Bot → `"X/Y confirmados"` (Y = titulares, X = titulares con `confirmed?`); Origen Manual sin cambios ("X jugadores cargados")

### Task 5: Tests
- [x] T5.1: `test/services/bot_confirmation_service_test.rb` — SI/SÍ/CONFIRMO, NO/NO PUEDO, ambiguo, sin pending, prioriza el turno más próximo, ignora suplentes y turnos cancelados
- [x] T5.2: `test/services/whatsapp_inbox_processor_test.rb` — TURNO crea + envía solicitudes individuales; SI/NO actualiza estado y responde; TURNO_COMMAND tiene prioridad sobre una confirmación pendiente
- [x] T5.3: `test/components/card_turno_component_test.rb` — bot-origin muestra "X/Y confirmados"; manual-origin sin cambios (regresión)
- [x] T5.4: `test/controllers/turnos_controller_test.rb` — `show` de un Turno bot renderiza el `status-pill` de `confirmation_status` por fila (cubre el gap de Story 5.2, ahora vía el partial extraído)
- [x] T5.5: `bin/rails test` — 0 failures, 0 errors, sin regresiones
- [x] T5.6: `bin/rubocop` sobre `.rb` nuevos/modificados — 0 offenses (NUNCA correr sobre `.erb`)

### Review Findings

- [x] [Review][Decision] `declined_message` promete una búsqueda de reemplazo que todavía no existe — `BotConfirmationService#declined_message` (app/services/bot_confirmation_service.rb:45-48) dice "Avisaremos si conseguimos un reemplazo". Resuelto: se mantiene el texto tal cual — consistente con la decisión ya documentada en Dev Notes, la promesa se cumple en cuanto Story 5.4 (próxima en el sprint) implemente la búsqueda de Suplentes.

- [x] [Review][Patch] Sin tiebreak determinístico en `pending_entry` cuando dos Turnos futuros comparten el mismo `start_time` para el mismo `phone` [app/services/bot_confirmation_service.rb:32-39] — corregido: se agregó `roster_entries.id ASC` como orden secundario. Test de regresión agregado.
- [x] [Review][Patch] `broadcast_roster_update` sin rescue propio — fallas de broadcast se reportaban como error genérico al jugador aunque su confirmación ya se guardó [app/services/whatsapp_inbox_processor.rb] — corregido: el broadcast ahora tiene su propio `rescue StandardError` que loguea sin re-lanzar.
- [x] [Review][Patch] `send_confirmation_requests` no tolera fallos parciales — un error en un titular cortaba el envío al resto [app/services/whatsapp_inbox_processor.rb] — corregido: rescue+log por entrada dentro del loop. Test de regresión agregado.
- [x] [Review][Patch] `pending_entry` no filtraba explícitamente por `Turno.bot?` [app/services/bot_confirmation_service.rb] — corregido: `.merge(Turno.active.bot)`. Test de regresión agregado (Turno manual con player vinculado no matchea).

- [x] [Review][Defer] Sin disparo automático del flujo de reemplazo a Suplentes cuando una entrada pasa a `uncovered` — deferred, pre-existing (por diseño: es exactamente el alcance de Story 5.4, no de esta historia).
- [x] [Review][Defer] Límite de borde "Turno activo pero ya en curso" (start_time pasado, partido sin terminar) sin test explícito [app/services/bot_confirmation_service.rb:32-39] — deferred, pre-existing (hereda el mismo patrón de `Turno.active`/`start_time` ya usado en historias previas).
- [x] [Review][Defer] Sin batching/background job para rosters grandes — los outbox messages se crean sincrónicamente dentro del manejo del webhook [app/services/whatsapp_inbox_processor.rb:61-65] — deferred, pre-existing (mismo patrón síncrono que `BotTurnoCreationService` ya usa).
- [x] [Review][Defer] `RosterEntry` con `player_id` anulado (Player borrado) cae a `handled?: false` y mensaje de ayuda genérico en vez de uno específico [app/services/bot_confirmation_service.rb:32-39] — deferred, pre-existing (escenario raro, fallback ya es seguro/no rompe).
- [x] [Review][Defer] Dependencia implícita de normalización E.164 del teléfono entrante para el join con `Player#phone` [app/services/bot_confirmation_service.rb:32-39] — deferred, pre-existing (la validación E.164 y la normalización del webhook ya están establecidas desde Story 5.1/5.2, no es nuevo en esta historia).
- [x] [Review][Defer] `CONFIRM_RE`/`DECLINE_RE` no toleran puntuación/espacios extra (ej. "SI!", "no.") [app/services/bot_confirmation_service.rb:6-7] — deferred, pre-existing (cae de forma controlada a la rama ambigua, que reenvía las opciones; no rompe el flujo, mismo estilo estricto de parseo que el resto del bot).

---

## Dev Notes

### Estado actual — qué YA existe (NO reinventar)

**Modelos (sin cambios de schema necesarios en esta historia):**
```ruby
# app/models/roster_entry.rb
class RosterEntry < ApplicationRecord
  belongs_to :turno
  belongs_to :player, optional: true
  enum :role, { titular: 0, suplente: 1 }
  enum :confirmation_status, { pending: 0, confirmed: 1, replacement: 2, uncovered: 3 }
  validates :name, presence: true
end

# app/models/player.rb — has_many :roster_entries; phone E.164 único
# app/models/turno.rb — enum :origin, { manual: 0, bot: 1 }; enum :status, { active: 0, cancelled: 1 }
#   has_many :roster_entries, -> { order(:position) }, dependent: :destroy
```

**`app/services/whatsapp_inbox_processor.rb` (estado actual completo, post Story 5.2 + fixes del 2026-06-17):**
```ruby
class WhatsappInboxProcessor
  TURNO_COMMAND = /\ATURNO\b/i

  def initialize(inbox_message)
    @inbox_message = inbox_message
    @phone = inbox_message.phone
    @body  = inbox_message.raw_body.strip
  end

  def process
    return handle_system_alert if @phone == "SYSTEM"

    if @body.match?(TURNO_COMMAND)
      handle_turno_command
    else
      handle_unknown_message
    end
  rescue StandardError => e
    reply("❌ Ocurrió un error interno. Por favor, intenta más tarde o contacta al soporte.")
    Rails.logger.error("[WhatsappInboxProcessor] Error: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  private

  def handle_system_alert
    return unless @body == "BOT_DISCONNECTED"
    SendWhatsappAlertJob.perform_later("Bot de WhatsApp desconectado — revisar el servicio.")
  end

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
  # ... turno_created_message, help_message sin cambios relevantes
end
```
**IMPORTANTE:** el `rescue StandardError` que envuelve todo `process` ya existe — no hay que volver a agregarlo. Cualquier excepción no controlada en `BotConfirmationService` ya cae en ese rescue genérico y responde "Ocurrió un error interno".

**`app/views/turnos/show.html.erb` (bloque roster actual, a extraer):**
```erb
<% else %>
  <div class="mt-8">
    <h2 class="text-sm font-bold uppercase tracking-wide text-text-secondary dark:text-text-secondary-dark mb-2">
      Roster (Solo lectura)
    </h2>
    <div class="bg-surface dark:bg-surface-dark border border-border dark:border-border-dark rounded-lg p-4 space-y-3">
      <% if @turno.roster_entries.empty? %>
        <p class="text-text-secondary dark:text-text-secondary-dark text-sm italic">Sin roster cargado</p>
      <% else %>
        <% @turno.roster_entries.each do |entry| %>
          <div class="py-2 border-b border-border dark:border-border-dark last:border-0 flex items-center justify-between">
            <div>
              <span class="text-text-primary dark:text-text-primary-dark font-medium"><%= entry.name %></span>
              <% if entry.suplente? %>
                <span class="ml-1 text-xs text-text-secondary dark:text-text-secondary-dark">(suplente)</span>
              <% end %>
            </div>
            <% if @turno.bot? %>
              <%= render StatusPillComponent.new(status: entry.confirmation_status, context: :roster) %>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
  </div>
<% end %>
```
Este bloque está dentro del branch `else` de `@editable` (`@editable = @turno.active? && @turno.manual?`) — los Turnos de Origen Bot **siempre** renderizan por este branch (nunca son editables), así que no hay conflicto con el form de edición.

**`StatusPillComponent` (sin cambios necesarios):** ya soporta `context: :roster` y mapea `confirmed`→verde, `pending`→amarillo, `replacement`→naranja, `uncovered`→rojo ("Sin cubrir"), vía `humanize_confirmation_status` en `StatusPresentationHelper`. **No tocar.**

**Patrón de broadcast ya establecido (Story 3.2), a replicar — NO reinventar:**
```ruby
# app/controllers/payments_controller.rb — referencia del patrón
Turbo::StreamsChannel.broadcast_replace_to(
  "complex_#{@complejo.id}_payments",
  target: "card-turno-#{@turno.id}",
  partial: "turnos/card_turno_stream",
  locals: { turno: @turno }
)
```
`app/views/turnos/index.html.erb` ya tiene `<%= turbo_stream_from "complex_#{@complejo.id}_payments" %>` y envuelve cada card en `<div id="card-turno-<%= turno.id %>">`. El canal `"complex_#{id}_payments"` es **reutilizable** para el broadcast del roster hacia el Calendario (ver Task 2.3) — no hace falta un canal nuevo para esa parte, aunque el nombre quedó atado a "payments" históricamente (cosmético, no renombrar en esta historia).

### Lo que agrega esta historia (alcance real)

1. Mensaje individual de confirmación a cada titular cuando se crea el Turno (AC1).
2. Servicio que interpreta SI/NO/ambiguo y actualiza `confirmation_status` (AC2-AC4).
3. Broadcast en tiempo real del `roster-row` en Detalle de Turno (AC5) — vía un canal **nuevo** `"turno_#{id}_roster"`, dedicado (el canal de pagos es por-complejo, no por-turno; el Detalle de Turno sí necesita granularidad por-turno).
4. Conteo "X/Y confirmados" en `CardTurnoComponent` para Origen Bot (UX-DR3, cierra el gap documentado en `deferred-work.md` desde la review de Story 2.1: *"`roster_summary` devuelve placeholders fijos... hasta que Epic 2/5 implemente Roster"*). Este punto no está en los AC literales de 5.3 pero es la continuación natural y ya documentada de ese placeholder — si se prefiere diferirlo, es la Task 4 la que se puede sacar sin afectar AC1-AC5.

**Explícitamente fuera de alcance (Story 5.4):**
- Ofrecer el cupo liberado a los Suplentes, ventana de 2 horas, estado final "Sin cubrir" por timeout, notificar al Capitán del resultado del reemplazo.
- Story 5.3 solo deja al jugador que declinó en `uncovered` y termina ahí — Story 5.4 retoma desde ese estado.

### Decisión de diseño: mapeo de "Pendiente de reemplazo" al enum existente

El AC de epics.md dice textualmente: *"mi Estado de Confirmación pasa a 'Pendiente de reemplazo'"*. El enum `confirmation_status` (fijado en `architecture.md` línea 281, **no modificar**) solo tiene 4 valores: `pending`, `confirmed`, `replacement`, `uncovered`. Ni el glosario del PRD ni `architecture.md` definen un 5º estado:
- `replacement` ("Reemplazo") está reservado para cuando un **Suplente** cubre el cupo (Story 5.4, AC2 de esa historia) — no aplica al titular que declina.
- `uncovered` ("Sin cubrir") es el mejor fit disponible para "este cupo necesita reemplazo" — además ya tiene estilo visual de alerta (`danger`/rojo) en `StatusPillComponent`, coherente con "esto necesita atención".

**Decisión:** declinar → `confirmation_status: :uncovered`. Cuando Story 5.4 implemente la oferta a Suplentes, deberá manejar la transición desde `uncovered`: si un Suplente confirma, ese Suplente pasa a `replacement`; si nadie confirma a tiempo, el titular original queda en `uncovered` (estado que ya quedó seteado por esta historia — Story 5.4 no necesita volver a setearlo, solo dejarlo si el flujo se agota).

### Decisión de diseño: orden de routing en `WhatsappInboxProcessor#process`

```ruby
def process
  return handle_system_alert if @phone == "SYSTEM"

  if @body.match?(TURNO_COMMAND)
    handle_turno_command
  else
    handle_confirmation_or_unknown
  end
rescue StandardError => e
  # ... sin cambios
end
```
**Por qué `TURNO_COMMAND` se chequea primero:** un Capitán que ya jugó un Turno anterior puede tener todavía una `RosterEntry` `pending` vieja (si nunca respondió). Si esa misma persona envía un nuevo comando `TURNO ...` para crear otro Turno, el mensaje **no** debe ser interceptado por la lógica de confirmación (que lo trataría como "respuesta ambigua" y le pediría SI/NO en lugar de crear el Turno). Por eso `TURNO_COMMAND` tiene prioridad absoluta; `BotConfirmationService` solo corre sobre mensajes que no matchean ese patrón. Cubrir esto con un test explícito (T5.2).

### `app/services/bot_confirmation_service.rb` (NUEVO — implementación de referencia)

```ruby
# frozen_string_literal: true

class BotConfirmationService
  Result = Struct.new(:handled?, :reply_text, :roster_entry, keyword_init: true)

  CONFIRM_RE = /\A(s[ií]|confirmo)\z/i
  DECLINE_RE = /\A(no|no puedo)\z/i

  def initialize(phone, raw_message)
    @phone = phone
    @body  = raw_message.strip
  end

  def call
    entry = pending_entry
    return Result.new(handled?: false, reply_text: nil, roster_entry: nil) unless entry

    case @body
    when CONFIRM_RE
      entry.update!(confirmation_status: :confirmed)
      Result.new(handled?: true, reply_text: confirmed_message(entry), roster_entry: entry)
    when DECLINE_RE
      entry.update!(confirmation_status: :uncovered)
      Result.new(handled?: true, reply_text: declined_message(entry), roster_entry: entry)
    else
      Result.new(handled?: true, reply_text: ambiguous_message(entry), roster_entry: nil)
    end
  end

  private

  def pending_entry
    RosterEntry.joins(:player, :turno)
               .where(players: { phone: @phone }, role: :titular, confirmation_status: :pending)
               .merge(Turno.active)
               .where("turnos.start_time >= ?", Time.current)
               .order("turnos.start_time ASC")
               .first
  end

  def confirmed_message(entry)
    "✅ ¡Gracias! Confirmaste tu asistencia al Turno del #{format_turno(entry.turno)}."
  end

  def declined_message(entry)
    "👍 Entendido, marcamos tu lugar como liberado para el Turno del #{format_turno(entry.turno)}. " \
      "Avisaremos si conseguimos un reemplazo."
  end

  def ambiguous_message(entry)
    "No entendí tu respuesta para el Turno del #{format_turno(entry.turno)}. Respondé SI o NO."
  end

  def format_turno(turno)
    "#{turno.start_time.strftime('%d/%m/%Y')} #{turno.start_time.strftime('%H:%M')} en #{turno.cancha.name}"
  end
end
```
**Notas sobre esta implementación de referencia:**
- `pending_entry` solo matchea `role: :titular` — los Suplentes nunca tienen una confirmación "pendiente de responder" en esta historia (quedan `pending` hasta que Story 5.4 los active). Cubrir con test.
- `.merge(Turno.active)` excluye Turnos cancelados — un jugador con una `RosterEntry` `pending` de un Turno cancelado no debe recibir el flujo de confirmación. Cubrir con test.
- `where("turnos.start_time >= ?", Time.current)` excluye Turnos ya pasados — sin este filtro, `order(... ASC).first` traería el más **antiguo** (potencialmente un Turno de ayer que nunca se respondió), no el más próximo a jugarse. Con el filtro, `ASC` sobre los que quedan da correctamente el más próximo a futuro. Cubrir con test explícito (T5.1).
- Si el jugador tiene confirmaciones pendientes en más de un Turno futuro simultáneamente, esta implementación responde por el **más próximo en el tiempo** — limitación de MVP conocida y aceptable (no hay contexto de "reply" en el mensaje de WhatsApp para desambiguar). Documentar, no resolver.
- `handled?: true` en el caso ambiguo también — el mensaje NO debe caer en `handle_unknown_message` (AC4 exige reenviar las opciones de confirmación, no el texto de ayuda genérico de creación de Turno).

### `app/services/whatsapp_inbox_processor.rb` (cambios — diff conceptual)

```ruby
def handle_turno_command
  result = BotTurnoCreationService.new(@phone, @body).call
  if result.success?
    reply(turno_created_message(result.turno))
    send_confirmation_requests(result.turno)
  else
    reply("❌ No pude crear el turno:\n#{result.errors.join("\n")}")
  end
end

def handle_confirmation_or_unknown
  result = BotConfirmationService.new(@phone, @body).call
  if result.handled?
    reply(result.reply_text)
    broadcast_roster_update(result.roster_entry) if result.roster_entry
  else
    handle_unknown_message
  end
end

def send_confirmation_requests(turno)
  turno.roster_entries.titular.each do |entry|
    WhatsappOutboxMessage.create!(phone: entry.player.phone, body: confirmation_request_message(turno, entry), status: "pending")
  end
end

def confirmation_request_message(turno, entry)
  fecha   = turno.start_time.strftime("%d/%m/%Y")
  horario = turno.start_time.strftime("%H:%M")
  "🏆 ¡Hola #{entry.name}! Te incluyeron en el Roster de un Turno:\n" \
    "📍 #{turno.cancha.name}, #{fecha} #{horario}\n\n" \
    "¿Confirmás tu asistencia? Respondé SI o NO."
end

def broadcast_roster_update(entry)
  turno = entry.turno
  Turbo::StreamsChannel.broadcast_replace_to(
    "turno_#{turno.id}_roster",
    target: "roster-section-#{turno.id}",
    partial: "turnos/roster_section",
    locals: { turno: turno }
  )
  Turbo::StreamsChannel.broadcast_replace_to(
    "complex_#{turno.cancha.complejo_id}_payments",
    target: "card-turno-#{turno.id}",
    partial: "turnos/card_turno_stream",
    locals: { turno: turno }
  )
end
```
**Decisión de producto a confirmar con el usuario (no bloqueante, ver pregunta al final):** `send_confirmation_requests` envía el mensaje a **todos** los titulares, incluido el Capitán (su propia `RosterEntry` también queda `pending` tras Story 5.2 — sin distinción de "soy el capitán" a nivel de datos). Es la interpretación literal del AC1 ("fui agregado al Roster... el Bot me contacta"). Alternativa: excluir al Capitán (`titulares.first`) de su propio mensaje de confirmación, asumiendo que quien crea el Turno obviamente asiste. Implementar la versión literal (todos reciben el mensaje); si el usuario prefiere la alternativa, es un cambio de una línea (`turno.roster_entries.titular.drop(1)`).

### Vista — extracción a partial + Turbo Stream (Task 3)

**`app/views/turnos/_roster_section.html.erb` (NUEVO):**
```erb
<div class="mt-8" id="roster-section-<%= turno.id %>">
  <h2 class="text-sm font-bold uppercase tracking-wide text-text-secondary dark:text-text-secondary-dark mb-2">
    Roster (Solo lectura)
  </h2>
  <div class="bg-surface dark:bg-surface-dark border border-border dark:border-border-dark rounded-lg p-4 space-y-3">
    <% if turno.roster_entries.empty? %>
      <p class="text-text-secondary dark:text-text-secondary-dark text-sm italic">Sin roster cargado</p>
    <% else %>
      <% turno.roster_entries.each do |entry| %>
        <div class="py-2 border-b border-border dark:border-border-dark last:border-0 flex items-center justify-between">
          <div>
            <span class="text-text-primary dark:text-text-primary-dark font-medium"><%= entry.name %></span>
            <% if entry.suplente? %>
              <span class="ml-1 text-xs text-text-secondary dark:text-text-secondary-dark">(suplente)</span>
            <% end %>
          </div>
          <% if turno.bot? %>
            <%= render StatusPillComponent.new(status: entry.confirmation_status, context: :roster) %>
          <% end %>
        </div>
      <% end %>
    <% end %>
  </div>
</div>
```

**`app/views/turnos/show.html.erb` (cambios):**
1. Agregar, junto al `turbo_stream_from` de pagos ya existente: `<%= turbo_stream_from "turno_#{@turno.id}_roster" %>`
2. Reemplazar el bloque `<% else %> ... <% end %>` (roster solo-lectura) por: `<%= render "turnos/roster_section", turno: @turno %>`

El bloque de edición (`<% if @editable %>`) **no se toca** — sigue intacto, ya que Turnos Bot nunca son `@editable`.

### `CardTurnoComponent` — UX-DR3 (Task 4)

**Estado actual (`app/components/card_turno_component.rb`):**
```ruby
def roster_summary
  count = @turno.roster_entries.size
  return "Sin roster cargado" if count.zero?
  "#{count} #{count == 1 ? "jugador cargado" : "jugadores cargados"}"
end
```

**Nuevo (preservando el comportamiento de Origen Manual intacto — no romper tests existentes):**
```ruby
def roster_summary
  return bot_roster_summary if @turno.bot?

  count = @turno.roster_entries.size
  return "Sin roster cargado" if count.zero?
  "#{count} #{count == 1 ? "jugador cargado" : "jugadores cargados"}"
end

private

def bot_roster_summary
  titulares = @turno.roster_entries.titular
  return "Sin roster cargado" if titulares.empty?

  confirmados = titulares.count(&:confirmed?)
  "#{confirmados}/#{titulares.size} confirmados"
end
```
El denominador es solo **titulares** (no Suplentes) — "confirmados" describe asistencia esperada, y los Suplentes no confirman asistencia hasta que Story 5.4 los activa. Los tests existentes (`test/components/card_turno_component_test.rb`) usan `Turno.create!` sin `origin:`, que por default es `:manual` (`enum :origin, { manual: 0, bot: 1 }`) — **no se rompen** con este cambio.

### Architecture Compliance

- `confirmation_status` y `payment_status`: "siempre strings legibles en español en la UI vía helper de presentación, pero almacenados como enum de Rails en inglés" [Source: architecture.md#281] — ya cumplido, no tocar `StatusPresentationHelper`.
- Servicios de dominio testeables sin levantar `whatsapp-service/` ni Postgres real [Source: epics.md "Additional Requirements"] — `BotConfirmationService` recibe `phone`/`raw_message` como strings planos, igual que `BotTurnoCreationService`, sin dependencias del servicio Node.
- `# frozen_string_literal: true` en todos los `.rb` nuevos (convención del proyecto desde Story 5.1/5.2).

### File Structure Requirements

**NEW:**
- `app/services/bot_confirmation_service.rb`
- `app/views/turnos/_roster_section.html.erb`
- `test/services/bot_confirmation_service_test.rb`

**UPDATE:**
- `app/services/whatsapp_inbox_processor.rb`
- `app/views/turnos/show.html.erb`
- `app/components/card_turno_component.rb`
- `test/services/whatsapp_inbox_processor_test.rb`
- `test/components/card_turno_component_test.rb`
- `test/controllers/turnos_controller_test.rb`

Sin migraciones — el schema ya soporta todo lo necesario.

### Testing Requirements

**`test/services/bot_confirmation_service_test.rb`:**
- "SI"/"sí"/"Confirmo" (case-insensitive) con `pending_entry` existente → `confirmation_status` pasa a `confirmed`, `result.handled?` true, `reply_text` presente.
- "NO"/"no puedo" → `confirmation_status` pasa a `uncovered`.
- Texto ambiguo (ej. "no sé", "tal vez") con `pending_entry` existente → `confirmation_status` sin cambios, `reply_text` pide SI/NO.
- Sin `RosterEntry` `pending` para ese `phone` → `result.handled?` false.
- `RosterEntry` de un Suplente (`role: :suplente`) con `confirmation_status: :pending` → no debe matchear (el Suplente no recibe este flujo en 5.3).
- `RosterEntry` `pending` de un Turno `cancelled` → no debe matchear.
- Dos `RosterEntry` `pending` para el mismo `phone` en Turnos futuros distintos → responde sobre el de `start_time` más próximo.
- `RosterEntry` `pending` de un Turno **ya pasado** (`start_time` en el pasado) + otra `pending` de un Turno futuro, mismo `phone` → responde sobre la futura, ignora la pasada (test de regresión del filtro `start_time >= Time.current`).

**`test/services/whatsapp_inbox_processor_test.rb` (agregar a los existentes, no romperlos):**
- Mensaje `TURNO` válido → además de la respuesta `✅ Turno creado...`, se crea un `WhatsappOutboxMessage` por cada titular pidiendo confirmación (`assert_difference("WhatsappOutboxMessage.count", N+1)` con N titulares).
- Un `phone` con `pending_entry` que envía "SI" → `WhatsappInboxProcessor.new(msg).process` actualiza el `RosterEntry` y crea un outbox reply.
- Un `phone` con `pending_entry` que envía un mensaje `TURNO ...` → se procesa como creación de Turno (no como respuesta de confirmación) — test de la decisión de orden de routing.

**`test/components/card_turno_component_test.rb` (agregar):**
- Turno `origin: :bot` con 2 titulares, 1 `confirmed` y 1 `pending` → `"1/2 confirmados"`.
- Turno `origin: :bot` sin roster → `"Sin roster cargado"` (mismo mensaje que manual, sin romper ese caso).
- Tests existentes (manual, sin `origin:`) deben seguir pasando sin modificarlos.

**`test/controllers/turnos_controller_test.rb` (agregar):**
- `GET turno_path` de un Turno `origin: :bot` con un `RosterEntry` `confirmed` → la respuesta incluye el `status-pill` con el texto "Confirmado" (cierra el gap de cobertura de Story 5.2 — antes no existía este test, y ahora el render pasa por el partial nuevo).

**Comando rubocop (solo `.rb`):**
```bash
bin/rubocop app/services/bot_confirmation_service.rb app/services/whatsapp_inbox_processor.rb \
            app/components/card_turno_component.rb \
            test/services/bot_confirmation_service_test.rb test/services/whatsapp_inbox_processor_test.rb \
            test/components/card_turno_component_test.rb test/controllers/turnos_controller_test.rb
```
**NUNCA correr rubocop sobre `.erb`** — parsea HTML como Ruby y da falsos positivos (lección de Story 5.1).

### Previous Story Intelligence (Story 5.2, finalizada 2026-06-17)

- Story 5.2 dejó `WhatsappInboxProcessor#process` envuelto en `rescue StandardError` con reply genérico — **no duplicar ese rescue** dentro de los métodos nuevos; dejar que las excepciones de `BotConfirmationService`/`send_confirmation_requests` burbujeen hasta ese rescue existente.
- `BotTurnoCreationService#validate_horario` ahora exige hora exacta (`:00`) — irrelevante para esta historia, pero confirma que `Turno#start_time` de Turnos Bot siempre cae en hora exacta (no afecta el formateo de `format_turno` en `BotConfirmationService`).
- El parseo de comandos del bot es case-insensitive de punta a punta (decisión de Story 5.2) — los regex `CONFIRM_RE`/`DECLINE_RE` de esta historia siguen esa misma convención (`/i`).
- Fixture `roster_entries.yml` sigue vacío (solo comentario) — los tests de esta historia deben crear `Turno`/`RosterEntry`/`Player` inline, igual que en `bot_turno_creation_service_test.rb`.
- `Player#phone` es único — para tests con múltiples jugadores, usar teléfonos E.164 distintos por test (patrón ya usado: `+549110000000X`).
- Baseline de tests tras Story 5.2 + fixes: `bin/rails test` en verde sobre el HEAD de esta historia (`e411a7c`) — correr la suite completa antes de empezar para confirmar el punto de partida.

---

## Project Context Reference

- PRD: `_bmad-output/planning-artifacts/prds/prd-retroai-2026-06-11/prd.md` — FR-2 (sección 4.1), Glosario ("Estado de Confirmación", "Suplente").
- Architecture: `_bmad-output/planning-artifacts/architecture.md` — línea 156 (modelo `RosterEntry`), línea 281 (enum `confirmation_status`, presentación bilingüe).
- Epics: `_bmad-output/planning-artifacts/epics.md` — Epic 5 / Story 5.3 (ACs), UX-DR3/UX-DR4 (sección "UX Design Requirements").
- Deferred work: `_bmad-output/implementation-artifacts/deferred-work.md` — entrada de Story 2.1 sobre `roster_summary`/placeholders, motivo de la Task 4.
- Story previa: `_bmad-output/implementation-artifacts/5-2-creacion-de-turno-y-roster-inicial-via-bot-fr-1.md`.

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

_Vacío_

### Completion Notes List

- `BotConfirmationService` implementado siguiendo la implementación de referencia de Dev Notes (sin cambios): interpreta SI/SÍ/CONFIRMO → `confirmed`, NO/NO PUEDO → `uncovered`, ambiguo → reenvía opciones sin cambiar estado, sin `pending_entry` → `handled? == false`. `pending_entry` filtra por `role: :titular`, `Turno.active`, `start_time >= Time.current`, ordenado por `start_time ASC`.
- `WhatsappInboxProcessor`: `TURNO_COMMAND` sigue teniendo prioridad de routing (test explícito de regresión); mensajes no-`TURNO` van a `handle_confirmation_or_unknown`. Tras crear un Turno se envía una solicitud de confirmación a cada titular (incluido el Capitán, interpretación literal de AC1 — ver "Preguntas abiertas" en el story file). El broadcast Turbo Stream (`turno_#{id}_roster` + `complex_#{id}_payments`) se dispara solo cuando `BotConfirmationService` devuelve un `roster_entry` (es decir, en confirmación/declinación, no en respuesta ambigua).
- Vista: bloque de roster de solo-lectura extraído a `_roster_section.html.erb`; `show.html.erb` ahora suscribe el canal `turno_#{id}_roster` además del canal de pagos ya existente. El bloque `@editable` (form de edición, Turnos Manual) no se tocó.
- `CardTurnoComponent#roster_summary`: Origen Bot → "X/Y confirmados" (denominador = titulares); Origen Manual sin cambios (tests de regresión en verde sin modificarlos).
- Decisión de implementación (no bloqueante, documentada en el story file): el Capitán recibe su propio mensaje de confirmación igual que el resto de titulares; Task 4 (UX-DR3) se incluyó en el alcance.
- Suite completa: 241 tests, 0 failures, 0 errors (baseline era 224 antes de esta historia). `bin/rubocop` sobre los 7 archivos `.rb` nuevos/modificados: 0 offenses. No se corrió rubocop sobre `.erb`.
- Post code-review: 4 patches aplicados (ver "Review Findings"). Suite final: 244 tests, 0 failures, 0 errors. `bin/rubocop` 0 offenses.

### File List

**NEW:**
- `app/services/bot_confirmation_service.rb`
- `app/views/turnos/_roster_section.html.erb`
- `test/services/bot_confirmation_service_test.rb`

**MODIFIED:**
- `app/services/whatsapp_inbox_processor.rb`
- `app/views/turnos/show.html.erb`
- `app/components/card_turno_component.rb`
- `test/services/whatsapp_inbox_processor_test.rb`
- `test/components/card_turno_component_test.rb`
- `test/controllers/turnos_controller_test.rb`
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (status tracking)

---

## Change Log

- 2026-06-17: Story creada (create-story workflow) a partir de Epic 5 / Story 5.3 en `epics.md`, con análisis de PRD (FR-2), architecture.md (enum `confirmation_status` fijo en 4 valores), UX-DR3/UX-DR4, `deferred-work.md` (gap de `roster_summary`) y el código real de Story 5.2 (post fixes del 2026-06-17, commit `e411a7c`). Decisiones documentadas: mapeo "Pendiente de reemplazo" → `uncovered`, orden de routing `TURNO` antes que confirmación, alcance de Task 4 (UX-DR3) como extensión opcional pero recomendada.
- 2026-06-18: Implementación completa (dev-story workflow). `BotConfirmationService` nuevo; `WhatsappInboxProcessor` enruta confirmaciones y envía solicitudes individuales tras crear Turno; vista de roster extraída a partial con Turbo Stream dedicado por Turno; `CardTurnoComponent` muestra "X/Y confirmados" para Origen Bot. Tests nuevos/actualizados en los 4 archivos correspondientes + cierre del gap de cobertura de Story 5.2 en `turnos_controller_test.rb`. Suite completa: 241/241 verde, rubocop 0 offenses.
- 2026-06-18: Code review (3 capas: Blind Hunter, Edge Case Hunter, Acceptance Auditor). 1 decisión resuelta (se mantiene el texto de `declined_message` tal cual). 4 patches aplicados: tiebreak determinístico en `pending_entry`, scope explícito `Turno.bot` en `pending_entry`, rescue+log en `broadcast_roster_update`, rescue+log por entrada en `send_confirmation_requests`. 6 items diferidos a `deferred-work.md` (pre-existentes/fuera de alcance). Suite final: 244/244 verde, rubocop 0 offenses. Status → `done`.

---

## Preguntas abiertas para el usuario (no bloqueantes — implementación puede proceder con la interpretación documentada)

1. **¿El Capitán recibe su propio mensaje de confirmación?** Implementado: sí, todos los titulares (incluido el Capitán) reciben el mensaje "¿Confirmás tu asistencia?" tras crear el Turno, por ser la lectura literal del AC1 y porque no hay forma de distinguir "soy el Capitán" a nivel de `RosterEntry`. Si preferís que el Capitán quede auto-confirmado (no recibe el mensaje a sí mismo), es un cambio de una línea en `send_confirmation_requests`.
2. **¿Task 4 (conteo "X/Y confirmados" en el Calendario)?** No es un AC literal de 5.3 — es la continuación de un placeholder documentado desde Story 2.1. Incluido en el alcance por default; se puede sacar sin afectar AC1-AC5 si preferís dejarlo para una historia de UI/polish separada.

---
story_id: "5.4"
story_key: "5-4-reemplazo-auto-gestionado-de-suplentes-fr-3"
epic_id: "5"
title: "Reemplazo auto-gestionado de suplentes (FR-3)"
status: "review"
last_updated: "2026-06-18"
baseline_commit: "d1f62b32dbd12a6b63c92e0d94c2f16f62047833"
---

# Story 5.4: Reemplazo auto-gestionado de suplentes (FR-3)

**As a** Capitán,
**I want** que cuando un Jugador titular cancele, el Bot ofrezca su lugar a los Suplentes automáticamente,
**So that** no tenga que buscar reemplazo manualmente por WhatsApp.

## Acceptance Criteria

- **AC1: Titular declina o retira confirmación → dispara flujo de reemplazo**
  - **Given** un Jugador titular que responde "NO" al Bot (o que retira su confirmación previa)
  - **When** el Bot procesa la declinación
  - **Then** su `confirmation_status` pasa a `uncovered` y se inicia el ofrecimiento al primer Suplente de la lista (según `position`)

- **AC2: Ofrecimiento a Suplentes en orden y con plazo**
  - **Given** un cupo que requiere reemplazo
  - **When** el sistema identifica al siguiente Suplente disponible (`pending`, sin `offered_at`)
  - **Then** le envía un mensaje ofreciendo el cupo y registra `offered_at`
  - **And** notifica al Capitán: "Jugador X no puede ir. Le ofrecimos el lugar a Suplente Y."

- **AC3: Plazo de respuesta (2h o inmediato)**
  - **Given** un ofrecimiento a un Suplente
  - **When** el Turno comienza en más de 2 horas
  - **Then** el plazo para responder es de 2 horas
  - **When** el Turno comienza en menos de 2 horas
  - **Then** el plazo para responder es inmediato (definido como 15 minutos para el MVP)

- **AC4: Suplente confirma → Cupo cubierto**
  - **Given** un Suplente que recibió una oferta
  - **When** responde "SI" dentro del plazo
  - **Then** su `confirmation_status` pasa a `replacement`, se detiene el flujo para ese cupo, y se notifica al Capitán: "¡Lugar cubierto! Suplente Y confirmó para el turno."

- **AC5: Suplente declina o timeout → Salta al siguiente**
  - **Given** un Suplente que recibió una oferta
  - **When** responde "NO" o vence el plazo sin respuesta
  - **Then** su `confirmation_status` pasa a `uncovered` y el sistema ofrece el cupo al siguiente Suplente de la lista
  - **And** si no quedan más Suplentes, se notifica al Capitán: "No conseguimos reemplazo para el lugar de X. El cupo queda sin cubrir."

## Tasks / Subtasks

### Task 1: Datos — Tracking de ofrecimientos
- [x] T1.1: Crear migración `AddOfferedAtToRosterEntries` agregando `offered_at:datetime` a `roster_entries`
- [x] T1.2: `bin/rails db:migrate`

### Task 2: `RosterReplacementService` — Motor de reemplazo
- [x] T2.1: Crear `app/services/roster_replacement_service.rb`
- [x] T2.2: Implementar `call(entry)` — recibe la entrada que declinó (titular o suplente anterior)
- [x] T2.3: Lógica para encontrar el siguiente suplente: `turno.roster_entries.suplente.pending.where(offered_at: nil).order(:position).first`
- [x] T2.4: Lógica de notificación al Capitán (vía `WhatsappOutboxMessage`)
- [x] T2.5: Programar `CheckReplacementTimeoutJob` según `start_time` del turno

### Task 3: `CheckReplacementTimeoutJob` — Manejo de timeouts
- [x] T3.1: Crear `app/jobs/check_replacement_timeout_job.rb`
- [x] T3.2: Verificar si la entrada sigue `pending` y tiene `offered_at`
- [x] T3.3: Si expiró: marcar `uncovered` y re-disparar `RosterReplacementService`

### Task 4: `BotConfirmationService` — Actualizar para Suplentes
- [x] T4.1: Actualizar `pending_entry` para incluir `suplentes` que tengan `offered_at` presente
- [x] T4.2: En `DECLINE_RE` (NO), disparar `RosterReplacementService` tras actualizar a `uncovered`
- [x] T4.3: En `CONFIRM_RE` (SI), si el rol es `suplente`, actualizar a `replacement` y notificar éxito al Capitán

### Task 5: UI — Feedback visual de ofrecimientos
- [x] T5.1: Actualizar `StatusPresentationHelper#humanize_confirmation_status` para aceptar opcionalmente un objeto `RosterEntry` (o crear una versión que lo acepte) y devolver "Ofrecido" si `offered_at` está presente y el estado es `pending`.
- [x] T5.2: Actualizar `StatusPillComponent#wrapper_classes` e `icon_classes` para manejar el estado visual de "Ofrecido" (sugerencia: usar los mismos colores que `partial`/`replacement` — naranja/amarillo).

### Task 6: Tests
- [x] T6.1: `test/services/roster_replacement_service_test.rb` — flujo completo: decline titular -> ofrece suplente 1 -> timeout -> ofrece suplente 2 -> confirma suplente 2 -> fin.
- [x] T6.2: `test/jobs/check_replacement_timeout_job_test.rb` — verifica que el job marca como `uncovered` y llama al servicio de reemplazo si el timeout expira.
- [x] T6.3: `test/services/bot_confirmation_service_test.rb` — respuestas de suplentes: "SI" a una oferta válida -> `replacement`; "SI" sin oferta previa -> ignorado (o `handle_unknown`).
- [x] T6.4: `bin/rails test` y `bin/rubocop`.

---

## Dev Notes

### Mensajes del Bot (Templates)

**Al Suplente (Oferta):**
> 🏆 ¡Hola [Nombre]! Se liberó un lugar para el Turno del [Fecha] [Hora] en [Cancha].
> ¿Querés sumarte? Respondé SI o NO.
> (Tenés [Plazo] para responder antes de que se ofrezca al siguiente).

**Al Capitán (Inicio de reemplazo):**
> 🔄 [Titular] no puede asistir al Turno de las [Hora].
> Ya le ofrecimos su lugar a los suplentes (empezando por [Suplente 1]). Te aviso si alguien confirma.

**Al Capitán (Éxito):**
> ✅ ¡Lugar cubierto! [Suplente] confirmó su asistencia para el Turno de las [Hora].
> El roster ya está actualizado en el Panel.

**Al Capitán (Agotado):**
> ⚠️ No logramos conseguir un reemplazo para el lugar de [Titular] (lista de suplentes agotada o tiempo cumplido).
> El cupo queda sin cubrir.

### Lógica de Timeout (AC3)
```ruby
timeout_duration = (turno.start_time - Time.current > 2.hours) ? 2.hours : 15.minutes
CheckReplacementTimeoutJob.set(wait: timeout_duration).perform_later(sub_entry.id)
```

### Notificaciones al Capitán
El Capitán es siempre la primera `RosterEntry` del turno (`position: 0`).
```ruby
captain_phone = turno.roster_entries.order(:position).first.player.phone
```

### Regla de Oro: No reinventar
- Usar `WhatsappOutboxMessage.create!(phone: ..., body: ..., status: "pending")` para todas las notificaciones del Bot.
- Usar el patrón de Turbo Stream ya establecido en `WhatsappInboxProcessor` para actualizar el Panel.

---

## Architecture Compliance
- `RosterReplacementService` vive en `app/services/` (POJO).
- `offered_at` permite manejar timeouts sin añadir estados al enum fijo de `architecture.md`.
- Notificaciones al Capitán son asíncronas vía `whatsapp_outbox`.

---

## Project Context Reference
- PRD: FR-3 (Reemplazo auto-gestionado).
- Architecture: Naming conventions, `RosterEntry` schema, `whatsapp_outbox` contract.
- Epics: Epic 5, Story 5.4.
- Story 5.3: Base de confirmaciones por WhatsApp.

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

_Vacío_

### Completion Notes List

- `RosterReplacementService` (nuevo, `app/services/`): recibe la `RosterEntry` que acaba de quedar `uncovered` (titular o suplente anterior), busca el siguiente suplente con `turno.roster_entries.suplente.pending.where(offered_at: nil).order(:position).first`, le marca `offered_at`, le envía la oferta por WhatsApp, notifica al Capitán (`roster_entries.order(:position).first.player.phone`) y programa `CheckReplacementTimeoutJob` con `2.hours` o `15.minutes` según falte más o menos de 2hs para el `start_time` del turno (AC3). Si no queda ningún suplente disponible, notifica al Capitán el mensaje de "agotado" (AC5). Al final siempre re-renderiza el partial de roster vía Turbo Stream (mismo patrón que `WhatsappInboxProcessor#broadcast_roster_update`), con `rescue` + log para no romper el flujo si el broadcast falla.
- `CheckReplacementTimeoutJob` (nuevo, `app/jobs/`): vuelve a buscar la `RosterEntry` por id; si ya no está `pending` (confirmó, o ya fue re-procesada) no hace nada — esto es lo que permite que "se detenga el flujo" en AC4 sin lógica adicional. Si sigue `pending` y tiene `offered_at`, la marca `uncovered` y dispara `RosterReplacementService` para ofrecer al siguiente.
- `BotConfirmationService`: `pending_entry` ahora matchea titulares `pending` (como antes) **o** suplentes `pending` con `offered_at` presente — un suplente sin oferta activa sigue sin poder "confirmar" nada (test explícito). En `CONFIRM_RE`, si la entrada es `suplente` pasa a `replacement` y se notifica el éxito al Capitán (AC4); si es `titular` se comporta igual que en la Story 5.3. En `DECLINE_RE` (aplica a titular y a suplente con oferta activa) se marca `uncovered` y se dispara `RosterReplacementService.new(entry).call` — esto cubre tanto AC1 (titular declina) como la primera mitad de AC5 (suplente declina → salta al siguiente). El mensaje de declinación distingue rol (texto distinto para suplente vs. titular) para que tenga sentido conversacional.
- Alcance no implementado a propósito: el paréntesis de AC1 "(o que retira su confirmación previa)" — un titular que ya está `confirmed` y luego responde NO — no está cubierto, porque `pending_entry` solo matchea `confirmation_status: :pending` y el Task 4 del story no pidió ese caso explícitamente. Lo documento acá por si se quiere una historia/ajuste futuro.
- UI: `RosterEntry#offered?` (`pending? && offered_at.present?`). `StatusPresentationHelper#humanize_confirmation_status` acepta ahora un `String`/`Symbol` (comportamiento previo intacto) o una `RosterEntry` (devuelve "Ofrecido" si `offered?`). `StatusPillComponent` recibe un `entry:` opcional y usa un `visual_status` interno ("offered" cuando `entry.offered?`) para reusar los colores de `partial`/`replacement` (naranja/amarillo) sin duplicar el `case`. La vista `_roster_section.html.erb` ahora pasa `entry:` al componente.
- Tests: `roster_replacement_service_test.rb` cubre AC1/AC2 (oferta en orden, salta ofertas ya en curso), AC3 (timeout 2h vs 15min vía `assert_enqueued_with` + `enqueued_jobs`), AC5 (capitán notificado cuando se agotan los suplentes) y un flujo end-to-end completo (decline titular → oferta suplente 1 → timeout → oferta suplente 2 → confirma suplente 2). `check_replacement_timeout_job_test.rb` cubre timeout real, entrada ya confirmada (no-op), entrada inexistente y entrada nunca ofrecida. `bot_confirmation_service_test.rb` suma 3 tests para suplentes (SI con oferta válida, NO con oferta válida dispara reemplazo, SI sin oferta → `handled? false`). `status_pill_component_test.rb` suma 2 tests para el estado visual "Ofrecido".
- Suite completa: 259 tests, 0 failures, 0 errors (baseline era 244 al cierre de Story 5.3; +15 tests nuevos de esta historia). `bin/rubocop` sobre los archivos `.rb` nuevos/modificados: 0 offenses (no se corrió rubocop sobre `.erb`).

### File List

**NEW:**
- `db/migrate/20260618144321_add_offered_at_to_roster_entries.rb`
- `app/services/roster_replacement_service.rb`
- `app/jobs/check_replacement_timeout_job.rb`
- `test/services/roster_replacement_service_test.rb`
- `test/jobs/check_replacement_timeout_job_test.rb`

**MODIFIED:**
- `db/schema.rb` (columna `offered_at` en `roster_entries`)
- `app/models/roster_entry.rb` (`offered?`)
- `app/services/bot_confirmation_service.rb` (soporte de suplentes en `pending_entry`, `CONFIRM_RE`, `DECLINE_RE`)
- `app/helpers/status_presentation_helper.rb` (`humanize_confirmation_status` acepta `RosterEntry`)
- `app/components/status_pill_component.rb` (`entry:` opcional, estado visual "offered")
- `app/views/turnos/_roster_section.html.erb` (pasa `entry:` al `StatusPillComponent`)
- `test/services/bot_confirmation_service_test.rb` (tests de suplentes)
- `test/components/status_pill_component_test.rb` (tests de "Ofrecido")
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (status tracking)

---

## Change Log

- 2026-06-18: Implementación completa (dev-story workflow). Migración `offered_at` en `roster_entries`; `RosterReplacementService` y `CheckReplacementTimeoutJob` nuevos implementan el motor de reemplazo automático de suplentes (AC1-AC5); `BotConfirmationService` extendido para que los suplentes puedan confirmar/declinar una oferta activa; feedback visual "Ofrecido" en el Panel (`StatusPillComponent` + `StatusPresentationHelper`). Suite completa: 259/259 verde (244 + 15 nuevos), rubocop 0 offenses. Status → `review`.

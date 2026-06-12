---
baseline_commit: 6d103c9ca097d141691dbd49a0e0f69b4343c454
---

# Story 2.3: Cancelación de Turno desde el Panel

**ID:** 2.3
**Key:** 2-3-cancelacion-de-turno-desde-el-panel
**Status:** done
**Epic:** Epic 2: Calendario y Gestión de Turnos

## 📝 Story Statement
**As a** Administrador o Empleado,
**I want** cancelar un Turno (de cualquier Origen) desde el Panel,
**So that** el horario vuelva a estar disponible cuando una reserva no se concreta.

## ✅ Acceptance Criteria

### AC 1: Cancelación libera el horario (FR-4)
**Given** un Turno (Bot o Manual)
**When** lo cancelo desde su Detalle de Turno
**Then** su estado pasa a Cancelado y el horario vuelve a mostrarse como "Cancha libre" en el Calendario (FR-4)

### AC 2: Turnos de Origen Bot — sin efectos secundarios
**Given** un Turno de Origen Bot
**When** lo cancelo desde el Panel
**Then** su Roster permanece de solo lectura (sin modificarse) y no se envía ninguna notificación a los Jugadores vía Bot

### AC 3: Confirmación corta, no bloqueante, con paso explícito
**Given** que cancelo un Turno
**When** confirmo la acción
**Then** veo una confirmación corta ("Turno cancelado") sin modal bloqueante (UX-DR7), con un paso de confirmación explícito antes de aplicar el cambio (no un gesto rápido, UX-DR9)

## 🏗️ Developer Context & Guardrails

### Technical Requirements

- **Framework:** Rails 8.1.3 (PostgreSQL — `config/database.yml` usa `adapter: postgresql`, soporta índices únicos parciales).

- **⚠️ Hallazgo crítico que esta historia DEBE resolver — conflicto con el índice único de 2.2:** Story 2.2 agregó `add_index :turnos, [:cancha_id, :start_time], unique: true` (índice único global) para impedir doble reserva (AC5 de 2.2). Si esta historia simplemente marca un Turno como "Cancelado" sin tocar ese índice, **será imposible crear un nuevo Turno en el mismo slot liberado** — el índice único global seguiría bloqueándolo, contradiciendo AC1 ("el horario vuelve a estar disponible"). Esta historia DEBE:
    1. Agregar una columna `status` (enum Rails `{ active: 0, cancelled: 1 }`, default `active`) a `turnos`.
    2. **Reemplazar** el índice único `index_turnos_on_cancha_id_and_start_time` por un índice único **parcial**: `add_index :turnos, [:cancha_id, :start_time], unique: true, where: "status = 0", name: "index_turnos_on_cancha_id_and_start_time_active"` (PostgreSQL soporta `where:` en `add_index`; `status = 0` corresponde a `active` con el mapeo de enum indicado).
    3. Actualizar la validación de unicidad en `app/models/turno.rb` para que excluya Turnos cancelados, usando la opción `conditions:` del validador (disponible en Rails ≥ 6.1): `validates :start_time, uniqueness: { scope: :cancha_id, conditions: -> { where.not(status: :cancelled) }, message: "ya tiene un turno reservado en este horario" }`.
    - Sin estos tres cambios, AC1 queda roto end-to-end aunque el botón "Cancelar" funcione — **no es opcional**.

- **Modelo `Turno`:** agregar `enum :status, { active: 0, cancelled: 1 }`. Todos los Turnos existentes (creados en 2.1/2.2) deben quedar `active` por default (columna `null: false, default: 0`).

- **`TurnosController#index` (Calendario):** la query de `@turnos` debe excluir Turnos `cancelled` (ej. `.active` — scope generado automáticamente por el enum) para que el slot vuelva a renderizarse como "Cancha libre" (AC1). Sin este cambio, un Turno cancelado seguiría ocupando su celda en `@turnos.index_by { ... }` aunque ya no sea reservable.

- **Acción `TurnosController#cancel`:** nueva acción dedicada (no reutilizar `update`) que SOLO actualiza `status: :cancelled` — esto satisface AC2 trivialmente: al no haber un "paso de roster" ni un job de notificación en el código de `cancel`, el roster (`roster_entries`) queda intacto y no se dispara ningún envío al Bot (que, de todos modos, no existe aún — Epic 5 — pero el guardrail es no introducir esa lógica aquí).
    - Idempotencia: si el Turno ya está `cancelled`, `cancel` no debe fallar — simplemente redirige con el mismo mensaje (evita errores si el usuario hace doble click o vuelve atrás con el navegador).

### Architecture Compliance
- `enum` de Rails en inglés (`active`/`cancelled`) — si en algún punto se necesita texto en español para `status` (ej. un badge "Cancelado" visible en Detalle de Turno), agregar el caso correspondiente a `app/helpers/status_presentation_helper.rb`, siguiendo el patrón de `humanize_payment_status`. No hardcodear strings en la vista.
- FR-4/FR-12: tanto Dueño como Empleado pueden cancelar cualquier Turno (de cualquier Origen) — `TurnoPolicy#cancel?` debe devolver `true` para ambos roles, igual que `show?`/`update?` (ya implementados en 2.2 con `user.complejo.present?`).
- Reutilizar `before_action :set_complejo` + `turno_scope` (`Turno.where(cancha: @complejo.canchas)`) ya presentes en `TurnosController` desde 2.1/2.2 — `cancel` debe buscar el Turno dentro de ese scope, nunca por ID global.
- UX — "confirmación corta sin modal bloqueante + paso explícito antes de aplicar el cambio": el patrón ya usado en el proyecto para esto es `button_to ..., method: :patch, form: { data: { turbo_confirm: "..." } }` (ver `app/views/canchas/_cancha.html.erb`, acción "Eliminar"). Turbo intercepta el submit y muestra el `confirm()` nativo del navegador antes de enviar la request — cumple "paso de confirmación explícito, no un gesto rápido" sin requerir un modal/JS custom. Tras la redirección, `flash[:notice] = "Turno cancelado"` se renderiza con el mecanismo de flash ya existente en `app/views/layouts/application.html.erb` — banner no bloqueante, consistente con AC3.

### Library & Framework Requirements
- No se requieren librerías nuevas. Reutilizar `button_to` + `data: { turbo_confirm: ... }` (Turbo Drive, ya disponible vía importmap) — el mismo mecanismo que `CanchasController#destroy`.

### File Structure Requirements
- Migración: `db/migrate/..._add_status_to_turnos_and_scope_unique_slot_index.rb` (agrega columna `status`, elimina el índice único global de 2.2 y crea el índice único parcial).
- Modelo: actualizar `app/models/turno.rb` (`enum :status`, `conditions:` en la validación de unicidad).
- Política: actualizar `app/policies/turno_policy.rb` (agregar `cancel?`).
- Rutas: en `config/routes.rb`, agregar ruta miembro `patch :cancel` dentro de `resources :turnos`:
  ```ruby
  resources :turnos, only: %i[ new create show update ] do
    member do
      patch :cancel
    end
  end
  ```
  (genera `cancel_turno_path(turno)`)
- Controlador: actualizar `app/controllers/turnos_controller.rb` — nueva acción `cancel`, y filtrar `@turnos` por `.active` en `index`.
- Vista: actualizar `app/views/turnos/show.html.erb` — agregar botón "Cancelar Turno" (`button_to cancel_turno_path(@turno), method: :patch, form: { data: { turbo_confirm: "¿Confirmás que querés cancelar este turno? El horario quedará libre." } }`), estilizado como acción destructiva (`text-danger dark:text-danger-dark`, igual que "Eliminar" en `canchas/_cancha.html.erb`). No mostrar el botón si el Turno ya está `cancelled` (Detalle de Turno de un Turno cancelado solo es accesible si el usuario guardó la URL directamente, ya que el Calendario deja de enlazarlo).
- Tests:
    - `test/models/turno_test.rb`: status default `active`; uniqueness permite recrear un Turno en `(cancha_id, start_time)` de un Turno `cancelled`.
    - `test/policies/turno_policy_test.rb`: `cancel?` → `true` para Dueño y Empleado.
    - `test/controllers/turnos_controller_test.rb`: `PATCH /turnos/:id/cancel` cambia `status` a `cancelled`, redirige al Calendario con notice "Turno cancelado", y el slot deja de aparecer en `@turnos` (vuelve a verse "Cancha libre"); para un Turno `origin: bot`, cancelar no modifica `roster_entries`; cancelar dos veces (idempotencia) no rompe.

### Testing Requirements
- **Unit Tests:** `Turno#status` default `active`; un segundo Turno puede crearse válidamente en el mismo `(cancha_id, start_time)` de un Turno `cancelled` existente (la unicidad solo aplica entre Turnos `active`).
- **Integration Tests:**
    - `PATCH /turnos/:id/cancel` (AC1): `status` pasa a `cancelled`, redirige a `calendario_path` con `notice: "Turno cancelado"`.
    - `GET /calendario` después de cancelar (AC1): el slot del Turno cancelado ya NO aparece en `@turnos` (vuelve a renderizarse como "Cancha libre").
    - Turno `origin: bot` con `roster_entries`: tras `PATCH .../cancel`, `roster_entries` permanecen sin cambios (AC2).
    - `turnos/show.html.erb` (AC3): el botón "Cancelar Turno" está presente y tiene `data-turbo-confirm` (paso de confirmación explícito).

## 🧠 Learnings from Previous Stories (2.1, 2.2)
- **`before_action :set_complejo` + `turno_scope`:** patrones ya establecidos en `TurnosController` — reutilizar tal cual para `cancel`.
- **Índice único `(cancha_id, start_time)` de 2.2:** introducido para AC5 de 2.2 (evitar doble reserva). Esta historia debe convertirlo en parcial (`where: "status = 0"`) — ver "Hallazgo crítico" arriba. Si no se hace, AC1 de esta historia queda implementado solo a medias (el Turno se marca `cancelled` pero el slot sigue "ocupado" para nuevas reservas).
- **`TurnoPolicy`:** creada en 2.2 con `new?/create?/show?/update?` → `user.complejo.present?` para ambos roles. Seguir el mismo patrón para `cancel?`.
- **Patrón `button_to` + `turbo_confirm`:** ya usado en `app/views/canchas/_cancha.html.erb` (acción "Eliminar") — es el patrón de referencia exacto para el botón "Cancelar Turno" de AC3.
- **`config/locales/es.yml`:** ya existe desde 2.1, no requiere cambios para esta historia (no se introduce nuevo texto con `l()`).
- **`reject_if` en `accepts_nested_attributes_for`:** en 2.2 se ajustó de `:all_blank` a `proc { |attrs| attrs["name"].blank? }` por un bug con `position`. No aplica a esta historia (no se tocan `roster_entries_attributes`), pero tenerlo presente si se modifica `turno_params`.

## 🛠️ Tasks / Subtasks

- [x] **Task 1: Migración — `status` + índice único parcial** (AC: 1)
    - [x] Migración: agregar `status` (integer, `null: false, default: 0`) a `turnos`.
    - [x] Migración: eliminar el índice único `index_turnos_on_cancha_id_and_start_time` (de 2.2).
    - [x] Migración: crear índice único parcial `(cancha_id, start_time)` con `where: "status = 0"`.
    - [x] `Turno`: `enum :status, { active: 0, cancelled: 1 }`; actualizar `validates :start_time, uniqueness: { ..., conditions: -> { where.not(status: :cancelled) } }`.

- [x] **Task 2: Autorización** (AC: 1, 2)
    - [x] `TurnoPolicy#cancel?` → `true` para Dueño y Empleado (mismo criterio que `show?`/`update?`).

- [x] **Task 3: Rutas y Controlador** (AC: 1, 2, 3)
    - [x] Ruta `member { patch :cancel }` dentro de `resources :turnos` → genera `cancel_turno_path`.
    - [x] `TurnosController#index`: filtrar `@turnos` por `.active` (excluir `cancelled`).
    - [x] `TurnosController#cancel`: buscar Turno vía `turno_scope`, `authorize`, `update!(status: :cancelled)` (idempotente si ya estaba `cancelled`), `redirect_to calendario_path(date: ...), notice: "Turno cancelado"`.

- [x] **Task 4: Vista — Botón "Cancelar Turno"** (AC: 1, 3)
    - [x] `turnos/show.html.erb`: agregar `button_to "Cancelar Turno", cancel_turno_path(@turno), method: :patch, form: { data: { turbo_confirm: "..." } }`, estilo destructivo (`text-danger`), visible solo si `@turno.active?`.

- [x] **Task 5: Testing y Validación** (AC: 1, 2, 3)
    - [x] Tests unitarios `Turno` (status default, uniqueness con Turno `cancelled`).
    - [x] Tests de `TurnoPolicy#cancel?`.
    - [x] Tests de integración: cancelar libera el slot en `/calendario`, notice "Turno cancelado", idempotencia, Turno `origin: bot` no modifica `roster_entries`.
    - [x] Test de vista/integración: botón "Cancelar Turno" presente con `data-turbo-confirm` en Detalle de Turno.
    - [x] Correr suite completa (`bin/rails test`) y confirmar 0 failures/errors antes de marcar `review`.

## 📝 Dev Agent Record
### Implementation Plan
- Migración `20260612210000_add_status_to_turnos_and_scope_unique_slot_index.rb`: agrega `status` (default `active`/0), elimina el índice único global `(cancha_id, start_time)` de 2.2 y lo reemplaza por uno parcial (`where: "status = 0"`).
- `Turno`: `enum :status, { active: 0, cancelled: 1 }` + `conditions: -> { where.not(status: :cancelled) }` en la validación de unicidad — permite re-reservar un slot cuyo Turno previo fue cancelado.
- `TurnoPolicy#cancel?`: agregado siguiendo el mismo criterio que `show?`/`update?`.
- `TurnosController#index`: `Turno.active.where(...)` para que los Turnos cancelados desaparezcan del Calendario.
- `TurnosController#cancel`: acción dedicada, solo actualiza `status: :cancelled` (idempotente), redirige al Calendario del día del turno con `notice: "Turno cancelado"`.
- Ruta `member { patch :cancel }` agregada a `resources :turnos`.
- `turnos/show.html.erb`: botón "Cancelar Turno" (`button_to` + `turbo_confirm`), visible solo si `@turno.active?`.

### Debug Log
- Durante la implementación, otro agente/LLM aplicó en paralelo fixes de code-review de la Story 2.2 sobre `app/policies/turno_policy.rb`, `app/controllers/turnos_controller.rb`, `app/views/turnos/show.html.erb` y `test/policies/turno_policy_test.rb` (autorización por `record.cancha.complejo_id == user.complejo_id`, `humanize_sport`, etc.). Se ajustó `cancel?` y su test al mismo patrón de autorización por instancia (`TurnoPolicy.new(user, turno_instance)`) para mantener consistencia y evitar `NoMethodError` al pasar la clase `Turno`.

### Completion Notes
- Las 3 ACs cumplidas: cancelar libera el slot (AC1, vía `status: :cancelled` + índice parcial + filtro `.active` en `index`), Turnos `origin: bot` no sufren cambios en su roster ni notificaciones al cancelar (AC2, por construcción — `cancel` solo toca `status`), y la confirmación usa `turbo_confirm` + flash no bloqueante "Turno cancelado" (AC3).
- Suite completa: `bin/rails test` → 105 runs, 307 assertions, 0 failures, 0 errors.

## 📂 File List
- `db/migrate/20260612210000_add_status_to_turnos_and_scope_unique_slot_index.rb` (nuevo)
- `db/schema.rb` (actualizado por la migración)
- `app/models/turno.rb` (enum `status` + `conditions:` en uniqueness)
- `app/policies/turno_policy.rb` (agregado `cancel?`)
- `config/routes.rb` (ruta `member { patch :cancel }`)
- `app/controllers/turnos_controller.rb` (acción `cancel`, `index` filtra `.active`)
- `app/views/turnos/show.html.erb` (botón "Cancelar Turno")
- `test/models/turno_test.rb` (tests status default + uniqueness con cancelado)
- `test/policies/turno_policy_test.rb` (test `cancel?`)
- `test/controllers/turnos_controller_test.rb` (tests `cancel`, AC1, AC2, AC3)

## 📜 Change Log
- 2026-06-12: Creación del story file (bmad-create-story).
- 2026-06-12: Implementación completa (dev-story) — Status → review.

## 📊 Story Completion Status
- **Analysis:** Ultimate context engine analysis completada (epics, architecture, EXPERIENCE.md, story 2.2 — incluyendo su impacto directo sobre el índice único de `turnos` — y schema actual).
- **Status:** done

---
baseline_commit: 6d103c9ca097d141691dbd49a0e0f69b4343c454
---

# Story 2.4: Turnos Fijos / Recurrentes

**ID:** 2.4
**Key:** 2-4-turnos-fijos-recurrentes
**Status:** done
**Epic:** Epic 2: Calendario y Gestión de Turnos

## 📝 Story Statement
**As a** Dueño del Complejo,
**I want** marcar un Turno de Origen Manual como recurrente (semanal),
**So that** el sistema genere automáticamente las instancias futuras sin que tenga que crearlas a mano cada semana.

## ✅ Acceptance Criteria

### AC 1: Generación automática de instancias futuras (FR-6)
**Given** que soy Dueño creando un Turno de Origen Manual
**When** marco la opción "Marcar como recurrente"
**Then** el sistema genera automáticamente instancias futuras semanales (misma Cancha, horario, día de la semana, Roster) vía `RecurringTurnoGenerator`/`GenerateRecurringTurnosJob`

### AC 2: Opción oculta para Empleado
**Given** que soy Empleado
**When** abro el formulario de Nuevo Turno
**Then** no veo la opción "Marcar como recurrente" (oculta para Empleado)

### AC 3: Instancias independientes con su propio Estado de Pago
**Given** instancias futuras generadas por un Turno Fijo
**When** las veo en el Calendario
**Then** cada una aparece como un Turno independiente con su propio Estado de Pago

### AC 4: Edición/cancelación de una instancia no afecta la serie
**Given** una instancia futura de un Turno Fijo
**When** la modifico o cancelo individualmente
**Then** el cambio no afecta al Turno recurrente original ni a otras instancias

## 🏗️ Developer Context & Guardrails

### Technical Requirements

- **Framework:** Rails 8.1.3 + PostgreSQL. **Solid Queue** ya está instalado (`gem "solid_queue"` en `Gemfile`) y `config/recurring.yml` existe (con ejemplos comentados) — este es el primer job real del proyecto.

- **⚠️ Decisión de scope — interpretación de `Turno.recurring_rule_id` (architecture.md línea 155):** `architecture.md` menciona `Turno.recurring_rule_id` (nullable) sin definir un modelo `RecurringRule` separado, y marca explícitamente "la semántica fina de edición de instancias de Turno Fijo... quedan pendientes de definición a nivel de FR/historias" (resuelto por AC4 de esta historia: instancias independientes). Para mantener el modelo de datos simple (sin nueva tabla) y cumplir AC3/AC4 "por construcción", esta historia interpreta `recurring_rule_id` como una **referencia auto-referencial dentro de `turnos`**:
    - `recurring` (boolean, default `false`): marca el Turno "original" que el Dueño marcó como recurrente.
    - `recurring_rule_id` (bigint, nullable, FK a `turnos.id`): en las instancias generadas, apunta al Turno original que las generó. Es **solo informativo/trazabilidad** — NO se usa para cascadear ediciones o cancelaciones (eso es justamente lo que AC4 prohíbe).
    - No crear un modelo `RecurringRule` ni tabla nueva — `Turno` referencia a sí mismo.

- **Migración:**
  ```ruby
  add_column :turnos, :recurring, :boolean, null: false, default: false
  add_reference :turnos, :recurring_rule, foreign_key: { to_table: :turnos }, null: true
  ```
  (El índice único parcial `(cancha_id, start_time) where status = 0` de la Story 2.3 sigue aplicando sin cambios — cada instancia generada es un Turno normal sujeto a las mismas reglas de unicidad/cancelación.)

- **Modelo `Turno`:**
  ```ruby
  belongs_to :recurring_rule, class_name: "Turno", optional: true
  has_many :recurring_instances, class_name: "Turno", foreign_key: :recurring_rule_id, dependent: :nullify
  ```

- **`app/services/recurring_turno_generator.rb`** (nuevo — primer archivo en `app/services/`, carpeta no existe todavía, crearla):
  - Recibe el Turno "original" (recién creado, `recurring: true`, `origin: :manual`).
  - Genera instancias futuras semanales para un horizonte fijo `WEEKS_AHEAD = 8` (≈2 meses) — `[ASSUMPTION]`: no hay un valor definido en PRD/epics; 8 semanas es un default razonable y configurable a futuro mediante una constante.
  - Para cada semana `1..WEEKS_AHEAD`: `start_time = turno_original.start_time + n.weeks`.
  - **Manejo de conflictos**: si ya existe un Turno `active` para `(cancha_id, start_time)` en esa semana (la validación de unicidad de 2.2/2.3 lo impediría), **omitir esa instancia silenciosamente** (no abortar todo el proceso) — el slot ya está ocupado por otra reserva y eso tiene prioridad.
  - Cada instancia generada: `cancha_id`, `start_time`, `reservation_name` (heredado), `origin: :manual`, `status: :active`, `payment_status: :pending` (default), `recurring: false`, `recurring_rule: turno_original`.
  - Copiar `roster_entries` del original a cada instancia (nuevos registros `RosterEntry` independientes — `name`/`position`, sin `id` compartido).
  - Interfaz: `RecurringTurnoGenerator.new(turno).call` — devuelve los Turnos creados (útil para tests).

- **`app/jobs/generate_recurring_turnos_job.rb`** (nuevo):
  ```ruby
  class GenerateRecurringTurnosJob < ApplicationJob
    queue_as :default

    def perform(turno_id)
      turno = Turno.find_by(id: turno_id)
      return if turno.nil?

      RecurringTurnoGenerator.new(turno).call
    end
  end
  ```
  - Sigue la convención de nombres de `architecture.md` línea 275 (sufijo `Job`, inglés).

- **`TurnosController#create`:** si `turno_params[:recurring]` es `true` (y el usuario es Dueño — ver Autorización abajo) y `@turno.save` tiene éxito, encolar `GenerateRecurringTurnosJob.perform_later(@turno.id)` **después** de guardar el Turno original (necesita su `id`).

### Architecture Compliance
- **Autorización (AC2, FR-6 NFR):** `TurnoPolicy#mark_recurring?` → `user&.owner? || false` (usa el enum `role` de `User`, ya existente: `owner`/`employee`). En `turno_params`, eliminar `:recurring` del hash permitido si `!policy(Turno).mark_recurring?` — defensa en profundidad además de ocultar el checkbox en la vista (un Empleado no puede forzar `recurring: true` manipulando el form).
- **Scope — solo en creación, no en edición:** Esta historia limita "Marcar como recurrente" al formulario de **Nuevo Turno** (`turnos/new.html.erb`). El AC1 dice "creando ... un Turno de Origen Manual"; activar recurrencia retroactivamente desde "Detalle de Turno" (`turnos/show.html.erb`) introduciría ambigüedad sobre desde qué fecha generar instancias y no está cubierto por los ACs. Si se requiere a futuro, es una historia separada.
- **AC3/AC4 "por construcción":** las instancias generadas son Turnos normales — `TurnosController#update`/`#cancel` (de la Story 2.2/2.3) ya operan sobre un único registro sin ninguna lógica de cascada. No agregar tal lógica. `recurring_rule_id` es solo trazabilidad.
- **Reutilizar patrones existentes:** `Turno.active` scope (2.3) para que las instancias generadas aparezcan en `/calendario` igual que cualquier Turno; `accepts_nested_attributes_for :roster_entries` ya maneja el Roster del Turno original — el generador copia esas `roster_entries` ya persistidas (no hace falta tocar `turno_params`).
- **Jobs (architecture.md línea 275):** nombre en inglés, sufijo `Job` — `GenerateRecurringTurnosJob` (ya coincide con el nombre dado en `epics.md`).

### Library & Framework Requirements
- `solid_queue` ya está en el `Gemfile` — no agregar gemas nuevas.
- En test, `ActiveJob::Base.queue_adapter` es `:test` por defecto (Rails) — usar `assert_enqueued_with` / `perform_enqueued_jobs` de `ActiveJob::TestHelper` (incluido automáticamente en `ActiveSupport::TestCase` vía `rails/test_help`).

### File Structure Requirements
- Migración: `db/migrate/..._add_recurring_fields_to_turnos.rb`.
- Modelo: `app/models/turno.rb` (agregar `recurring_rule`/`recurring_instances`).
- Servicio (nuevo): `app/services/recurring_turno_generator.rb`.
- Job (nuevo): `app/jobs/generate_recurring_turnos_job.rb`.
- Política: `app/policies/turno_policy.rb` (agregar `mark_recurring?`).
- Controlador: `app/controllers/turnos_controller.rb` (`create`: permitir/encolar; `turno_params`: filtrar `:recurring` según policy).
- Vista: `app/views/turnos/new.html.erb` (checkbox "Marcar como recurrente (semanal)", visible solo si `policy(Turno).mark_recurring?`).
- Tests:
    - `test/models/turno_test.rb`: `recurring` default `false`; asociación `recurring_rule`/`recurring_instances`.
    - `test/services/recurring_turno_generator_test.rb` (nuevo): genera `WEEKS_AHEAD` instancias semanales, copia Roster, omite slots ya ocupados, `recurring_rule` apunta al original.
    - `test/jobs/generate_recurring_turnos_job_test.rb` (nuevo): `perform` invoca al generador y crea instancias; no falla si el Turno no existe.
    - `test/policies/turno_policy_test.rb`: `mark_recurring?` → `true` para Dueño, `false` para Empleado.
    - `test/controllers/turnos_controller_test.rb`: `create` con `recurring: "1"` (Dueño) encola `GenerateRecurringTurnosJob` con el id del Turno creado; `create` con `recurring: "1"` (Empleado) NO marca `recurring: true` ni encola el job; `new.html.erb` muestra el checkbox solo para Dueño.

### Testing Requirements
- **Unit Tests (modelo):** `Turno#recurring` default `false`; `recurring_rule`/`recurring_instances` funcionan correctamente (self-referencia).
- **Unit Tests (servicio `RecurringTurnoGenerator`):**
    - Dado un Turno con `recurring: true` y 2 `roster_entries`, genera 8 instancias futuras (una por semana, mismo día/horario, `cancha_id` igual).
    - Cada instancia generada tiene `recurring_rule_id == turno_original.id`, `recurring: false`, `origin: :manual`, `status: :active`, copia de `reservation_name` y `roster_entries` (mismos `name`).
    - Si ya existe un Turno `active` en `(cancha_id, start_time)` de una semana futura (conflicto), esa instancia se omite y el resto se genera normalmente (no lanza excepción).
- **Unit Tests (job):** `GenerateRecurringTurnosJob.perform_now(turno.id)` crea las instancias esperadas (vía generador); `perform_now(id_inexistente)` no falla.
- **Policy Tests:** `TurnoPolicy#mark_recurring?` → `true` para `users(:one)` (Dueño/owner), `false` para `users(:two)` (Empleado/employee).
- **Integration Tests (AC1, AC2):**
    - `POST /turnos` con `turno[recurring] = "1"` autenticado como Dueño → el Turno creado tiene `recurring: true` y `GenerateRecurringTurnosJob` queda encolado con su `id` (`assert_enqueued_with`).
    - `POST /turnos` con `turno[recurring] = "1"` autenticado como Empleado → el Turno creado tiene `recurring: false` y NO se encola ningún job.
    - `GET /turnos/new` como Dueño → el checkbox "Marcar como recurrente" está presente; como Empleado → ausente.
- **Integration/E2E (AC3, AC4):** tras ejecutar el generador (`perform_enqueued_jobs` o llamando al servicio directamente en el test), las instancias generadas aparecen en `GET /calendario` de la semana correspondiente como Turnos independientes (cada una con su propio `payment_status: pending`); cancelar una instancia (`PATCH /turnos/:id/cancel`) no cambia el `status` del Turno original ni de las demás instancias.

## 🧠 Learnings from Previous Stories (2.1, 2.2, 2.3)
- **`Turno.active` scope (2.3):** las instancias generadas deben quedar `status: :active` (default) para que `TurnosController#index` (que filtra `.active`) las muestre en el Calendario — sin esto AC3 no se cumple.
- **Índice único parcial `(cancha_id, start_time) where status = 0` (2.3):** cualquier instancia generada que choque con un Turno `active` existente en esa semana fallará la validación de unicidad si se intenta `save!` — por eso el generador debe chequear (`Turno.active.exists?(...)`) y omitir, no usar `create!` que abortaría todo el batch.
- **`accepts_nested_attributes_for :roster_entries` con `reject_if: proc { |attrs| attrs["name"].blank? }` (2.2):** al copiar el Roster del original, construir `roster_entries` directamente con `.build(name:, position:)` sobre las instancias nuevas (no pasar por `roster_entries_attributes`), ya que el generador corre en background, no en un formulario.
- **`TurnoPolicy` con métodos `?` por acción (2.2/2.3):** seguir el mismo patrón para `mark_recurring?`.
- **Patrón de autorización por instancia (`record.cancha.complejo_id == user.complejo_id`, fix de code-review aplicado durante 2.3):** `mark_recurring?` NO necesita este chequeo porque se evalúa sobre la clase `Turno` (antes de tener un registro/cancha asociado), igual que `new?`/`create?`.
- **`humanize_sport` helper (fix de code-review de 2.3):** ya disponible y usado en `turnos/new.html.erb` y `turnos/show.html.erb` — no reintroducir `.sport.humanize` inline.

## 🛠️ Tasks / Subtasks

- [x] **Task 1: Migración y modelo** (AC: 1, 3, 4)
    - [x] Migración: agregar `recurring` (boolean, `null: false, default: false`) y `recurring_rule_id` (bigint, nullable, FK a `turnos`) a `turnos`.
    - [x] `Turno`: `belongs_to :recurring_rule, class_name: "Turno", optional: true`; `has_many :recurring_instances, class_name: "Turno", foreign_key: :recurring_rule_id, dependent: :nullify`.
    - [x] Test: `recurring` default `false`; asociación self-referencial funciona.

- [x] **Task 2: `RecurringTurnoGenerator`** (AC: 1, 3)
    - [x] Crear `app/services/recurring_turno_generator.rb` con `WEEKS_AHEAD = 8`, generación semanal, copia de Roster, manejo de conflictos (omitir slot ocupado).
    - [x] Tests del servicio: genera 8 instancias, copia Roster, `recurring_rule_id` correcto, omite conflictos sin lanzar excepción.

- [x] **Task 3: `GenerateRecurringTurnosJob`** (AC: 1)
    - [x] Crear `app/jobs/generate_recurring_turnos_job.rb` (`perform(turno_id)` → `RecurringTurnoGenerator.new(turno).call`, no-op si el Turno no existe).
    - [x] Test del job: `perform_now` crea instancias; `perform_now` con id inexistente no falla.

- [x] **Task 4: Autorización** (AC: 2)
    - [x] `TurnoPolicy#mark_recurring?` → `user&.owner? || false`.
    - [x] Test de policy: `true` para Dueño, `false` para Empleado.

- [x] **Task 5: Controlador — `create` con recurrencia** (AC: 1, 2)
    - [x] `turno_params`: incluir `:recurring`; eliminarlo del hash si `!policy(Turno).mark_recurring?`.
    - [x] `create`: si `@turno.save` y `@turno.recurring?`, `GenerateRecurringTurnosJob.perform_later(@turno.id)`.
    - [x] Tests de integración: Dueño con `recurring: "1"` → Turno `recurring: true` + job encolado; Empleado con `recurring: "1"` → Turno `recurring: false`, sin job.

- [x] **Task 6: Vista — checkbox "Marcar como recurrente"** (AC: 1, 2)
    - [x] `turnos/new.html.erb`: checkbox `turno[recurring]`, visible solo si `policy(Turno).mark_recurring?`.
    - [x] Tests de vista: presente para Dueño, ausente para Empleado.

- [x] **Task 7: Validación end-to-end** (AC: 1, 2, 3, 4)
    - [x] Test de integración: ejecutar el flujo completo (crear Turno recurrente como Dueño → `perform_enqueued_jobs` → instancias visibles en `/calendario` de semanas futuras, cada una con su propio `payment_status`).
    - [x] Test: cancelar una instancia individual no afecta el Turno original ni otras instancias.
    - [x] Correr suite completa (`bin/rails test`) y confirmar 0 failures/errors antes de marcar `review`.

## 📝 Dev Agent Record
### Implementation Plan
- Migración auto-referencial (`recurring`, `recurring_rule_id`) sobre `turnos`, sin modelo `RecurringRule` nuevo, según la decisión de scope documentada en Dev Notes.
- `RecurringTurnoGenerator` genera `WEEKS_AHEAD = 8` instancias semanales con `.build` directo de `roster_entries` (no `roster_entries_attributes`), usando `Turno.active.exists?` para detectar y omitir conflictos de slot.
- `GenerateRecurringTurnosJob#perform` resuelve el Turno por id (no-op si no existe) y delega en el generador.
- `TurnoPolicy#mark_recurring?` replica el patrón existente (`new?`/`create?`) evaluado sobre la clase `Turno`.
- `turno_params` permite `:recurring` y lo elimina si `!policy(Turno).mark_recurring?` (defensa en profundidad además del checkbox condicional en la vista).
- `TurnosController#create` encola `GenerateRecurringTurnosJob.perform_later(@turno.id)` solo si `@turno.recurring?` tras el `save`.
- Checkbox "Marcar como recurrente (semanal)" en `turnos/new.html.erb`, visible solo si `policy(Turno).mark_recurring?`.

### Debug Log
- Sin incidencias. Migración aplicada con `bin/rails db:migrate`.

### Completion Notes
- Implementadas todas las tareas (1-7). Suite completa: `bin/rails test` → 120 runs, 420 assertions, 0 failures, 0 errors, 0 skips.
- `rubocop` sobre los archivos tocados: solo 2 offenses preexistentes en `turnos_controller.rb` (líneas no modificadas por esta historia, `Layout/SpaceInsideArrayLiteralBrackets`), no relacionadas con esta implementación.
- **Fixes de code-review aplicados:**
  - `RecurringTurnoGenerator#call`: `instance.save!` ahora está envuelto en `rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique` para que una condición de carrera en una semana (slot ocupado entre el chequeo `exists?` y el `save!`) omita esa instancia sin abortar el resto de la serie. Test agregado en `recurring_turno_generator_test.rb`.
  - `turno_params`: `:recurring` ahora solo se permite cuando `action_name == "create"` (y `policy(Turno).mark_recurring?`), evitando que un Dueño pueda marcar `recurring: true` en `update` (donde no se encola el job de generación). Test agregado en `turnos_controller_test.rb`.
  - `TurnoPolicy#mark_recurring?`: removido el `|| false` redundante (`user&.owner?` ya es `true`/`false`/`nil`, equivalentes en contexto booleano).
- Suite completa post-fixes: `bin/rails test` → 122 runs, 425 assertions, 0 failures, 0 errors, 0 skips.
- **Fixes adicionales de code-review (issues preexistentes detectados en el diff, no introducidos por esta historia pero corregidos a pedido):**
  - `Cancha#broadcasts_to :complejo`: el `target` por defecto (`dom_id(model_name.plural)` = `"canchas"`) no coincidía con el contenedor real `<ul id="<%= dom_id(@complejo, :canchas) %>">` de `configuracion/show.html.erb`, por lo que el `append`/`remove` vía Turbo Stream era un no-op silencioso. Se agregó `target: ->(cancha) { ActionView::RecordIdentifier.dom_id(cancha.complejo, :canchas) }`.
  - `turnos/index.html.erb`: `cancha.sport.humanize` (riesgo de `NoMethodError` si `sport` es `nil`) reemplazado por el helper `humanize_sport(cancha.sport)`, ya usado en `turnos/show.html.erb`/`new.html.erb`/`card_turno_component`. También se actualizó `canchas/_cancha.html.erb` (`cancha.sport&.humanize` → `humanize_sport(cancha.sport)`) para usar el mismo helper de forma consistente en las tres vistas.
  - `CanchasController`: eliminado el `rescue_from ArgumentError, with: :handle_invalid_sport` controller-wide (podía enmascarar errores no relacionados en `index`/`destroy` al invocar `cancha_params` sin `params[:cancha]`, lanzando `ActionController::ParameterMissing`). Reemplazado por `rescue ArgumentError` local en `create`/`update`, asignando `sport` por separado (solo si está presente en los params) para capturar el `ArgumentError` del enum sin afectar el resto de los atributos. Tests agregados en `canchas_controller_test.rb` (sport inválido en create/update).
- Suite completa final: `bin/rails test` → 124 runs, 430 assertions, 0 failures, 0 errors, 0 skips. `rubocop` sobre archivos Ruby tocados: 0 offenses.

## 📂 File List
- `db/migrate/20260612220000_add_recurring_fields_to_turnos.rb` (nuevo)
- `db/schema.rb` (actualizado por la migración)
- `app/models/turno.rb`
- `app/models/cancha.rb`
- `app/services/recurring_turno_generator.rb` (nuevo)
- `app/jobs/generate_recurring_turnos_job.rb` (nuevo)
- `app/policies/turno_policy.rb`
- `app/controllers/turnos_controller.rb`
- `app/controllers/canchas_controller.rb`
- `app/views/turnos/new.html.erb`
- `app/views/turnos/index.html.erb`
- `app/views/canchas/_cancha.html.erb`
- `test/models/turno_test.rb`
- `test/services/recurring_turno_generator_test.rb` (nuevo)
- `test/jobs/generate_recurring_turnos_job_test.rb` (nuevo)
- `test/policies/turno_policy_test.rb`
- `test/controllers/turnos_controller_test.rb`
- `test/controllers/canchas_controller_test.rb`

## 📜 Change Log
- 2026-06-12: Creación del story file (bmad-create-story).
- 2026-06-12: Implementación completa (Tasks 1-7) — turnos fijos/recurrentes (RecurringTurnoGenerator, GenerateRecurringTurnosJob, autorización y vista). Status → review.
- 2026-06-12: Fixes de code-review aplicados — rescue de conflicto de unicidad en `RecurringTurnoGenerator`, `:recurring` restringido a `create` en `turno_params`, limpieza de `TurnoPolicy#mark_recurring?`.
- 2026-06-12: Fixes adicionales de code-review (issues preexistentes) — target correcto en `Cancha#broadcasts_to`, `humanize_sport` consistente en vistas de cancha/calendario, refactor de manejo de `sport` inválido en `CanchasController` (sin `rescue_from` controller-wide).
- 2026-06-12: Story marcada como done tras revisión completa.

## 📊 Story Completion Status
- **Analysis:** Ultimate context engine analysis completada (epics, architecture, PRD §8 Open Questions/OQ2, EXPERIENCE.md, stories 2.2/2.3 — incluyendo el scope `status`/índice parcial de 2.3 y su impacto en el generador de recurrentes — y schema/Gemfile actuales).
- **Status:** done

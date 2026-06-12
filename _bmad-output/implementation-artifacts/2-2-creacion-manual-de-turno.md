---
baseline_commit: 6d103c9ca097d141691dbd49a0e0f69b4343c454
---

# Story 2.2: Creación manual de Turno

**ID:** 2.2
**Key:** 2-2-creacion-manual-de-turno
**Status:** done
**Epic:** Epic 2: Calendario y Gestión de Turnos

## 📝 Story Statement
**As a** Administrador o Empleado,
**I want** crear un Turno de Origen Manual tocando un slot vacío del Calendario,
**So that** pueda registrar reservas que llegan por teléfono o mostrador.

## ✅ Acceptance Criteria

### AC 1: Apertura de Nuevo Turno desde slot vacío
**Given** un slot "Cancha libre" en el Calendario
**When** lo toco
**Then** se abre Nuevo Turno con Cancha/horario/deporte pre-cargados (UX-DR9)

### AC 2: Creación del Turno con roster básico
**Given** el formulario de Nuevo Turno abierto
**When** completo el nombre de quien reserva y, opcionalmente, un roster básico (nombres, sin Estado de Confirmación) y guardo
**Then** se crea un Turno de Origen Manual con un `Payment` en estado Pendiente

### AC 3: Reflejo inmediato en el Calendario
**Given** que guardé el Turno
**When** vuelvo al Calendario
**Then** el slot ya no aparece como "Cancha libre" sino como una `card-turno` con el nuevo Turno y su reservante

### AC 4: Roster editable en Detalle de Turno
**Given** un Turno de Origen Manual
**When** abro su Detalle de Turno
**Then** el roster muestra nombres editables, sin Estado de Confirmación (UX-DR4)
**And** si el roster está vacío, se muestra "Todavía no cargaste el roster" sin bloquear el registro de pago (UX-DR8)

### AC 5: Validación de disponibilidad
**Given** que el sistema valida disponibilidad
**When** intento crear un Turno sobre una Cancha/horario ya ocupado
**Then** el sistema lo impide

## 🏗️ Developer Context & Guardrails

### Technical Requirements

- **Framework:** Rails 8.1.3, Tailwind CSS v4.x, ViewComponent, Pundit.

- **Decisión de scope — `Payment` (AC2):** NO crear un modelo `Payment` completo en esta historia. `Turno#payment_status` ya existe desde Story 2.1 (enum `pending/partial/paid`, default `pending`). Un Turno recién creado ya cumple "con un `Payment` en estado Pendiente" simplemente dejando `payment_status` en su default. La extracción a un modelo `Payment` dedicado (monto, fecha, registro de pago) es el alcance explícito de Story 3.1/3.2 (FR-8/FR-9) — no lo adelantes aquí.

- **Decisión de scope — `RosterEntry` (AC2/AC4):** Crear un modelo `RosterEntry` NUEVO, pero MINIMAL:
    - Columnas: `turno_id` (references), `name` (string, requerido si la fila no está vacía), `role` (enum `{ titular: 0, suplente: 1 }`, default `titular`), `confirmation_status` (enum `{ pending: 0, confirmed: 1, replacement: 2, uncovered: 3 }`, default `pending`), `position` (integer, para mantener el orden cargado).
    - **NO crear `Player`/`ComplexPlayer`/`Complex` en esta historia.** `RosterEntry.name` es un campo de texto libre, denormalizado — suficiente para "roster básico (nombres, sin Estado de Confirmación)". `confirmation_status` se modela igual desde ya (consistencia con `architecture.md` línea 156 y compatibilidad futura con Epic 5/FR-1-3), pero **NO se muestra en la UI para Turnos `origin: manual`** (UX-DR4) — simplemente no renderices ese dato en `turnos/show.html.erb` para este Origen.
    - Epic 5 (Bot WhatsApp) agregará `player_id` (nullable, FK a `Player`) a `roster_entries` sin romper `name` ni romper esta historia.

- **Migraciones nuevas:**
    1. `add_column :turnos, :reservation_name, :string` — "nombre de quien reserva" (AC2/AC3). Nullable a nivel DB pero validado `presence: true` a nivel modelo (un Turno manual siempre tiene reservante).
    2. `add_index :turnos, [:cancha_id, :start_time], unique: true` — soporta AC5 (impide doble reserva del mismo slot) y resuelve de paso el ítem deferred de Story 2.1 sobre `index_by` descartando turnos silenciosamente.
    3. `create_table :roster_entries` con las columnas descriptas arriba + `belongs_to :turno`.

- **Cambios en `app/models/turno.rb`:**
    - `has_many :roster_entries, dependent: :destroy`
    - `accepts_nested_attributes_for :roster_entries, reject_if: :all_blank, allow_destroy: true`
    - `validates :reservation_name, presence: true`
    - `validates :start_time, uniqueness: { scope: :cancha_id, message: "ya tiene un turno reservado en este horario" }` (AC5)

### Architecture Compliance
- Nombres de tabla/columna en inglés snake_case (`roster_entries`, `reservation_name`, `confirmation_status`), manteniendo `Turno`/`RosterEntry`/`Cancha` como nombres de clase según convención ya establecida (`architecture.md` línea 228).
- `enum` de Rails en inglés + helper de presentación en español para cualquier estado visible (`status_presentation_helper.rb`) — si se necesita presentar `role`/`confirmation_status` en algún punto, sumar el helper correspondiente ahí, no hardcodear strings en la vista.
- FR-12: tanto Dueño como Empleado tienen acceso a "Nuevo Turno" y "Detalle de Turno" — `TurnoPolicy#new?/create?/show?/update?` deben devolver `true` para ambos roles (no es una sección exclusiva de Dueño, a diferencia de `CanchaPolicy`/`ConfiguracionPolicy`).
- Reutilizar el patrón `before_action :set_complejo` (ya presente en `TurnosController` desde el review de 2.1) para todas las acciones nuevas; las Canchas/Turnos siempre se buscan dentro de `@complejo.canchas` / `@complejo.canchas.turnos`, nunca por ID global, para no filtrar datos entre complejos.
- AC5 (validación de disponibilidad): la validación de unicidad del modelo es la fuente de verdad. En el controlador, capturar el fallo de `@turno.save` (no `rescue` de `ActiveRecord::RecordNotUnique` — dejar que la `validates :uniqueness` lo maneje como error de validación normal) y `render :new, status: :unprocessable_entity` mostrando el mensaje de error, igual que el patrón de `CanchasController#create`.

### Library & Framework Requirements
- Sin librerías JS nuevas. "Nuevo Turno" y "Detalle de Turno" se implementan como vistas de página completa (`turnos/new.html.erb`, `turnos/show.html.erb`), siguiendo el mismo patrón que `canchas/new.html.erb`/`edit.html.erb` (form_with + `InputFieldComponent` + `ButtonPrimaryComponent` + link "Volver"). La UX describe estas pantallas como "sheet/modal" (UX-DR del EXPERIENCE.md), pero esa interacción (drag-to-close, overlay) requeriría JS adicional fuera del alcance — **se documenta como ítem deferred** para una iteración de UI posterior; el contenido y orden de secciones deben coincidir con el mock (`mockups/detalle-turno.html`) aunque el contenedor sea una página en vez de un modal.
- Para el roster básico en "Nuevo Turno", usar `fields_for :roster_entries` con `accepts_nested_attributes_for` y renderizar un número fijo de filas vacías (ej. 4, suficiente para "grupo de 4" según Flow 1 de `EXPERIENCE.md`). Las filas con `name` en blanco se descartan vía `reject_if: :all_blank` — no se requiere JS para agregar/quitar filas dinámicamente en esta historia.
- En "Detalle de Turno", el roster se edita con un `form_with model: @turno` que vuelve a usar `fields_for :roster_entries` sobre las entradas existentes (+ una fila vacía adicional para agregar un nombre más), enviado a `TurnosController#update`.

### File Structure Requirements
- Migraciones: `db/migrate/..._add_reservation_name_and_unique_slot_index_to_turnos.rb`, `db/migrate/..._create_roster_entries.rb`
- Modelos: `app/models/roster_entry.rb`, actualizar `app/models/turno.rb`
- Política: `app/policies/turno_policy.rb`
- Rutas: reemplazar la ruta placeholder `get "turnos/new", to: "turnos#new", as: :new_turno` por `resources :turnos, only: [:new, :create, :show, :update]` en `config/routes.rb` (genera `new_turno_path`, `turnos_path`, `turno_path`)
- Controlador: `app/controllers/turnos_controller.rb` — reemplazar la acción `new` placeholder (que actualmente redirige con "Próximamente...") por la implementación real; agregar `create`, `show`, `update`
- Vistas:
    - `app/views/turnos/new.html.erb` (Nuevo Turno — AC1/AC2)
    - `app/views/turnos/show.html.erb` (Detalle de Turno — AC4, basado en `mockups/detalle-turno.html`: header con `court-tag`, roster, status-pill, reservante)
    - Actualizar `app/views/turnos/index.html.erb` (AC3 — la `card-turno` debe enlazar a `turno_path(turno)`)
- Componentes a actualizar:
    - `app/components/card_turno_component.rb` / `.html.erb` — `reservee_name` debe devolver `turno.reservation_name`; `roster_summary` debe reflejar `turno.roster_entries.size` real (ej. "N cargados" en vez de "0/4 confirmados", ya que Turnos manuales no tienen confirmaciones)
- Tests:
    - `test/models/roster_entry_test.rb`, actualizar `test/models/turno_test.rb` (uniqueness, reservation_name presence, nested attributes)
    - `test/policies/turno_policy_test.rb`
    - Actualizar `test/controllers/turnos_controller_test.rb` (new/create/show/update, incluyendo el caso AC5 de slot ocupado)
    - Actualizar `test/components/card_turno_component_test.rb`

### Testing Requirements
- **Unit Tests:** `RosterEntry` pertenece a `Turno`; filas en blanco se descartan (`reject_if: :all_blank`). `Turno` requiere `reservation_name`; no permite dos Turnos con el mismo `(cancha_id, start_time)` (AC5).
- **Integration Tests:**
    - `GET /turnos/new?cancha_id=...&date=...&hour=...` devuelve 200 y pre-carga cancha/horario/deporte (AC1).
    - `POST /turnos` con datos válidos crea el `Turno` (`origin: manual`, `payment_status: pending` por default) + `RosterEntry` por cada nombre no vacío, y redirige al Calendario (AC2/AC3).
    - `POST /turnos` sobre un slot ya ocupado (mismo `cancha_id` + `start_time` de un Turno existente) NO crea el Turno, responde `:unprocessable_entity` y muestra el error (AC5).
    - `GET /turnos/:id` (Detalle de Turno) muestra el roster editable y, si está vacío, el texto "Todavía no cargaste el roster" (AC4).
    - `PATCH /turnos/:id` actualiza nombres del roster.
- **Component Tests:** `CardTurnoComponent` renderiza `reservation_name` y el conteo real de `roster_entries`.

## 🧠 Learnings from Previous Stories (2.1)
- **Locale `:es` ya configurado:** `config/locales/es.yml` existe desde el review de 2.1 — `l(..., locale: :es)` funciona correctamente, no hay que volver a crearlo.
- **`before_action :set_complejo`:** patrón ya aplicado en `TurnosController#index` (y en `CanchasController`/`ConfiguracionController`) — reutilizarlo tal cual para `new`/`create`/`show`/`update`, no reinventar.
- **`parse_date` helper:** `TurnosController` ya tiene un método privado `parse_date` que rescata `ArgumentError`/`TypeError` de `Date.parse` — reutilizarlo si `new`/`create` necesitan parsear `params[:date]`.
- **Ruta placeholder a reemplazar:** la ruta `get "turnos/new", to: "turnos#new", as: :new_turno` y la acción `TurnosController#new` (que hoy solo redirige con "Próximamente vas a poder crear turnos desde acá.") son el placeholder creado en el review de 2.1 específicamente para que esta historia los reemplace.
- **`index_by` en `TurnosController#index`:** con el nuevo índice único `(cancha_id, start_time)`, ya no pueden existir dos Turnos para la misma clave — el `index_by { |t| [t.cancha_id, t.start_time.hour] }` deja de tener un caso de descarte silencioso para Turnos creados desde esta historia en adelante.
- **`CardTurnoComponent` placeholders:** `reservee_name` ("Sin nombre") y `roster_summary` ("0/4 confirmados") fueron documentados como placeholders deferred en 2.1 explícitamente "hasta Epic 2" — esta historia es donde se resuelven.
- **Componentes:** seguir usando `InputFieldComponent`/`ButtonPrimaryComponent` como en `canchas/new.html.erb`/`edit.html.erb`.

## 🛠️ Tasks / Subtasks

- [x] **Task 1: Modelos y Migraciones** (AC: 2, 4, 5)
    - [x] Migración: agregar `reservation_name` (string) a `turnos`.
    - [x] Migración: agregar índice único `(cancha_id, start_time)` a `turnos`.
    - [x] Migración + modelo `RosterEntry` (`turno_id`, `name`, `role` enum, `confirmation_status` enum, `position`).
    - [x] `Turno`: `has_many :roster_entries, dependent: :destroy`, `accepts_nested_attributes_for`, `validates :reservation_name, presence: true`, `validates :start_time, uniqueness: { scope: :cancha_id, ... }`.

- [x] **Task 2: Autorización** (AC: 1, 2, 4)
    - [x] Crear `TurnoPolicy` (`new?`, `create?`, `show?`, `update?` → `true` para cualquier usuario con `complejo` asignado, Dueño o Empleado).

- [x] **Task 3: Rutas y Controlador** (AC: 1, 2, 3, 4, 5)
    - [x] Reemplazar la ruta placeholder por `resources :turnos, only: [:new, :create, :show, :update]`.
    - [x] `TurnosController#new`: leer `cancha_id`, `date`, `hour` de `params`, construir `@turno` con `cancha`/`start_time` pre-cargados y 4 `roster_entries` vacíos vía `build`.
    - [x] `TurnosController#create`: `authorize`, asignar `origin: :manual`, guardar; si falla por slot ocupado (AC5) o validación, `render :new, status: :unprocessable_entity`; si OK, `redirect_to calendario_path(date: ...)` con notice.
    - [x] `TurnosController#show`: Detalle de Turno — cargar `@turno` con `roster_entries`.
    - [x] `TurnosController#update`: actualizar `reservation_name` y `roster_entries_attributes` (AC4).

- [x] **Task 4: Vistas** (AC: 1, 2, 3, 4)
    - [x] `turnos/new.html.erb`: cancha/horario/deporte pre-cargados (read-only), campo `reservation_name`, 4 filas `fields_for :roster_entries` para nombres.
    - [x] `turnos/show.html.erb`: basado en `mockups/detalle-turno.html` — `court-tag`, `status-pill` de `payment_status`, `reservation_name`, roster editable (sin `confirmation_status` para `origin: manual`), mensaje "Todavía no cargaste el roster" si vacío (UX-DR8), sin bloquear nada relacionado a pago.
    - [x] `turnos/index.html.erb`: la `card-turno` debe enlazar a `turno_path(turno)`.
    - [x] `CardTurnoComponent`: `reservee_name` → `turno.reservation_name`; `roster_summary` → reflejar `turno.roster_entries.size`.

- [x] **Task 5: Testing y Validación** (AC: 1, 2, 3, 4, 5)
    - [x] Tests unitarios `RosterEntry` y `Turno` (uniqueness, presence, nested attributes).
    - [x] Tests de `TurnoPolicy`.
    - [x] Tests de integración `TurnosController` (new/create/show/update + caso AC5 de conflicto).
    - [x] Tests de `CardTurnoComponent` actualizados.
    - [x] Correr suite completa (`bin/rails test`) y confirmar 0 failures/errors antes de marcar `review`.

## 📝 Dev Agent Record
### Implementation Plan
- Migraciones: agregar `reservation_name` + índice único `(cancha_id, start_time)` a `turnos`; crear `roster_entries`.
- Modelos: `RosterEntry` (enums `role`/`confirmation_status`, `validates :name, presence: true`); `Turno` con `has_many :roster_entries`, `accepts_nested_attributes_for`, validaciones de `reservation_name` y unicidad de slot.
- `TurnoPolicy`: acceso habilitado para Dueño y Empleado (cualquier usuario con `complejo`).
- Rutas: `resources :turnos, only: [:new, :create, :show, :update]` reemplazando el placeholder de 2.1.
- `TurnosController`: implementadas `new`/`create`/`show`/`update` reusando `set_complejo`/`parse_date`.
- Vistas `turnos/new.html.erb` y `turnos/show.html.erb` (página completa, patrón `canchas/new`/`edit`), con `fields_for :roster_entries`.
- `CardTurnoComponent`: `reservee_name`/`roster_summary` reales + tarjeta envuelta en `link_to turno_path(@turno)` (cumple el requisito de enlace de `turnos/index.html.erb` sin tocar esa vista directamente).

### Debug Log
- 2026-06-12: Task 1 completada. Migraciones + modelos `RosterEntry`/`Turno` actualizados. Ajustado `reject_if` de `:all_blank` a `proc { |attrs| attrs["name"].blank? }` porque `:all_blank` no descartaba filas vacías que incluían `position` (deviation documentada).
- 2026-06-12: Task 2 completada. `TurnoPolicy` creada y testeada (Dueño y Empleado autorizados).
- 2026-06-12: Task 3 completada. Rutas reemplazadas y `TurnosController` con `new`/`create`/`show`/`update`.
- 2026-06-12: Task 4 completada. Vistas `new`/`show` creadas; `CardTurnoComponent` actualizado con datos reales y enlace a Detalle de Turno.
- 2026-06-12: Task 5 completada. Tests de modelos, policy, controlador y componente agregados/actualizados. `bin/rails test` → 97 runs, 285 assertions, 0 failures, 0 errors, 0 skips.

### Completion Notes
- AC1-AC5 implementadas. AC2 "Payment en estado Pendiente" satisfecho reutilizando `Turno#payment_status` (default `pending`), sin crear modelo `Payment` (alcance de Story 3.x según decisión documentada en Dev Notes).
- `RosterEntry` creado como modelo minimal con `name` denormalizado (sin `Player`/`ComplexPlayer`), `confirmation_status`/`role` presentes para compatibilidad futura con Epic 5 pero no expuestos en la UI de Turnos manuales (UX-DR4).
- AC5 resuelto vía índice único `(cancha_id, start_time)` + `validates :start_time, uniqueness: { scope: :cancha_id }`; el controlador re-renderiza `:new` con `:unprocessable_entity` ante conflicto.
- "Nuevo Turno"/"Detalle de Turno" implementados como páginas completas (no sheet/modal) — deferred, ver nota en Dev Notes sobre la interacción sheet/modal de la UX.
- `bin/rubocop` ejecutado sobre archivos modificados: 1 offense pre-existente (Story 2.1, `turnos_controller.rb:14`, `SpaceInsideArrayLiteralBrackets`), no introducida por esta historia — no corregida, fuera de alcance.

## 📂 File List
- `db/migrate/20260612193732_add_reservation_name_and_unique_slot_index_to_turnos.rb`
- `db/migrate/20260612194835_create_roster_entries.rb`
- `db/schema.rb`
- `app/models/turno.rb`
- `app/models/roster_entry.rb`
- `app/policies/turno_policy.rb`
- `config/routes.rb`
- `app/controllers/turnos_controller.rb`
- `app/views/turnos/new.html.erb`
- `app/views/turnos/show.html.erb`
- `app/components/card_turno_component.rb`
- `app/components/card_turno_component.html.erb`
- `test/models/turno_test.rb`
- `test/models/roster_entry_test.rb`
- `test/policies/turno_policy_test.rb`
- `test/controllers/turnos_controller_test.rb`
- `test/components/card_turno_component_test.rb`
- `test/fixtures/roster_entries.yml`

## 📜 Change Log
- 2026-06-12: Creación del story file (bmad-create-story).
- 2026-06-12: Implementación completa. Status -> review.

## 📊 Story Completion Status
- **Analysis:** Ultimate context engine analysis completada (epics, architecture, UX mockups/EXPERIENCE, story 2.1 y su Dev/Review record, schema actual).
- **Status:** done

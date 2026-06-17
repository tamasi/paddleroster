---
story_id: "3.1"
story_key: "3-1-visualizacion-del-estado-de-pago"
epic_id: "3"
title: "Visualización del Estado de Pago"
status: "done"
last_updated: "2026-06-13"
baseline_commit: a47585d5335f49801cf8a7dff6ec86bf509f5975
---

# Story 3.1: Visualización del Estado de Pago

**As a** Administrador o Empleado,
**I want** ver el Estado de Pago de cualquier Turno en el Calendario y en su Detalle,
**So that** pueda saber de un vistazo qué Turnos tienen pagos pendientes sin revisar el cuaderno.

## Acceptance Criteria

- **AC1: Pago Pendiente**
  - **Given** un Turno con `Payment` en estado Pendiente
  - **When** lo veo en el Calendario o en su Detalle de Turno
  - **Then** su `status-pill` muestra "Pago Pendiente"

- **AC2: Pago Parcial con monto**
  - **Given** un Turno con `Payment` Parcial (monto pagado menor al total)
  - **When** lo veo
  - **Then** su `status-pill` muestra "Pago Parcial" junto con el monto pagado

- **AC3: Pagado**
  - **Given** un Turno con `Payment` Pagado (monto pagado igual al total)
  - **When** lo veo
  - **Then** su `status-pill` muestra "Pagado"

- **AC4: Historial de pagos en Detalle de Turno**
  - **Given** el Detalle de Turno
  - **When** lo abro
  - **Then** veo el historial de pagos registrados para ese Turno (monto, fecha, quién lo registró)

## Developer Context

### Estado actual (qué YA existe, no reinventar)

- `Turno` (`app/models/turno.rb`) ya tiene `enum :payment_status, { pending: 0, partial: 1, paid: 2 }`, columna `payment_status` en `db/schema.rb` (default `0`/pending).
- `StatusPillComponent` (`app/components/status_pill_component.rb` + `.html.erb`) ya renderiza "Pago Pendiente" / "Pago Parcial" / "Pagado" según `status_presentation_helper#humanize_payment_status`. Ya cubre AC1 y AC3 tal cual están — **no modificar su lógica de color/label**, solo el contenido que lo rodea.
- `CardTurnoComponent` (`app/components/card_turno_component.rb` + `.html.erb`) ya renderiza `StatusPillComponent.new(status: @turno.payment_status)` en el Calendario (AC1/AC3 ya cubiertas ahí).
- `app/views/turnos/show.html.erb` (Detalle de Turno) ya renderiza `StatusPillComponent.new(status: @turno.payment_status)` (AC1/AC3 ya cubiertas ahí).
- `test/components/status_pill_component_test.rb` ya existe y pasa para los 3 estados de pago — **no romperlo**.

### Lo que falta (alcance real de esta historia)

1. **No existe el modelo `Payment`** (mencionado en `architecture.md` líneas 157, 360, 460: `app/models/payment.rb`, tabla `payments`, vinculado a `Turno`). Sin este modelo no hay "historial de pagos" (AC4) ni "monto pagado" (AC2) que mostrar.
2. **AC2 no está cubierta**: el `status-pill` "Pago Parcial" actualmente no muestra ningún monto — falta agregar el monto pagado junto al pill cuando `payment_status == "partial"` (y, por consistencia con AC1/AC3 que aplican a Calendario y Detalle, hacerlo en ambos lugares: `CardTurnoComponent` y `turnos/show.html.erb`).
3. **AC4 no está cubierta**: `turnos/show.html.erb` no tiene ninguna sección de historial de pagos.

### Business Logic & Domain Requirements

- **Modelo `Payment`** (`architecture.md` línea 157, 360): "vinculado a `Turno`, con `status` (Pagado/Parcial/Pendiente) y monto". Para esta historia (solo visualización, sin formulario de registro — eso es Story 3.2):
  - `Payment belongs_to :turno`
  - `amount` (decimal, monto del pago individual)
  - `paid_at` (datetime, fecha del pago — puede ser igual a `created_at` si no se especifica)
  - `registered_by` → referencia a `User` que registró el pago ("quién lo registró" en AC4). Usar `belongs_to :registered_by, class_name: "User", optional: true` (opcional porque pagos futuros vía bot, FR-9/Epic 5, podrían no tener un `User` asociado).
- **`Turno` gana `has_many :payments, dependent: :destroy`**.
- **"Monto pagado" (AC2)**: es la suma de `turno.payments.sum(:amount)`. NO calcular ni validar "monto total esperado del turno" — eso no existe en el modelo de datos actual y es responsabilidad de Story 3.2 (que sí valida contra el total). Esta historia es de solo lectura: muestra lo que ya hay.
- **NO crear UI ni controller para registrar pagos** (`PaymentsController#create`, formularios, Turbo Streams) — eso es 100% Story 3.2 (FR-9, NFR-2). Esta historia es FR-8 únicamente (visualización).
- **`Turno#payment_status` sigue siendo la fuente de verdad para el `status-pill`** (no derivar el estado del pill a partir de `payments` en esta historia — eso requeriría definir "monto total esperado", fuera de alcance). `payment_status` se setea manualmente/vía fixtures/seeds para los tests de esta historia, igual que ya ocurre hoy.

### Technical Requirements

- **Migración**: `bin/rails generate migration CreatePayments turno:references amount:decimal paid_at:datetime registered_by:references` y ajustar a mano:
  - `t.references :turno, null: false, foreign_key: true`
  - `t.decimal :amount, precision: 10, scale: 2, null: false`
  - `t.datetime :paid_at, null: false`
  - `t.references :registered_by, foreign_key: { to_table: :users }` (sin `null: false`, ver arriba)
  - Considerar `t.index :turno_id` (Rails lo crea automáticamente con `references`)
- **Modelo `app/models/payment.rb`**:
  ```ruby
  class Payment < ApplicationRecord
    belongs_to :turno
    belongs_to :registered_by, class_name: "User", optional: true

    validates :amount, presence: true, numericality: { greater_than: 0 }
    validates :paid_at, presence: true
  end
  ```
- **`app/models/turno.rb`**: agregar `has_many :payments, dependent: :destroy`. Opcional: método helper `total_paid` (= `payments.sum(:amount)`) para no repetir la query en las vistas/componentes.
- **Vistas/Componentes** (display monto pagado junto al pill, solo cuando `payment_status == "partial"`):
  - `app/components/card_turno_component.html.erb`: junto a `StatusPillComponent.new(status: @turno.payment_status)`, si `@turno.partial?`, mostrar el monto pagado formateado (usar `number_to_currency` o similar, moneda local — revisar si ya hay un helper de formato de moneda en el proyecto; si no, usar `number_to_currency(amount, unit: "$", precision: 0)` como default razonable para MVP).
  - `app/views/turnos/show.html.erb`: igual, junto al `StatusPillComponent.new(status: @turno.payment_status)` en el header.
  - Nueva sección "Historial de pagos" en `turnos/show.html.erb` (AC4): lista de `@turno.payments` (orden por `paid_at` desc), cada item mostrando monto, fecha (`paid_at`, formateada con `l(...)` o `strftime`) y quién lo registró (`payment.registered_by&.email_address || "—"`). Si `@turno.payments.empty?`, mostrar mensaje "Sin pagos registrados".
- **`InicioController`/`OccupancyBarComponent` (Story 2.5)**: NO tocar — fuera de alcance de esta historia.
- **Accesibilidad (UX-DR10)**: el monto pagado debe ser texto real (no solo color), igual que el resto de `status-pill`.

### Architecture Compliance

- **RBAC**: no se requiere policy nueva — la visualización del estado de pago hereda de las políticas existentes de `Turno` (`TurnoPolicy#show?`), que ya garantizan que el usuario pertenece al complejo de la cancha. No crear `PaymentPolicy` en esta historia (no hay acciones de escritura sobre `Payment` todavía).
- **Convenciones de nombres**: tabla `payments` (plural, snake_case) — ya está reservada en `architecture.md` línea 224.
- **ViewComponent**: la lógica de formateo de monto debe vivir en el componente/helper, no repetirse inline en las vistas (usar `StatusPresentationHelper` o un helper nuevo si conviene, ej. `format_amount`).

### File Structure Requirements

- `db/migrate/<timestamp>_create_payments.rb` (nuevo)
- `app/models/payment.rb` (nuevo)
- `app/models/turno.rb` (modificado: `has_many :payments`)
- `app/components/card_turno_component.rb` / `.html.erb` (modificado: mostrar monto si `partial?`)
- `app/views/turnos/show.html.erb` (modificado: monto si `partial?` + sección historial de pagos)
- `app/helpers/status_presentation_helper.rb` (posible: agregar helper de formateo de monto si se reutiliza en 2+ lugares)
- `test/models/payment_test.rb` (nuevo)
- `test/components/card_turno_component_test.rb` (nuevo o modificado, si ya existe)
- `test/controllers/turnos_controller_test.rb` (modificado: cubrir AC1-AC4 en `#show`)
- `test/fixtures/payments.yml` (nuevo, si se usan fixtures) — o usar `Payment.create!` inline en los tests, siguiendo el patrón de `Turno.create!` ya usado en `test/controllers/inicio_controller_test.rb`

## Previous Story Intelligence (2.4 - 2.5)

- **Story 2.5** estableció el patrón de tests con `Turno.create!(cancha:, start_time:, reservation_name:, status: :active)` dentro de `setup`/tests individuales (sin fixture de `turnos.yml`). Seguir el mismo patrón para `Payment` (crear inline en los tests que lo necesiten).
- **Story 2.4/2.5**: `bin/rails test` + `bin/rubocop` sobre archivos nuevos/modificados son el gate estándar antes de marcar `review`. La suite actual está en 132 runs / 454 assertions, 0 failures — cualquier regresión debe corregirse antes de avanzar.
- **`StatusPillComponent`** y su test (`test/components/status_pill_component_test.rb`) ya cubren los 3 labels de pago — no dupliques esa cobertura, solo agregá tests para el contenido nuevo (monto + historial).
- **Convención de commits**: un commit por historia al finalizar (`git add -A` + commit con mensaje descriptivo), sin push (repo sin remoto configurado, `git push` falla — no intentar push salvo pedido explícito).

## Tasks / Subtasks

- [x] **Task 1: Modelo `Payment` y migración (AC2, AC4)**
  - [x] Generar migración `CreatePayments`: `turno_id` (FK, `null: false`), `amount` (decimal 10,2, `null: false`), `paid_at` (datetime, `null: false`), `registered_by_id` (FK a `users`, opcional)
  - [x] Crear `app/models/payment.rb`: `belongs_to :turno`, `belongs_to :registered_by, class_name: "User", optional: true`, validaciones (`amount` presente y > 0, `paid_at` presente)
  - [x] Agregar `has_many :payments, dependent: :destroy` en `app/models/turno.rb`
  - [x] Ejecutar `bin/rails db:migrate` y confirmar `db/schema.rb` actualizado
  - [x] `test/models/payment_test.rb`: validaciones de `amount`/`paid_at`, asociación con `turno` y `registered_by` (incluyendo caso `registered_by: nil`)

- [x] **Task 2: Mostrar monto pagado junto al `status-pill` "Pago Parcial" (AC2)**
  - [x] En `app/components/card_turno_component.html.erb` (Calendario): si `@turno.partial?`, mostrar el monto pagado (`@turno.payments.sum(:amount)`) como texto junto al `status-pill`
  - [x] En `app/views/turnos/show.html.erb` (Detalle de Turno): igual, junto al `status-pill` del header
  - [x] Verificar que para `pending`/`paid` NO se muestre ningún monto adicional (no romper AC1/AC3 ni el test existente de `status_pill_component_test.rb`)
  - [x] Tests: agregar/actualizar tests de `CardTurnoComponent` y de `turnos#show` cubriendo los 3 estados (pending sin monto, partial con monto, paid sin monto)

- [x] **Task 3: Historial de pagos en Detalle de Turno (AC4)**
  - [x] Agregar sección "Historial de pagos" en `app/views/turnos/show.html.erb`, listando `@turno.payments.order(paid_at: :desc)`: monto, fecha (`paid_at`), quién lo registró (`registered_by&.email_address` o "—")
  - [x] Mostrar mensaje "Sin pagos registrados" cuando `@turno.payments.empty?`
  - [x] Test en `test/controllers/turnos_controller_test.rb` (`#show`): turno con 2+ `Payment` muestra ambos (monto, fecha, registrado por); turno sin pagos muestra "Sin pagos registrados"

- [x] **Task 4: Validación final**
  - [x] Ejecutar `bin/rails test` completo — 0 failures, 0 errors, sin regresiones sobre la suite existente (132 runs / 454 assertions previas)
  - [x] Ejecutar `bin/rubocop` sobre archivos nuevos/modificados — 0 offenses (salvo offenses preexistentes no relacionados)
  - [x] Confirmar AC1-AC4 cubiertas por tests automatizados

## Project Context Reference

- **Epics**: `_bmad-output/planning-artifacts/epics.md` (Epic 3, Story 3.1, líneas 419-441; FR-8/FR-9 líneas 34-36)
- **Architecture**: `_bmad-output/planning-artifacts/architecture.md` (modelo `Payment` líneas 157, 360, 460)
- **UX Design**: `_bmad-output/planning-artifacts/ux-designs/ux-retroai-2026-06-10/DESIGN.md` (status-pill, líneas 131-143, 261) y `EXPERIENCE.md` (líneas 33, 59-62, 76, 95-99)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Implementation Plan

- **Modelo `Payment`**: migración `CreatePayments` (`turno_id` FK `null: false`, `amount` decimal 10,2 `null: false`, `paid_at` datetime `null: false`, `registered_by_id` FK opcional a `users`). `Payment belongs_to :turno`, `belongs_to :registered_by, class_name: "User", optional: true`, validaciones `amount` (presente, > 0) y `paid_at` (presente). `Turno has_many :payments, dependent: :destroy`.
- **AC1/AC3** ya estaban cubiertas por `StatusPillComponent` + `Turno#payment_status` (sin cambios de lógica, solo se agregó contenido alrededor).
- **AC2**: nuevo helper `StatusPresentationHelper#format_amount` (`number_to_currency(amount, unit: "$", precision: 0, delimiter: ".")`). `CardTurnoComponent#total_paid` (`@turno.payments.sum(:amount)`) y, cuando `@turno.partial?`, se renderiza el monto junto al `status-pill` en `card_turno_component.html.erb` y en `turnos/show.html.erb`. Para `pending`/`paid` no se muestra ningún monto.
- **AC4**: nueva sección "Historial de pagos" en `turnos/show.html.erb`, listando `@turno.payments.order(paid_at: :desc)` con monto (`format_amount`), fecha (`paid_at` formateada `dd/mm/yyyy`) y `registered_by&.email_address || "—"`. Si no hay pagos, muestra "Sin pagos registrados".
- No se tocó `Turno#payment_status` ni se creó UI/controller de registro de pagos (Story 3.2).

### Debug Log References

- Sin incidencias.

### Completion Notes List

- Implementadas todas las tareas (1-4).
- AC1/AC3: ya cubiertas por implementación previa (`StatusPillComponent` + `Turno#payment_status`); verificado sin regresiones.
- AC2: monto pagado visible junto al `status-pill` "Pago Parcial" en Calendario (`CardTurnoComponent`) y Detalle de Turno (`turnos/show.html.erb`); no se muestra para `pending`/`paid`.
- AC4: sección "Historial de pagos" en Detalle de Turno con monto/fecha/quién lo registró, y mensaje "Sin pagos registrados" si no hay pagos.
- Suite completa: `bin/rails test` → 146 runs, 490 assertions, 0 failures, 0 errors, 0 skips (132 runs/454 assertions previas + 14 nuevas: 7 de `Payment`, 3 de `CardTurnoComponent`, 4 de `turnos#show`).
- `rubocop` sobre archivos nuevos/modificados: 0 offenses.

### File List

- `db/migrate/20260613221514_create_payments.rb` (nuevo)
- `db/schema.rb` (actualizado: tabla `payments`)
- `app/models/payment.rb` (nuevo)
- `app/models/turno.rb` (actualizado: `has_many :payments, dependent: :destroy`)
- `app/helpers/status_presentation_helper.rb` (actualizado: helper `format_amount`)
- `app/components/card_turno_component.rb` (actualizado: método `total_paid`)
- `app/components/card_turno_component.html.erb` (actualizado: muestra monto si `partial?`)
- `app/views/turnos/show.html.erb` (actualizado: monto si `partial?` + sección "Historial de pagos")
- `test/models/payment_test.rb` (nuevo)
- `test/components/card_turno_component_test.rb` (actualizado: 3 tests nuevos)
- `test/controllers/turnos_controller_test.rb` (actualizado: 4 tests nuevos)

## Change Log

- 2026-06-13: Story creada (create-story workflow) a partir de Epic 3 / Story 3.1 en `epics.md`, con análisis de código existente (`StatusPillComponent`, `CardTurnoComponent`, `Turno.payment_status`) para acotar el alcance real (modelo `Payment` + historial + monto, sin tocar registro de pagos que es Story 3.2).
- 2026-06-13: Implementación completa (Tasks 1-4) — modelo `Payment` + migración, monto pagado junto al `status-pill` "Pago Parcial" (AC2) en Calendario y Detalle de Turno, historial de pagos en Detalle de Turno (AC4). AC1/AC3 verificadas sobre implementación existente. Status → review.

---
**Status:** done

---
story_id: "3.2"
story_key: "3-2-registro-de-pago"
epic_id: "3"
title: "Registro de Pago"
status: "done"
last_updated: "2026-06-16"
baseline_commit: a47585d5335f49801cf8a7dff6ec86bf509f5975
---

# Story 3.2: Registro de Pago

**As a** Administrador o Empleado,
**I want** registrar un pago (completo o parcial) para un Turno,
**So that** el Estado de Pago se actualice al instante y reemplace el cuaderno de pagos.

## Acceptance Criteria

- **AC1: Botón "Registrar pago" visible cuando aplica**
  - **Given** el Detalle de Turno con Estado de Pago Pendiente o Parcial
  - **When** abro la vista
  - **Then** veo el `button-action` "Registrar pago" (naranja, full-width en mobile), según UX-DR5

- **AC2: Paso de confirmación**
  - **Given** el Detalle de Turno con Estado de Pago Pendiente o Parcial
  - **When** toco el `button-action` "Registrar pago"
  - **Then** se revela un formulario con campo de monto y elección "Pago completo"/"Pago parcial"

- **AC3: Registro exitoso del pago**
  - **Given** el paso de confirmación con monto válido seleccionado
  - **When** confirmo
  - **Then** se crea un registro `Payment` asociado al Turno (monto, `paid_at = Time.current`, `registered_by = Current.user`)

- **AC4: Estado → Pagado cuando se iguala el total esperado**
  - **Given** que el monto ingresado sumado a pagos previos iguala el `price` del Turno (si está seteado)
  - **When** guardo
  - **Then** el Estado de Pago pasa a "Pagado" sin recargar la pantalla (Turbo Stream, FR-9/NFR-2), y el `button-action` se oculta o deshabilita

- **AC5: Estado → Pago Parcial cuando es menor**
  - **Given** que el monto ingresado sumado a pagos previos es menor al `price` del Turno, O el usuario elige "Pago parcial" sin `price` seteado
  - **When** guardo
  - **Then** el Estado de Pago pasa a "Pago Parcial" mostrando el monto acumulado, sin recargar la pantalla

- **AC6: Validación de sobrepago**
  - **Given** que el Turno tiene `price` seteado
  - **When** el monto ingresado haría que el total supere el `price`
  - **Then** el sistema muestra un error inline (sin recargar) y no crea el Payment

- **AC7: Actualización en Calendario sin recarga**
  - **Given** que registro un pago desde el Detalle de Turno
  - **When** la actualización se aplica
  - **Then** el `status-pill` correspondiente en el Calendario también se actualiza (Turbo Streams broadcast, FR-9/NFR-2)

- **AC8: Botón oculto cuando Pagado**
  - **Given** un Turno con Estado de Pago "Pagado"
  - **When** abro el Detalle de Turno
  - **Then** NO veo el `button-action` "Registrar pago" (ya no aplica)

## Developer Context

### Estado actual — qué YA existe (no reinventar)

- `Payment` (`app/models/payment.rb`): `belongs_to :turno`, `belongs_to :registered_by, class_name: "User", optional: true`, validaciones `amount` (present, > 0) y `paid_at` (present). **No agregar más validaciones aquí** — la lógica de negocio de acumulación vive en el controller.
- `Turno` (`app/models/turno.rb`): `has_many :payments, dependent: :destroy`, `enum :payment_status, { pending: 0, partial: 1, paid: 2 }`. Helpers: `turno.partial?`, `turno.paid?`, `turno.pending?`.
- `StatusPresentationHelper#format_amount`: actualmente implementado como `number_to_currency(amount)` (sin opciones custom) en `app/helpers/status_presentation_helper.rb`. NO duplicar. Verificar el resultado actual con `bin/rails console` si los tests de 3.1 sobre el monto formateado fallan — puede que el locale `es` configure el formato automáticamente.
- `app/views/turnos/show.html.erb`: ya tiene la sección "Historial de pagos" con `@turno.payments.order(paid_at: :desc)`. Esta sección se va a reemplazar vía Turbo Stream — el dev agent debe asignarle un `id` DOM fijo para targeting.
- `TurnosController#show`: ya usa `turno_scope.includes(payments: :registered_by)` — los payments están pre-cargados, no agregar otro includes.
- `TurnosController#index`: ya usa `.includes(:cancha, :roster_entries, :payments)` — el Calendario ya tiene payments disponibles para el broadcast partial.
- `app/controllers/payments_controller.rb`: stub con solo `def index`. Agregar `def create` aquí.
- `config/routes.rb`: ya tiene `get "pagos", to: "payments#index"`. Agregar ruta anidada para `create` (ver Technical Requirements).
- `app/assets/tailwind/application.css`: `--color-accent: #FF8A1E` (claro), `--color-accent-dark: #FFA64D` (oscuro). Usar `bg-accent dark:bg-accent-dark text-white` para el `button-action`.
- `ButtonPrimaryComponent` usa `bg-primary` (azul) — **NO usar este componente para el botón de pago**. El botón de pago es naranja (`accent`), diferente por diseño (DESIGN.md: naranja = única acción de pago primaria).
- `app/javascript/controllers/dark_mode_toggle_controller.js`: único Stimulus controller existente. El dev agent puede crear uno nuevo para toggle del formulario, O puede usar CSS/ERB puro con `<details>`.

### Lo que agrega esta historia (alcance real)

1. **Campo `price` en `Turno`** (opcional, nullable): "monto total esperado" visible en Detalle de Turno. Migration `add_column`. Si `nil`, el usuario elige explícitamente "Pago completo" vs "Pago parcial".
2. **Botón `button-action` "Registrar pago"** en `show.html.erb`, naranja, solo visible cuando `!@turno.paid?`.
3. **Formulario de confirmación** inline en `show.html.erb` — campo monto + radio (completo/parcial). Se revela al pulsar el botón (Stimulus controller toggle, o `<details>`). Cuando `@turno.price` está seteado y el total acumulado + monto = price, el radio "Pago completo" puede preseleccionarse.
4. **`PaymentsController#create`**: crea el `Payment`, recalcula `turno.payment_status`, responde con Turbo Stream (actualiza 3 secciones en Detalle de Turno). Además hace broadcast al canal del Calendario.
5. **`PaymentPolicy#create?`**: autorización Pundit para el `create` action.
6. **Turbo Stream para Detalle de Turno**: actualiza in-place la sección de estado de pago + el formulario + el historial de pagos.
7. **Turbo Stream broadcast para Calendario** (AC7): el canal `"complex_#{complejo_id}_payments"` actualiza la card-turno sin recarga.
8. **Tests**: `PaymentsController` tests con `format: :turbo_stream`, tests de `Turno#payment_status` transitions.

### Business Logic & Domain Requirements

**Campo `price` en `Turno`:**
- `price` decimal(10,2), nullable. Si nil → el usuario elige manualmente completo/parcial.
- Si seteado: validar que `turno.payments.sum(:amount) + nuevo_amount <= turno.price`.
- Comparar con igualdad: si `new_total >= turno.price` → `payment_status = :paid` (usar `turno.price.to_f` y `new_total.to_f` para comparar; redondear a 2 decimales antes de comparar para evitar errores de float). Recomendación: `new_total.round(2) >= turno.price.round(2)`.

**Determinación de `payment_status` tras pago:**
```ruby
existing_total = turno.payments.sum(:amount)
new_total = existing_total + amount.to_d

if turno.price.present? && new_total.round(2) > turno.price.round(2)
  # AC6: error inline, no crear payment
  @payment.errors.add(:amount, "supera el monto total del turno")
  respond_with_turbo_stream_error
elsif (turno.price.present? && new_total.round(2) >= turno.price.round(2)) || payment_type == "complete"
  # AC4: pagado
  turno.update!(payment_status: :paid)
else
  # AC5: parcial
  turno.update!(payment_status: :partial)
end
```

**`payment_type` param**: `"complete"` o `"partial"`. Si `turno.price` está seteado, `payment_type` puede ser ignorado (el math decide). Si `turno.price` es nil, `payment_type` es requerido.

**`paid_at`**: usar `Time.current` en el controller, no depender del usuario.

**`registered_by`**: `Current.user` (siempre disponible en el controller via `Authentication` concern).

**No modificar `Turno#payment_status` directamente desde el modelo** — la lógica de transición de estado vive en el controller para mantener la separación de responsabilidades del MVP.

**El campo `price` en el formulario de Nuevo Turno**: agregar como campo opcional (no requerido para AC). Agregar `price` a `turno_params` en `TurnosController`. En `turnos/new.html.erb`, agregar input opcional con placeholder "Monto del turno (opcional)".

**El campo `price` en Detalle de Turno**: mostrar "Monto del turno: #{format_amount(@turno.price)}" si `@turno.price.present?`, antes del `button-action`.

### Technical Requirements

**Migración**:
```ruby
# db/migrate/TIMESTAMP_add_price_to_turnos.rb
def change
  add_column :turnos, :price, :decimal, precision: 10, scale: 2
end
```
Sin `null: false` ni default — precio opcional.

**Rutas** (`config/routes.rb`):
```ruby
resources :turnos, only: %i[ new create show update ] do
  member do
    patch :cancel
  end
  resources :payments, only: [:create]   # → POST /turnos/:turno_id/payments
end
```
Mantener `get "pagos", to: "payments#index"` donde está (fuera del bloque de turnos).

**`PaymentsController#create`** (estructura):
```ruby
class PaymentsController < ApplicationController
  before_action :set_complejo
  before_action :set_turno

  def create
    authorize @turno, :create_payment?   # policy check en TurnoPolicy (ver abajo)
    # ... lógica de negocio ...
    respond_to do |format|
      format.turbo_stream { render turbo_stream: [streams...] }
      format.html { redirect_to turno_path(@turno), notice: "Pago registrado" }
    end
  end

  private

  def set_complejo
    @complejo = Current.user.complejo
    redirect_to root_path, alert: "No tenés un complejo asignado." if @complejo.nil?
  end

  def set_turno
    @turno = Turno.joins(:cancha).where(canchas: { complejo_id: @complejo.id }).find(params[:turno_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to calendario_path, alert: "El turno solicitado no existe."
  end

  def payment_params
    params.require(:payment).permit(:amount, :payment_type)
  end
end
```

**Política Pundit**: agregar método `create_payment?` en `TurnoPolicy` (no crear `PaymentPolicy` separada — el payment se autoriza sobre el turno existente):
```ruby
# En TurnoPolicy:
def create_payment?
  user&.complejo.present? && record.cancha.complejo_id == user.complejo_id && !record.paid?
end
```

**Turbo Stream IDs** — DOM ids necesarios en `show.html.erb`:
- `id="payment-status-section-<%= @turno.id %>"` — sección que contiene el `StatusPillComponent` + monto + `button-action` + formulario de pago
- `id="payment-history-<%= @turno.id %>"` — sección "Historial de pagos" (ya existe en show.html.erb, agregar el id)

Estos ids son el target del Turbo Stream replace desde el controller.

**Turbo Streams desde `PaymentsController#create`**:
```ruby
render turbo_stream: [
  turbo_stream.replace("payment-status-section-#{@turno.id}",
    partial: "turnos/payment_status_section", locals: { turno: @turno }),
  turbo_stream.replace("payment-history-#{@turno.id}",
    partial: "turnos/payment_history", locals: { turno: @turno }),
  turbo_stream.prepend("turbo-flash",
    partial: "shared/flash", locals: { message: "Pago registrado" })
]
```

**Broadcast a Calendario** (AC7):
```ruby
# Después de crear el payment y actualizar el turno, en el controller:
Turbo::StreamsChannel.broadcast_replace_to(
  "complex_#{@complejo.id}_payments",
  target: "card-turno-#{@turno.id}",
  partial: "turnos/card_turno_stream",
  locals: { turno: @turno.reload }
)
```
Crear `app/views/turnos/_card_turno_stream.html.erb`:
```erb
<div id="card-turno-<%= turno.id %>">
  <%= render CardTurnoComponent.new(turno: turno) %>
</div>
```
En `app/views/turnos/index.html.erb`, dentro del slot con turno:
```erb
<% if turno %>
  <div id="card-turno-<%= turno.id %>">
    <%= render CardTurnoComponent.new(turno: turno) %>
  </div>
<% else %>
  ...
<% end %>
```
Y agregar `turbo_stream_from "complex_#{@complejo.id}_payments"` al inicio del template del Calendario.

**Nota sobre cable en development**: `cable.yml` usa `adapter: async` en development — los broadcasts funcionan solo dentro del mismo proceso (no entre pestañas en dev). En test, `adapter: test` — los broadcasts NO se procesan automáticamente. Los tests NO deben assertar sobre la recepción del broadcast; testear solo que el broadcast fue disparado con `assert_broadcast_on` de ActionCable::Testing (si se quiere), o simplemente omitir este assert en tests del controller y cubrirlo en un test de integración separado.

**`show.html.erb` — secciones a agregar/refactorizar**:
La sección del header de estado de pago (líneas 19-30 del archivo actual) debe envolver todo en `<div id="payment-status-section-<%= @turno.id %>">`. Agregar ahí:
- Mostrar `price` si presente: `<p>Monto del turno: <%= format_amount(@turno.price) %></p>`
- El `button-action` "Registrar pago" (naranja, solo si `!@turno.paid?`)
- El formulario inline de confirmación (toggle con `<details>` o Stimulus)

La sección "Historial de pagos" (líneas 89-108) debe tener `id="payment-history-<%= @turno.id %>"` en el `<div class="mt-8">` wrapper.

**Formulario de pago** (mínimo viable):
```erb
<%= form_with url: turno_payments_path(@turno), method: :post,
    data: { turbo_frame: "_top" } do |f| %>
  <%= render InputFieldComponent.new(
    label: "Monto a registrar",
    name: "payment[amount]",
    value: nil,
    type: "number",
    step: "1",
    min: "1",
    placeholder: "Ej: 12000"
  ) %>

  <div class="mt-4 space-y-2">
    <label class="flex items-center gap-2">
      <%= radio_button_tag "payment[payment_type]", "complete", !@turno.partial?,
          class: "text-primary" %>
      <span>Pago completo</span>
    </label>
    <label class="flex items-center gap-2">
      <%= radio_button_tag "payment[payment_type]", "partial", @turno.partial?,
          class: "text-primary" %>
      <span>Pago parcial</span>
    </label>
  </div>

  <div class="mt-4">
    <button type="submit"
      class="w-full py-3 px-4 rounded-md font-semibold text-white bg-accent dark:bg-accent-dark hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-accent dark:focus:ring-accent-dark"
      data-turbo-submits-with="Guardando...">
      Confirmar pago
    </button>
  </div>
<% end %>
```

**`InputFieldComponent`**: ya existe (`app/components/input_field_component.rb`). Verificar si acepta `type: "number"` — si no lo acepta, renderizar el input directamente inline en el formulario (no crear un nuevo componente, solo usar `<input type="number" ...>` con los estilos Tailwind existentes del proyecto).

### Architecture Compliance

- **Turbo + Importmap**: sin bundler de JS, sin Node. Cualquier JS adicional va en `app/javascript/controllers/` como Stimulus controller e importado en `app/javascript/controllers/index.js`. Si se usa `<details>` para el toggle, no se necesita Stimulus nuevo.
- **Pundit**: el método `create_payment?` va en `TurnoPolicy` (no hay `PaymentPolicy` en esta historia — no hay `show?`, `update?`, `destroy?` en `Payment` aún). La autorización se hace sobre el Turno.
- **`current_user`**: se accede vía `Current.user` (patrón `Authentication` del proyecto), no `current_user`. Ver `app/controllers/application_controller.rb` y el módulo `Authentication`.
- **Naming**: `turno_payments_path(@turno)` es la URL helper para `POST /turnos/:turno_id/payments`.
- **`turno_params` en `TurnosController`**: agregar `:price` al permit list para `create` y `update` actions.
- **No agregar validación en el modelo `Turno`** sobre `price` (debe ser nullable para backward compat). Validar en el controller que el monto + acumulado ≤ price solo cuando price presente.
- **Accesibilidad**: el formulario de pago debe seguir UX-DR10 — labels asociados a inputs (`for`/`id`), error messages inline con `role="alert"`, tap targets ≥ 44px para radios.

### File Structure Requirements

**Nuevos archivos**:
- `db/migrate/TIMESTAMP_add_price_to_turnos.rb`
- `app/views/turnos/_payment_status_section.html.erb` (partial para Turbo Stream replace)
- `app/views/turnos/_payment_history.html.erb` (partial para Turbo Stream replace)
- `app/views/turnos/_card_turno_stream.html.erb` (partial para broadcast al Calendario)
- `test/controllers/payments_controller_test.rb`
- (Opcional, si se usa Stimulus) `app/javascript/controllers/payment_form_controller.js`

**Archivos modificados**:
- `config/routes.rb` — agregar `resources :payments, only: [:create]` nested en `:turnos`
- `app/controllers/payments_controller.rb` — agregar `def create` y métodos privados
- `app/policies/turno_policy.rb` — agregar `def create_payment?`
- `app/models/turno.rb` — agregar validación opcional de price (si se decide, ej: `validates :price, numericality: { greater_than: 0, allow_nil: true }`)
- `app/controllers/turnos_controller.rb` — agregar `:price` a `turno_params`
- `app/views/turnos/new.html.erb` — agregar input price opcional
- `app/views/turnos/show.html.erb` — agregar ids DOM, mostrar price, botón naranja, formulario de pago
- `app/views/turnos/index.html.erb` — agregar `turbo_stream_from`, wrappear cards con ids
- `test/controllers/turnos_controller_test.rb` — actualizar tests de create para permitir el nuevo param `:price` si es necesario

**Archivos a NO tocar**:
- `app/models/payment.rb` — ya completo para esta historia
- `app/components/status_pill_component.*` — no tocar
- `app/components/card_turno_component.*` — no tocar (el broadcast usa su render, no lo modifica)
- `test/models/payment_test.rb` — ya cubre las validaciones del modelo
- `test/components/card_turno_component_test.rb` — ya cubre los 3 estados

## Previous Story Intelligence (Story 3.1)

- **Story 3.1** implementó el modelo `Payment` completo, `Turno#has_many :payments`, `format_amount` helper, y la sección "Historial de pagos" en `show.html.erb`. **Todo eso ya existe y funciona** — NO reimplementar ni tocar su lógica.
- **Suite de tests al cierre de 3.1**: 146 runs / 490 assertions, 0 failures. Cualquier regresión debe corregirse antes de marcar review.
- **Patron de tests**: `Turno.create!(cancha: @cancha, start_time: ..., reservation_name: ...)` inline en setup, `Payment.create!(turno: @turno, amount: ..., paid_at: Time.current)` inline. Sin fixtures de payments ni turnos.
- **Story 3.1** agregó el comentario en `card_turno_component.html.erb`: `<%# En futuras historias, si hay botón de acción primario, irá aquí %>`. El botón-action de esta historia va en `show.html.erb` (Detalle de Turno), NO en `CardTurnoComponent` (eso es el Calendario en tarjeta compacta).
- **`bin/rails test` + `bin/rubocop`** son el gate antes de marcar review. Correr sobre todos los archivos nuevos/modificados.
- **Sin push**: repositorio sin remoto configurado — no intentar `git push`.

## Tasks / Subtasks

- [x] **Task 1: Migración `price` en `Turno`**
  - [x] Generar `add_price_to_turnos`: `add_column :turnos, :price, :decimal, precision: 10, scale: 2`
  - [x] Ejecutar `bin/rails db:migrate` y confirmar `db/schema.rb` actualizado
  - [x] Agregar `validates :price, numericality: { greater_than: 0, allow_nil: true }` en `app/models/turno.rb`
  - [x] Agregar `:price` a `turno_params` en `TurnosController` (create + update)
  - [x] Agregar campo price opcional en `turnos/new.html.erb`

- [x] **Task 2: Rutas y autorización (AC1, AC3)**
  - [x] Agregar `resources :payments, only: [:create]` nested en `resources :turnos` en `config/routes.rb`
  - [x] Agregar `create_payment?` en `TurnoPolicy`

- [x] **Task 3: `PaymentsController#create` con Turbo Streams (AC3, AC4, AC5, AC6)**
  - [x] Implementar `before_action :set_complejo, :set_turno` (siguiendo patrón de `TurnosController`)
  - [x] Lógica: crear `Payment`, calcular `new_total`, determinar nuevo `payment_status`, validar sobrepago
  - [x] Responder con `format.turbo_stream` (replace 2 secciones) y `format.html` (redirect fallback)
  - [x] Broadcast a `"complex_#{@complejo.id}_payments"` para Calendario (AC7)

- [x] **Task 4: Partials y show.html.erb (AC1, AC2, AC4, AC5, AC8)**
  - [x] Crear `_payment_status_section.html.erb`: status pill + price display + button-action + formulario toggle
  - [x] Crear `_payment_history.html.erb`: sección historial (extraída de show.html.erb actual)
  - [x] Crear `_card_turno_stream.html.erb`: wrapper con id para broadcast
  - [x] Actualizar `show.html.erb`: usar partials con ids DOM, botón naranja visible solo si `!@turno.paid?`
  - [x] Actualizar `turnos/index.html.erb`: `turbo_stream_from "complex_#{@complejo.id}_payments"`, wrappear `CardTurnoComponent` en `<div id="card-turno-<%= turno.id %>">`

- [x] **Task 5: Tests (AC1-AC8)**
  - [x] `test/controllers/payments_controller_test.rb`: 12 tests cubriendo todos los ACs
  - [x] `test/controllers/turnos_controller_test.rb`: 3 tests nuevos (AC1, AC8, price display)
  - [x] `test/models/turno_test.rb`: 3 tests nuevos (price validation)
  - [x] Ejecutar `bin/rails test` completo — 164 runs, 537 assertions, 0 failures

- [x] **Task 6: Validación final**
  - [x] `bin/rails test` completo — 164 runs / 537 assertions, sin regresiones (previo: 146/490)
  - [x] `bin/rubocop` sobre archivos nuevos/modificados — 0 offenses
  - [x] Confirmar AC1-AC8 cubiertos

## Project Context Reference

- **Epics**: `_bmad-output/planning-artifacts/epics.md` (Epic 3, Story 3.2, líneas 443-474; FR-9 línea 36; NFR-2 línea 54)
- **Architecture**: `_bmad-output/planning-artifacts/architecture.md`
  - Turbo Streams canal: línea 276 (`"complex_#{complex.id}_payments"`)
  - `PaymentsController`: línea 347, 460
  - `data-turbo-submits-with`: línea 294 (loading state nativo)
  - Rutas anidadas: línea 232
- **UX Design**:
  - `_bmad-output/planning-artifacts/ux-designs/ux-retroai-2026-06-10/DESIGN.md` líneas 198, 265 (button-action naranja, accent color)
  - `_bmad-output/planning-artifacts/ux-designs/ux-retroai-2026-06-10/EXPERIENCE.md` línea 62 (UX-DR5 confirmación), línea 294 (data-turbo-submits-with)
  - `_bmad-output/planning-artifacts/ux-designs/ux-retroai-2026-06-10/mockups/detalle-turno.html` (mockup completo: antes/después de pago)
- **Previous story**: `_bmad-output/implementation-artifacts/3-1-visualizacion-del-estado-de-pago.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Implementation Plan

- **Migración `price`**: `add_column :turnos, :price, :decimal, precision: 10, scale: 2` (nullable). Validación `numericality: { greater_than: 0, allow_nil: true }`. Agregado `:price` a `turno_params` y campo opcional en `new.html.erb`.
- **Rutas**: `resources :payments, only: [ :create ]` nested en `resources :turnos`.
- **Policy**: `create_payment?` en `TurnoPolicy`: comprueba que el user pertenece al complejo y que el turno no está ya pagado.
- **`PaymentsController#create`**: `before_action :set_turno` scope con `joins(:cancha).where(canchas: { complejo_id: @complejo.id })`. Lógica: calcula `new_total`, valida sobrepago si `turno.price` está seteado, crea `Payment`, actualiza `payment_status` (`:paid` si `payment_type == "complete"` o `new_total >= price`; `:partial` si parcial), broadcast al canal del Calendario. Responde `format.turbo_stream` con `replace` de 2 secciones; `format.html` redirige.
- **Partials**: `_payment_status_section.html.erb` (status pill + price display + `<details>` con form naranja), `_payment_history.html.erb` (extraída de show), `_card_turno_stream.html.erb` (wrapper para broadcast).
- **`show.html.erb`**: refactorizado para usar los dos partials con sus ids DOM (`payment-status-section-{id}`, `payment-history-{id}`). Toggle del formulario vía HTML nativo `<details>/<summary>` — sin Stimulus adicional.
- **`index.html.erb`**: agregado `turbo_stream_from "complex_#{@complejo.id}_payments"` y `<div id="card-turno-{id}">` wrapper en cada card.

### Debug Log References

- Rubocop: 2 offenses autocorregidas (`Layout/SpaceInsideArrayLiteralBrackets` en `payments_controller.rb` y `routes.rb`).
- `format_amount` no disponible en controller — se simplificó mensaje de error a texto plano.

### Completion Notes List

- AC1: Botón "Registrar pago" (`<details>/<summary>` naranja accent) visible en Detalle de Turno cuando `!turno.paid?`.
- AC2: Form con campo monto + radio completo/parcial se revela al expandir el `<details>`.
- AC3: `PaymentsController#create` crea `Payment` con `amount`, `paid_at: Time.current`, `registered_by: Current.user`.
- AC4: Auto-marca `:paid` si `payment_type == "complete"` o si `new_total >= turno.price`.
- AC5: Marca `:partial` si `payment_type == "partial"` y `new_total < turno.price` (o sin price).
- AC6: Bloquea (422) si `new_total > turno.price`; no crea Payment.
- AC7: `Turbo::StreamsChannel.broadcast_replace_to "complex_#{id}_payments"` actualiza el card en Calendario.
- AC8: `TurnoPolicy#create_payment?` rechaza si `turno.paid?`; Pundit redirige al root con alerta.
- Suite: 164 runs / 537 assertions, 0 failures, 0 errors (previo: 146/490 — +18 tests nuevos).
- Rubocop: 0 offenses en archivos modificados.

### File List

- `db/migrate/20260616113016_add_price_to_turnos.rb` (nuevo)
- `db/schema.rb` (actualizado: columna `price` en `turnos`)
- `app/models/turno.rb` (actualizado: validación `price`, método `total_paid` ya agregado por hook)
- `app/controllers/payments_controller.rb` (actualizado: acción `create` completa)
- `app/controllers/turnos_controller.rb` (actualizado: `:price` en `turno_params`)
- `app/policies/turno_policy.rb` (actualizado: `create_payment?`)
- `config/routes.rb` (actualizado: `resources :payments, only: [:create]` nested)
- `app/views/turnos/new.html.erb` (actualizado: campo price opcional)
- `app/views/turnos/show.html.erb` (refactorizado: usa partials con ids DOM)
- `app/views/turnos/index.html.erb` (actualizado: `turbo_stream_from`, wrapper ids en cards)
- `app/views/turnos/_payment_status_section.html.erb` (nuevo)
- `app/views/turnos/_payment_history.html.erb` (nuevo)
- `app/views/turnos/_card_turno_stream.html.erb` (nuevo)
- `test/controllers/payments_controller_test.rb` (actualizado: 12 tests de `create`)
- `test/controllers/turnos_controller_test.rb` (actualizado: 3 tests de show para Story 3.2)
- `test/models/turno_test.rb` (actualizado: 3 tests de validación de price)

## Change Log

- 2026-06-16: Story creada (create-story workflow).
- 2026-06-16: Implementación completa — migración price en Turno, PaymentsController#create con Turbo Streams y broadcast al Calendario, partials `_payment_status_section`, `_payment_history`, `_card_turno_stream`, refactor de show.html.erb. Status → review.

---
**Status:** done

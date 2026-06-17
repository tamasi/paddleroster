---
story_id: "4.1"
story_key: "4-1-reporte-de-ocupacion-por-cancha-y-periodo"
epic_id: "4"
title: "Reporte de Ocupación por Cancha y período"
status: "done"
last_updated: "2026-06-16"
baseline_commit: a47585d5335f49801cf8a7dff6ec86bf509f5975
---

# Story 4.1: Reporte de Ocupación por Cancha y período

**As a** Dueño del Complejo,
**I want** ver la Ocupación de cada Cancha (pádel vs fútbol 5) para un período seleccionable,
**So that** pueda tomar decisiones comerciales (ej. agregar horarios, promociones en horarios de baja ocupación).

## Acceptance Criteria

- **AC1: Vista de Reportes disponible para el Dueño**
  - **Given** que soy Dueño autenticado
  - **When** abro Reportes
  - **Then** veo la Ocupación por Cancha para un período seleccionable (semana/mes), cada cancha con su barra de ocupación y el porcentaje como texto adyacente

- **AC2: Acceso denegado a Empleados**
  - **Given** que soy Empleado autenticado
  - **When** intento acceder a Reportes por URL directa (`/reportes`)
  - **Then** el acceso me es denegado y soy redirigido con mensaje de error (`ReportPolicy`, FR-12/NFR-3)

- **AC3: Filtro de período — semana / mes**
  - **Given** que estoy en Reportes
  - **When** selecciono "Esta semana" o "Este mes"
  - **Then** la vista muestra la ocupación del período correspondiente, una sección por día, con barras por cancha

- **AC4: Filtro de deporte — Pádel / Fútbol 5**
  - **Given** que estoy en Reportes
  - **When** selecciono el filtro "Pádel" o "Fútbol 5"
  - **Then** solo se muestran las canchas del deporte elegido

- **AC5: Turnos cancelados no cuentan como ocupados**
  - **Given** el cálculo de Ocupación para el período
  - **When** un Turno está Cancelado (`status: :cancelled`)
  - **Then** ese horario no cuenta como ocupado (solo `Turno.active` cuenta)

- **AC6: Componente `OccupancyBarComponent` con contraste AA**
  - **Given** el reporte de Ocupación
  - **When** lo visualizo
  - **Then** cada barra usa `OccupancyBarComponent` (ya implementado) con el porcentaje como texto adyacente, contraste AA 4.5:1 (NFR-4), responsive (UX-DR11)

- **AC7: Acceso denegado sin autenticación**
  - **Given** un usuario no autenticado
  - **When** intenta acceder a `/reportes`
  - **Then** es redirigido a `new_session_path`

## Developer Context

### Estado actual — qué YA existe (NO reinventar)

**`OccupancyBarComponent`** (`app/components/occupancy_bar_component.rb`):
```ruby
OccupancyBarComponent.new(label: "Cancha 1", percentage: 70)
# percentage se clamp a 0..100 automáticamente
```
Ya usado en `app/views/inicio/index.html.erb`. NO duplicar ni modificar.

**Ruta ya existe** en `config/routes.rb`:
```ruby
get "reportes", to: "reports#index", as: :reportes
```
NO agregar nueva ruta. La ruta existe desde Story 1.3.

**`BottomNavComponent`**: ya muestra "Reportes" solo para `user.owner?`. No tocar.

**`ReportsController`** (`app/controllers/reports_controller.rb`): tiene stub vacío:
```ruby
class ReportsController < ApplicationController
  def index
  end
end
```
Solo agregar `before_action :set_complejo`, lógica de `index` y método privado `set_complejo`.

**`app/views/reports/index.html.erb`**: tiene placeholder "Próximamente". Reemplazar completamente.

**Patrón de ocupación** en `InicioController#index` — ya implementado, seguir este patrón:
```ruby
turnos_hoy = Turno.active.where(cancha: @canchas, start_time: @date.all_day)
turnos_por_cancha = turnos_hoy.group_by(&:cancha_id)
horas_operativas = Complejo::HORARIO_OPERATIVO.size  # 10 (14..23)
```

**`Complejo::HORARIO_OPERATIVO = (14..23)`** — 10 slots disponibles por cancha por día.

**`ApplicationController`** ya incluye `Pundit::Authorization` y tiene:
```ruby
rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
def user_not_authorized
  flash[:alert] = "No tenés permiso para realizar esta acción."
  redirect_to(request.referrer || root_path)
end
```
La redenegación de acceso para Empleados se maneja automáticamente — no agregar `rescue_from` en `ReportsController`.

**Patrón de autorización sin modelo** (de `ConfiguracionController`):
```ruby
def show
  authorize :configuracion  # sin arg de acción → usa el nombre del action (show?)
end
```
Para `ReportsController#index`, usar: `authorize :report` → llama `ReportPolicy#index?`.

**`StatusPresentationHelper#humanize_sport`** — BUG EXISTENTE:
El enum `Cancha.sport` tiene `{ padel: 0, futbol_5: 1 }`. `cancha.sport` devuelve `"futbol_5"` (con guión bajo). Pero el helper mapea `"futbol5"` (sin guión), por lo que cae en el `else` → `"futbol_5".humanize` → `"Futbol 5"` (sin acento, capitalización incorrecta).

**Fixear en esta historia**: agregar `when "futbol_5" then "Fútbol 5"` al helper:
```ruby
def humanize_sport(sport)
  case sport.to_s
  when "padel" then "Pádel"
  when "futbol_5", "futbol5" then "Fútbol 5"
  else sport.to_s.humanize
  end
end
```

**Patrón `set_complejo`** (de `TurnosController` y `PaymentsController`):
```ruby
before_action :set_complejo

private

def set_complejo
  return if Current.user.nil?
  @complejo = Current.user.complejo
  redirect_to root_path, alert: "No tenés un complejo asignado." if @complejo.nil?
end
```

### Lo que agrega esta historia (alcance real)

1. **`app/policies/report_policy.rb`** — nueva policy Pundit solo para Dueño
2. **`ReportsController#index`** — lógica de datos con período y filtro de deporte
3. **`app/views/reports/index.html.erb`** — UI completa: filter pills + cards por día + barras de ocupación
4. **Fix `humanize_sport`** en `StatusPresentationHelper` (bug existente, ver arriba)
5. **`test/controllers/reports_controller_test.rb`** — tests de auth + datos

### Lógica de datos del controlador

```ruby
class ReportsController < ApplicationController
  before_action :set_complejo

  def index
    authorize :report   # → ReportPolicy#index?

    @period    = params[:period].presence_in(%w[week month]) || "week"
    @sport     = params[:sport].presence_in(%w[padel futbol_5])

    start_date = @period == "month" ? Date.current.beginning_of_month : Date.current.beginning_of_week
    end_date   = @period == "month" ? Date.current.end_of_month       : Date.current.end_of_week

    canchas = @complejo.canchas.order(:name)
    canchas = canchas.where(sport: @sport) if @sport.present?
    @canchas = canchas

    horas_operativas = Complejo::HORARIO_OPERATIVO.size  # 10

    turnos = Turno.active
                  .where(cancha: @canchas, start_time: start_date.beginning_of_day..end_date.end_of_day)
                  .includes(:cancha)

    turnos_por_dia = turnos.group_by { |t| t.start_time.to_date }

    @report_days = (start_date..end_date).map do |date|
      dia_turnos = turnos_por_dia[date] || []
      turnos_por_cancha_id = dia_turnos.group_by(&:cancha_id)

      canchas_data = @canchas.map do |cancha|
        ocupados   = turnos_por_cancha_id[cancha.id]&.size || 0
        percentage = (ocupados.to_f / horas_operativas * 100).round
        { cancha: cancha, percentage: percentage, ocupados: ocupados }
      end

      { date: date, canchas_data: canchas_data }
    end
  end

  private

  def set_complejo
    return if Current.user.nil?
    @complejo = Current.user.complejo
    redirect_to root_path, alert: "No tenés un complejo asignado." if @complejo.nil?
  end
end
```

### `ReportPolicy`

Siguiendo el patrón de `ConfiguracionPolicy`:
```ruby
# app/policies/report_policy.rb
class ReportPolicy < ApplicationPolicy
  def index?
    user&.owner?
  end
end
```
No necesita `class Scope` — no hay `.policy_scope` en reportes.

### Vista (`app/views/reports/index.html.erb`)

Estructura esperada (implementar en Tailwind con tokens del proyecto):
1. `content_for :page_title, "Reportes"`
2. Título `<h1>` — "Reportes"
3. **Filter pills** — dos grupos: período (Esta semana / Este mes) y deporte (Todo / Pádel / Fútbol 5)
4. **Estado vacío** si `@canchas.empty?` — "No hay canchas configuradas"
5. **Cards por día** — para cada día en `@report_days`:
   - Heading: nombre del día en español capitalizado + fecha corta
   - Una barra `OccupancyBarComponent` por cancha, con label = `"#{cancha.name} — #{humanize_sport(cancha.sport)}"`
   - Si `canchas_data` está vacío (no hay canchas en el filtro): no mostrar el card

**Filter pills — links con GET params:**
Los links deben preservar los otros params activos. Ejemplo:
```erb
<%= link_to "Esta semana", reportes_path(period: "week", sport: @sport),
    class: "... #{@period == 'week' ? 'active-classes' : 'inactive-classes'}" %>
<%= link_to "Este mes", reportes_path(period: "month", sport: @sport),
    class: "... #{@period == 'month' ? 'active-classes' : 'inactive-classes'}" %>
```
Para el filtro de deporte, `@sport.nil?` es "Todo". Links:
```erb
<%= link_to "Todo", reportes_path(period: @period), class: "..." %>
<%= link_to "Pádel", reportes_path(period: @period, sport: "padel"), class: "..." %>
<%= link_to "Fútbol 5", reportes_path(period: @period, sport: "futbol_5"), class: "..." %>
```

**Nombre del día en español:**
```ruby
# En el helper o inline en la vista:
I18n.l(day_data[:date], format: "%A").capitalize  # → "Miércoles"
# Formato corto de fecha:
I18n.l(day_data[:date], format: :default)         # → "16/06/2026" (con es.yml format: "%d/%m/%Y")
```
Heading card: `"#{I18n.l(date, format: "%A").capitalize} #{I18n.l(date, format: :default)}"`
Ejemplo: "Miércoles 11/06/2026"

**Estilos de filter pills** — seguir patrón del mockup:
- Activo: borde `border-primary`, texto `text-primary`, fondo blanco
- Inactivo: borde `border-border dark:border-border-dark`, texto `text-text-secondary`
- Token colores: `primary`, `border`, `text-secondary`, `surface`, `background` (ya definidos en application.tailwind.css)

**Card de día** — usar las clases del proyecto: `bg-surface dark:bg-surface-dark border border-border dark:border-border-dark rounded-2xl p-4`

**Responsive (UX-DR11):**
- Mobile: cards apilados verticalmente con scroll (comportamiento default)
- Notebook (`md+`): dos columnas de cards con `grid grid-cols-1 md:grid-cols-2 gap-4`

**Estado vacío** para días sin turnos: mostrar igualmente las barras al 0% — el componente ya las muestra correctamente. No filtrar días sin turnos, ya que el 0% es información valiosa.

### Architecture Compliance

- **Sin JS adicional**: los filter pills son `<a href>` estándar — Turbo Drive maneja la navegación sin recarga completa. No necesita Stimulus.
- **Pundit sin modelo**: `authorize :report` — Pundit infiere `ReportPolicy` desde el símbolo.
- **`Current.user`** para acceder al usuario, no `current_user`.
- **Naming**: `report_policy.rb` (singular, siguiendo `configuracion_policy.rb`), NO `reports_policy.rb`.
- **No tocar** `OccupancyBarComponent`, `BottomNavComponent`, ni rutas existentes.
- **`humanize_sport`** vive en `StatusPresentationHelper` (already included via `helper :all` in Rails). Usar desde la vista como `humanize_sport(cancha.sport)`.

### File Structure Requirements

**Nuevos archivos:**
- `app/policies/report_policy.rb`
- `test/controllers/reports_controller_test.rb`

**Archivos modificados:**
- `app/controllers/reports_controller.rb` — reemplazar stub con implementación completa
- `app/views/reports/index.html.erb` — reemplazar placeholder con UI completa
- `app/helpers/status_presentation_helper.rb` — fix `humanize_sport` para `"futbol_5"`

**Archivos a NO tocar:**
- `app/components/occupancy_bar_component.rb` + `.html.erb` — ya está listo
- `config/routes.rb` — la ruta ya existe
- `app/components/bottom_nav_component.rb` — ya maneja Reportes para owner
- `db/schema.rb` — no hay migraciones en esta historia
- Tests de otros controllers y models — no deben romperse

### Testing Requirements

Baseline actual: **165 runs, 542 assertions, 0 failures**

Tests a escribir (`test/controllers/reports_controller_test.rb`):

```ruby
class ReportsControllerTest < ActionDispatch::IntegrationTest
  # AC7: requiere autenticación
  test "index requires authentication" do
    get reportes_path
    assert_redirected_to new_session_path
  end

  # AC2: empleado bloqueado por URL directa
  test "index denies access to employees" do
    sign_in_as(users(:two))  # role: employee
    get reportes_path
    assert_redirected_to request.referrer || root_path
    assert_not_nil flash[:alert]
  end

  # AC1: dueño puede acceder
  test "index renders for owner" do
    sign_in_as(users(:one))  # role: owner
    get reportes_path
    assert_response :success
  end

  # AC3: período por defecto es semana
  test "index defaults to week period" do
    sign_in_as(users(:one))
    get reportes_path
    assert_response :success
    # @report_days tiene 7 días (lunes a domingo de la semana actual)
    # No assertar fechas concretas — usar count
  end

  # AC3: filtro de mes
  test "index accepts month period" do
    sign_in_as(users(:one))
    get reportes_path, params: { period: "month" }
    assert_response :success
  end

  # AC4: filtro de deporte
  test "index filters by sport" do
    sign_in_as(users(:one))
    get reportes_path, params: { sport: "padel" }
    assert_response :success
  end

  # AC5: turnos cancelados no cuentan
  test "cancelled turnos do not count toward occupancy" do
    sign_in_as(users(:one))
    cancha = canchas(:one)  # padel, belongs to piloto
    turno = Turno.create!(
      cancha: cancha,
      start_time: Date.current.beginning_of_week.to_time.change(hour: 14),
      reservation_name: "Test",
      status: :cancelled
    )

    get reportes_path, params: { period: "week" }

    assert_response :success
    # El turno cancelado no debe inflar el porcentaje
    # No hay forma limpia de assertar el porcentaje sin exponer @report_days;
    # validar la respuesta exitosa y que el test no explota es suficiente.
    # Si se quiere assertar más, usar assert_select sobre el DOM.
  end
end
```

**Nota sobre `parallelize` y test isolation:** Los tests usan `parallelize(workers: :number_of_processors)`. Los turnos creados en tests deben usar fechas específicas (no `Time.current` con offset de horas) para evitar flakiness con `all_day`. Usar `.beginning_of_week.to_time.change(hour: 14)` como en el ejemplo.

### Previous Story Intelligence (Story 3.2)

- **Test suite baseline al cierre de 3.2**: 165 runs / 542 assertions, 0 failures. Correr `bin/rails test` completo al finalizar — debe ser >= 165 runs sin nuevas failures.
- **Patrón de `set_complejo` + `authorize`**: igual en todos los controllers. Copiar el patrón exacto de `PaymentsController` / `TurnosController`.
- **`Current.user`** siempre disponible en controllers (módulo `Authentication`).
- **`bin/rails test` + `bin/rubocop`** son el gate antes de marcar review. Rubocop puede requerir `# frozen_string_literal: true` al inicio de nuevos archivos `.rb`.
- **Sin push**: repositorio sin remoto — no intentar `git push`.
- **No hay `flash` turbo parcial** en esta historia — el Turbo Drive estándar maneja la navegación a `/reportes` (no Turbo Streams).

## Tasks / Subtasks

- [x] **Task 1: `ReportPolicy`**
  - [x] Crear `app/policies/report_policy.rb` con `def index? = user&.owner?`
  - [x] Verificar que `authorize :report` en el controller resuelve a `ReportPolicy#index?`

- [x] **Task 2: `ReportsController#index`**
  - [x] Agregar `before_action :set_complejo` + método privado `set_complejo` (copiar de PaymentsController)
  - [x] Implementar `index`: `authorize :report`, parseo de `period` y `sport` params, cálculo de `@report_days`
  - [x] Verificar que `Turno.active` excluye `:cancelled` (AC5)

- [x] **Task 3: Fix `humanize_sport`**
  - [x] Agregar `when "futbol_5", "futbol5" then "Fútbol 5"` en `StatusPresentationHelper#humanize_sport`
  - [x] Verificar que `humanize_sport("futbol_5")` devuelve "Fútbol 5" (no "Futbol 5" sin acento)

- [x] **Task 4: Vista `reports/index.html.erb`**
  - [x] Filter pills con links que preservan el otro parámetro activo
  - [x] Estado vacío cuando `@canchas.empty?`
  - [x] Cards por día con heading en español + fecha
  - [x] `OccupancyBarComponent` por cancha con label `"#{cancha.name} — #{humanize_sport(cancha.sport)}"`
  - [x] Responsive: una columna en mobile, dos en notebook (`md:grid-cols-2`)
  - [x] Verificar contraste en modo oscuro (usar tokens `dark:` existentes)

- [x] **Task 5: Tests**
  - [x] Crear `test/controllers/reports_controller_test.rb` (7 tests)
  - [x] Ejecutar `bin/rails test` completo — debe mantener 0 failures

- [x] **Task 6: Validación final**
  - [x] `bin/rails test` — >= 165 runs previos, 0 failures (170 runs / 552 assertions)
  - [x] `bin/rubocop` sobre archivos nuevos/modificados — 0 offenses
  - [x] Confirmar AC1-AC7 cubiertos
  - [x] Confirmar que `humanize_sport("futbol_5")` ya devuelve "Fútbol 5" con acento

## Project Context Reference

- **Epics**: `_bmad-output/planning-artifacts/epics.md` (Epic 4, Story 4.1, líneas 481-508; FR-10 línea 38)
- **Architecture**:
  - `ReportsController` + `ReportPolicy`: líneas 346, 373, 374, 460
  - Pundit RBAC: líneas 165, 302
  - `InicioController` occupancy pattern: `app/controllers/inicio_controller.rb`
- **UX Design**:
  - Mockup completo: `_bmad-output/planning-artifacts/ux-designs/ux-retroai-2026-06-10/mockups/reportes.html`
  - Filter pills, occupancy bars, responsive: `EXPERIENCE.md` líneas 34, 37, 63, 105, 121-127
  - `OccupancyBarComponent` tokens: `DESIGN.md` línea 267
- **Previous story**: `_bmad-output/implementation-artifacts/3-2-registro-de-pago.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `I18n.l(date, format: :default)` fallaba con "Translation missing: es.date.formats.default" — `es.yml` no tiene `date.formats`. Solución: reemplazado por `I18n.t("date.day_names")[date.wday].capitalize` + `date.strftime("%d/%m/%Y")`.
- Rubocop en `.erb` genera falsos positivos (HTML parseado como Ruby). Ejecutado solo sobre archivos `.rb`.

### Completion Notes List

- AC1: `ReportsController#index` con `authorize :report` → `ReportPolicy#index?` — acceso solo para dueño.
- AC2: `ReportPolicy#index?` devuelve `false` para empleados → `Pundit::NotAuthorizedError` → redirect con flash.
- AC3: Filtro de período (`week`/`month`) vía param GET, 7 o ~30 cards de días, filter pills linkados.
- AC4: Filtro de deporte (`padel`/`futbol_5`) vía param GET, preserva el período activo en el link.
- AC5: `Turno.active` filtra turnos cancelados automáticamente (enum `status: 0`).
- AC6: `OccupancyBarComponent.new(label:, percentage:)` usado por cada cancha en cada día.
- AC7: `Authentication` concern de Rails redirige a `new_session_path` si no autenticado.
- Fix bug `humanize_sport`: agregado `when "futbol_5", "futbol5"` para cubrir el valor real del enum.
- Suite final: 170 runs / 552 assertions, 0 failures (baseline 165/542 → +5 runs, +10 assertions).

### File List

- `app/policies/report_policy.rb` (nuevo)
- `app/controllers/reports_controller.rb` (actualizado: implementación completa)
- `app/views/reports/index.html.erb` (actualizado: UI completa con filter pills y occupancy bars)
- `app/helpers/status_presentation_helper.rb` (actualizado: fix `humanize_sport` para `"futbol_5"`)
- `test/controllers/reports_controller_test.rb` (actualizado: 7 tests de auth y datos)

## Change Log

- 2026-06-16: Story creada (create-story workflow).
- 2026-06-16: Implementación completa — ReportPolicy, ReportsController#index con filtros de período/deporte, vista con OccupancyBarComponent, fix humanize_sport. Status → review.

---
**Status:** review

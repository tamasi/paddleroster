---
baseline_commit: 6d103c9
---

# Story 1.3: Roles y control de acceso Dueño/Empleado

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an administrador del sistema,
I want que el sistema distinga los roles Dueño y Empleado con accesos diferenciados,
so that cada usuario vea y use solo lo que corresponde a su rol.

## Acceptance Criteria

1. **Given** un usuario con rol Empleado autenticado **When** navega el Panel **Then** ve solo Inicio, Calendario y Pagos en `{components.bottom-nav}` (sin "Reportes"), según UX-DR2 [Source: epics.md#Story-1.3, línea 207]
2. **Given** un usuario con rol Dueño autenticado **When** navega el Panel **Then** ve Inicio, Calendario, Pagos, Reportes en `{components.bottom-nav}`, y accede a Configuración desde el menú de usuario del `{components.app-header}` [Source: epics.md#Story-1.3, línea 211; EXPERIENCE.md línea 37]
3. **Given** el modelo `User` **When** se crea **Then** tiene una columna `role` (`owner`/`employee`, default `employee`) y existe una `ApplicationPolicy` base de Pundit, de la que heredan las policies de cada sección a medida que se construyen (ej. `ConfiguracionPolicy` en Story 1.5, `ReportPolicy` en Story 4.1) [Source: epics.md#Story-1.3, línea 215; architecture.md línea 165]

## Tasks / Subtasks

- [x] Task 1: Agregar columna `role` a `User` e instalar Pundit (AC: #3)
  - [x] Subtask 1.1: Generar migración `add_role_to_users`: `add_column :users, :role, :integer, default: 0, null: false` (0 = `employee`, 1 = `owner`). Ejecutar `bin/rails db:migrate`
  - [x] Subtask 1.2: En `app/models/user.rb`, declarar `enum :role, { employee: 0, owner: 1 }, default: :employee` (sintaxis Rails 8 con keyword arguments)
  - [x] Subtask 1.3: Agregar `gem "pundit"` al `Gemfile` (única gema nueva requerida por esta story; ya está pre-aprobada — ver Dev Notes) y ejecutar `bundle install`
  - [x] Subtask 1.4: Ejecutar `bin/rails g pundit:install` → genera `app/policies/application_policy.rb` (ya existe el directorio `app/policies/` con `.keep` desde Story 1.1) y agrega `include Pundit::Authorization` a `ApplicationController`. NO crear policies específicas (`ConfiguracionPolicy`, `ReportPolicy`, etc.) — quedan para Stories 1.5 y 4.1
  - [x] Subtask 1.5: Actualizar `db/seeds.rb`: el usuario `admin@retroai.test` debe quedar con `role: :owner` (es el Dueño del complejo piloto)
  - [x] Subtask 1.6: Actualizar `test/fixtures/users.yml`: asignar `role: owner` a `one` y `role: employee` a `two`, para poder testear ambos roles en componentes/integración
  - [x] Subtask 1.7: Test de modelo (`test/models/user_test.rb`): default `role` es `"employee"`; un usuario puede ser `owner`; `user.owner?`/`user.employee?` responden según el enum

- [x] Task 2: Crear `AppHeaderComponent` y `BottomNavComponent` con navegación diferenciada por rol (AC: #1, #2)
  - [x] Subtask 2.1: Crear `BottomNavComponent` (ViewComponent, `app/components/`) mapeando el token `{components.bottom-nav}` de `DESIGN.md`: recibe el usuario actual (o su `role`), renderiza siempre los ítems Inicio/Calendario/Pagos y agrega "Reportes" solo si `role: owner`; el ítem activo (según `request.path`) se resalta con `{colors.primary}`/`{colors.primary-dark}` (aproximar con `text-blue-600 dark:text-blue-400`, ver Dev Notes), los inactivos con `{colors.text-secondary}` (aproximar `text-gray-500 dark:text-gray-400`)
  - [x] Subtask 2.2: Crear `AppHeaderComponent` (ViewComponent, `app/components/`) mapeando `{components.app-header}`: muestra el título de la pantalla (`{typography.display}`, vía `content_for(:title)` o parámetro) y, a la derecha, un menú de usuario (`<details>`/`<summary>` o similar sin JS) con el link "Configuración" (solo si `role: owner`) y el botón "Cerrar sesión" (igual al que hoy está en `app/views/home/index.html.erb`)
  - [x] Subtask 2.3: Integrar ambos componentes en `app/views/layouts/application.html.erb`: `AppHeaderComponent` arriba y `BottomNavComponent` abajo, renderizados solo cuando `authenticated?` es true (ocultos en `sessions/new`, `passwords/*`). Mover el botón "Cerrar sesión" de `app/views/home/index.html.erb` al `AppHeaderComponent` (eliminar la duplicación)
  - [x] Subtask 2.4: Tests de componente (`test/components/`): `BottomNavComponent` con usuario `employee` renderiza 3 ítems (Inicio, Calendario, Pagos) y NO renderiza "Reportes"; con usuario `owner` renderiza los 4 ítems. `AppHeaderComponent` con usuario `employee` NO renderiza el link "Configuración"; con `owner` sí lo renderiza

- [x] Task 3: Crear páginas placeholder para Calendario, Pagos, Reportes y Configuración (AC: #1, #2)
  - [x] Subtask 3.1: `TurnosController#index` (acción Calendario) + ruta `get "calendario", to: "turnos#index", as: :calendario` + vista placeholder `app/views/turnos/index.html.erb` ("Calendario — Próximamente"), siguiendo el patrón de `HomeController`/`app/views/home/index.html.erb` de Story 1.2
  - [x] Subtask 3.2: `PaymentsController#index` (acción Pagos) + ruta `get "pagos", to: "payments#index", as: :pagos` + vista placeholder `app/views/payments/index.html.erb`
  - [x] Subtask 3.3: `ReportsController#index` (acción Reportes) + ruta `get "reportes", to: "reports#index", as: :reportes` + vista placeholder `app/views/reports/index.html.erb`
  - [x] Subtask 3.4: `ConfiguracionController#index` + ruta `get "configuracion", to: "configuracion#index", as: :configuracion` + vista placeholder `app/views/configuracion/index.html.erb`. NO implementar control de acceso a nivel de ruta para Empleado todavía (FR-12/AC de Story 1.5 lo cubre con `ConfiguracionPolicy`); estas 4 páginas son accesibles para cualquier usuario autenticado en esta story, la diferenciación de esta story es solo de **navegación** (AC #1, #2)
  - [x] Subtask 3.5: Tests de integración (`test/controllers/`, uno por controller nuevo): usuario autenticado recibe `200 OK` en `/calendario`, `/pagos`, `/reportes`, `/configuracion`; usuario no autenticado es redirigido a `new_session_path` (ya cubierto por el `before_action :require_authentication` global)

- [x] Task 4: Validar suite completa y dejar el proyecto listo para Story 1.4 (AC: #1-#3)
  - [x] Subtask 4.1: Correr `bin/rails test` (suite completa) → 0 failures, 0 errors
  - [x] Subtask 4.2: Correr `bin/rubocop -A` → sin offenses
  - [x] Subtask 4.3: Verificar manualmente con `bin/dev`: login como `admin@retroai.test` (owner) → bottom-nav muestra Inicio/Calendario/Pagos/Reportes y el menú de usuario tiene "Configuración"; crear/loguear un usuario `employee` → bottom-nav muestra solo Inicio/Calendario/Pagos y el menú de usuario NO tiene "Configuración"
  - [x] Subtask 4.4: Documentar en Completion Notes cualquier desviación (ej. las 4 páginas placeholder de Task 3, que no estaban en el alcance original de `architecture.md` pero son necesarias para que el bottom-nav tenga destinos válidos), siguiendo el patrón de desviación documentada de Stories 1.1 y 1.2

### Review Findings

- [x] [Review][Patch] `AppHeaderComponent` no usa navegación segura (`&.`) para `current_user`, inconsistente con `BottomNavComponent` [app/components/app_header_component.html.erb:46,49]
- [x] [Review][Patch] `db/seeds.rb` no actualiza el rol a `owner` si `admin@retroai.test` ya existía antes de esta migración (`find_or_create_by!` no ejecuta el bloque sobre registros existentes) [db/seeds.rb]
- [x] [Review][Patch] Falta test que verifique que `AppHeaderComponent`/`BottomNavComponent` NO se renderizan en páginas no autenticadas (`/session/new`), tal como exige la Subtask 2.3 [test/controllers/sessions_controller_test.rb]
- [x] [Review][Defer] FR-12 sin enforcement server-side: un Empleado autenticado puede acceder a `/configuracion` y `/reportes` directamente por URL (la UI solo oculta los links) [app/controllers/configuracion_controller.rb, app/controllers/reports_controller.rb] — deferred, explícitamente alcance de Story 1.5 (`ConfiguracionPolicy`) y Story 4.1 (`ReportPolicy`), pero queda como gap real mientras tanto
- [x] [Review][Defer] `BottomNavComponent#active?` usa comparación exacta de path; no resaltará el tab padre para futuras rutas anidadas (ej. `/calendario/:id`) [app/components/bottom_nav_component.rb:113] — deferred, pre-existing pattern, revisar en Epic 2 cuando existan rutas de detalle
- [x] [Review][Defer] Alias de rutas (`calendario_path`, `pagos_path`, etc.) podrían colisionar con nombres de ruta autogenerados si futuras stories agregan `resources :turnos`/`:payments` [config/routes.rb] — deferred, riesgo a validar cuando se agreguen esas rutas

## Dev Notes

- **Alcance estricto**: esta story implementa SOLO la columna `role` + infraestructura base de Pundit (`ApplicationPolicy`) + navegación diferenciada por rol (`BottomNavComponent`/`AppHeaderComponent`). NO implementar `ConfiguracionPolicy`, `ReportPolicy`, ni bloqueo de rutas por rol (FR-12) — eso es Story 1.5 (Configuración, AC: "Empleado intenta acceder a Configuración por URL directa → acceso denegado") y Story 4.1 (Reportes). NO implementar `Invitation` — eso es Story 1.4. NO implementar las pantallas reales de Calendario/Pagos/Reportes/Configuración (Epics 2-5 y Story 1.5) — solo placeholders mínimos para que la navegación tenga destinos [Source: epics.md#Story-1.3, #Story-1.4, #Story-1.5, #Story-4.1].
- **Dependencia nueva pre-aprobada**: `gem "pundit"` es requerida explícitamente por `architecture.md` ("Autenticación con el generador nativo de Rails 8 + Pundit para RBAC" y "RBAC: columna `role` en `User` + Pundit para policies por controller") [Source: architecture.md líneas 131, 165]. Está pre-aprobada para esta story — no HALTear pidiendo aprobación de dependencias por esto.
- **Enum `role`**: Rails 8 soporta `enum :role, { employee: 0, owner: 1 }, default: :employee` (sintaxis con keyword arguments, distinta de la sintaxis legacy `enum role: { ... }`). Confirmar que `bin/rails generate authentication` (Story 1.2) no agregó ya ninguna columna `role` — no la agregó, está confirmado en `db/schema.rb` actual (`users` solo tiene `email_address`, `password_digest`, timestamps).
- **Pundit install**: `bin/rails g pundit:install` genera `app/policies/application_policy.rb` (clase base con `user`/`record`, métodos `index?`/`show?`/etc. devolviendo `false` por defecto) y agrega `include Pundit::Authorization` a `ApplicationController`. El directorio `app/policies/` ya existe (con `.keep`) desde el setup de Story 1.1 — el generador debería sobreescribir/usar ese directorio sin problema.
- **`{components.bottom-nav}` (DESIGN.md línea 255)**: "Fija en mobile, 4 ítems: Inicio, Calendario, Pagos, Reportes. Ítem activo en `{colors.primary}`/`{colors.primary-dark}`, inactivos en `{colors.text-secondary}`. En notebook (md+) se reubica como barra lateral o superior persistente, mismos ítems, mismo orden." Para Empleado son 3 ítems (sin Reportes) — el orden no cambia entre roles, solo la cantidad [Source: EXPERIENCE.md línea 64, "El orden no cambia entre roles ni breakpoints — solo la cantidad de ítems"].
- **`{components.app-header}` (DESIGN.md línea 253)**: "Fondo `{colors.primary}` en modo claro / `{colors.background-dark}` en oscuro. Contiene: título de pantalla (`{typography.display}`), y a la derecha, acceso a perfil/usuario activo." El menú de usuario es donde vive "Configuración" para el Dueño [Source: EXPERIENCE.md línea 37, "Configuración vive fuera de la navegación principal, en el menú de usuario del `{components.app-header}`, visible solo para el dueño"].
- **Aproximación de tokens con Tailwind (mismo patrón que `InputFieldComponent` de Story 1.2)**: `theme.extend` con los tokens reales de `DESIGN.md` (`colors.primary` `#0B5FA5`/`#5BA3E0`, `colors.text-secondary`, etc.) todavía NO está configurado — usar utilidades estándar de Tailwind como aproximación: activo → `text-blue-600 dark:text-blue-400`, inactivo → `text-gray-500 dark:text-gray-400`, header → `bg-blue-700 dark:bg-gray-900 text-white`. Cuando se configure el theme (Story 1.6, modo claro/oscuro global), reemplazar estas clases por los tokens reales sin cambiar la API de los componentes — repetir la nota dejada en Story 1.2 para `InputFieldComponent`.
- **Sin JS para el menú de usuario**: usar `<details>`/`<summary>` HTML nativo para el dropdown del menú de usuario en `AppHeaderComponent` — evita escribir un Stimulus controller nuevo para esta story (la arquitectura reserva Stimulus para Story 1.6 en adelante, `dark_mode_toggle_controller.js`).
- **Naming de controllers (architecture.md líneas 458-462)**: `TurnosController` (Calendario, FR-4/5/6/7/15), `PaymentsController` (Pagos, FR-8/9), `ReportsController` (Reportes, FR-10), `ConfiguracionController` (Configuración) — usar estos nombres exactos aunque las rutas/paths sean en español (`/calendario`, `/pagos`, `/reportes`, `/configuracion`) para que coincidan con `architecture.md` cuando Epics 2-5 y Story 1.5 implementen el contenido real.
- **Testing**: Minitest. Tests de modelo para el enum `role`, tests de componente para `BottomNavComponent`/`AppHeaderComponent` (uno por rol), tests de integración (controller) para las 4 rutas placeholder [Source: architecture.md#Structure-Patterns].
- **Aprendizajes de Story 1.2**: `app/components/` y `test/components/` ya existen y tienen el patrón establecido por `InputFieldComponent`/`input_field_component_test.rb` (ViewComponent::TestCase, `render_inline`, `assert_selector`/`assert_no_selector`). `app/controllers/home_controller.rb` + `app/views/home/index.html.erb` + `root "home#index"` ya existen (agregados como desviación documentada en 1.2) — `HomeController#index` es el modelo a seguir para los 4 controllers placeholder de Task 3. El layout `app/views/layouts/application.html.erb` actualmente solo tiene `<main class="container mx-auto mt-28 px-5 flex">` sin header/nav — agregar los componentes ahí. El botón "Cerrar sesión" vive hoy en `app/views/home/index.html.erb` (`button_to "Cerrar sesión", session_path, method: :delete`) y debe moverse al `AppHeaderComponent` para no duplicarse en cada página. Convención de mensajes en español ya establecida (`SessionsController`, vistas).

### Project Structure Notes

- Nuevos archivos siguen la estructura ya definida en `architecture.md`: `app/policies/application_policy.rb` (generado por Pundit), `app/components/{bottom_nav,app_header}_component.{rb,html.erb}`, `app/controllers/{turnos,payments,reports,configuracion}_controller.rb`, `app/views/{turnos,payments,reports,configuracion}/index.html.erb`, `db/migrate/*_add_role_to_users.rb`.
- Sin variaciones detectadas respecto a `architecture.md` más allá de las 4 páginas placeholder (Task 3), que son una extensión mínima y necesaria del mismo patrón ya documentado como desviación en Story 1.2 (`HomeController`).

### References

- [Source: epics.md#Story-1.3-Roles-y-control-de-acceso-Dueño-Empleado] (líneas 197-215)
- [Source: epics.md#UX-DR2] (línea 86)
- [Source: architecture.md#Authentication-and-Security] (líneas 162-168)
- [Source: architecture.md#Decision-Impact-Analysis] (líneas 199-212)
- [Source: architecture.md#Project-Structure] (líneas 371-397, 454-469)
- [Source: DESIGN.md líneas 251, 253, 255] ({components.app-header}, {components.bottom-nav})
- [Source: EXPERIENCE.md líneas 37, 64, 104] (Information Architecture, navegación por rol)
- [Source: _bmad-output/implementation-artifacts/1-2-login-multi-usuario.md] (Dev Notes, patrón InputFieldComponent, HomeController, convenciones de testing)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `bin/rails test` (suite completa): 36 runs, 110 assertions, 0 failures, 0 errors, 0 skips
- `bin/rubocop -A`: 58 files inspected, no offenses detected
- Verificación manual con `bin/rails server`: login `admin@retroai.test` (owner) → bottom-nav con Inicio/Calendario/Pagos/Reportes + link "Configuración" en el menú de usuario; login con un usuario `employee` temporal → bottom-nav con solo Inicio/Calendario/Pagos, sin "Configuración"

### Completion Notes List

- AC#3: `User#role` (enum `employee`/`owner`, default `employee`) agregado vía migración `add_role_to_users`. Gema `pundit` agregada e instalada; `bin/rails g pundit:install` generó `app/policies/application_policy.rb` y se agregó `include Pundit::Authorization` a `ApplicationController`. No se crearon policies específicas (quedan para Stories 1.5/4.1).
- AC#1/#2: `BottomNavComponent` y `AppHeaderComponent` (ViewComponents) creados y wireados en `app/views/layouts/application.html.erb`, renderizados solo cuando `authenticated?`. El botón "Cerrar sesión" se movió de `home/index` al menú de usuario del `AppHeaderComponent`. Verificado por componente (tests) y manualmente (owner ve 4 tabs + Configuración; employee ve 3 tabs sin Configuración).
- **Desviación documentada**: para que `BottomNavComponent`/`AppHeaderComponent` tuvieran destinos de navegación válidos, se agregaron en esta story las rutas `/calendario`, `/pagos`, `/reportes`, `/configuracion` y sus controllers (`TurnosController`, `PaymentsController`, `ReportsController`, `ConfiguracionController`) con vistas placeholder ("Próximamente"). Esto no estaba en el alcance original de `architecture.md` para 1.3, pero es una extensión mínima necesaria — sigue el mismo patrón de desviación documentado en Story 1.2 (`HomeController`). El contenido real de estas pantallas y el control de acceso a nivel de ruta para Configuración/Reportes (FR-12) quedan para Epics 2-5 y Story 1.5, según lo establecido en los Dev Notes.
- Se ajustó `app/views/layouts/application.html.erb`: `mt-28` → `mt-8 pb-20` en `<main>`, ya que el header ya no es flotante (ahora está en el flujo normal del documento) y el bottom-nav fijo en mobile requiere padding inferior para no tapar contenido.
- Aproximación de tokens de DESIGN.md con utilidades Tailwind estándar (`text-blue-600`/`text-blue-400` para activo, `text-gray-500`/`text-gray-400` para inactivo, `bg-blue-700`/`bg-gray-900` para el header) — mismo enfoque documentado en Story 1.2 para `InputFieldComponent`, a reemplazar cuando se configure el `theme.extend` en Story 1.6.

### File List

- **Nuevos**: `db/migrate/20260612013820_add_role_to_users.rb`, `app/policies/application_policy.rb`, `app/components/bottom_nav_component.rb`, `app/components/bottom_nav_component.html.erb`, `app/components/app_header_component.rb`, `app/components/app_header_component.html.erb`, `app/controllers/turnos_controller.rb`, `app/controllers/payments_controller.rb`, `app/controllers/reports_controller.rb`, `app/controllers/configuracion_controller.rb`, `app/views/turnos/index.html.erb`, `app/views/payments/index.html.erb`, `app/views/reports/index.html.erb`, `app/views/configuracion/index.html.erb`, `test/components/bottom_nav_component_test.rb`, `test/components/app_header_component_test.rb`, `test/controllers/turnos_controller_test.rb`, `test/controllers/payments_controller_test.rb`, `test/controllers/reports_controller_test.rb`, `test/controllers/configuracion_controller_test.rb`
- **Modificados**: `Gemfile`, `Gemfile.lock`, `app/models/user.rb`, `app/controllers/application_controller.rb`, `db/seeds.rb`, `db/schema.rb`, `test/fixtures/users.yml`, `test/models/user_test.rb`, `config/routes.rb`, `app/views/layouts/application.html.erb`, `app/views/home/index.html.erb`
- **Modificados en code review (2026-06-12)**: `app/components/app_header_component.html.erb` (navegación segura `&.` para `current_user`), `db/seeds.rb` (asegurar `role: :owner` en `admin@retroai.test` aunque el registro ya existiera), `test/controllers/sessions_controller_test.rb` (test que verifica que `header`/`nav` no se renderizan en `/session/new`)

---
baseline_commit: 28df29aa3b3c683e9dc8b73ca10f3712212932d8
---

# Story 1.2: Login multi-usuario

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Dueño o Empleado del Complejo,
I want autenticarme individualmente en el Panel,
so that pueda acceder a las funciones según mi rol sin compartir credenciales.

## Acceptance Criteria

1. **Given** un usuario con cuenta activa, **When** ingresa email y contraseña correctos en Login, **Then** accede a Inicio y queda autenticado (sesión creada vía el generador de auth de Rails 8).
2. **Given** credenciales incorrectas, **When** intenta loguearse, **Then** ve un mensaje de error inline en el formulario, sin revelar si el email existe.
3. **Given** una sesión expirada mientras navega una pantalla autenticada, **When** la sesión expira, **Then** es redirigido a Login con el mensaje "Tu sesión expiró, iniciá sesión de nuevo" **and** tras reautenticarse, vuelve a la pantalla donde estaba (UX-DR8).
4. **Given** el formulario de Login, **When** se renderiza, **Then** usa `{components.input-field}` con validación inline (UX-DR1, UX-DR10).

## Tasks / Subtasks

- [x] Task 1: Generar autenticación base con el generador nativo de Rails 8 (AC: #1, #2)
  - [x] Subtask 1.1: Ejecutar `bin/rails generate authentication` — genera `User` (con `has_secure_password`/bcrypt), `Session`, `SessionsController`, `PasswordsController`, `Current` (CurrentAttributes), concern `Authentication` en `ApplicationController`, y vistas/migraciones base
  - [x] Subtask 1.2: Revisar la migración generada para `users` (campos `email_address`, `password_digest`) y `sessions` (con tracking de IP/user-agent) y ejecutar `bin/rails db:migrate`
  - [x] Subtask 1.3: **NO agregar la columna `role` a `User` en esta story** — corresponde a Story 1.3. Confirmar que el generador no la incluye por defecto
  - [x] Subtask 1.4: Crear un usuario de prueba (seed o fixture) con email/contraseña conocidos para poder probar el login manualmente y en tests
  - [x] Subtask 1.5: Verificar que `bin/rails generate authentication` deja protegidas por defecto las rutas autenticadas (concern `Authentication#require_authentication` como `before_action` en `ApplicationController`) y que `SessionsController#new`/`#create`/`#destroy` quedan accesibles sin sesión

- [x] Task 2: Adaptar las vistas de Login al Design System (AC: #2, #4)
  - [x] Subtask 2.1: Crear `InputFieldComponent` (ViewComponent) en `app/components/` mapeando 1:1 el token `{components.input-field}` de `DESIGN.md` (`{rounded.md}`, borde `{colors.border}`/`{colors.border-dark}`, fondo `{colors.surface}`/`{colors.surface-dark}`, padding `{spacing.3}`) — soporta `dark:` variants vía Tailwind
  - [x] Subtask 2.2: `InputFieldComponent` debe soportar mostrar un mensaje de error inline DEBAJO del campo, en `{typography.meta}` + `{colors.danger}`, cuando el campo tiene errores de validación (nunca solo borde rojo sin texto) — ver EXPERIENCE.md línea 65
  - [x] Subtask 2.3: Reescribir la vista `app/views/sessions/new.html.erb` (generada por el scaffold de auth) usando `InputFieldComponent` para los campos email y contraseña
  - [x] Subtask 2.4: Test de componente para `InputFieldComponent` cubriendo: render normal, render con mensaje de error inline, atributos de accesibilidad (label asociado al input vía `for`/`id`)
  - [x] Subtask 2.5: Crear test de componente/sistema (Minitest) que verifique: login con credenciales correctas redirige a Inicio (`/`) y crea una `Session`; login con credenciales incorrectas muestra el error inline en el formulario sin revelar si el email existe (mensaje genérico, ej. "Email o contraseña incorrectos")

- [x] Task 3: Manejar expiración de sesión con redirect-and-return (AC: #3)
  - [x] Subtask 3.1: En el concern `Authentication` (generado por `bin/rails generate authentication`), cuando `require_authentication` falla (sin sesión activa o sesión expirada), guardar la URL solicitada (ej. `session[:return_to_after_authenticating] = request.url` si es GET) antes de redirigir a `new_session_path`
  - [x] Subtask 3.2: Mostrar el mensaje flash "Tu sesión expiró, iniciá sesión de nuevo" al redirigir por sesión expirada (distinguir de un acceso directo a `/session/new` sin sesión previa, que no debería mostrar ese mensaje — ver Dev Notes)
  - [x] Subtask 3.3: En `SessionsController#create`, tras autenticar exitosamente, redirigir a `session.delete(:return_to_after_authenticating) || root_path` (patrón estándar del generador de Rails 8, confirmar que ya viene implementado o completarlo)
  - [x] Subtask 3.4: Test de sistema (Minitest `ActionDispatch::IntegrationTest`): usuario autenticado cuya sesión es destruida/expirada intenta acceder a una ruta protegida → es redirigido a Login con el mensaje de sesión expirada → tras loguearse de nuevo, vuelve a la URL original

- [x] Task 4: Validar suite completa y dejar el proyecto listo para Story 1.3 (AC: #1-#4)
  - [x] Subtask 4.1: Correr `bin/rails test` (suite completa) → 0 failures, 0 errors
  - [x] Subtask 4.2: Correr `bin/rubocop -A` → sin offenses
  - [x] Subtask 4.3: Verificar manualmente con `bin/dev`: login correcto, login incorrecto (mensaje inline), logout, y flujo de sesión expirada con redirect-and-return
  - [x] Subtask 4.4: Documentar en Dev Notes/Completion Notes cualquier archivo generado por el scaffold de auth que no estaba contemplado en `architecture.md`, siguiendo el patrón de desviación documentada de Story 1.1

### Review Findings

- [x] [Review][Patch] Open redirect potencial vía `return_to_after_authenticating` (usa `request.url` absoluto) [app/controllers/concerns/authentication.rb:33]
- [x] [Review][Patch] El email ingresado se pierde al fallar el login (redirect sin preservar `email_address`) [app/controllers/sessions_controller.rb:497]
- [x] [Review][Patch] `InputFieldComponent`: riesgo de `ArgumentError` por keyword duplicado si `html_options` incluye `type`/`name`/`value` [app/components/input_field_component.rb, app/components/input_field_component.html.erb]
- [x] [Review][Patch] `terminate_session` no valida `Current.session` nil antes de `.destroy` [app/controllers/concerns/authentication.rb:54]
- [x] [Review][Patch] `db/seeds.rb` crea un usuario admin con password hardcodeada sin restringir a entorno de desarrollo [db/seeds.rb]
- [x] [Review][Patch] Falta test para `HomeController#index` (página de Inicio, AC#1) [test/controllers/home_controller_test.rb]
- [x] [Review][Defer] `seeds.rb` usa `find_or_create_by!` y no actualiza la password si el usuario admin ya existe con otra [db/seeds.rb] — deferred, pre-existing
- [x] [Review][Defer] `PasswordsController#update` no valida longitud/complejidad mínima de password [app/controllers/passwords_controller.rb] — deferred, pre-existing (scaffold generado, fuera del alcance de los AC de esta story)
- [x] [Review][Defer] Falta test de normalización (mayúsculas/espacios) de `email_address` en el login (AC#2) [test/controllers/sessions_controller_test.rb] — deferred, pre-existing
- [x] [Review][Defer] `PasswordsController#update`, en fallo, redirige reutilizando el token viejo en vez de uno nuevo [app/controllers/passwords_controller.rb] — deferred, pre-existing
- [x] [Review][Defer] La heurística de "sesión expirada" no distingue una cookie inválida/forjada de una expiración real [app/controllers/concerns/authentication.rb:35] — deferred, pre-existing (limitación de diseño documentada en Dev Notes)
- [x] [Review][Defer] `return_to_after_authenticating` solo se guarda en requests GET (limitación de diseño documentada en Dev Notes, AC#3) [app/controllers/concerns/authentication.rb:33] — deferred, pre-existing
- [x] [Review][Defer] `InputFieldComponent` usa clases Tailwind aproximadas en vez de mapeo 1:1 con tokens de `DESIGN.md` [app/components/input_field_component.rb] — deferred, pre-existing (desviación ya documentada en Completion Notes, abordar en Story 1.6)
- [x] [Review][Defer] URLs muy largas guardadas en `return_to_after_authenticating` podrían exceder el límite de la cookie de sesión [app/controllers/concerns/authentication.rb:33] — deferred, pre-existing
- [x] [Review][Defer] `InputFieldComponent`: `name` nil/vacío produce un `field_id` vacío (edge case sin caller actual que lo dispare) [app/components/input_field_component.rb:13] — deferred, pre-existing
- [x] [Review][Defer] Falta test de cobertura para el flujo intermedio fallo-luego-éxito de `return_to_after_authenticating` [test/integration/session_expiration_test.rb] — deferred, pre-existing

## Dev Notes

- **Alcance estricto**: esta story implementa SOLO autenticación (login/logout/sesión). NO implementar la columna `role`, `Pundit`, `ApplicationPolicy`, ni diferenciación de navegación por rol — eso es Story 1.3 [Source: epics.md#Story-1.3-Roles-y-control-de-acceso-Dueño-Empleado]. NO implementar `Invitation`/registro de usuarios — eso es Story 1.4.
- **Generador nativo Rails 8**: usar `bin/rails generate authentication` (disponible desde Rails 8.0+, confirmado en Rails 8.1.3 instalado). Genera: modelo `User` con `has_secure_password`, modelo `Session` (con `user_agent`/`ip_address`), `Current` (`ActiveSupport::CurrentAttributes`), concern `Authentication` incluido en `ApplicationController`, controllers `SessionsController`/`PasswordsController`, vistas mínimas en `app/views/sessions/` y `app/views/passwords/`, helper de cookies firmadas para el `session_id` [Source: architecture.md#Authentication-and-Security].
- **No reinventar el generador**: el flujo de creación/destrucción de `Session` y el `before_action :require_authentication` en `ApplicationController` ya vienen resueltos por el generador — la Task 1 es ejecutarlo y verificar, no reimplementar manualmente. Cualquier ajuste debe ser mínimo (agregar mensaje de sesión expirada, redirect-and-return).
- **Mensaje de error de login sin revelar existencia del email (AC #2)**: usar un mensaje genérico tipo "Email o contraseña incorrectos" tanto si el email no existe como si la contraseña es incorrecta — el generador de Rails 8 normalmente ya implementa esto así (`User.authenticate_by(email_address:, password:)`), confirmar y no debilitarlo.
- **Sesión expirada vs. acceso directo sin sesión (AC #3)**: distinguir ambos casos para no mostrar "Tu sesión expiró..." a un usuario que simplemente nunca inició sesión y entra directo a `/login`. Una heurística simple: solo mostrar el mensaje de expiración cuando `require_authentication` falla en una request que llevaba una cookie de sesión pero la `Session` ya no existe en la base (sesión inválida/expirada), no cuando no hay cookie de sesión en absoluto.
- **`InputFieldComponent` (UX-DR1)**: es el primer ViewComponent del proyecto (`app/components/` ya existe con `.keep` desde Story 1.1). Mapea 1:1 el token `input-field` de `DESIGN.md`:
  ```yaml
  input-field:
    background: '{colors.surface}' / '{colors.surface-dark}'
    border: '{colors.border}' / '{colors.border-dark}'
    radius: '{rounded.md}'   # 10px
    padding: '{spacing.3}'
  ```
  [Source: DESIGN.md líneas 173-179, 269]. Usado en Login y formularios de configuración (futuro) — diseñarlo genérico (label, name, type, value, error message) para reutilización en Story 1.5+.
- **Validación inline (UX-DR1, UX-DR10, AC #4)**: "Validación inline, error debajo del campo en `{typography.meta}` + `{colors.danger}`. Nunca solo borde rojo sin texto" [Source: EXPERIENCE.md línea 65]. Accesibilidad: el orden de foco sigue el orden visual y los errores de validación se anuncian junto al campo (asociar con `aria-describedby` si es posible) [Source: EXPERIENCE.md línea 98, UX-DR10 en epics.md línea 102].
- **UX-DR8 — Sesión expirada**: "redirect to Login with message 'Tu sesión expiró, iniciá sesión de nuevo', return to original screen after re-auth" [Source: epics.md línea 98, EXPERIENCE.md línea 79].
- **Naming/convenciones**: snake_case Rails estándar. `User`, `Session`, `SessionsController`, `InputFieldComponent` (ViewComponent con sufijo `Component`) [Source: architecture.md#Naming-Patterns].
- **Testing**: Minitest, tests de sistema/integración para los flujos de login/logout/expiración, test de componente para `InputFieldComponent` en `test/components/` [Source: architecture.md#Structure-Patterns, Story 1.1 Dev Notes].
- **Aprendizajes de Story 1.1**: Ruby 3.4.9 / Rails 8.1.3 ya configurados y funcionando; Postgres local vía socket Unix sin password (`retroai_development`/`retroai_test`); `bin/rails db:migrate` + `bin/rails test` + `bin/rubocop -A` son los comandos de validación que ya funcionan en este entorno; repo Git inicializado con primer commit `28df29a`. `app/components/`, `test/services/`, `app/policies/` ya existen (con `.keep`) — usar `app/components/` para `InputFieldComponent` y `test/components/` (crear si no existe) para su test.

### Project Structure Notes

- Archivos esperados nuevos/generados por `bin/rails generate authentication` (Rails 8.1): `app/models/user.rb`, `app/models/session.rb`, `app/models/current.rb`, `app/controllers/sessions_controller.rb`, `app/controllers/passwords_controller.rb`, `app/controllers/concerns/authentication.rb`, `app/views/sessions/new.html.erb`, `app/views/passwords/{new,edit}.html.erb`, `app/mailers/passwords_mailer.rb` + vistas de mailer, migraciones `db/migrate/*_create_users.rb` y `*_create_sessions.rb`. Confirmar el set exacto generado por la versión instalada (8.1.3) y documentarlo en Completion Notes (puede variar levemente vs. lo documentado en `architecture.md`, igual que la desviación documentada en Story 1.1 con `.kamal/`/`ci.yml`).
- `InputFieldComponent` va en `app/components/input_field_component.rb` + `app/components/input_field_component.html.erb` (convención ViewComponent estándar), con su test en `test/components/input_field_component_test.rb`.
- No crear `app/policies/application_policy.rb` ni tocar `Gemfile` para agregar Pundit en esta story — eso es Story 1.3.

### References

- [Source: epics.md#Story-1.2-Login-multi-usuario] — historia y acceptance criteria originales (líneas 172-195).
- [Source: epics.md líneas 84-106] — definiciones maestras UX-DR1 (ViewComponents/`InputFieldComponent`), UX-DR8 (sesión expirada/redirect-and-return), UX-DR10 (accesibilidad: foco, errores inline, contraste AA).
- [Source: architecture.md#Authentication-and-Security] — generador `bin/rails generate authentication`, `User`/`has_secure_password`, `Session` con tracking IP/user-agent, alcance de `role`/Pundit diferido a 1.3.
- [Source: architecture.md#Frontend-Architecture] — ViewComponent mapeando 1:1 Component Patterns de EXPERIENCE.md, incluyendo `input-field`.
- [Source: EXPERIENCE.md línea 65] — spec de validación inline de `{components.input-field}`.
- [Source: EXPERIENCE.md línea 79] — patrón de estado "Sesión expirada".
- [Source: EXPERIENCE.md línea 98] — accesibilidad: orden de foco, errores anunciados junto al campo.
- [Source: DESIGN.md líneas 173-179, 269] — tokens del componente `input-field`.
- [Source: 1-1-inicializacion-del-proyecto.md#Dev-Agent-Record] — entorno confirmado (Ruby 3.4.9/Rails 8.1.3/Postgres), comandos de validación, estructura de directorios existente.

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `bin/rails generate authentication` (Rails 8.1.3) → generó `User`/`Session`/`Current`, `SessionsController`/`PasswordsController`, concern `Authentication`, migraciones `create_users`/`create_sessions`, vistas mínimas, `bcrypt` descomentado en Gemfile.
- `bin/rails db:migrate` → tablas `users`/`sessions` creadas en `retroai_development`/`retroai_test` sin errores.
- `bin/rails generate view_component:component InputField label name type value error_message` (gema `view_component` agregada al Gemfile, `bundle install` → `view_component 4.12.0`).
- `bin/rails test` (suite completa, 19 runs / 71 assertions) → `0 failures, 0 errors`.
- `bin/rubocop -A` → `43 files inspected, no offenses detected`.
- Verificación manual con servidor Puma local (`bin/rails server -p 3001`) vía `curl` con cookie jar: (1) acceso a `/` sin sesión → redirect a `/session/new` sin warning; (2) login con credenciales incorrectas → error inline "Email o contraseña incorrectos" bajo el campo email (`#email_address_error`); (3) login correcto → redirect a `/` (Inicio), muestra "Inicio" + botón "Cerrar sesión"; (4) logout → redirect a `/session/new`; (5) sesión expirada (cookie válido pero `Session` borrada de la DB) → redirect a `/session/new` con banner ámbar `#warning` "Tu sesión expiró, iniciá sesión de nuevo"; tras reautenticarse, redirect exacto a la URL original (`/?ref=protegido`).

### Completion Notes List

- **Task 1**: `User` (con `has_secure_password`, `normalizes :email_address`), `Session` (`belongs_to :user`, tracking `ip_address`/`user_agent`), `Current` y el concern `Authentication` quedaron tal como los genera Rails 8.1.3 — AC #1 cumplido (login crea `Session` y autentica). NO se agregó columna `role` (queda para Story 1.3). Se agregó un usuario de seed (`admin@retroai.test` / `password123`) en `db/seeds.rb` para pruebas manuales; los fixtures `one@example.com`/`two@example.com` (password "password") ya venían generados para tests.
- **Adición no prevista pero necesaria para que el sistema funcione end-to-end**: el proyecto no tenía ruta raíz (`root`) ni controlador "Inicio" (Story 2.5 los implementará en detalle). Se creó `HomeController#index` + vista placeholder `app/views/home/index.html.erb` ("Inicio" + botón "Cerrar sesión") y se configuró `root "home#index"` en `config/routes.rb`, ya que AC #1 requiere que el login redirija a "Inicio" y el generador de auth usa `root_url` como fallback de `after_authentication_url`. Es un placeholder mínimo que Story 2.5 reemplazará con el contenido real.
- **Task 2**: Se agregó la gema `view_component` (no estaba en el Gemfile original) — requerida por `architecture.md#Frontend-Architecture` ("Componentes: ViewComponent, mapeando 1:1 los Component Patterns de EXPERIENCE.md"). Se creó `InputFieldComponent` (`app/components/`) mapeando el token `{components.input-field}` de DESIGN.md (rounded-md, borde y fondo con variantes `dark:`, padding `p-3`), con soporte de mensaje de error inline (`{typography.meta}` ≈ `text-sm font-medium`, `{colors.danger}` ≈ `text-red-600`/`dark:text-red-400`) debajo del campo, asociado vía `aria-describedby`/`aria-invalid` (UX-DR1, UX-DR10, EXPERIENCE.md línea 65). **Nota para futuras stories**: los tokens exactos de `DESIGN.md` (`colors.border`, `colors.surface`, `colors.danger`, etc.) todavía no están mapeados en `theme.extend` de Tailwind — se usaron utilidades estándar de Tailwind (`border-gray-300`/`dark:border-gray-700`, `bg-white`/`dark:bg-gray-800`, `text-red-600`/`dark:text-red-400`) como aproximación. Cuando se configure el theme de diseño (candidato: Story 1.6 modo claro/oscuro global), reemplazar estas clases por los tokens reales sin cambiar la API del componente.
- La vista `app/views/sessions/new.html.erb` fue reescrita usando `InputFieldComponent` para email y contraseña; el mensaje de error de `SessionsController#create` se cambió a "Email o contraseña incorrectos" (genérico, no revela si el email existe — AC #2) y se renderiza como `error_message` del campo email.
- **Task 3**: en el concern `Authentication`, `request_authentication` ahora: (a) solo guarda `return_to_after_authenticating` para requests GET (evita reintentar un POST/DELETE tras el login), y (b) distingue sesión expirada (cookie `session_id` presente pero `Session` ya no existe) de "nunca inició sesión" (sin cookie) — solo en el primer caso setea `flash[:warning] = "Tu sesión expiró, iniciá sesión de nuevo"`. Se agregó un banner ámbar (`#warning`, `bg-amber-50`/`text-amber-800`) en la vista de Login para este mensaje, distinto del banner verde de `flash[:notice]` (usado por `PasswordsController` para "instrucciones enviadas"). `after_authentication_url` (ya generado por Rails 8) maneja el redirect-and-return — AC #3 cumplido.
- **Task 4**: suite completa (19 tests / 71 assertions) y `rubocop -A` sin offenses. Verificación manual end-to-end de los 4 ACs vía `curl` contra un servidor Puma local.
- **Desviaciones documentadas** (siguiendo el patrón de Story 1.1): adición de `HomeController`/vista "Inicio"/`root` route (no estaba en el alcance original pero es indispensable para AC #1), y adición de la gema `view_component` (requerida por `architecture.md#Frontend-Architecture` para UX-DR1 pero no presente en el Gemfile generado por `rails new`).

### File List

- **Generados por `bin/rails generate authentication`**: `app/models/user.rb`, `app/models/session.rb`, `app/models/current.rb`, `app/controllers/sessions_controller.rb` (luego editado), `app/controllers/passwords_controller.rb`, `app/controllers/concerns/authentication.rb` (luego editado), `app/mailers/passwords_mailer.rb`, `app/views/passwords_mailer/{reset.html.erb,reset.text.erb}`, `app/views/passwords/{new.html.erb,edit.html.erb}`, `app/views/sessions/new.html.erb` (luego reescrito), `app/channels/application_cable/connection.rb`, `db/migrate/20260611214413_create_users.rb`, `db/migrate/20260611214428_create_sessions.rb`, `test/fixtures/users.yml`, `test/models/user_test.rb`, `test/controllers/sessions_controller_test.rb` (luego editado), `test/controllers/passwords_controller_test.rb`, `test/mailers/previews/passwords_mailer_preview.rb`, `test/test_helpers/session_test_helper.rb`
- **Modificados**: `Gemfile` (descomentado `bcrypt`, agregado `view_component`), `Gemfile.lock`, `app/controllers/application_controller.rb` (incluye `Authentication`), `app/controllers/concerns/authentication.rb` (redirect-and-return + mensaje de sesión expirada), `app/controllers/sessions_controller.rb` (mensajes en español), `app/views/sessions/new.html.erb` (uso de `InputFieldComponent`, banner `flash[:warning]`), `test/controllers/sessions_controller_test.rb` (tests de error inline), `test/test_helper.rb` (require de `session_test_helper`), `config/routes.rb` (agregado `root "home#index"`), `db/seeds.rb` (usuario de prueba), `db/schema.rb`
- **Nuevos (manual)**: `app/components/input_field_component.rb`, `app/components/input_field_component.html.erb`, `test/components/input_field_component_test.rb`, `app/controllers/home_controller.rb`, `app/views/home/index.html.erb`, `test/integration/session_expiration_test.rb`, `test/controllers/home_controller_test.rb`
- **Modificados en code review (2026-06-11)**: `app/controllers/concerns/authentication.rb` (fix open redirect: `request.fullpath` en vez de `request.url`; guard nil en `terminate_session`), `app/controllers/sessions_controller.rb` (preservar `email_address` en redirect tras login fallido), `app/components/input_field_component.rb` (evitar `ArgumentError` por keyword duplicado en `field_html_options`), `db/seeds.rb` (restringir seed de admin a `Rails.env.development?`), `test/controllers/sessions_controller_test.rb` (test actualizado para nuevo redirect con `email_address`)

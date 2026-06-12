---
baseline_commit: 6d103c9
---

# Story 1.4: Invitación de Empleados

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Dueño del Complejo,
I want generar un link/código de invitación para que un Empleado cree su cuenta,
so that no tenga que cargar credenciales manualmente para cada empleado.

## Acceptance Criteria

1. **Given** que estoy en Configuración como Dueño **When** genero una invitación **Then** el sistema crea un `Invitation` con token único (`has_secure_token`), `expires_at` y queda asociada a mi `Complejo` (vía `complejo_id`) y a mí (`invited_by`) [Source: epics.md#Story-1.4, línea 227; architecture.md línea 166]
2. **Given** un link de invitación válido (no usado, no expirado) **When** un Empleado lo abre (`GET /invitations/:token`) y completa el formulario de registro (`PATCH /invitations/:token`) **Then** se crea su cuenta con `role: employee`, asociada automáticamente al mismo `Complejo` de la invitación, sin intervención adicional del Dueño, y el Empleado queda autenticado [Source: epics.md#Story-1.4, línea 231]
3. **Given** un link de invitación ya usado (`used_at` presente) o expirado (`expires_at` pasado) **When** alguien intenta usarlo (`GET`/`PATCH /invitations/:token`) **Then** el sistema rechaza la creación de cuenta y muestra un mensaje claro, sin crear ningún `User` [Source: epics.md#Story-1.4, línea 235]

## Tasks / Subtasks

- [x] Task 1: Crear modelo `Complejo` (renombrado de `Complex`, ver Dev Notes) y asociarlo a `User` (AC: #1, #2)
  - [x] Subtask 1.1: Generar migración `CreateComplejos`: tabla `complejos` con `name` (string, `null: false`). Ejecutar `bin/rails db:migrate`
  - [x] Subtask 1.2: Crear `app/models/complejo.rb`: `has_many :users`, `has_many :invitations`, `validates :name, presence: true`
  - [x] Subtask 1.3: Generar migración `AddComplejoToUsers`: `add_reference :users, :complejo, foreign_key: true` (columna nullable a nivel DB para no romper filas existentes; la asociación es obligatoria a nivel de modelo). Ejecutar `bin/rails db:migrate`
  - [x] Subtask 1.4: En `app/models/user.rb`, agregar `belongs_to :complejo` (por defecto en Rails 8 `belongs_to` es requerido — valida presencia automáticamente)
  - [x] Subtask 1.5: Actualizar `db/seeds.rb`: crear (o encontrar) el Complejo piloto (`Complejo.find_or_create_by!(name: "Complejo Piloto")`) y asegurar que `admin@retroai.test` quede asociado a él (mismo patrón ya usado para `role: :owner` en Story 1.3 — actualizar también si el registro ya existía)
  - [x] Subtask 1.6: Crear fixture `test/fixtures/complejos.yml` con un complejo (`piloto: name: Complejo Piloto`). Actualizar `test/fixtures/users.yml`: asociar `one` y `two` a `complejo: piloto`
  - [x] Subtask 1.7: Tests de modelo (`test/models/complejo_test.rb`, `test/models/user_test.rb`): `Complejo` requiere `name`; un `User` sin `complejo` no es válido (`belongs_to` requerido)

- [x] Task 2: Crear modelo `Invitation` (AC: #1, #3)
  - [x] Subtask 2.1: Generar migración `CreateInvitations`: tabla `invitations` con `token` (string, `null: false`, índice único — requerido por `has_secure_token`), `expires_at` (datetime, `null: false`), `used_at` (datetime, nullable), `invited_by_id` (referencia a `users`, `null: false`, FK), `complejo_id` (referencia a `complejos`, `null: false`, FK), timestamps. Ejecutar `bin/rails db:migrate`
  - [x] Subtask 2.2: Crear `app/models/invitation.rb`: `has_secure_token`, `belongs_to :complejo`, `belongs_to :invited_by, class_name: "User"`; constante `EXPIRATION_PERIOD = 7.days`; callback `before_validation` (`on: :create`) que setea `expires_at ||= EXPIRATION_PERIOD.from_now`; métodos `expired?` (`expires_at.past?`), `used?` (`used_at.present?`), `redeemable?` (`!used? && !expired?`)
  - [x] Subtask 2.3: Tests de modelo (`test/models/invitation_test.rb`): se genera un `token` único automáticamente al crear; `expires_at` se setea por defecto a ~7 días desde la creación si no se especifica; `expired?`/`used?`/`redeemable?` responden correctamente para los 3 casos (vigente, usada, expirada)

- [x] Task 3: `InvitationsController#create` — el Dueño genera una invitación desde Configuración (AC: #1)
  - [x] Subtask 3.1: Agregar a `config/routes.rb`: `resources :invitations, param: :token, only: %i[ create show update ]` (mismo patrón que `resources :passwords, param: :token`)
  - [x] Subtask 3.2: Crear `app/controllers/invitations_controller.rb` con la acción `create`: si `Current.user.owner?` es `false`, redirigir a `root_path` con `alert: "No tenés permiso para generar invitaciones"` (guardia mínima inline — NO es la `ConfiguracionPolicy` completa de Story 1.5, ver Dev Notes); si es Dueño, crear `Current.user.complejo.invitations.create!(invited_by: Current.user)` y redirigir a `configuracion_path` con `notice` que incluya el link completo (`invitation_url(invitation.token)`)
  - [x] Subtask 3.3: Actualizar `app/views/configuracion/index.html.erb`: agregar un formulario/botón "Invitar empleado" (`button_to "Invitar empleado", invitations_path, method: :post`); si `flash[:notice]` contiene el link generado, mostrarlo (reutilizar el bloque de `flash[:notice]` ya existente en otras vistas, ej. `sessions/new.html.erb`)
  - [x] Subtask 3.4: Tests de integración (`test/controllers/invitations_controller_test.rb`): usuario `owner` autenticado → `POST /invitations` crea un `Invitation` (verificar `complejo_id`/`invited_by_id`) y redirige a `/configuracion` con el link en el `notice`; usuario `employee` autenticado → `POST /invitations` NO crea `Invitation` y redirige; usuario no autenticado → redirige a `new_session_path`

- [x] Task 4: `InvitationsController#show`/`#update` — el Empleado completa el registro vía link (AC: #2, #3)
  - [x] Subtask 4.1: En `app/controllers/invitations_controller.rb`, agregar `allow_unauthenticated_access only: %i[ show update ]` y un `before_action :set_invitation, only: %i[ show update ]` que busque por `token` (`Invitation.find_by(token: params[:token])`); si no existe, asignar `@invitation = nil` (se maneja en la vista, no error 404 duro)
  - [x] Subtask 4.2: Acción `show`: si `@invitation&.redeemable?` es `true`, instanciar `@user = @invitation.complejo.users.build` para el formulario; si no (invitación inexistente, usada o expirada), la vista mostrará el mensaje de error (AC #3)
  - [x] Subtask 4.3: Acción `update`: si `@invitation&.redeemable?` es `false`, volver a renderizar `show` (la vista mostrará el mensaje de error, AC #3); si es `true`, construir `@user = @invitation.complejo.users.build(params.require(:user).permit(:email_address, :password, :password_confirmation))`, forzar `@user.role = :employee`; si `@user.save`, marcar `@invitation.update!(used_at: Time.current)`, llamar `start_new_session_for(@user)` y redirigir a `root_path` con `notice: "Cuenta creada"`; si falla la validación, re-renderizar `show` con los errores inline (`status: :unprocessable_entity`)
  - [x] Subtask 4.4: Crear `app/views/invitations/show.html.erb`: si la invitación es `redeemable?`, mostrar formulario de registro (`form_with url: invitation_path(params[:token]), method: :patch`) con `InputFieldComponent` para `email_address` (type email), `password` y `password_confirmation` (type password, `maxlength: 72`), siguiendo el estilo de `app/views/sessions/new.html.erb`; si no es `redeemable?` (o `@invitation` es `nil`), mostrar un mensaje "Este link de invitación no es válido o expiró." sin formulario
  - [x] Subtask 4.5: Tests de integración: invitación válida → `GET /invitations/:token` devuelve 200 y renderiza el formulario; `PATCH /invitations/:token` con datos válidos crea un `User` con `role: employee` y `complejo_id` igual al de la invitación, marca `used_at`, inicia sesión (cookie `session_id` presente) y redirige a `root_path`; invitación expirada o ya usada → `GET`/`PATCH /invitations/:token` muestran el mensaje de error y NO crean ningún `User` (AC #3); reutilizar el mismo token después de redimirlo → segundo intento rechazado (AC #3)

- [x] Task 5: Validar suite completa y dejar el proyecto listo para Story 1.5 (AC: #1-#3)
  - [x] Subtask 5.1: Correr `bin/rails test` (suite completa) → 0 failures, 0 errors
  - [x] Subtask 5.2: Correr `bin/rubocop -A` → sin offenses
  - [x] Subtask 5.3: Verificar manualmente con `bin/dev`: login como `admin@retroai.test` (owner) → en Configuración, "Invitar empleado" genera un link y lo muestra; abrir ese link en una sesión sin cookies (incógnito) → completar el formulario de registro → se crea la cuenta como `employee` asociada al "Complejo Piloto" y queda autenticado en Inicio; volver a abrir el mismo link → mensaje de invitación inválida/usada
  - [x] Subtask 5.4: Documentar en Completion Notes las desviaciones: (1) renombre `Complex`→`Complejo` (colisión con la clase `Complex` de Ruby, ver Dev Notes) — aplica también a Stories futuras que referencien este modelo; (2) guardia mínima de `owner?` en `InvitationsController#create` (no es la `ConfiguracionPolicy` completa de Story 1.5); (3) la "lista de usuarios con su rol" en Configuración (EXPERIENCE.md línea 39) queda fuera de alcance de esta story — Story 1.5 construye la UI completa de Configuración

## Dev Notes

- **⚠️ Desviación de arquitectura obligatoria — `Complex` → `Complejo`**: `architecture.md` (líneas 152-154, 462, 467) define el modelo como `Complex`/tabla `complexes`/FK `complex_id`. **Esto es inviable en Ruby**: `Complex` es una clase core de Ruby (números complejos, `Complex(1,2)`); `class Complex < ApplicationRecord` lanza `TypeError: superclass mismatch for class Complex` porque la superclase real de `::Complex` es `Numeric`. Esta story usa **`Complejo`** (modelo), **`complejos`** (tabla), **`complejo_id`** (FK) — consistente con el patrón ya aprobado en `architecture.md` línea 228 de mantener nombres de dominio en español cuando el Glosario del PRD los define (igual que `Turno`/`turnos`). Esta misma convención debe respetarse en Story 1.5 (`Configuración del Complejo y Canchas`, que extiende este modelo) y en cualquier referencia futura a `ComplexPlayer` (sería `ComplejoPlayer`/`complejo_players`, fuera de alcance de esta story).
- **Alcance estricto de `Complejo` en esta story**: el modelo `Complejo` se crea con el mínimo necesario para que `Invitation`/`User` puedan asociarse a él (`name` únicamente). Story 1.5 agrega los datos de contacto del Complejo, el modelo `Court`/canchas y la UI de edición en Configuración. NO implementar nada de Story 1.5 acá [Source: epics.md#Story-1.5, líneas 237-260].
- **Modelo `Invitation` (architecture.md línea 166)**: "`Invitation` con `has_secure_token`, `expires_at`, `used_at`, `invited_by` — single-use + time-limited, con auditoría." `has_secure_token` (Rails nativo, sin dependencias nuevas) genera automáticamente un `token` único en `before_create` y agrega el método `regenerate_token` — requiere una columna `token` (string) con índice único en la migración.
- **Guardia de autorización mínima en `InvitationsController#create`**: Story 1.3 documentó como gap diferido que FR-12 no tiene enforcement server-side todavía (`ConfiguracionPolicy`/`ReportPolicy` llegan en Stories 1.5/4.1). Sin embargo, `InvitationsController#create` permite crear cuentas nuevas — dejarlo abierto a cualquier usuario autenticado sería una escalación de privilegios nueva y evitable. Por eso esta story agrega una guardia inline (`Current.user.owner?`) SOLO para esta acción, sin introducir una `Pundit::Policy` nueva (eso sigue siendo alcance de Story 1.5). No agregar guardias similares a `TurnosController`/`PaymentsController`/etc. — ese gap permanece diferido tal como quedó documentado en la Story 1.3.
- **Patrón de rutas con `:token`**: `app/controllers/passwords_controller.rb` + `resources :passwords, param: :token` ya establecen el patrón de un resource autenticado por token en la URL en vez de `:id`. `InvitationsController` sigue el mismo patrón: `resources :invitations, param: :token, only: %i[ create show update ]` → `POST /invitations` (Dueño genera), `GET /invitations/:token` (formulario de registro), `PATCH /invitations/:token` (envío del registro). `allow_unauthenticated_access only: %i[ show update ]` (mismo helper que usa `SessionsController`/`PasswordsController`, definido en `app/controllers/concerns/authentication.rb`).
- **Reutilizar `start_new_session_for`**: método privado de `Authentication` concern (`app/controllers/concerns/authentication.rb`), ya usado por `SessionsController#create`. Tras crear el `User` vía invitación, llamarlo para autenticar inmediatamente al nuevo Empleado (consistente con AC#2 "queda autenticado").
- **`InputFieldComponent` (Story 1.2)**: reutilizar para el formulario de registro en `app/views/invitations/show.html.erb`, igual que `app/views/sessions/new.html.erb` (email/password) — agregar también `password_confirmation` (campo nuevo para este formulario, `has_secure_password` lo valida automáticamente si está presente).
- **Mensajes en español, tono "vos"** (EXPERIENCE.md líneas 41-51): ej. "Cuenta creada", "Este link de invitación no es válido o expiró.", "No tenés permiso para generar invitaciones".
- **Seeds**: `db/seeds.rb` actualmente crea/asegura `admin@retroai.test` con `role: :owner` (Story 1.3). Esta story agrega la creación del `Complejo` piloto y la asociación `admin.complejo = <Complejo Piloto>` (igual patrón `find_or_create_by!` + `update!` si ya existía, para que sea idempotente).
- **Testing**: Minitest. Tests de modelo para `Complejo`/`Invitation`/`User` (validaciones y asociaciones nuevas), tests de integración (controller) para `InvitationsController` cubriendo las 3 ACs. Usar fixtures (`test/fixtures/complejos.yml`, actualizar `users.yml`) y el helper `sign_in_as` (`test/test_helpers/session_test_helper.rb`) ya disponible vía `fixtures :all` [Source: architecture.md#Structure-Patterns].
- **Aprendizajes de Story 1.3**: convención de controllers placeholder (`ConfiguracionController#index` ya existe con vista placeholder) — esta story agrega contenido real a `app/views/configuracion/index.html.erb` por primera vez, pero NO implementa el resto de Configuración (lista de Canchas, datos del Complejo) — eso es Story 1.5. El layout (`app/views/layouts/application.html.erb`) y los componentes de navegación (`AppHeaderComponent`/`BottomNavComponent`) ya renderizan correctamente para usuarios autenticados; las vistas de `InvitationsController#show`/`#update` son accedidas SIN sesión (`allow_unauthenticated_access`), por lo que el layout no mostrará header/bottom-nav para ellas (mismo comportamiento que `sessions/new`).

### Project Structure Notes

- Nuevos archivos: `db/migrate/*_create_complejos.rb`, `db/migrate/*_add_complejo_to_users.rb`, `db/migrate/*_create_invitations.rb`, `app/models/complejo.rb`, `app/models/invitation.rb`, `app/controllers/invitations_controller.rb`, `app/views/invitations/show.html.erb`, `test/fixtures/complejos.yml`, `test/models/complejo_test.rb`, `test/models/invitation_test.rb`, `test/controllers/invitations_controller_test.rb`.
- Archivos modificados: `app/models/user.rb` (`belongs_to :complejo`), `config/routes.rb` (rutas de `invitations`), `app/views/configuracion/index.html.erb` (form "Invitar empleado"), `db/seeds.rb` (Complejo piloto), `test/fixtures/users.yml` (asociación a `complejo: piloto`).
- Desviación documentada respecto a `architecture.md`: nombre del modelo `Complex`/`complexes`/`complex_id` → `Complejo`/`complejos`/`complejo_id` (ver Dev Notes, colisión con la clase Ruby `Complex`). Mantener esta convención en Story 1.5 y siguientes.

### References

- [Source: epics.md#Story-1.4, líneas 217-235]
- [Source: epics.md#Story-1.5, líneas 237-260]
- [Source: architecture.md, líneas 131, 152-154, 162-168, 224-228, 350-357, 462, 467]
- [Source: EXPERIENCE.md, líneas 35, 37, 39, 41-51, 65]
- [Source: 1-3-roles-y-control-de-acceso-dueno-empleado.md#Dev-Notes, #File-List]

### Review Findings

- [x] [Review][Decision] Email duplicado en registro vía invitación puede causar error 500 — `User` no validaba unicidad de `email_address` a nivel de modelo (solo existía índice único en la base de datos). Resuelto: se agregó `validates :email_address, uniqueness: true` a `app/models/user.rb` (combina con `normalizes` que ya baja a minúsculas). [app/models/user.rb]
- [x] [Review][Patch] Falta test de integración para el path `unprocessable_entity` de `InvitationsController#update` con errores de validación reales (ej. email duplicado, contraseñas que no coinciden). Resuelto: se agregó el test "registration with an already taken email shows a validation error" en `test/controllers/invitations_controller_test.rb`, y "requires a unique email_address" en `test/models/user_test.rb`.
- [x] [Review][Defer] `users.complejo_id` es nullable a nivel de DB (sin backfill) — un `User` pre-existente sin `complejo` asignado haría que `Current.user.complejo.invitations.create!` lance `NoMethodError` (`nil.invitations`) en `InvitationsController#create`. Riesgo bajo en el estado actual del proyecto (sin usuarios reales, fixtures y seeds ya asociados a un Complejo); revisar si se cargan datos reales antes de Story 1.5. [db/migrate/20260612123229_add_complejo_to_users.rb, app/controllers/invitations_controller.rb:9] — deferred, pre-existing
- [x] [Review][Defer] Condición de carrera: dos requests concurrentes con el mismo token podrían pasar `redeemable?` antes de que cualquiera marque `used_at`, redimiendo la invitación dos veces. Edge case de baja probabilidad para el MVP actual. [app/controllers/invitations_controller.rb:26-33] — deferred, pre-existing
- [x] [Review][Defer] Sin rate limiting ni UI para listar/revocar invitaciones generadas — cada click en "Invitar empleado" crea una fila nueva sin límite. Backlog para una story futura de gestión de invitaciones. [app/controllers/invitations_controller.rb:6-10, app/views/configuracion/index.html.erb] — deferred, pre-existing

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6 (claude-sonnet-4-6)

### Debug Log References

- Suite completa: `bin/rails test` → 52 runs, 166 assertions, 0 failures, 0 errors, 0 skips
- `bin/rubocop -A` → 67 files inspected, no offenses detected
- Verificación manual end-to-end vía `bin/rails server` + `curl`: login owner → generar invitación en Configuración → abrir link sin sesión → completar registro → cuenta `employee` creada y asociada a "Complejo Piloto", auto-login (cookie `session_id`), redirige a Inicio → reabrir el mismo link muestra "Este link de invitación no es válido o expiró."

### Completion Notes List

1. **Desviación de arquitectura — `Complex` → `Complejo`**: `architecture.md` define el modelo de complejo deportivo como `Complex`/`complexes`/`complex_id`, pero `Complex` es una clase core de Ruby (`Numeric`), y `class Complex < ApplicationRecord` lanza `TypeError: superclass mismatch for class Complex`. Se implementó como `Complejo`/`complejos`/`complejo_id`, siguiendo el precedente de `architecture.md` de mantener nombres de dominio en español (ej. `Turno`). Esta convención debe respetarse en Story 1.5 y en cualquier referencia futura a `ComplexPlayer` (sería `ComplejoPlayer`/`complejo_players`).
2. **Guardia de autorización mínima en `InvitationsController#create`**: se agregó una verificación inline `Current.user.owner?` (sin Pundit) para evitar que un `employee` autenticado genere invitaciones y escale privilegios. La `ConfiguracionPolicy` completa (Pundit), que cubriría esta y otras acciones de Configuración, sigue siendo alcance de Story 1.5, según lo documentado como gap diferido en la revisión de Story 1.3.
3. **"Lista de usuarios con su rol" fuera de alcance**: `app/views/configuracion/index.html.erb` solo agrega el botón "Invitar empleado" y el `flash[:notice]` con el link generado. La UI completa de Configuración (datos del Complejo, Canchas, lista de usuarios con su rol — EXPERIENCE.md línea 39) es alcance de Story 1.5.
4. **Modelo `Complejo` mínimo**: se creó únicamente con `name` (`null: false`), `has_many :users`, `has_many :invitations`. Story 1.5 agrega datos de contacto y el modelo `Court`/canchas.
5. **Seeds**: `db/seeds.rb` ahora crea/encuentra "Complejo Piloto" (`Complejo.find_or_create_by!`) y asegura que `admin@retroai.test` quede asociado a él de forma idempotente, tanto para instalaciones nuevas como para la base de datos de desarrollo existente.

### File List

- `db/migrate/20260612123212_create_complejos.rb` (nuevo)
- `db/migrate/20260612123229_add_complejo_to_users.rb` (nuevo)
- `db/schema.rb` (modificado, regenerado por las migraciones)
- `app/models/complejo.rb` (nuevo)
- `app/models/user.rb` (modificado: `belongs_to :complejo`)
- `db/seeds.rb` (modificado: Complejo Piloto + asociación con `admin@retroai.test`)
- `test/fixtures/complejos.yml` (nuevo)
- `test/fixtures/users.yml` (modificado: `complejo: piloto` en `one` y `two`)
- `test/models/complejo_test.rb` (nuevo)
- `test/models/user_test.rb` (modificado: test "requires a complejo")
- `db/migrate/20260612123954_create_invitations.rb` (nuevo)
- `app/models/invitation.rb` (nuevo)
- `test/models/invitation_test.rb` (nuevo)
- `config/routes.rb` (modificado: rutas de `invitations`)
- `app/controllers/invitations_controller.rb` (nuevo)
- `app/views/configuracion/index.html.erb` (modificado: botón "Invitar empleado" + flash notice)
- `test/controllers/invitations_controller_test.rb` (nuevo, ampliado en Task 4 con `show`/`update`)
- `app/views/invitations/show.html.erb` (nuevo)

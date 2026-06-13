
## Deferred from: code review of 1-1-inicializacion-del-proyecto.md (2026-06-11)
- Gemas redundantes en Gemfile: Gemas como jbuilder e image_processing vienen por defecto en Rails 8 pero no están explícitamente requeridas por la arquitectura del MVP. Se mantienen por ser defaults del framework.

## Deferred from: code review of 1-2-login-multi-usuario (2026-06-11)
- `seeds.rb` usa `find_or_create_by!` y no actualiza la password si el usuario admin ya existe con otra. Pre-existente, sin impacto en los AC de esta story.
- `PasswordsController#update` no valida longitud/complejidad mínima de password. Es código del scaffold generado por `bin/rails generate authentication`, fuera del alcance de los AC de Story 1.2 (login). Considerar en una futura story de seguridad/políticas de password.
- Falta test de normalización (mayúsculas/espacios) de `email_address` en el flujo de login (AC#2). `normalizes :email_address` ya aplica en el modelo, pero no hay test explícito que cubra login con email en distinto casing.
- `PasswordsController#update`, en el branch de error, redirige reutilizando el token viejo en vez de generar uno nuevo. Código del scaffold generado, fuera del alcance de esta story.
- La heurística de "sesión expirada" (basada en presencia de cookie `session_id` firmada) no distingue una cookie inválida/forjada de una expiración real — ambas muestran el mismo mensaje "Tu sesión expiró". Limitación de diseño documentada en Dev Notes de Story 1.2.
- `return_to_after_authenticating` solo se guarda para requests GET (no para POST/PUT/DELETE). Limitación de diseño documentada en Dev Notes de Story 1.2, aceptable para el AC#3 actual.
- `InputFieldComponent` usa clases utilitarias de Tailwind aproximadas en lugar de un mapeo 1:1 literal con los tokens de `DESIGN.md`. Desviación ya documentada en Completion Notes de Story 1.2; revisar cuando se implemente el sistema de theming en Story 1.6 (modo claro/oscuro global).
- URLs muy largas guardadas en `session[:return_to_after_authenticating]` podrían exceder el límite de tamaño de la cookie de sesión (4KB). Edge case de baja probabilidad dado el tamaño actual de las rutas de la app.
- `InputFieldComponent#field_id`: si `name` es `nil` o se reduce a string vacío tras `parameterize`, el `id`/`for` del campo queda vacío. Ningún caller actual (`sessions/new.html.erb`) dispara este caso.
- Falta test de integración que cubra el flujo intermedio: login fallido seguido de login exitoso preservando `return_to_after_authenticating` (actualmente solo se testea el caso de éxito directo).

## Deferred from: code review of 1-3-roles-y-control-de-acceso-dueno-empleado (2026-06-12)
- FR-12 sin enforcement server-side: un Empleado autenticado puede acceder a `/configuracion` y `/reportes` directamente por URL — la UI solo oculta los links del nav/menú. Explícitamente alcance de Story 1.5 (`ConfiguracionPolicy`) y Story 4.1 (`ReportPolicy`), pero queda como gap real de seguridad hasta que se implementen esas policies.
- `BottomNavComponent#active?` usa comparación exacta de `request.path`; no resaltará el tab padre para futuras rutas anidadas (ej. `/calendario/:id`). Revisar cuando Epic 2 agregue rutas de detalle de turno.
- Alias de rutas (`calendario_path`, `pagos_path`, `reportes_path`, `configuracion_path`) podrían colisionar con nombres de ruta autogenerados si futuras stories agregan `resources :turnos`/`:payments`/etc. Validar al definir esas rutas.

## Deferred from: code review of 1-4-invitacion-de-empleados (2026-06-12)
- `users.complejo_id` es nullable a nivel de DB (sin backfill) — un `User` pre-existente sin `complejo` asignado haría que `Current.user.complejo.invitations.create!` lance `NoMethodError` (`nil.invitations`) en `InvitationsController#create`. Riesgo bajo en el estado actual del proyecto (sin usuarios reales, fixtures y seeds ya asociados a un Complejo); revisar si se cargan datos reales antes de Story 1.5.
- Condición de carrera: dos requests concurrentes con el mismo token podrían pasar `redeemable?` antes de que cualquiera marque `used_at`, redimiendo la invitación dos veces. Edge case de baja probabilidad para el MVP actual.
- Sin rate limiting ni UI para listar/revocar invitaciones generadas — cada click en "Invitar empleado" crea una fila nueva sin límite. Backlog para una story futura de gestión de invitaciones.

## Deferred from: code review of 1-5-configuracion-del-complejo-y-canchas (2026-06-12)
- Falta test de seeds que verifique exactamente 7 canchas asociadas al complejo piloto tras `db:seed`, según el Testing Requirement explícito de la Story 1.5.
- `CanchaPolicy`/`ConfiguracionPolicy` solo validan `user.owner?`, sin verificar pertenencia al `complejo` del usuario — válido hoy (single-tenant piloto), pero frágil ante multi-tenancy futura.
- Inconsistencia de estilo en `CanchasController`: `authorize Cancha` (clase) en `index/new/create` vs `authorize @cancha` (instancia) en `edit/update/destroy`.
- Falta índice único `(complejo_id, name)` en la tabla `canchas` para evitar nombres de cancha duplicados dentro de un mismo complejo.
- `db/seeds.rb` realiza dos `update!` separados (`role` y `complejo`) sobre el admin; si el segundo falla, queda un estado intermedio inconsistente (admin con `role: owner` pero sin `complejo`), lo cual además rompería `CanchasController#set_complejo`.
- FK `complejo_id` en `canchas` sin `on_delete: :cascade`/`:restrict`; un borrado directo por SQL de un `Complejo` dejaría `canchas` huérfanas (bypass de `dependent: :destroy`).
- Vistas `app/views/canchas/new.html.erb` y `app/views/canchas/edit.html.erb` usan clases Tailwind antiguas (`text-blue-600`, `dark:text-white`, `bg-gray-800`, `focus:ring-blue-600`) en lugar de los tokens DESIGN.md ya aplicados en `configuracion/edit.html.erb` y otras vistas migradas en Story 1.6.
- Formularios de Cancha (`canchas/new.html.erb`, `canchas/edit.html.erb`) mezclan `f.select` (form builder estándar) con `InputFieldComponent` usando `name` hardcodeado como string — funciona pero es un patrón inconsistente que podría desincronizarse si cambia el modelo/form scope.

## Deferred from: code review of 2-1-calendario-de-turnos-por-cancha-horario (2026-06-12)
- `index_by { |t| [t.cancha_id, t.start_time.hour] }` en `TurnosController#index` descarta silenciosamente un Turno si dos comparten cancha/hora. No aplicable hoy (no existe creación de turnos), pero considerar validación de unicidad `(cancha_id, start_time)` en `Turno` al implementar Story 2.2.
- `CardTurnoComponent#roster_summary`/`#reservee_name` devuelven placeholders fijos ("Sin nombre", "0/4 confirmados") hasta que Epic 2/5 implemente Roster. Documentado en comentarios de código, no en Completion Notes.
- `StatusPillComponent` tiene una rama `else` (clases grises genéricas `bg-gray-100`/`text-gray-500`) que es código muerto: `Turno#payment_status` solo admite `pending`/`partial`/`paid`.
- No hay test de integración que verifique el render real de `card-turno`/`status-pill` con un Turno existente, ni el slot "Cancha libre"; `test/system/calendario_test.rb` fue creado pero no se ejecuta por falta de ChromeDriver en el entorno — AC1/AC2/AC5 sin verificación end-to-end ejecutada.
- `app/views/canchas/index.html.erb` y `canchas/show.html.erb` (Story 1.5, done) son archivos de 0 bytes pese a que `CanchasController#index`/`#show` están ruteados — renderizan páginas en blanco.
- `CanchasController` usa `rescue_from ArgumentError, with: :handle_invalid_sport` de forma demasiado amplia, capturando cualquier `ArgumentError` de la acción y no solo el del enum `sport`.
- El link de invitación se inyecta completo en `flash[:notice]` (`InvitationsController#create`) y se renderiza con `break-all` — exposición menor de una credencial de un solo uso vía flash/sesión/logs.

## Deferred from: code review of 1-6-modo-claro-oscuro-global (2026-06-12)
- Brittle Navigation State: BottomNavComponent relies on naive exact string match for active tabs
- Unmanaged Dropdown State: <details> dropdown lacks JS listener to close on outside click
- Swallowed System Errors: Authentication view ignores alert or error flashes
- MVC Violation via Params: invitations/show.html.erb directly accesses params[:token] in form URL
- Hardcoded String Debt: User-facing text is hardcoded instead of using I18n
- Opaque Invitation UX: "Invitar empleado" button fires POST without collecting email

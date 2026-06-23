
## Deferred from: code review of 1-1-inicializacion-del-proyecto.md (2026-06-11)
- Gemas redundantes en Gemfile: Gemas como jbuilder e image_processing vienen por defecto en Rails 8 pero no están explícitamente requeridas por la arquitectura del MVP. Se mantienen por ser defaults del framework.

## Deferred from: code review of 1-2-login-multi-usuario (2026-06-11)
- `seeds.rb` usa `find_or_create_by!` y no actualiza la password si el usuario admin ya existe con otra. Pre-existente, sin impacto en los AC de esta story.
- `PasswordsController#update` no valida longitud/complejidad mínima de password. Es código del scaffold generado por `bin/rails generate authentication`, fuera del alcance de los AC de Story 1.2 (login). Considerar en una futura story de seguridad/políticas de password.
- Falta test de normalización (mayúsculas/espacios) de `email_address` en el flujo de login (AC#2). `normalizes :email_address` ya aplica en el modelo, pero no hay test explícito que cubra login con email en distinto casing.
- `PasswordsController#update`, en el branch de error, redirige reutilizando el token viejo en vez de generar uno nuevo. Código del scaffold generado, fuera del alcance de esta story.
- La heurística de "sesión expirada" (basada en presencia de cookie `session_id` firmada) no distingue una cookie inválida/forjada de una expiración real — ambas muestran el mismo mensaje "Tu sesión expiró". Limitación de diseño documentada en Dev Notes de Story 1.2.
- `return_to_after_authenticating` solo se guarda para requests GET (no para POST/PUT/DELETE). Limitación de diseño documentada en Dev Notes de Story 1.2, aceptable para el AC#3 actual.
- URLs muy largas guardadas en `session[:return_to_after_authenticating]` podrían exceder el límite de tamaño de la cookie de sesión (4KB). Edge case de baja probabilidad dado el tamaño actual de las rutas de la app.
- `InputFieldComponent#field_id`: si `name` es `nil` o se reduce a string vacío tras `parameterize`, el `id`/`for` del campo queda vacío. Ningún caller actual (`sessions/new.html.erb`) dispara este caso.
- Falta test de integración que cubra el flujo intermedio: login fallido seguido de login exitoso preservando `return_to_after_authenticating` (actualmente solo se testea el caso de éxito directo).

## Deferred from: code review of 1-3-roles-y-control-de-acceso-dueno-empleado (2026-06-12)
- `BottomNavComponent#active?` usa comparación exacta de `request.path`; no resaltará el tab padre para futuras rutas anidadas (ej. `/calendario/:id`). Revisar cuando Epic 2 agregue rutas de detalle de turno.

## Deferred from: code review of 1-4-invitacion-de-empleados (2026-06-12)
- `users.complejo_id` es nullable a nivel de DB (sin backfill) — un `User` pre-existente sin `complejo` asignado haría que `Current.user.complejo.invitations.create!` lance `NoMethodError` (`nil.invitations`) en `InvitationsController#create`. Riesgo bajo en el estado actual del proyecto (sin usuarios reales, fixtures y seeds ya asociados a un Complejo); revisar si se cargan datos reales antes de Story 1.5.
- Condición de carrera: dos requests concurrentes con el mismo token podrían pasar `redeemable?` antes de que cualquiera marque `used_at`, redimiendo la invitación dos veces. Edge case de baja probabilidad para el MVP actual.
- Sin rate limiting ni UI para listar/revocar invitaciones generadas — cada click en "Invitar empleado" crea una fila nueva sin límite. Backlog para una story futura de gestión de invitaciones.

## Deferred from: code review of 1-5-configuracion-del-complejo-y-canchas (2026-06-12)
- Falta test de seeds que verifique exactamente 7 canchas asociadas al complejo piloto tras `db:seed`, según el Testing Requirement explícito de la Story 1.5.
- `CanchaPolicy`/`ConfiguracionPolicy` solo validan `user.owner?`, sin verificar pertenencia al `complejo` del usuario — válido hoy (single-tenant piloto), pero frágil ante multi-tenancy futura.
- Inconsistencia de estilo en `CanchasController`: `authorize Cancha` (clase) en `new/create` vs `authorize @cancha` (instancia) en `edit/update/destroy`.
- Falta índice único `(complejo_id, name)` en la tabla `canchas` para evitar nombres de cancha duplicados dentro de un mismo complejo.
- `db/seeds.rb` realiza dos `update!` separados (`role` y `complejo`) sobre el admin; si el segundo falla, queda un estado intermedio inconsistente (admin con `role: owner` pero sin `complejo`), lo cual además rompería `CanchasController#set_complejo`.
- FK `complejo_id` en `canchas` sin `on_delete: :cascade`/`:restrict`; un borrado directo por SQL de un `Complejo` dejaría `canchas` huérfanas (bypass de `dependent: :destroy`).
- Formularios de Cancha (`canchas/new.html.erb`, `canchas/edit.html.erb`) mezclan `f.select` (form builder estándar) con `InputFieldComponent` usando `name` hardcodeado como string — funciona pero es un patrón inconsistente que podría desincronizarse si cambia el modelo/form scope.

## Deferred from: code review of 2-1-calendario-de-turnos-por-cancha-horario (2026-06-12)
- `StatusPillComponent` tiene una rama `else` (clases grises genéricas `bg-gray-100`/`text-gray-500`) que es código muerto: ningún estado actual (payment_status, confirmation_status) cae en ella.
- No hay test de integración que verifique el render real de `card-turno`/`status-pill` con un Turno existente, ni el slot "Cancha libre"; `test/system/calendario_test.rb` fue creado pero no se ejecuta por falta de ChromeDriver en el entorno — AC1/AC2/AC5 sin verificación end-to-end ejecutada.
- El link de invitación se inyecta completo en `flash[:notice]` (`InvitationsController#create`) y se renderiza con `break-all` — exposición menor de una credencial de un solo uso vía flash/sesión/logs.

## Deferred from: code review of 1-6-modo-claro-oscuro-global (2026-06-12)
- Brittle Navigation State: BottomNavComponent relies on naive exact string match for active tabs
- Unmanaged Dropdown State: <details> dropdown lacks JS listener to close on outside click
- MVC Violation via Params: invitations/show.html.erb directly accesses params[:token] in form URL
- Hardcoded String Debt: User-facing text is hardcoded instead of using I18n
- Opaque Invitation UX: "Invitar empleado" button fires POST without collecting email

## Deferred from: code review of 5-2-creacion-de-turno-y-roster-inicial-via-bot-fr-1.md (2026-06-17)
- Architectural Coupling: Node.js accede directamente a la DB de Rails [whatsapp-service/src/db.ts] — deferred, pre-existing
- Falta de Rate Limiting en el Bot [app/services/whatsapp_inbox_processor.rb] — deferred, pre-existing (fuera de alcance MVP)

## Deferred from: code review of 5-3-confirmacion-individual-de-asistencia-fr-2.md (2026-06-18)
- Límite de borde "Turno activo pero ya en curso" (start_time pasado, partido sin terminar) sin test explícito [app/services/bot_confirmation_service.rb:32-39] — deferred, pre-existing (hereda el patrón `Turno.active`/`start_time` ya usado en historias previas).
- Sin batching/background job para rosters grandes — los outbox messages de confirmación se crean sincrónicamente dentro del manejo del webhook [app/services/whatsapp_inbox_processor.rb:61-65] — deferred, pre-existing (mismo patrón síncrono que `BotTurnoCreationService`).
- `RosterEntry` con `player_id` anulado (Player borrado) cae a mensaje de ayuda genérico en vez de uno específico [app/services/bot_confirmation_service.rb:32-39] — deferred, pre-existing (escenario raro, fallback ya es seguro).
- Dependencia implícita de normalización E.164 del teléfono entrante para el join con `Player#phone` [app/services/bot_confirmation_service.rb:32-39] — deferred, pre-existing (establecido desde Story 5.1/5.2).
- `CONFIRM_RE`/`DECLINE_RE` no toleran puntuación/espacios extra (ej. "SI!", "no.") [app/services/bot_confirmation_service.rb:6-7] — deferred, pre-existing (cae de forma controlada a la rama ambigua, mismo estilo estricto de parseo que el resto del bot).

## Deferred from: code review of 5-4-reemplazo-auto-gestionado-de-suplentes-fr-3.md (2026-06-18)
- Concurrency issue if multiple suplentes offered at same time [app/services/roster_replacement_service.rb:14] — deferred, pre-existing

## Deferred from: code review of 1-7-conexion-del-bot-de-whatsapp-fr-16.md (2026-06-19)
- `upsertConnectionStatus`/`connection-poller.ts` siempre operan sobre "la primera fila"/el socket global, ignorando `complejo_id` [whatsapp-service/src/connection-status.ts, connection-poller.ts] — deferred, decisión de alcance ya documentada (PRD §10 Guardrails, Out of Scope de la Story 1.7, decision-log del PRD): un solo Complejo activo por diseño en este MVP, sin multi-sesión real.
- `SELECT...FOR UPDATE SKIP LOCKED` en `connection-poller.ts` sin transacción explícita, el lock no protege nada como está escrito [whatsapp-service/src/connection-poller.ts:22-32] — deferred, replica exactamente el mismo patrón preexistente de `outbox-poller.ts` (Story 5.1), no es una regresión de esta historia.
- Polling del Stimulus controller sin límite de tiempo ni vía de escape si el QR nunca se escanea o la conexión nunca resuelve [app/javascript/controllers/whatsapp_connection_controller.js] — deferred, mejora de UX, ninguna AC lo exige.

## Deferred from: code review of 6-1-pipeline-de-ci-cd-build-y-push-de-imagenes.md (2026-06-19)
- Sin `concurrency` group en `build_and_push_web`/`build_and_push_whatsapp` — dos pushes rápidos a `master` pueden disparar builds en paralelo; con el tag flotante `type=ref,event=branch` ("master"), el que termine último "gana" esa tag específica sin importar cuál commit es más nuevo [.github/workflows/ci.yml] — deferred, decisión explícita de Hernan: la tag por sha siempre es inmutable y confiable; la tag de branch es solo conveniencia, no crítica en un proyecto de un solo desarrollador.
- `packages: write` sin firma de imagen ni provenance attestation (cosign/`provenance: true`) — cualquiera que pueda mergear a `master` puede publicar contenido arbitrario al namespace de GHCR sin verificación posterior [.github/workflows/ci.yml] — deferred, hardening de madurez de producción, alcance de una historia futura.
- `build_and_push_web`/`build_and_push_whatsapp` son prácticamente copy-paste (mismos 5 steps, solo cambia `context`/`file`/`images`) [.github/workflows/ci.yml] — deferred, un matrix o workflow reusable evitaría que un cambio futuro se aplique en un job y se olvide en el otro; no bloqueante para AC1-AC4.
- Cambio de rama default (`main`→`master`) no auditado contra reglas de branch protection en GitHub [.github/workflows/ci.yml] — deferred, sin acceso de API para verificarlo desde acá (sí se confirmó que ningún otro workflow referencia `main`); pedirle a Hernan que revise Settings → Branches manualmente.
- Condición `if: github.event_name == 'push' && github.ref == 'refs/heads/master'` duplicada literalmente en los 2 jobs nuevos [.github/workflows/ci.yml] — deferred, GitHub Actions no permite compartir condiciones entre jobs sin workflows reusables; no vale el refactor para 2 jobs.
- Actions de terceros pineadas por tag mayor (`@v4`/`@v6`/`@v7`), no por SHA de commit [.github/workflows/ci.yml] — deferred, consistente con el resto de `ci.yml` ya pineado igual; decisión de política a nivel de repo, no específica de esta historia.
- `needs: [...]` trata un job "skipped" como satisfecho igual que "success" [.github/workflows/ci.yml] — deferred, latente: hoy ninguno de los 5 jobs existentes tiene condiciones propias, sin impacto actual.
- Sin alerta si una imagen publica y la otra falla en el mismo push (estado "split-brain") [.github/workflows/ci.yml] — deferred, requiere monitoreo/alerting, fuera de alcance de esta historia.
- `config/brakeman.ignore` es una excepción de seguridad autoaprobada sin segundo revisor, ticket o fecha de vencimiento [config/brakeman.ignore] — deferred, razonable para este hallazgo puntual (confianza "Weak", código generado por Rails), pero no hay política de repo para excepciones de este tipo.
- El slot vacío "Cancha libre" es un `link_to` (`<a>`) estilizado como botón [app/views/turnos/index.html.erb:82] — deferred, nota de accesibilidad menor, preexistente en la vista, fuera de alcance de esta historia.
- AC3/AC4 de la Story 6.1 verificados por inspección de código/diseño en vez de un PR real o un build roto real — deferred, decisión explícita ya documentada en Completion Notes (evitar ensuciar el historial de Packages/Actions con runs de prueba).
- Falta traducción al español para el mensaje de presence de la asociación `cancha` en `Turno` (`belongs_to :cancha`, requerida por default) — se ve literalmente "Translation missing..." incrustado en cualquier mensaje de validación que la mencione [config/locales/es.yml] — deferred, preexistente, sin relación con CI/CD; hallazgo nuevo encontrado al verificar empíricamente la clave `record_invalid` de esta historia.

## Deferred from: code review of 6-2-configuracion-real-de-despliegue-kamal.md (2026-06-22)
- Accesorio `db` en loopback (`127.0.0.1:5432:5432`) + alcanzabilidad vía nombre de contenedor `retroai-db` sin verificar contra un droplet real [config/deploy.yml accessories.db] — deferred, ya señalado explícitamente como "Riesgo no resuelto" en los Dev Notes de la Story 6.2; no verificable sin droplet real (AC3 fuera de alcance).
- Sin estrategia de backup/DR para el volumen persistente de Postgres [config/deploy.yml accessories.db.directories] — deferred, ninguna AC de la Story 6.2 lo pide; madurez de infraestructura para una historia futura.
- Sin configuración de SSL/proxy/dominio documentada para `web` en producción [config/deploy.yml, README.md] — deferred, trabajo de infraestructura más amplio (dominio, certificados), fuera del alcance de la Story 6.2.
- Accesorio `whatsapp` sin healthcheck/puerto publicado para monitoreo externo (el `health-server.ts` interno del servicio queda sin nadie que lo consulte) [config/deploy.yml accessories.whatsapp] — deferred, consistente con que `web` tampoco tiene proxy/healthcheck en este mismo archivo; mejora de observabilidad futura.
- `.kamal/secrets` no usa guard `${VAR:?...}` para `KAMAL_REGISTRY_PASSWORD`/`RETROAI_DATABASE_PASSWORD` — un secreto vacío/no seteado falla más adelante con un error menos claro en vez de fallar rápido [.kamal/secrets] — deferred, mejora de robustez, no un bug funcional.
- Sin runbook de rotación para `POSTGRES_PASSWORD`/PAT de GHCR — las env vars de la imagen oficial de Postgres solo aplican en la primera inicialización del volumen; una rotación futura requeriría procedimiento manual propio [README.md, .kamal/secrets] — deferred, primer deploy es virgen, no aplica todavía.
- `README.md` (paso `bin/kamal setup`) no advierte sobre contenedores/puertos preexistentes en el droplet de un intento previo, ni que el placeholder `203.0.113.10` no tiene ningún gate automático que impida olvidarlo [README.md] — deferred, mejora de runbook, AC3 ya documenta el placeholder como acción manual.
- `architecture.md` describe `whatsapp` como "servicio", pero la Story 6.2 (Task 0) lo modela como accesorio Kamal — decisión ya razonada y documentada explícitamente en la propia historia; solo falta alinear la terminología de `architecture.md` [_bmad-output/planning-artifacts/architecture.md] — deferred, cosmético, no bloqueante.

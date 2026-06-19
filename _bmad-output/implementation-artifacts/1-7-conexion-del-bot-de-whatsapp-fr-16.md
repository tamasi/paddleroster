---
story_id: "1.7"
story_key: "1-7-conexion-del-bot-de-whatsapp-fr-16"
epic_id: "1"
title: "Conexión del Bot de WhatsApp (FR-16)"
status: "done"
last_updated: "2026-06-19"
baseline_commit: "0820f19a16a2c9e6383367d451a2d8b0c0488ae1"
---

# Story 1.7: Conexión del Bot de WhatsApp (FR-16)

**As a** Dueño del Complejo,
**I want** conectar y administrar el número de WhatsApp de mi Bot desde Configuración,
**So that** no dependa de acceso al servidor para emparejar o re-emparejar el Bot.

## Acceptance Criteria

- **AC1: Estado Desconectado**
  - **Given** que soy Dueño autenticado en Configuración
  - **When** el Bot no tiene ninguna sesión de WhatsApp activa
  - **Then** veo el estado "Desconectado" y un botón para iniciar la conexión

- **AC2: Emparejamiento por QR**
  - **Given** que inicio la conexión desde Configuración
  - **When** el Bot todavía no fue emparejado
  - **Then** veo un código QR para escanear con la app de WhatsApp, el mismo mecanismo que hoy solo se ve por terminal

- **AC3: Conectado, número detectado automáticamente**
  - **Given** que escaneo el QR con mi WhatsApp
  - **When** el emparejamiento se completa
  - **Then** Configuración muestra el estado "Conectado" junto con el número de WhatsApp vinculado, detectado automáticamente (nunca ingresado a mano)

- **AC4: Desconectar / re-emparejar**
  - **Given** que el Bot está Conectado
  - **When** toco "Desconectar"
  - **Then** la sesión se cierra, vuelve a mostrarse el estado "Desconectado" y puedo iniciar un nuevo emparejamiento con otro número

- **AC5: RBAC**
  - **Given** que soy Empleado autenticado
  - **When** intento acceder a esta sección de Configuración (por navegación o URL directa)
  - **Then** el acceso me es denegado (consistente con Story 1.3 / FR-12)

## Tasks / Subtasks

### Task 1: Datos — tabla compartida `whatsapp_connections`
- [x] T1.1: Migración `CreateWhatsappConnections`: `complejo_id` (FK a `complejos`, índice único — una conexión por Complejo), `status:string` (default `"disconnected"`), `phone:string` (nullable), `qr_code:text` (nullable), `requested_action:string` (nullable), timestamps
- [x] T1.2: `bin/rails db:migrate`
- [x] T1.3: Modelo `app/models/whatsapp_connection.rb`: `belongs_to :complejo`, `validates :complejo_id, uniqueness: true`, `VALID_STATUSES = %w[disconnected connecting connected]`, `VALID_ACTIONS = %w[connect disconnect]`, `validates :status, inclusion: { in: VALID_STATUSES }`, `validates :requested_action, inclusion: { in: VALID_ACTIONS }, allow_nil: true` — mismo patrón que `WhatsappOutboxMessage` (`app/models/whatsapp_outbox_message.rb`): strings simples, no `enum` de Rails, porque la tabla la lee/escribe también `whatsapp-service/` (TypeScript) — un enum numérico de Rails forzaría sincronizar un mapeo en el otro lenguaje.
- [x] T1.4: Agregar `def self.for_complejo!(complejo); find_or_create_by!(complejo: complejo); rescue ActiveRecord::RecordNotUnique; find_by!(complejo: complejo); end` al modelo — `find_or_create_by!` no es atómico: dos requests casi simultáneos contra `WhatsappConnectionsController#show` (ej. la primera vez que el Dueño abre Configuración y el frame dispara su propio fetch) podrían chocar contra el índice único de `complejo_id`. Este class method es el único punto de creación perezosa (T3.3 lo usa, ver Project Structure Notes sobre por qué `ConfiguracionController` no lo necesita).

### Task 2: `whatsapp-service` — persistir estado/QR/número en `whatsapp_connections`
- [x] T2.1: Agregar dependencia `qrcode` (no confundir con `qrcode-terminal`, que ya está y solo genera ASCII de terminal) a `whatsapp-service/package.json` — se necesita para convertir el string QR de Baileys a una imagen `data:image/png;base64,...` que Rails pueda renderizar con `image_tag` sin URLs externas.
- [x] T2.2: Crear `whatsapp-service/src/connection-status.ts` con una función `upsertConnectionStatus({ status, phone, qrCode })`: hace `UPDATE whatsapp_connections SET status = $1, phone = $2, qr_code = $3, requested_action = NULL, updated_at = NOW()`. Como el MVP sigue siendo de un único Complejo activo, no hay que resolver "cuál" fila — usar la primera fila existente (`ORDER BY id ASC LIMIT 1`); si no existe ninguna, no hacer nada (la fila la crea Rails de forma perezosa, ver Task 3).
- [x] T2.3: Modificar `connectToWhatsApp()` en `whatsapp-service/src/baileys-client.ts` (NO reescribir desde cero, ya maneja `creds.update`/`connection.update`/reconexión dentro de un único handler `sock.ev.on("connection.update", ...)` — agregar las llamadas a `upsertConnectionStatus` dentro de cada branch existente, no crear handlers nuevos):
  - En el branch `if (qr) { ... }`: además de `qrcode.generate(qr, ...)` (se mantiene, sigue siendo útil para debug por terminal), generar `await qrcodeLib.toDataURL(qr)` y llamar `upsertConnectionStatus({ status: "connecting", phone: null, qrCode: dataUri })`.
  - En el branch `if (connection === "open") { ... }`: llamar `upsertConnectionStatus({ status: "connected", phone: jidToPhone(sock.user!.id), qrCode: null })` — usar la función `jidToPhone` que ya existe en el archivo.
  - En el branch `if (connection === "close") { ... }`, sub-caso `loggedOut` true: llamar `upsertConnectionStatus({ status: "disconnected", phone: null, qrCode: null })`.
  - Mismo branch, sub-caso de reconexión automática (no-logout, el que hace `setTimeout(() => connectToWhatsApp(), 5000)`): NO tocar el estado persistido — sigue siendo `"connected"` o `"connecting"` según corresponda; la reconexión es transparente, no hace falta un cuarto estado.
  - **Vocabularios de estado distintos, no confundir:** `ConnectionState` (el tipo TS existente, valores `"open" | "close" | "connecting"`, en memoria, devuelto por `getConnectionState()`) y `whatsapp_connections.status` (persistido, valores `"disconnected" | "connecting" | "connected"`, T1.3) son **dos vocabularios separados** — no son el mismo string. No reusar el valor de `getConnectionState()` directamente como `status` de la tabla; cada uno se actualiza por separado en el lugar que le corresponde.
  - **Guard de conexión concurrente:** agregar `let connectionInFlight = false;` a nivel de módulo. Al inicio de `connectToWhatsApp()`: `if (connectionInFlight) return; connectionInFlight = true;` — limpiar a `false` cuando el branch `open` o el branch `close` con `loggedOut` se ejecuten (la conexión deja de estar "en vuelo" al resolverse, en cualquier sentido). Esto evita invocaciones concurrentes si el Dueño clickea "Conectar" mientras una conexión anterior todavía está en curso (T2.5 depende de este flag).
- [x] T2.4: Agregar función `disconnectWhatsApp(): Promise<void>` en `baileys-client.ts` que llama `await sock?.logout()` — esto dispara naturalmente el evento `connection.update` con `loggedOut: true` (T2.3 ya lo cubre).
- [x] T2.5: Crear `whatsapp-service/src/connection-poller.ts` — mismo patrón que `outbox-poller.ts` (`setInterval` cada 2.5s + guard `isPolling`, ver Dev Notes): lee `SELECT id, requested_action FROM whatsapp_connections WHERE requested_action IS NOT NULL LIMIT 1 FOR UPDATE SKIP LOCKED`. Si `requested_action = 'connect'` y `getConnectionState() !== "open"` → llamar `connectToWhatsApp()` (el guard `connectionInFlight` de T2.3 absorbe el caso de que ya haya una en curso — no hace falta duplicar esa lógica acá). Si `requested_action = 'disconnect'` → llamar `disconnectWhatsApp()`. Limpiar `requested_action` a `NULL` después de disparar la acción (no esperar a que termine — el resultado lo refleja T2.3 vía `upsertConnectionStatus`).
- [x] T2.6: Registrar `startConnectionPoller()` en `whatsapp-service/src/index.ts`, junto a `startOutboxPoller()`.

### Task 3: Rails — Controller, rutas y policy
- [x] T3.1: `app/policies/whatsapp_connection_policy.rb` — `show?`/`update?` → `user.owner?` (mismo patrón que `ConfiguracionPolicy`).
- [x] T3.2: Rutas en `config/routes.rb`, anidadas en `resource :configuracion`: `resource :whatsapp_connection, only: [:show], controller: "whatsapp_connections" do member { post :connect; post :disconnect } end` (resource singular: hay una sola conexión por Complejo en este MVP).
- [x] T3.3: `app/controllers/whatsapp_connections_controller.rb`: `set_complejo` (mismo patrón que `CanchasController`) + `WhatsappConnection.for_complejo!(@complejo)` (T1.4) para obtener `@whatsapp_connection` en todas las acciones. `#show` (`authorize @whatsapp_connection`, renderiza el turbo-frame con el estado actual — usado tanto por la carga inicial de Configuración como por el polling de T4.3). `#connect`: `authorize`, `@whatsapp_connection.update!(requested_action: "connect")`, redirige a `configuracion_path` (o responde turbo-stream). `#disconnect`: igual con `requested_action: "disconnect"`.

### Task 4: UI — sección "Bot de WhatsApp" en Configuración
- [x] T4.1: Partial `app/views/configuracion/_whatsapp_connection.html.erb` envuelto en `<%= turbo_frame_tag "whatsapp-connection-status", src: whatsapp_connection_path do %>` — **el `src:` es obligatorio**: `FrameElement#reload()` (T4.3) solo re-fetchea si el frame tiene un `src` apuntando a una URL; un frame inline sin `src` no tiene nada que recargar y el polling de T4.3 sería un no-op silencioso. Contenido: pill de estado (ver Dev Notes para mapeo de colores), el número si `connected?`, el QR si `connecting?` y hay `qr_code` — `image_tag @whatsapp_connection.qr_code` funciona directamente con el data URI `data:image/png;base64,...` generado en T2.3/T2.1 (Rails pasa URIs de datos tal cual al atributo `src`, sin necesitar `asset_path` ni guardar el archivo en `public/`) — botón "Conectar" (`button_to ... whatsapp_connection_connect_path`) si `disconnected?`, botón "Desconectar" si `connected?`.
- [x] T4.2: Agregar la sección a `app/views/configuracion/show.html.erb`, como tercera `<section>` (mismo patrón visual que "Canchas"/"Empleados"): título "Bot de WhatsApp" + `render "configuracion/whatsapp_connection"` (el partial resuelve su propio contenido vía el turbo-frame con `src`, T4.1 — `ConfiguracionController#show` no necesita cargar `@whatsapp_connection` él mismo).
- [x] T4.3: Stimulus controller `app/javascript/controllers/whatsapp_connection_controller.js`: mientras el estado mostrado sea "Conectando", llama `setInterval(() => this.element.reload(), 3000)` sobre el `<turbo-frame>` (`this.element` es el propio frame, `connect()` del controller Stimulus se dispara cuando el frame se conecta al DOM — usar la API `reload()` nativa de Turbo 8, ya disponible vía Importmap, no agregar dependencias JS nuevas). Detener el intervalo (`clearInterval`) cuando el estado deje de ser "Conectando" (conectado o desconectado) — comparar `data-status` en el frame, actualizado en cada respuesta del servidor.

### Task 5: Tests
- [x] T5.1: `test/models/whatsapp_connection_test.rb` — validaciones de `status`/`requested_action`, unicidad de `complejo_id`.
- [x] T5.2: `test/policies/whatsapp_connection_policy_test.rb` — owner permitido, empleado denegado (mismo patrón que `configuracion_policy_test.rb`).
- [x] T5.3: `test/controllers/whatsapp_connections_controller_test.rb` — owner ve el estado, puede `connect`/`disconnect` (verificar que `requested_action` se setea); empleado denegado por URL directa (AC5).
- [x] T5.4: `bin/rails test` y `bin/rubocop`. **No** se requiere test formal del lado `whatsapp-service/` (consistente con `architecture.md` → Test Organization: "`whatsapp-service/` no requiere suite de tests formal en el MVP").

### Review Findings

- [x] [Review][Patch] `connectionInFlight` nunca se resetea si `connectToWhatsApp()` lanza una excepción antes de registrar los event handlers (ej. `useMultiFileAuthState`/`fetchLatestBaileysVersion`/`makeWASocket` fallan) — "Conectar" queda como no-op silencioso permanente hasta reiniciar el servicio. [whatsapp-service/src/baileys-client.ts] — **Resuelto:** se extrajo el cuerpo a `connectToWhatsAppUnguarded()`, envuelto en `try/catch` que resetea `connectionInFlight = false` y re-lanza el error (los callers existentes ya lo manejan: `index.ts` sale del proceso, el poller lo loguea).
- [x] [Review][Patch] Primer arranque del servicio (antes de que el Dueño visite Configuración por primera vez): `connectToWhatsApp()` se dispara igual en `index.ts` y el primer QR/estado se pierde silenciosamente porque la fila `whatsapp_connections` todavía no existe. [whatsapp-service/src/connection-status.ts, db/seeds.rb] — **Resuelto distinto a lo propuesto:** en vez de sembrar la fila en `db/seeds.rb` (que solo corre en development), `upsertConnectionStatus` ahora hace un `INSERT ... SELECT ... FROM complejos LIMIT 1 ON CONFLICT (complejo_id) DO UPDATE` — crea la fila si falta y la actualiza si ya existe, sin depender de que Rails la haya creado primero. Funciona en cualquier entorno. Verificado manualmente contra la DB de development (fila inexistente → INSERT; segunda llamada → UPDATE del mismo registro).
- [x] [Review][Patch] `disconnectWhatsApp()` no persiste `status: "disconnected"` por sí mismo — depende enteramente de que el evento `connection.update` (close+loggedOut) se dispare; si `sock.logout()` lanza una excepción o el evento se demora, el clic en "Desconectar" del Dueño no se refleja (viola la garantía literal de AC4). [whatsapp-service/src/baileys-client.ts] — **Resuelto:** `sock.logout()` envuelto en `try/catch`, y en un `finally` se llama `upsertConnectionStatus({status: "disconnected", ...})` directamente — el handler de `connection.update` lo vuelve a setear cuando el evento llegue, de forma idempotente.
- [x] [Review][Patch] `jidToPhone(sock!.user!.id)` usa doble non-null assertion sin guarda — si Baileys disparara "open" antes de poblar `sock.user`, rompería el handler sin protección. [whatsapp-service/src/baileys-client.ts] — **Resuelto:** cambiado a `sock?.user?.id ? jidToPhone(sock.user.id) : null`.
- [x] [Review][Defer] `upsertConnectionStatus`/`connection-poller.ts` siempre operan sobre "la primera fila"/el socket global, ignorando `complejo_id` — deferred, decisión de alcance ya documentada (PRD §10 Guardrails, Out of Scope de esta historia, decision-log): un solo Complejo activo por diseño en este MVP, sin multi-sesión real.
- [x] [Review][Defer] `SELECT...FOR UPDATE SKIP LOCKED` en `connection-poller.ts` sin transacción explícita, el lock no protege nada como está escrito — deferred, replica exactamente el mismo patrón preexistente de `outbox-poller.ts` (Story 5.1), no es una regresión de esta historia.
- [x] [Review][Defer] Polling del Stimulus controller sin límite de tiempo ni vía de escape si el QR nunca se escanea — deferred, mejora de UX, ninguna AC lo exige.

---

## Dev Notes

### Hallazgo de `architecture.md` que respalda esta historia
`architecture.md` (Process Patterns → Error Handling) ya anticipaba esto sin haberlo construido: *"Errores del servicio Baileys (mensajes en failed): no se muestran como error de UI al usuario — quedan visibles en una vista de 'Estado del Bot' (Configuración) para Dueño, y disparan la alerta de Telegram."* Y en Gap Analysis (Nice-to-Have): *"Documentar un runbook breve de 'qué hacer si hay que re-escanear el QR de WhatsApp'."* Esta historia construye exactamente esa vista — no es un agregado ad-hoc, cierra un gap ya identificado en la arquitectura original.

### Nueva pieza arquitectónica: tabla `whatsapp_connections`
El límite de servicio documentado en `architecture.md` (`Service Boundaries`) decía que la única frontera entre Rails y `whatsapp-service/` eran las tablas `whatsapp_outbox`/`whatsapp_inbox`. Esta historia agrega una tercera tabla compartida, **siguiendo el mismo patrón exacto** (texto plano, sin JSON estructurado, columnas de estado en string simple legibles desde ambos lenguajes, polling cada ~2.5s) — no es una desviación de arquitectura, es una extensión consistente del mismo contrato. Recomendación (no bloqueante para esta historia): agregar una entrada breve a `architecture.md` § Data Architecture / API & Communication Patterns documentando `whatsapp_connections` una vez implementada, para que el documento siga siendo la fuente de verdad completa.

### Regla de Oro: No reinventar
- `whatsapp-service/src/db.ts` ya expone `query<T>(sql, params)` sobre un pool `pg` compartido — usarlo tal cual para toda consulta nueva a `whatsapp_connections`, no crear una conexión nueva.
- El patrón de poller (`setInterval` + guard `isPolling` + `try/finally`) ya está en `whatsapp-service/src/outbox-poller.ts` — clonar la forma, no reinventar el mecanismo.
- `jidToPhone`/`phoneToJid` ya existen en `baileys-client.ts` — reusar para extraer el número del `sock.user.id` tras conectar.
- Colores: no inventar paleta nueva para los 3 estados. Reusar los tokens de `DESIGN.md` ya mapeados en `StatusPillComponent` (`app/components/status_pill_component.rb`): "Conectado" → mismos tokens que `paid`/`confirmed` (verde/éxito), "Conectando" → mismos tokens que `pending` (azul/accent), "Desconectado" → mismos tokens que `cancelled`/`uncovered` (rojo/danger). No es obligatorio reusar el componente `StatusPillComponent` en sí (su `label`/`context` están atados a los dominios de pago/roster/turno, no a conexión de Bot) — alcanza con reusar las mismas clases Tailwind de token.
- `WhatsappConnection.for_complejo!` (T1.4) para crear el registro perezosamente — mismo espíritu que `ComplexPlayer.find_or_create_by!` en `BotTurnoCreationService`, pero con el rescue de unicidad que ese otro caso no necesita (acá hay un índice único real en juego).
- `WhatsappOutboxMessage` (`app/models/whatsapp_outbox_message.rb`) es la referencia de cómo validar un campo `status` de tabla compartida con `VALID_STATUSES` + `validates ... inclusion:` en vez de `enum` — clonar ese patrón para `WhatsappConnection`.

### Limitación de entorno conocida (Story 1.6)
Los tests de sistema (`test/system/`, requieren ChromeDriver) no pueden ejecutarse en este entorno de desarrollo (falta una dependencia nativa, sin `sudo`). Esta historia no requiere un test de sistema nuevo — Task 5 se cubre con tests de modelo/policy/controller (request specs), que sí corren. Si en algún punto se considera necesario verificar el polling del Stimulus controller end-to-end, documentarlo como gap conocido en vez de intentar correr `test/system` (ver Debug Log de Story 1.6 para el error exacto).

### Architecture Compliance
- `WhatsappConnection` vive en `app/models/`, `WhatsappConnectionsController` en `app/controllers/`, `WhatsappConnectionPolicy` en `app/policies/` — convención Rails estándar, ningún directorio nuevo.
- `whatsapp-service/` sigue sin tener migraciones propias ni lógica de negocio — solo lee/escribe la tabla que Rails ya migró, igual que con `whatsapp_outbox`/`whatsapp_inbox`.
- snake_case en Rails/DB, camelCase en `whatsapp-service/` (`upsertConnectionStatus`, `connection-poller.ts`) — consistente con `architecture.md` → Naming Patterns.

### Project Structure Notes
- No hace falta tocar `RosterReplacementService`, `BotConfirmationService` ni ningún servicio del Bot existente — esta historia es ortogonal al flujo de roster/confirmación/reemplazo (Epic 5), toca solo infraestructura de conexión.
- Gracias al `src:` del turbo-frame (T4.1), `ConfiguracionController#show` no necesita cargar `@whatsapp_connection` — el frame hace su propio request a `WhatsappConnectionsController#show`, que es el único lugar que llama `WhatsappConnection.for_complejo!` (T1.4). Sin duplicación entre los dos controllers.

### References
- [Source: architecture.md#Process-Patterns] — vista "Estado del Bot" ya anticipada.
- [Source: architecture.md#Gap-Analysis-Results] — runbook de re-escaneo de QR, nice-to-have ya identificado.
- [Source: architecture.md#Data-Architecture, #API-and-Communication-Patterns, #Format-Patterns] — patrón de tablas compartidas en texto plano, contrato `whatsapp_outbox`/`whatsapp_inbox` a extender de la misma forma.
- [Source: prd.md#4.6-Conexión-del-Bot-de-WhatsApp] — FR-16, agregado en la actualización del PRD del 2026-06-18.
- [Source: epics.md#Epic-1, Story 1.7] — historia y acceptance criteria originales.
- [Source: whatsapp-service/src/baileys-client.ts, outbox-poller.ts, db.ts] — código real a extender, no reescribir.
- [Source: app/views/configuracion/show.html.erb, app/controllers/canchas_controller.rb] — patrón establecido de secciones de Configuración y `set_complejo`.

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

_Vacío_

### Completion Notes List

- Validación independiente del checklist (agente fresco) encontró 3 issues críticos antes de implementar, ya corregidos en el archivo de la historia: vocabularios de estado distintos (`ConnectionState` en memoria vs. `whatsapp_connections.status` persistido) que no había que confundir, `find_or_create_by!` no atómico (resuelto con `WhatsappConnection.for_complejo!` + rescue de `RecordNotUnique`), y guard de conexión concurrente (`connectionInFlight`) para que clickear "Conectar" dos veces no dispare dos `connectToWhatsApp()` en paralelo.
- Diseño final del turbo-frame: `data-controller`/`data-status` viven en el propio `<turbo-frame>` (no en un div interno), porque `FrameElement#reload()` (usado por el Stimulus controller) es un método del frame — el controller necesita que `this.element` sea el frame mismo.
- `ConfiguracionController#show` NO carga `@whatsapp_connection` — la sección en `configuracion/show.html.erb` es un `turbo_frame_tag` placeholder con `src:`, que el propio navegador refetchea contra `WhatsappConnectionsController#show` al cargar la página. Esto evita la duplicación de `WhatsappConnection.for_complejo!` entre dos controllers (y el riesgo de carrera que eso traería).
- `whatsapp-service/`: `connectToWhatsApp()` y `connection-poller.ts` extendidos sin reescribir nada existente — se agregaron las llamadas a `upsertConnectionStatus`/el guard `connectionInFlight` dentro de los branches ya existentes de `connection.update`. `npx tsc --noEmit` sin errores (no hay suite de tests formal para este servicio, consistente con `architecture.md`).
- Verificación de UI manual (no había `chromium-cli` disponible en este entorno, ni tampoco Chrome — mismo gap ya documentado en Story 1.6): se levantó `bin/rails server` y se verificó por `curl` con sesión real de Dueño/Empleado contra `RAILS_ENV=development`: estado "Desconectado" + botón "Conectar" se renderiza correctamente; tras togglear el registro a mano (sin levantar `whatsapp-service` real — no corresponde disparar una conexión real a WhatsApp en una verificación de desarrollo) se confirmó el render de "Conectando" con el QR como `<img>` con el data URI, y "Conectado" con el número y botón "Desconectar". Empleado denegado tanto por GET como por POST (302 a `/`). Estado de la tabla restaurado a `disconnected` al finalizar.
- Suite completa: 276/276 tests verde (259 baseline + 17 nuevos: 9 modelo, 2 policy, 6 controller). `bin/rubocop` sobre los 9 archivos `.rb` nuevos/modificados: 0 offenses (los 5 offenses restantes en el repo son preexistentes, en archivos no tocados por esta historia).

### File List

**NEW:**
- `db/migrate/20260618213124_create_whatsapp_connections.rb`
- `app/models/whatsapp_connection.rb`
- `app/policies/whatsapp_connection_policy.rb`
- `app/controllers/whatsapp_connections_controller.rb`
- `app/views/whatsapp_connections/show.html.erb`
- `app/views/configuracion/_whatsapp_connection.html.erb`
- `app/javascript/controllers/whatsapp_connection_controller.js`
- `whatsapp-service/src/connection-status.ts`
- `whatsapp-service/src/connection-poller.ts`
- `test/models/whatsapp_connection_test.rb`
- `test/policies/whatsapp_connection_policy_test.rb`
- `test/controllers/whatsapp_connections_controller_test.rb`

**MODIFIED:**
- `db/schema.rb` (tabla `whatsapp_connections`)
- `app/helpers/status_presentation_helper.rb` (`humanize_whatsapp_connection_status`, `whatsapp_connection_badge_classes`)
- `app/views/configuracion/show.html.erb` (sección "Bot de WhatsApp")
- `config/routes.rb` (`resource :whatsapp_connection` anidado en `configuracion`)
- `whatsapp-service/src/baileys-client.ts` (persistencia de estado/QR/número, `disconnectWhatsApp`, guard `connectionInFlight`)
- `whatsapp-service/src/index.ts` (registra `startConnectionPoller()`)
- `whatsapp-service/package.json` / `package-lock.json` (dependencia `qrcode` + `@types/qrcode`)
- `app/assets/builds/tailwind.css` (regenerado por el build de Tailwind)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (status tracking)

## Change Log

- 2026-06-19: Implementación completa (dev-story workflow). Tabla y modelo `WhatsappConnection`, extensión de `whatsapp-service/` (estado/QR/número persistidos, poller de `requested_action`, guard de conexión concurrente), `WhatsappConnectionsController`/policy/rutas, sección "Bot de WhatsApp" en Configuración con turbo-frame + Stimulus polling. Suite completa: 276/276 verde, rubocop 0 offenses. Status → `review`.
- 2026-06-19: Code review (3 capas: Blind Hunter, Edge Case Hunter, Acceptance Auditor — 2 de las 3 fallaron en el primer intento por una restricción de sandbox sobre `/tmp` que les impedía leer el diff, resuelto copiándolo dentro del repo y reintentando). 4 patches aplicados: guard de `connectionInFlight` con reset-on-error en `connectToWhatsApp()`, `upsertConnectionStatus` convertido a upsert real (`INSERT...ON CONFLICT`) para no perder el primer QR si la fila todavía no existe, `disconnectWhatsApp()` persiste `disconnected` explícitamente en vez de depender solo del evento async, guarda defensiva en `jidToPhone(sock.user.id)`. 3 items diferidos a `deferred-work.md` (uno es una decisión de alcance ya documentada, no un gap nuevo; los otros dos son patrones preexistentes/mejoras de UX sin AC asociada). 12 hallazgos descartados como ruido o ya mitigados. Suite final: 276/276 verde, `npx tsc --noEmit` sin errores. Status → `done`.

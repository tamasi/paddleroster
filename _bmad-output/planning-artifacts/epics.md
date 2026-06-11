---
stepsCompleted: [1, 2, 3]
inputDocuments:
  - "{project-root}/_bmad-output/planning-artifacts/prds/prd-retroai-2026-06-11/prd.md"
  - "{project-root}/_bmad-output/planning-artifacts/architecture.md"
  - "{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-retroai-2026-06-10/DESIGN.md"
  - "{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-retroai-2026-06-10/EXPERIENCE.md"
---

# retroai - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for retroai, decomposing the requirements from the PRD, UX Design, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR-1: Un Capitán puede crear un Turno (Cancha, deporte, fecha, horario) y cargar su Roster inicial (nombres + contactos de WhatsApp) en una sola interacción con el Bot. El Bot valida números de WhatsApp y disponibilidad de Cancha/horario antes de enviar invitaciones.

FR-2: Cada Jugador de un Turno de Origen Bot recibe un mensaje individual del Bot y puede confirmar o rechazar su asistencia con una respuesta simple (botón/palabra clave). El Estado de Confirmación se actualiza en tiempo real, visible al Capitán (Bot) y en el Detalle de Turno del Panel.

FR-3: Un Jugador que había confirmado puede retirar su confirmación; el Bot ofrece su cupo a los Suplentes del Roster (en el orden listado por el Capitán) y, si alguno confirma, actualiza el Roster y notifica al Capitán. Si ningún Suplente confirma dentro del plazo definido, el cupo queda "Sin cubrir" y se notifica al Capitán.

FR-4: Administrador/Empleado pueden ver, para cualquier Cancha y fecha, qué horarios tienen un Turno y cuáles están libres ("Cancha libre" es accionable).

FR-5: Administrador/Empleado pueden crear un Turno de Origen Manual tocando un slot vacío del Calendario, completando Cancha/horario/deporte (pre-cargados) y un Roster básico (nombres, sin Estado de Confirmación).

FR-6: Administrador puede marcar un Turno (de Origen Manual) como recurrente (semanal); el sistema genera automáticamente las instancias futuras de ese Turno (misma Cancha, horario, día de la semana, Roster), modificables/cancelables individualmente sin afectar el Turno original. Solo el Dueño puede crear/editar Turnos Fijos.

FR-7: El sistema registra y conserva el Origen (Bot/Manual) de cada Turno, consultable para reporting (medición de SM-1).

FR-8: Administrador/Empleado pueden ver el Estado de Pago (Pagado/Parcial/Pendiente) de cualquier Turno, en Inicio, Calendario, Pagos y Detalle de Turno, siempre con texto explícito además de color.

FR-9: Administrador/Empleado pueden registrar un pago para un Turno (completo o parcial, con monto), actualizando su Estado de Pago de inmediato sin necesidad de recargar la pantalla. El registro queda asociado al Turno (monto, fecha).

FR-10: Dueño puede ver, para un período seleccionable (semana/mes), el porcentaje de Ocupación de cada Cancha desglosado por día y horario, distinguiendo pádel de fútbol 5, siempre con el valor numérico visible.

FR-11: Cualquier usuario (Dueño o Empleado) puede autenticarse individualmente en el Panel. Una sesión expirada redirige a Login y, tras reautenticar, devuelve al usuario a la pantalla donde estaba.

FR-12: El sistema distingue dos roles con accesos diferenciados: Dueño (Inicio, Calendario, Pagos, Reportes, Configuración) y Empleado (Inicio, Calendario, Pagos, Detalle de Turno, Nuevo Turno — sin Reportes ni Configuración, ni por navegación ni por URL/ruta directa).

FR-13: Dueño puede generar un link/código de invitación desde Configuración; un Empleado lo usa para crear su cuenta y queda asociado automáticamente al Complejo, con rol Empleado. Un link/código usado o expirado no permite crear una cuenta nueva.

FR-14: Dueño puede ver y editar, desde Configuración, los datos del Complejo (nombre, datos de contacto) y la lista de Canchas (nombre/identificador, deporte asociado). Las Canchas dadas de alta aparecen como columnas/agenda en el Calendario. Empleado no tiene acceso a esta sección.

FR-15: Administrador/Empleado pueden cancelar un Turno (de cualquier Origen) desde el Panel. Un Turno cancelado libera el horario en el Calendario. Para Turnos de Origen Bot, cancelar no modifica el Roster (permanece de solo lectura) ni notifica a los Jugadores vía Bot.

### NonFunctional Requirements

NFR-1: Las notificaciones del Bot (invitación, confirmación, cambio de roster) deben llegar en segundos, no minutos — crítico para coordinar reemplazos de último momento (FR-3).

NFR-2: El Estado de Pago del Panel se actualiza sin necesidad de recargar la pantalla tras registrar un pago (FR-9), vía Turbo Streams/Solid Cable.

NFR-3: RBAC a nivel de ruta (no solo de navegación): un Empleado no puede acceder a Configuración ni Reportes por URL/ruta directa (FR-12), aplicado vía Pundit policies.

NFR-4: Accesibilidad — contraste AA mínimo 4.5:1 en ambos modos (claro/oscuro); todo estado de pago/ocupación con texto explícito, nunca solo color; tap targets ≥44px en mobile; orden de foco en formularios sigue el orden visual.

NFR-5: Modo claro/oscuro disponible desde el día 1, con tokens propios por modo (no inversión automática), paleta "Pádel Pro" de `DESIGN.md`.

NFR-6: Diseño responsive mobile-first + notebook, mismo orden de información en ambos breakpoints (mismo dato, distinta disposición).

NFR-7: Sin presupuesto para servicios externos pagos en el MVP — cualquier costo recurrente debe evitarse o justificarse (condiciona el enfoque del Bot de WhatsApp y la elección de hosting/infraestructura).

NFR-8: El sistema valida contra un único Complejo piloto (7 Canchas) sin necesitar multi-tenancy, pero el modelo de datos no debe acoplar la identidad del Jugador al Complejo de forma irreversible (portabilidad futura multi-complejo).

NFR-9: Mantenibilidad por un desarrollador único — stack simple, "aburrido", de bajo overhead operativo, sin infraestructura que requiera administración constante.

### Additional Requirements

- **Starter template (Epic 1, Story 1)**: inicializar el proyecto con `rails new retroai --database=postgresql --css=tailwind` (Rails 8, PostgreSQL, Tailwind), más la configuración inicial mínima de `whatsapp-service/` (esqueleto Node/TS + conexión a Postgres + endpoint `/health`).
- **Modelo de datos compartido**: migraciones para `Player`, `Complex`, `Court`, `ComplexPlayer`, `Turno`, `RosterEntry`, `Payment` — `Player` desacoplado de `Complex` desde el día 1 (vía `ComplexPlayer`).
- **Autenticación y RBAC**: generador nativo de Rails 8 (`User` con `has_secure_password`, modelo `Session`) + Pundit (policies por controller) + modelo `Invitation` (`has_secure_token`, `expires_at`, `used_at`, `invited_by`).
- **Contrato whatsapp_outbox / whatsapp_inbox**: tablas Postgres compartidas entre Rails y `whatsapp-service/`, con polling cada 2-3seg, retry/backoff (5s/30s/2min → `failed`), texto plano, E.164, timestamps UTC.
- **Jobs de Solid Queue**: `ProcessWhatsappInboxJob`, `GenerateRecurringTurnosJob`, `SendWhatsappAlertJob`.
- **Servicios de dominio**: `RosterReplacementService` (FR-3), `WhatsappInboxProcessor`, `RecurringTurnoGenerator` (FR-6) — testeables sin levantar `whatsapp-service/` ni Postgres real.
- **Alertas operativas**: bot de Telegram (gratuito) — notifica si el health-check de `whatsapp-service/` falla o si hay mensajes `whatsapp_outbox` en `failed` acumulados.
- **CI/CD e infraestructura**: GitHub Actions (tests Minitest → build de imágenes → push a GHCR) + Kamal 2 → droplet DigitalOcean (4GB/2vCPU) con `config/deploy.yml` definiendo servicios `web` (Rails), `whatsapp` (adaptador) y accesorio Postgres.
- **Rate limiting**: `Rack::Attack` para el login.

### UX Design Requirements

UX-DR1: Implementar los ViewComponents de Component Patterns: `StatusPillComponent` (variantes `paid`/`pending`/`partial`), `CardTurnoComponent`, `InputFieldComponent`, `OccupancyBarComponent`, `BottomNavComponent`, `ButtonActionComponent`, `ButtonPrimaryComponent` — mapeando 1:1 los tokens visuales de `DESIGN.md`.

UX-DR2: Implementar la Information Architecture completa: Login, Inicio, Calendario, Nuevo Turno, Detalle de Turno, Pagos, Reportes (solo Dueño), Configuración (solo Dueño) — con los accesos por rol especificados (Dueño: 4 tabs + Configuración en menú de usuario; Empleado: 3 tabs, sin Reportes ni Configuración, ni en nav ni por URL).

UX-DR3: `card-turno`: tap abre Detalle de Turno (sheet/modal); muestra siempre el `status-pill` de pago y un conteo resumido del roster ("4/4 confirmados") — el detalle del roster vive solo en Detalle de Turno.

UX-DR4: Roster row en Detalle de Turno: si el Turno es de Origen Bot, cada fila muestra el Estado de Confirmación (Confirmado/Pendiente/Reemplazo) de solo lectura; si es de Origen Manual, el nombre es editable y no muestra estado de confirmación.

UX-DR5: `button-action` ("Registrar pago"): abre paso de confirmación (monto, "Pago completo"/"Pago parcial"); al confirmar, el `status-pill` se actualiza en el momento sin recargar la pantalla.

UX-DR6: `occupancy-bar`: en Inicio una barra por cancha (resumen del día); en Reportes una barra por combinación cancha/horario/día, navegable; siempre acompañada del valor numérico como texto adyacente (no solo ancho de barra).

UX-DR7: Voice & tone — microcopy en "vos", cercano y directo, confirmaciones cortas en el momento ("Turno guardado", "Pago registrado"), sin alertas modales para acciones de rutina.

UX-DR8: State patterns a implementar: "Sin turnos hoy" (Inicio, no es error), "Cancha libre" (Calendario, slot punteado, tap → Nuevo Turno pre-cargado), "Roster vacío" (Detalle de Turno, no bloquea registro de pago), "Roster con confirmaciones pendientes" (solo lectura), estados de Pago (Pendiente/Parcial/Pagado), "Carga inicial" (skeleton de 2-3 tarjetas, nunca spinner full-screen), "Sin conexión" (banner no bloqueante, datos visibles previos), "Sesión expirada" (redirige a Login y vuelve a la pantalla original tras reautenticar).

UX-DR9: Interaction primitives: tap como interacción primaria; tap en slot vacío del Calendario → Nuevo Turno pre-cargado; pull-to-refresh en Inicio y Calendario (mobile); swipe horizontal entre canchas en agenda mobile del Calendario; sheets/modales con confirmación de descarte si hay cambios sin guardar (no tap-fuera accidental); sin drag-and-drop ni "deslizar para confirmar".

UX-DR10: Accessibility floor: contraste AA 4.5:1 en ambos modos; `status-pill` siempre con texto explícito; `occupancy-bar` con porcentaje como texto adyacente; tap targets ≥44px incluyendo filas de roster y botones en sheets; orden de foco en formularios sigue el orden visual, errores anunciados junto al campo; modo oscuro con tokens `-dark` propios (no inversión automática).

UX-DR11: Responsive: Calendario — agenda vertical por cancha con swipe horizontal en mobile vs. grilla cancha×horario (7 columnas) en notebook (`md+`); Reportes — una barra a la vez con scroll vertical y selector en mobile vs. varias barras simultáneas en notebook; Detalle de Turno — sheet desde abajo en mobile vs. modal centrado en notebook, mismo contenido y orden.

UX-DR12: Dark mode toggle (Stimulus controller `dark-mode-toggle`) persistido en `localStorage`/cookie, clase `dark` en `<html>` + Tailwind `dark:`, tokens "Pádel Pro" de `DESIGN.md`.

### FR Coverage Map

FR-1: Epic 5 - Creación de Turno y Roster inicial vía Bot
FR-2: Epic 5 - Confirmación individual de asistencia
FR-3: Epic 5 - Reemplazo auto-gestionado de Suplentes
FR-4: Epic 2 - Calendario de Turnos por Cancha/horario
FR-5: Epic 2 - Creación manual de Turno
FR-6: Epic 2 - Turnos Fijos/Recurrentes
FR-7: Epic 2 - Registro del Origen del Turno
FR-8: Epic 3 - Visualización de Estado de Pago
FR-9: Epic 3 - Registro de Pago
FR-10: Epic 4 - Reporte de Ocupación
FR-11: Epic 1 - Login multi-usuario
FR-12: Epic 1 - Roles Dueño/Empleado
FR-13: Epic 1 - Invitación de Empleados
FR-14: Epic 1 - Gestión de Canchas y datos del Complejo
FR-15: Epic 2 - Cancelación de Turno desde el Panel

## Epic List

### Epic 1: Acceso y Configuración del Complejo
Dueño y Empleados pueden autenticarse en el Panel, el Dueño invita empleados sin cargar credenciales manualmente, y el Dueño configura los datos del Complejo y sus 7 Canchas — la base sobre la que se construye todo lo demás.
**FRs covered:** FR-11, FR-12, FR-13, FR-14

### Epic 2: Calendario y Gestión de Turnos
Administrador/Empleado ven el Calendario de las 7 Canchas, crean Turnos manuales (llamadas telefónicas), configuran Turnos Fijos recurrentes, cancelan Turnos, y el sistema registra el Origen de cada Turno para reporting — reemplaza el cuaderno de reservas para todo lo que no llega por el Bot.
**FRs covered:** FR-4, FR-5, FR-6, FR-7, FR-15

### Epic 3: Pagos
Administrador/Empleado ven y registran el Estado de Pago de cualquier Turno, con actualización inmediata sin recargar la pantalla — reemplaza el cuaderno de pagos.
**FRs covered:** FR-8, FR-9

### Epic 4: Reportes de Ocupación
El Dueño ve la Ocupación por Cancha/día/horario para un período seleccionable, distinguiendo pádel de fútbol 5 — visibilidad para decisiones comerciales que antes no existía.
**FRs covered:** FR-10

### Epic 5: Bot de WhatsApp — Roster con Confirmación y Reemplazo
Un Capitán crea un Turno y arma su Roster vía WhatsApp, cada Jugador confirma individualmente, y los reemplazos por cancelación se gestionan solos ofreciendo el cupo a los Suplentes — el diferencial central de retroai frente al cuaderno/WhatsApp informal.
**FRs covered:** FR-1, FR-2, FR-3

## Epic 1: Acceso y Configuración del Complejo

Dueño y Empleados pueden autenticarse en el Panel, el Dueño invita empleados sin cargar credenciales manualmente, y el Dueño configura los datos del Complejo y sus 7 Canchas — la base sobre la que se construye todo lo demás.

### Story 1.1: Inicialización del Proyecto

As a Hernan (desarrollador),
I want tener el proyecto Rails 8 inicializado con Tailwind/Postgres y el esqueleto del servicio `whatsapp-service` corriendo localmente,
So that pueda empezar a construir features sobre una base consistente con la arquitectura definida.

**Acceptance Criteria:**

**Given** que no existe el proyecto
**When** ejecuto `rails new retroai --database=postgresql --css=tailwind`
**Then** el proyecto arranca con `bin/dev` y sirve una página por defecto conectada a Postgres

**Given** el directorio `whatsapp-service/` creado con `package.json`/`tsconfig.json`/`Dockerfile`
**When** ejecuto `npm run dev`
**Then** el servicio expone `/health` respondiendo 200 con un cuerpo simple (sin conexión real a Baileys todavía)

**Given** el esqueleto de ambos servicios
**When** reviso el repo
**Then** la estructura de directorios coincide con la definida en `architecture.md` (Project Structure & Boundaries)

### Story 1.2: Login multi-usuario

As a Dueño o Empleado del Complejo,
I want autenticarme individualmente en el Panel,
So that pueda acceder a las funciones según mi rol sin compartir credenciales.

**Acceptance Criteria:**

**Given** un usuario con cuenta activa
**When** ingresa email y contraseña correctos en Login
**Then** accede a Inicio y queda autenticado (sesión creada vía el generador de auth de Rails 8)

**Given** credenciales incorrectas
**When** intenta loguearse
**Then** ve un mensaje de error inline en el formulario, sin revelar si el email existe

**Given** una sesión expirada mientras navega una pantalla autenticada
**When** la sesión expira
**Then** es redirigido a Login con el mensaje "Tu sesión expiró, iniciá sesión de nuevo"
**And** tras reautenticarse, vuelve a la pantalla donde estaba (UX-DR8)

**Given** el formulario de Login
**When** se renderiza
**Then** usa `{components.input-field}` con validación inline (UX-DR1, UX-DR10)

### Story 1.3: Roles y control de acceso Dueño/Empleado

As an administrador del sistema,
I want que el sistema distinga los roles Dueño y Empleado con accesos diferenciados,
So that cada usuario vea y use solo lo que corresponde a su rol.

**Acceptance Criteria:**

**Given** un usuario con rol Empleado autenticado
**When** navega el Panel
**Then** ve solo Inicio, Calendario y Pagos en `{components.bottom-nav}` (sin "Reportes"), según UX-DR2

**Given** un usuario con rol Dueño autenticado
**When** navega el Panel
**Then** ve Inicio, Calendario, Pagos, Reportes, y accede a Configuración desde el menú de usuario

**Given** el modelo `User`
**When** se crea
**Then** tiene una columna `role` (`owner`/`employee`) y una `ApplicationPolicy` base de Pundit que distingue ambos roles (NFR-3), de la que heredan las policies de cada sección a medida que se construyen (ej. `ConfiguracionPolicy` en Story 1.5, `ReportPolicy` en Story 4.1)

### Story 1.4: Invitación de Empleados

As a Dueño del Complejo,
I want generar un link/código de invitación para que un Empleado cree su cuenta,
So that no tenga que cargar credenciales manualmente para cada empleado.

**Acceptance Criteria:**

**Given** que estoy en Configuración como Dueño
**When** genero una invitación
**Then** el sistema crea un `Invitation` con token único, fecha de expiración, y queda asociada a mi Complejo

**Given** un link de invitación válido (no usado, no expirado)
**When** un Empleado lo abre y completa el formulario de registro
**Then** se crea su cuenta con rol `employee`, asociada automáticamente al mismo Complejo, sin intervención adicional del Dueño

**Given** un link de invitación ya usado o expirado
**When** alguien intenta usarlo para crear una cuenta
**Then** el sistema rechaza la creación de cuenta y muestra un mensaje claro

### Story 1.5: Configuración del Complejo y Canchas

As a Dueño del Complejo,
I want ver y editar los datos del Complejo y la lista de Canchas,
So that el Calendario y el resto del Panel reflejen la configuración real de mi complejo.

**Acceptance Criteria:**

**Given** que soy Dueño autenticado
**When** voy a Configuración
**Then** puedo ver y editar el nombre y datos de contacto del Complejo

**Given** que soy Dueño autenticado en Configuración
**When** agrego, edito o elimino una Cancha (nombre/identificador, deporte: pádel/fútbol 5)
**Then** el cambio se guarda y la Cancha aparece/desaparece inmediatamente como columna/agenda en el Calendario

**Given** que soy Empleado autenticado
**When** intento acceder a Configuración (por navegación o URL directa)
**Then** el acceso me es denegado (consistente con Story 1.3 / FR-12)

**Given** los seeds del Complejo piloto
**When** se cargan (`db/seeds.rb`)
**Then** existen las 7 Canchas iniciales (5 pádel + 2 fútbol 5)

### Story 1.6: Modo claro/oscuro global

As a usuario del Panel (Dueño o Empleado),
I want alternar entre modo claro y oscuro,
So that pueda usar el Panel cómodamente en distintas condiciones de luz (ej. mostrador con sol).

**Acceptance Criteria:**

**Given** que estoy en cualquier pantalla autenticada
**When** toco el toggle de tema en el header
**Then** la interfaz cambia entre modo claro/oscuro usando los tokens `-dark` de `DESIGN.md` (no inversión automática de colores)

**Given** que elegí un modo
**When** recargo la página o vuelvo a entrar
**Then** el modo elegido persiste (vía `localStorage`/cookie)

**Given** el modo oscuro activo
**When** reviso `status-pill`/`occupancy-bar`/textos
**Then** mantienen contraste AA 4.5:1 (NFR-4)

## Epic 2: Calendario y Gestión de Turnos

Administrador/Empleado ven el Calendario de las 7 Canchas, crean Turnos manuales (llamadas telefónicas), configuran Turnos Fijos recurrentes, cancelan Turnos, y el sistema registra el Origen de cada Turno para reporting — reemplaza el cuaderno de reservas para todo lo que no llega por el Bot.

**FRs cubiertos:** FR-4, FR-5, FR-6, FR-7, FR-15

### Story 2.1: Calendario de Turnos por Cancha/horario

As a Administrador o Empleado,
I want ver, para cualquier Cancha y fecha, qué horarios tienen un Turno y cuáles están libres,
So that pueda saber de un vistazo la disponibilidad del complejo sin un cuaderno.

**Acceptance Criteria:**

**Given** que estoy autenticado en el Panel
**When** abro Calendario y selecciono una fecha
**Then** veo las 7 Canchas con sus horarios, cada uno mostrando "Cancha libre" o una `card-turno` con Cancha, horario, reservante/roster resumido y Estado de Pago (`status-pill`)

**Given** un horario sin Turno
**When** lo veo en el Calendario
**Then** se muestra como "Cancha libre" con borde punteado y texto "Cancha libre — tocá para crear un turno" (UX-DR8), accionable

**Given** que estoy en mobile
**When** veo el Calendario
**Then** es una agenda vertical por cancha con swipe horizontal para cambiar de cancha (UX-DR11)
**And** en notebook (`md+`) es una grilla cancha×horario de 7 columnas, mismo dato

**Given** un Turno (de cualquier Origen)
**When** se crea
**Then** queda registrado con su `origin` (Bot/Manual), consultable para reporting (FR-7) — ej. es posible obtener la proporción de Turnos con Origen Bot sobre el total para un período

**Given** un Turno recién creado
**When** no tiene pago registrado todavía
**Then** su `status-pill` muestra "Pago Pendiente" por defecto

### Story 2.2: Creación manual de Turno

As a Administrador o Empleado,
I want crear un Turno de Origen Manual tocando un slot vacío del Calendario,
So that pueda registrar reservas que llegan por teléfono o mostrador.

**Acceptance Criteria:**

**Given** un slot "Cancha libre" en el Calendario
**When** lo toco
**Then** se abre Nuevo Turno con Cancha/horario/deporte pre-cargados (UX-DR9)

**Given** el formulario de Nuevo Turno abierto
**When** completo el nombre de quien reserva y, opcionalmente, un roster básico (nombres, sin Estado de Confirmación) y guardo
**Then** se crea un Turno de Origen Manual con un `Payment` en estado Pendiente

**Given** que guardé el Turno
**When** vuelvo al Calendario
**Then** el slot ya no aparece como "Cancha libre" sino como una `card-turno` con el nuevo Turno y su reservante

**Given** un Turno de Origen Manual
**When** abro su Detalle de Turno
**Then** el roster muestra nombres editables, sin Estado de Confirmación (UX-DR4)
**And** si el roster está vacío, se muestra "Todavía no cargaste el roster" sin bloquear el registro de pago (UX-DR8)

**Given** que el sistema valida disponibilidad
**When** intento crear un Turno sobre una Cancha/horario ya ocupado
**Then** el sistema lo impide

### Story 2.3: Cancelación de Turno desde el Panel

As a Administrador o Empleado,
I want cancelar un Turno (de cualquier Origen) desde el Panel,
So that el horario vuelva a estar disponible cuando una reserva no se concreta.

**Acceptance Criteria:**

**Given** un Turno (Bot o Manual)
**When** lo cancelo desde su Detalle de Turno
**Then** su estado pasa a Cancelado y el horario vuelve a mostrarse como "Cancha libre" en el Calendario (FR-4)

**Given** un Turno de Origen Bot
**When** lo cancelo desde el Panel
**Then** su Roster permanece de solo lectura (sin modificarse) y no se envía ninguna notificación a los Jugadores vía Bot

**Given** que cancelo un Turno
**When** confirmo la acción
**Then** veo una confirmación corta ("Turno cancelado") sin modal bloqueante (UX-DR7), con un paso de confirmación explícito antes de aplicar el cambio (no un gesto rápido, UX-DR9)

### Story 2.4: Turnos Fijos / Recurrentes

As a Dueño del Complejo,
I want marcar un Turno de Origen Manual como recurrente (semanal),
So that el sistema genere automáticamente las instancias futuras sin que tenga que crearlas a mano cada semana.

**Acceptance Criteria:**

**Given** que soy Dueño creando o editando un Turno de Origen Manual
**When** marco la opción "Marcar como recurrente"
**Then** el sistema genera automáticamente instancias futuras semanales (misma Cancha, horario, día de la semana, Roster) vía `RecurringTurnoGenerator`/`GenerateRecurringTurnosJob`

**Given** que soy Empleado
**When** abro el formulario de Nuevo Turno
**Then** no veo la opción "Marcar como recurrente" (oculta para Empleado)

**Given** instancias futuras generadas por un Turno Fijo
**When** las veo en el Calendario
**Then** cada una aparece como un Turno independiente con su propio Estado de Pago

**Given** una instancia futura de un Turno Fijo
**When** la modifico o cancelo individualmente
**Then** el cambio no afecta al Turno recurrente original ni a otras instancias

### Story 2.5: Inicio — resumen del día

As a Administrador o Empleado,
I want ver al entrar al Panel un resumen de la Ocupación de hoy por Cancha,
So that tenga una vista rápida del estado del día sin entrar al Calendario.

**Acceptance Criteria:**

**Given** que estoy autenticado en el Panel
**When** abro Inicio
**Then** veo una `occupancy-bar` por Cancha con el resumen de Turnos de hoy, junto con el valor numérico como texto adyacente (UX-DR6/UX-DR10)

**Given** que no hay Turnos cargados para hoy
**When** abro Inicio
**Then** veo el estado "Sin turnos hoy" (no es un error, UX-DR8)

**Given** que estoy en mobile
**When** deslizo hacia abajo en Inicio
**Then** se actualiza la información (pull-to-refresh, UX-DR9)

**Given** que soy Empleado
**When** abro Inicio
**Then** veo la misma información que el Dueño (Inicio no tiene restricciones de rol, a diferencia de Reportes/Configuración — FR-12)

## Epic 3: Pagos

Administrador/Empleado ven y registran el Estado de Pago de cualquier Turno, con actualización inmediata sin recargar la pantalla — reemplaza el cuaderno de pagos.

**FRs cubiertos:** FR-8, FR-9

### Story 3.1: Visualización del Estado de Pago

As a Administrador o Empleado,
I want ver el Estado de Pago de cualquier Turno en el Calendario y en su Detalle,
So that pueda saber de un vistazo qué Turnos tienen pagos pendientes sin revisar el cuaderno.

**Acceptance Criteria:**

**Given** un Turno con `Payment` en estado Pendiente
**When** lo veo en el Calendario o en su Detalle de Turno
**Then** su `status-pill` muestra "Pago Pendiente"

**Given** un Turno con `Payment` Parcial (monto pagado menor al total)
**When** lo veo
**Then** su `status-pill` muestra "Pago Parcial" junto con el monto pagado

**Given** un Turno con `Payment` Pagado (monto pagado igual al total)
**When** lo veo
**Then** su `status-pill` muestra "Pagado"

**Given** el Detalle de Turno
**When** lo abro
**Then** veo el historial de pagos registrados para ese Turno (monto, fecha, quién lo registró)

### Story 3.2: Registro de Pago

As a Administrador o Empleado,
I want registrar un pago (completo o parcial) para un Turno,
So that el Estado de Pago se actualice al instante y reemplace el cuaderno de pagos.

**Acceptance Criteria:**

**Given** el Detalle de Turno con Estado de Pago Pendiente o Parcial
**When** toco el `button-action` "Registrar pago"
**Then** se abre un paso de confirmación donde indico el monto y elijo "Pago completo" o "Pago parcial" (UX-DR5)

**Given** el paso de confirmación de "Registrar pago"
**When** confirmo
**Then** se crea un registro de pago asociado al Turno

**Given** que el monto ingresado sumado a pagos previos iguala el total esperado del Turno
**When** guardo
**Then** el Estado de Pago pasa a "Pagado" sin recargar la pantalla (Turbo Stream, FR-9/NFR-2)

**Given** que el monto ingresado sumado a pagos previos es menor al total esperado
**When** guardo
**Then** el Estado de Pago pasa a "Pago Parcial" mostrando el monto acumulado

**Given** que ingreso un monto que superaría el total esperado
**When** intento guardar
**Then** el sistema lo impide y muestra un error inline (sin recargar)

**Given** que registro un pago desde el Detalle de Turno
**When** la actualización se aplica
**Then** el `status-pill` correspondiente en el Calendario también se actualiza sin recargar la página (Turbo Streams)

## Epic 4: Reportes de Ocupación

El Dueño ve la Ocupación por Cancha/día/horario para un período seleccionable, distinguiendo pádel de fútbol 5 — visibilidad para decisiones comerciales que antes no existía.

**FRs cubiertos:** FR-10

### Story 4.1: Reporte de Ocupación por Cancha y período

As a Dueño del Complejo,
I want ver la Ocupación de cada Cancha (pádel vs fútbol 5) para un período seleccionable,
So that pueda tomar decisiones comerciales (ej. agregar horarios, promociones en horarios de baja ocupación).

**Acceptance Criteria:**

**Given** que soy Dueño
**When** abro Reportes
**Then** veo la Ocupación por Cancha/día/horario para un período seleccionable (ej. semana, mes, rango personalizado)

**Given** el período seleccionado
**When** veo el reporte
**Then** la Ocupación distingue claramente entre Canchas de pádel y de fútbol 5

**Given** que soy Empleado
**When** intento acceder a Reportes (por navegación o por URL directa)
**Then** el acceso me es denegado (`ReportPolicy`, FR-12/NFR-3)

**Given** el reporte de Ocupación
**When** lo visualizo
**Then** usa el componente `occupancy-bar` con contraste AA 4.5:1 (NFR-4) y es responsive (mobile/desktop, UX-DR11)

**Given** el cálculo de Ocupación para el período
**When** un Turno está Cancelado
**Then** ese horario no cuenta como ocupado

## Epic 5: Bot de WhatsApp — Roster con Confirmación y Reemplazo

Un Capitán crea un Turno y arma su Roster vía WhatsApp, cada Jugador confirma individualmente, y los reemplazos por cancelación se gestionan solos ofreciendo el cupo a los Suplentes — el diferencial central de retroai frente al cuaderno/WhatsApp informal.

**FRs cubiertos:** FR-1, FR-2, FR-3

### Story 5.1: Infraestructura del Bot de WhatsApp

As a Capitán,
I want que el Bot de WhatsApp esté conectado y responda a mensajes,
So that pueda interactuar con retroai desde WhatsApp sin instalar nada.

**Acceptance Criteria:**

**Given** que `whatsapp-service` está desplegado y vinculado a un número de WhatsApp (vía QR/Baileys)
**When** un usuario envía cualquier mensaje al número del Bot
**Then** el mensaje queda registrado en `whatsapp_inbox` y el Bot responde con un mensaje de bienvenida/ayuda

**Given** un mensaje saliente generado desde el Panel/Rails
**When** se inserta en `whatsapp_outbox`
**Then** `whatsapp-service` lo entrega al destinatario en segundos (NFR-1)

**Given** que `whatsapp-service` pierde la conexión con WhatsApp
**When** esto ocurre
**Then** se envía una alerta al Telegram de operaciones (`SendWhatsappAlertJob`)

**Given** un mensaje entrante en `whatsapp_inbox`
**When** llega
**Then** `ProcessWhatsappInboxJob` lo procesa de forma asíncrona (Solid Queue)

### Story 5.2: Creación de Turno y Roster inicial vía Bot (FR-1)

As a Capitán,
I want crear un Turno y cargar mi Roster inicial enviando un mensaje al Bot,
So that no tenga que coordinar manualmente por WhatsApp con cada jugador.

**Acceptance Criteria:**

**Given** que envío al Bot un mensaje con Cancha, deporte, fecha, horario y la lista de Jugadores (nombres/teléfonos)
**When** el formato es válido y no hay duplicados
**Then** se crea un Turno de Origen Bot con su Roster inicial, cada jugador con Estado de Confirmación "Pendiente"

**Given** que mi mensaje tiene una entrada inválida o duplicada (ej. teléfono repetido, formato incorrecto)
**When** el Bot la detecta
**Then** me reporta el error específico sin crear el Turno ni enviar nada a los Jugadores, hasta que lo corrija

**Given** un Jugador del Roster cuyo número ya existe como `Player`
**When** se crea el Turno
**Then** se vincula al `Player` existente sin duplicarlo, preservando la portabilidad del Jugador entre Complejos a futuro

**Given** un Jugador del Roster cuyo número no existe como `Player`
**When** se crea el Turno
**Then** se crea un nuevo `Player` asociado a ese Complejo vía `ComplexPlayer`

**Given** que el Turno se creó
**When** lo veo en el Calendario del Panel
**Then** aparece con Origen Bot y su Roster (FR-4/FR-7, Epic 2)

### Story 5.3: Confirmación individual de asistencia (FR-2)

As a Jugador,
I want confirmar mi asistencia a un Turno respondiendo al mensaje del Bot,
So that el Capitán sepa quién va a jugar sin preguntar uno por uno.

**Acceptance Criteria:**

**Given** que fui agregado al Roster de un Turno
**When** el Bot me contacta
**Then** recibo un mensaje pidiéndome confirmar mi asistencia

**Given** que respondo confirmando
**When** el Bot procesa mi respuesta
**Then** mi Estado de Confirmación pasa a "Confirmado" y se refleja en el `roster-row` del Detalle de Turno en el Panel

**Given** que respondo que no puedo asistir
**When** el Bot procesa mi respuesta
**Then** mi Estado de Confirmación pasa a "Pendiente de reemplazo" y se dispara el flujo de reemplazo (FR-3, Story 5.4)

**Given** que mi respuesta no es reconocible (texto ambiguo)
**When** el Bot la recibe
**Then** me reenvía las opciones válidas sin cambiar mi Estado de Confirmación

**Given** el Capitán
**When** abre el Detalle del Turno en el Panel
**Then** ve el Estado de Confirmación de cada Jugador del Roster en tiempo real (`roster-row`, UX-DR3)

### Story 5.4: Reemplazo auto-gestionado de Suplentes (FR-3)

As a Capitán,
I want que cuando un Jugador titular cancele, el Bot ofrezca su lugar a los Suplentes automáticamente,
So that no tenga que buscar reemplazo manualmente por WhatsApp.

**Acceptance Criteria:**

**Given** que un Jugador titular cancela su asistencia
**When** esto ocurre
**Then** el Bot ofrece el cupo liberado a los Suplentes en el orden en que el Capitán los listó originalmente

**Given** un Suplente al que se le ofrece el cupo
**When** confirma dentro del plazo
**Then** su Estado de Confirmación pasa a "Reemplazo" y ocupa el lugar del Jugador titular en el Roster

**Given** un Suplente al que se le ofrece el cupo
**When** no responde o rechaza
**Then** el Bot ofrece el cupo al siguiente Suplente de la lista

**Given** que el Turno comienza en más de 2 horas
**When** se ofrece un cupo a un Suplente
**Then** el plazo para responder es de 2 horas

**Given** que el Turno comienza en menos de 2 horas
**When** se ofrece un cupo a un Suplente
**Then** el plazo para responder es inmediato

**Given** que ningún Suplente confirma dentro del plazo (lista agotada o timeout vencido)
**When** esto ocurre
**Then** el cupo queda como "Sin cubrir" y se notifica al Capitán por el Bot

**Given** el Detalle de Turno en el Panel
**When** un cupo queda "Sin cubrir"
**Then** se refleja con su propio estado visual en el `roster-row` (UX-DR3/UX-DR4)

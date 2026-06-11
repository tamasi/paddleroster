---
title: retroai
status: final
created: 2026-06-11
updated: 2026-06-11
sources:
  - "{project-root}/_bmad-output/planning-artifacts/briefs/brief-retroai-2026-06-10/brief.md"
  - "{project-root}/_bmad-output/planning-artifacts/briefs/brief-retroai-2026-06-10/addendum.md"
  - "{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-retroai-2026-06-10/DESIGN.md"
  - "{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-retroai-2026-06-10/EXPERIENCE.md"
  - "{project-root}/_bmad-output/planning-artifacts/research/market-plataformas-reserva-turnos-complejos-deportivos-padel-futbol5-latam-research-2026-06-11.md"
---

# PRD: retroai

## 0. Document Purpose

Este PRD define el alcance funcional del MVP de retroai para el complejo piloto (5 canchas de pádel + 2 de fútbol 5). Construye sobre el **Product Brief** (`brief.md`/`addendum.md`, visión y problema) y la **UX del panel administrador** (`DESIGN.md`/`EXPERIENCE.md`, ya finalizada con 4 journeys y mocks de pantallas clave) — no los duplica, sino que los referencia donde corresponde. El vocabulario está anclado en el **Glosario** (§3): los Requisitos Funcionales (FR), Journeys de Usuario (UJ) y Métricas de Éxito (SM) usan estos términos de forma literal. Las suposiciones inferidas se marcan inline con `[ASSUMPTION]` y se indexan en §9.

## 1. Vision

Retroai reemplaza la gestión manual e informal de turnos en complejos deportivos de barrio (canchas de pádel y fútbol 5) por dos flujos especializados según el rol: el **jugador** (especialmente el "capitán" de un grupo fijo) coordina su turno semanal —roster, confirmaciones, reemplazos por cancelación— a través de un **bot de WhatsApp**, sin instalar nada ni registrarse. El **administrador** del complejo controla pagos pendientes/parciales/pagados y la ocupación real de sus 7 canchas desde un **panel web/app** mobile-first.

Hoy ese costo se paga en horas: capitanes que persiguen confirmaciones uno por uno por WhatsApp, cupos que quedan vacíos por cancelaciones de último momento, y administradores que llevan pagos y ocupación en un cuaderno. El mercado de pádel en Argentina viene en franco crecimiento (entre 2 y 3 millones de jugadores, +30% de canchas en los últimos años), pero las plataformas existentes (Playtomic, Matchpoint, CanchaFija, ATC, Easycancha, Padelero) —algunas con costos de varias decenas de miles de pesos por mes— arrastran quejas frecuentes de comisiones, cobros incorrectos y soporte deficiente, y ninguna resuelve el roster de un grupo fijo recurrente. Retroai responde con "sin comisiones, sin descarga, sin registro" para el jugador (vía WhatsApp, el canal que ya usa) y un panel liviano y económico para el administrador.

El proyecto nace como iniciativa personal de Hernan, validada en un complejo piloto real con el que tiene relación directa — lo que permite co-diseñar el producto junto al dueño y a jugadores reales desde el primer día. Es una apuesta inicial modesta y de bajo riesgo: la ventaja no es tecnológica sino de acceso a un complejo real y conocimiento del dominio, con potencial de crecimiento orgánico vía redes sociales hacia otros complejos de la zona. La diferenciación de canal por rol (bot para el jugador, panel para el administrador) sobre un **modelo de datos y lógica de negocio compartidos** es el principio de diseño que atraviesa todo el MVP.

**Visión a 2-3 años** (fuera del alcance de este PRD, ver `brief.md` → Visión): un perfil de Jugador portable entre complejos, con reputación, dentro de una red multi-complejo con monetización de doble cara. El MVP no debe cerrarle la puerta a esa evolución (ver §10 Constraints and Guardrails).

## 2. Target User

### 2.1 Jobs To Be Done

**Jugador Frecuente / Capitán de Grupo Fijo:**
- Armar el roster de su turno semanal (pádel o fútbol 5) sin tener que escribir uno por uno a cada jugador.
- Que cada jugador confirme su propia asistencia, sin que el capitán tenga que perseguir respuestas.
- Cuando alguien cancela, que el cupo se cubra solo — sin que el capitán tenga que buscar reemplazo llamando a contactos.

**Administrador del Complejo (Dueño):**
- Saber, de un vistazo, qué turnos están pagos, cuáles parciales y cuáles pendientes — sin cuaderno ni planilla.
- Ver la ocupación real por cancha, día y horario para tomar decisiones de negocio (promociones, horarios de baja demanda).
- Delegar la operación diaria (cobro, alta de turnos por teléfono) a empleados de mostrador, sin darles acceso a reportes o configuración del negocio.

**Empleado de Mostrador:**
- Cobrar un turno y marcarlo como pagado en el momento, sin demoras.
- Atender una llamada pidiendo un turno y crear la reserva en el momento, viendo qué horarios están libres.

### 2.2 Non-Users (v1)

- **Jugador ocasional/visitante** que busca completar un partido en un complejo que no es "el suyo" — relevante recién cuando exista una red multi-complejo (ver Visión del Brief). En el MVP, retroai asume que todo jugador pertenece a un grupo fijo de un complejo.
- **Complejos con un solo deporte o una sola cancha** — el modelo está pensado desde el día 1 para multi-cancha/multi-deporte (5 pádel + 2 fútbol 5), pero el MVP no se valida contra complejos de otro tamaño/mix.

### 2.3 Key User Journeys

Los journeys UJ-1 a UJ-3 corresponden al **bot de WhatsApp** (sin UX visual propia aún — se especifican por comportamiento). Los journeys UJ-4 a UJ-7 corresponden al **panel administrador** y reflejan 1:1 los "Key Flows" 1-4 de `EXPERIENCE.md`, donde además hay mocks HTML de las pantallas involucradas.

- **UJ-1. Diego arma el roster del martes desde el grupo de WhatsApp.**
  - **Persona + contexto:** Diego es el capitán de un grupo fijo que juega fútbol 5 todos los martes 20hs. Hoy arma la lista a mano, escribiendo a cada uno.
  - **Entry state:** Diego ya tiene un turno reservado (creado por él vía bot, o ya existente como turno fijo configurado por el complejo — ver UJ-7). No necesita cuenta ni instalar nada — opera desde su WhatsApp habitual.
  - **Path:** Diego le escribe al bot de retroai (o usa un comando/menú). El bot le pide la lista de jugadores (nombres + números de WhatsApp) para el turno del martes. Diego la envía de una.
  - **Climax:** El bot confirma "Roster armado — les avisé a los 9 para que confirmen" y cada jugador recibe su mensaje individual de confirmación en simultáneo.
  - **Resolution:** Diego ve en cualquier momento, desde el bot, cuántos confirmaron y quiénes faltan — sin tener que preguntarles uno por uno.
  - **Edge case:** si Diego carga un número de WhatsApp inválido o repetido, el bot se lo señala antes de enviar las invitaciones, no después.

- **UJ-2. Lucía confirma su lugar del martes con un toque.**
  - **Persona + contexto:** Lucía juega fútbol 5 los martes con el grupo de Diego. Hoy confirma por WhatsApp grupal, lo que a veces se pierde entre otros mensajes.
  - **Entry state:** Lucía recibe un mensaje individual del bot (no del grupo) preguntando si juega el martes 20hs.
  - **Path:** Lucía responde con un botón/opción "Sí, juego" (o "No puedo").
  - **Climax:** El bot confirma su lugar al instante ("Listo, te anoté para el martes 20hs") — Diego y el panel ven su estado como "Confirmado" sin que Lucía haga nada más.
  - **Resolution:** Lucía no vuelve a pensar en el turno hasta el día — sin grupo de WhatsApp que revisar.
  - **Edge case:** si Lucía no responde en el plazo esperado, queda como "Pendiente" — visible para Diego y para el panel (ver `EXPERIENCE.md` → State Patterns, "Roster con confirmaciones pendientes").

- **UJ-3. Nicolás no puede ir y el bot consigue su reemplazo.**
  - **Persona + contexto:** Nicolás confirmó el martes pero le surgió un imprevisto el mismo día. Hoy esto significa pagar de más entre los que quedan, o jugar incompletos.
  - **Entry state:** Nicolás ya había confirmado (UJ-2) para el turno del martes 20hs.
  - **Path:** Nicolás le avisa al bot que no puede ir ("No puedo ir" / cambia su respuesta). El bot marca su cupo como "liberado" y lo ofrece automáticamente a los suplentes definidos para ese roster.
  - **Climax:** Uno de los suplentes confirma desde su WhatsApp y el cupo queda cubierto — Diego recibe un aviso "Nicolás no va, Martín lo reemplaza" sin haber hecho nada.
  - **Resolution:** El roster vuelve a estar completo; el panel refleja el roster actualizado (Martín en vez de Nicolás).
  - **Edge case:** si ningún suplente confirma antes de un plazo (`[ASSUMPTION]`, ver §9), el cupo queda "Sin cubrir" y Diego es notificado para resolverlo manualmente — el bot no deja a Diego sin información.

- **UJ-4. Marcela registra un pago.** *(= Flow 1 en `EXPERIENCE.md`, mock: `mockups/inicio.html` → `mockups/detalle-turno.html`)*
  - Marcela, empleada de mostrador, cobra en efectivo al jugador que llega para el turno de las 19hs, abre el Detalle de Turno desde Inicio y toca "Registrar pago". El pill cambia de "Pago Pendiente" a "Pagado" en el momento.

- **UJ-5. Hernan revisa Reportes de Ocupación.** *(= Flow 2 en `EXPERIENCE.md`, mock: `mockups/reportes.html`)*
  - Hernan, dueño, revisa desde la notebook los Reportes y detecta que las canchas de fútbol 5 los miércoles a las 14hs vienen vacías hace semanas — decide ofrecer una promo para ese horario.

- **UJ-6. Marcela crea un turno manual por una llamada.** *(= Flow 3 en `EXPERIENCE.md`, mock: `mockups/calendario.html`)*
  - Alguien llama pidiendo un turno de pádel para mañana 18hs. Marcela abre Calendario, ve el slot libre, toca "Nuevo Turno" y carga cancha/horario/reservante + roster básico. La cancha deja de aparecer libre.

- **UJ-7. Hernan configura un turno fijo recurrente.** *(= Flow 4 en `EXPERIENCE.md`)*
  - Hernan sabe que un grupo juega fútbol 5 todos los martes 20hs hace meses por fuera del bot. Desde Calendario en notebook, crea el turno, carga el roster que conoce y lo marca como recurrente — el sistema genera automáticamente las instancias futuras semana a semana.

## 3. Glossary

- **Turno** — Una reserva de cancha en un horario específico, para pádel o fútbol 5. Tiene cancha, fecha, hora de inicio/fin, deporte, **Roster**, **Estado de Pago** y **Origen**.
- **Cancha** — Una de las 7 unidades reservables del complejo piloto (5 de pádel, 2 de fútbol 5).
- **Roster** — La lista de jugadores asociados a un Turno. Cada jugador tiene un nombre y, si el Turno es de **Origen Bot**, un **Estado de Confirmación**.
- **Origen** — Cómo se creó el Turno: **Origen Bot** (creado por el Capitán vía WhatsApp, con Roster y confirmaciones individuales) u **Origen Manual** (creado por Administrador/Empleado desde el Panel, con Roster básico sin confirmaciones individuales).
- **Capitán** — El jugador que crea un Turno y arma su Roster inicial vía el Bot de WhatsApp.
- **Jugador** — Cualquier persona incluida en el Roster de un Turno. Recibe mensajes individuales del Bot solo si el Turno es de Origen Bot.
- **Estado de Confirmación** — Por jugador, en Turnos de Origen Bot: **Confirmado**, **Pendiente** o **Reemplazo** (cuando un Suplente cubre el cupo de otro jugador).
- **Suplente** — Jugador designado, dentro del Roster de un Turno de Origen Bot, como candidato a cubrir un cupo liberado.
- **Turno Fijo / Recurrente** — Un Turno marcado como recurrente por el Administrador, que genera automáticamente nuevas instancias del mismo Turno (misma Cancha, horario, día de la semana) hacia adelante.
- **Estado de Pago** — Por Turno: **Pagado**, **Parcial** o **Pendiente**. Se actualiza únicamente mediante el registro de un pago en el Panel.
- **Administrador / Dueño** — Rol con acceso completo al Panel, incluyendo Reportes de Ocupación y Configuración.
- **Empleado** — Rol con acceso al Panel para operación diaria (Inicio, Calendario, Pagos, Detalle de Turno, Nuevo Turno), sin acceso a Reportes ni Configuración.
- **Panel** — La aplicación web/app mobile-first usada por Administrador y Empleado. Especificada en `EXPERIENCE.md`/`DESIGN.md`.
- **Bot** — El bot de WhatsApp usado por Capitanes y Jugadores para gestionar Turnos de Origen Bot.
- **Ocupación** — Porcentaje de Canchas/horarios reservados (con Turno) sobre el total disponible, para un período dado.
- **Complejo** — El conjunto de 7 Canchas gestionado por un Administrador. El MVP asume un único Complejo (el piloto).

## 4. Features

### 4.1 Roster de Turno con Confirmación y Reemplazo (Bot de WhatsApp)

**Description:** Un Capitán crea un Turno de Origen Bot y carga su Roster inicial (nombres + números de WhatsApp) directamente desde una conversación con el Bot. Cada Jugador del Roster recibe un mensaje individual para confirmar su asistencia — sin instalar nada, sin registrarse. Si un Jugador no puede asistir, el Bot libera su cupo y lo ofrece a los Suplentes designados, notificando al Capitán del resultado. Realiza UJ-1, UJ-2, UJ-3.

**Functional Requirements:**

#### FR-1: Creación de Turno y Roster inicial vía Bot

Un Capitán puede crear un Turno (Cancha, deporte, fecha, horario) y cargar su Roster inicial (nombres + contactos de WhatsApp) en una sola interacción con el Bot. Realiza UJ-1.

**Consequences (testable):**
- El Bot valida que cada contacto del Roster sea un número de WhatsApp con formato válido antes de enviar invitaciones, y reporta al Capitán cualquier entrada inválida o duplicada sin enviar nada hasta que se corrija.
- El Turno creado queda visible en el Panel (Calendario) con Origen Bot.
- El Turno creado por el Bot respeta la disponibilidad de Cancha/horario — el Bot no permite crear un Turno sobre una Cancha/horario ya ocupado por otro Turno.

**Out of Scope:**
- Selección de Cancha/horario asistida por el Bot mediante un calendario visual — el MVP asume que el Capitán conoce/coordina el horario (ver `[ASSUMPTION]` en §9).

#### FR-2: Confirmación individual de asistencia

Cada Jugador de un Turno de Origen Bot recibe un mensaje individual del Bot y puede confirmar o rechazar su asistencia con una respuesta simple (botón/palabra clave). Realiza UJ-2.

**Consequences (testable):**
- El Estado de Confirmación de cada Jugador (Confirmado/Pendiente/Reemplazo) se actualiza en tiempo real y es visible tanto al Capitán (vía Bot) como en el Detalle de Turno del Panel.
- Un Jugador que no responde queda en estado Pendiente — el sistema no asume confirmación por defecto ni rechazo por defecto.

#### FR-3: Reemplazo auto-gestionado

Un Jugador que había confirmado puede retirar su confirmación; el Bot ofrece su cupo a los Suplentes del Roster y, si alguno confirma, actualiza el Roster y notifica al Capitán del cambio. Realiza UJ-3.

**Consequences (testable):**
- El cupo liberado se ofrece a los Suplentes en el orden en que el Capitán los listó al definir el Roster (`[ASSUMPTION]`, ver §9), hasta que uno confirme o se agoten los Suplentes.
- Si ningún Suplente confirma dentro de las 2 horas previas al inicio del Turno —o de inmediato si el Turno comienza en menos de 2 horas— (`[ASSUMPTION]`, ver §9), el cupo queda en estado "Sin cubrir" y el Capitán recibe una notificación — el sistema no deja el cambio sin reportar.
- El Roster actualizado (con el reemplazo aplicado) es el que se muestra en el Detalle de Turno del Panel.

**Feature-specific NFRs:**
- Las notificaciones del Bot (invitación, confirmación, cambio de roster) deben llegar en segundos, no minutos — la coordinación de un reemplazo de último momento depende de esto.

---

### 4.2 Gestión de Turnos (Calendario, creación manual y recurrentes)

**Description:** El Panel muestra el Calendario de las 7 Canchas (5 pádel + 2 fútbol 5). Los Turnos de Origen Bot aparecen automáticamente (creados vía FR-1). Para reservas que no llegan por el Bot (llamada telefónica, grupos que aún no usan retroai), Administrador/Empleado crean Turnos de Origen Manual directamente desde un slot vacío del Calendario, con un Roster básico sin confirmaciones individuales. Administrador puede además marcar un Turno como recurrente para que genere instancias futuras automáticamente. Realiza UJ-6, UJ-7. Ver `EXPERIENCE.md` → Information Architecture e Interaction Primitives para el comportamiento detallado del Calendario.

**Functional Requirements:**

#### FR-4: Calendario de Turnos por Cancha/horario

Administrador/Empleado pueden ver, para cualquier Cancha y fecha, qué horarios tienen un Turno y cuáles están libres. Realiza UJ-5, UJ-6.

**Consequences (testable):**
- Un horario sin Turno se muestra como "Cancha libre" y es accionable (ver FR-5).
- Un horario con Turno muestra Cancha, horario, reservante/Roster resumido y Estado de Pago.

#### FR-5: Creación manual de Turno

Administrador/Empleado pueden crear un Turno de Origen Manual tocando un slot vacío del Calendario, completando Cancha/horario/deporte (pre-cargados) y un Roster básico (nombres, sin Estado de Confirmación). Realiza UJ-6.

**Consequences (testable):**
- Tras guardar, el slot deja de aparecer como "Cancha libre" y muestra el nuevo Turno con su reservante.
- Un Turno de Origen Manual no genera mensajes del Bot ni Estados de Confirmación por Jugador (ver Glosario → Origen).

#### FR-6: Turnos Fijos / Recurrentes

Administrador puede marcar un Turno (de Origen Manual) como recurrente (semanal); el sistema genera automáticamente las instancias futuras de ese Turno (misma Cancha, horario, día de la semana, Roster). Realiza UJ-7.

**Consequences (testable):**
- Cada instancia futura generada aparece en el Calendario como un Turno independiente (con su propio Estado de Pago), heredando Cancha/horario/Roster del Turno original.
- Administrador puede modificar o cancelar instancias futuras individualmente sin afectar el Turno recurrente original (`[ASSUMPTION]`, ver §9).

**Feature-specific NFRs:** Solo Dueño puede crear/editar Turnos Fijos — el formulario de Nuevo Turno no muestra la opción "Marcar como recurrente" a usuarios con rol Empleado (`[ASSUMPTION]`, alineado con que Configuración es solo-Dueño en `EXPERIENCE.md`; ver §9).

#### FR-7: Registro del Origen del Turno

El sistema registra y conserva el Origen (Bot / Manual) de cada Turno, de forma consultable para reporting. Realiza la medición de SM-1.

**Consequences (testable):**
- Es posible obtener, para un período dado, la proporción de Turnos con Origen Bot sobre el total de Turnos — esta es la métrica base de SM-1.

#### FR-15: Cancelación de Turno desde el Panel

Administrador/Empleado pueden cancelar un Turno (de cualquier Origen) desde el Panel.

**Consequences (testable):**
- Un Turno cancelado deja de contar como "Cancha ocupada" — el horario vuelve a mostrarse como "Cancha libre" en el Calendario (FR-4).
- Para un Turno de Origen Bot, cancelarlo desde el Panel no modifica su Roster (que permanece de solo lectura) — solo cambia el Estado del Turno a Cancelado. Cancelar no notifica a los Jugadores vía Bot (`[ASSUMPTION]`, ver §9) — el Capitán es responsable de avisar al grupo si la cancelación ocurre por fuera del Bot.

---

### 4.3 Pagos del Turno

**Description:** El Panel centraliza el Estado de Pago de cada Turno y permite a Administrador/Empleado registrar pagos (completos o parciales) cobrados fuera del sistema (efectivo, transferencia). No incluye procesamiento de pagos online. Realiza UJ-4. Ver `EXPERIENCE.md` → Component Patterns (`status-pill-*`, `button-action`) y mock `mockups/detalle-turno.html`.

**Functional Requirements:**

#### FR-8: Visualización de Estado de Pago

Administrador/Empleado pueden ver el Estado de Pago (Pagado/Parcial/Pendiente) de cualquier Turno, en Inicio, Calendario, Pagos y Detalle de Turno. Realiza UJ-4.

**Consequences (testable):**
- El Estado de Pago se muestra siempre con texto explícito además de color (ver `EXPERIENCE.md` → Accessibility Floor).
- La pantalla "Pagos" permite ver todos los Turnos agrupados/filtrables por Estado de Pago.

#### FR-9: Registro de Pago

Administrador/Empleado pueden registrar un pago para un Turno (completo o parcial, con monto), actualizando su Estado de Pago de inmediato. Realiza UJ-4.

**Consequences (testable):**
- Tras confirmar "Registrar pago", el Estado de Pago del Turno cambia a Pagado (si completo) o Parcial (si parcial) sin necesidad de recargar la pantalla.
- El registro de pago queda asociado al Turno y es consultable en su Detalle (monto, fecha de registro).

**Out of Scope:**
- Procesamiento de pagos online / pasarela de pago (tarjeta, link de pago) — `[ASSUMPTION]`, ver §9.
- Facturación / comprobantes fiscales.

---

### 4.4 Reportes de Ocupación

**Description:** El Dueño accede a reportes de Ocupación por Cancha, día y horario, para identificar patrones (horarios vacíos, canchas más demandadas) y tomar decisiones comerciales. Realiza UJ-5. Ver `EXPERIENCE.md` → Responsive & Platform y mock `mockups/reportes.html`.

**Functional Requirements:**

#### FR-10: Reporte de Ocupación por Cancha/horario/día

Dueño puede ver, para un período seleccionable (semana/mes), el porcentaje de Ocupación de cada Cancha desglosado por día y horario, distinguiendo pádel de fútbol 5. Realiza UJ-5.

**Consequences (testable):**
- El reporte permite identificar combinaciones Cancha+horario+día con Ocupación 0% durante varias semanas consecutivas (caso UJ-5).
- El porcentaje de Ocupación se muestra siempre acompañado de su valor numérico, no solo como representación visual (ver `EXPERIENCE.md` → Accessibility Floor).

**Out of Scope:**
- Exportación a Excel/CSV (`[ASSUMPTION]`, ver §9).
- Recomendaciones automáticas (precios dinámicos / promos) — ver §5 Non-Goals.

---

### 4.5 Autenticación y Gestión de Usuarios (Panel)

**Description:** El Panel soporta múltiples usuarios desde el día 1, con dos roles (Dueño/Empleado) y un flujo de invitación que evita que el Dueño tenga que cargar credenciales manualmente. Ver `EXPERIENCE.md` → Foundation, Information Architecture y State Patterns ("Sesión expirada").

**Functional Requirements:**

#### FR-11: Login multi-usuario

Cualquier usuario (Dueño o Empleado) puede autenticarse individualmente en el Panel.

**Consequences (testable):**
- Una sesión expirada redirige a Login y, tras reautenticar, devuelve al usuario a la pantalla donde estaba (ver `EXPERIENCE.md` → State Patterns).

#### FR-12: Roles Dueño / Empleado

El sistema distingue dos roles con accesos diferenciados: Dueño (Inicio, Calendario, Pagos, Reportes, Configuración) y Empleado (Inicio, Calendario, Pagos, Detalle de Turno, Nuevo Turno — sin Reportes ni Configuración).

**Consequences (testable):**
- Un Empleado autenticado no ve el ítem "Reportes" en la navegación ni puede acceder a Configuración por URL/ruta directa.

#### FR-13: Invitación de Empleados

Dueño puede generar un link/código de invitación desde Configuración; un Empleado lo usa para crear su cuenta y queda asociado automáticamente al Complejo, con rol Empleado.

**Consequences (testable):**
- Un Empleado que se registra mediante un link/código de invitación válido queda asociado al mismo Complejo que el Dueño que lo generó, sin intervención manual adicional del Dueño.
- Un link/código de invitación usado o expirado no permite crear una cuenta nueva (`[ASSUMPTION]` sobre expiración, ver §9).

#### FR-14: Gestión de Canchas y datos del Complejo

Dueño puede ver y editar, desde Configuración, los datos del Complejo (nombre, datos de contacto) y la lista de Canchas (nombre/identificador, deporte asociado).

**Consequences (testable):**
- Las Canchas dadas de alta en Configuración son las que aparecen como columnas/agenda en el Calendario (FR-4) — agregar o quitarlas ahí se refleja inmediatamente en el Calendario.
- Empleado no tiene acceso a esta sección (alineado con FR-12).

**Out of Scope:**
- Configuración de tarifas/precios por Cancha u horario — `[ASSUMPTION]`, ver §9.

## 5. Non-Goals (Explicit)

- **Matching de jugadores sueltos** para completar Roster, perfiles con nivel/reputación y calificación post-partido — evolución futura (red multi-complejo).
- **Motor de precios dinámicos** / sugerencias de descuento y notificaciones automáticas asociadas.
- **Pedido de refrigerios** pre-configurado para el Turno.
- **Red multi-complejo** con perfiles de Jugador compartidos entre complejos independientes, y monetización de doble cara.
- **App móvil/web dedicada para el Jugador** — decisión de diseño (no limitación temporal); el Jugador opera exclusivamente vía Bot de WhatsApp en el MVP.
- **Procesamiento de pagos online / pasarela de pago** — el Panel registra pagos cobrados por otros medios (efectivo, transferencia), no los procesa.
- **Soporte multi-complejo en este MVP** — el sistema se valida contra un único Complejo piloto, aunque el modelo de datos no lo impide a futuro (ver Visión del Brief).

## 6. MVP Scope

### 6.1 In Scope

- Bot de WhatsApp: creación de Turno + Roster por el Capitán (FR-1), confirmación individual (FR-2), reemplazo auto-gestionado (FR-3) — para Turnos de pádel y fútbol 5 indistintamente.
- Panel: Calendario de las 7 Canchas con Turnos de ambos Orígenes (FR-4), creación manual de Turno (FR-5), Turnos Fijos/Recurrentes (FR-6), registro de Origen para reporting (FR-7), cancelación de Turno (FR-15).
- Panel: visualización y registro de Estado de Pago (FR-8, FR-9).
- Panel: Reportes de Ocupación por Cancha/día/horario (FR-10).
- Panel: Login multi-usuario, roles Dueño/Empleado, invitación de Empleados (FR-11, FR-12, FR-13).
- Modo claro/oscuro y diseño responsive (mobile-first + notebook) del Panel, según `DESIGN.md`/`EXPERIENCE.md`.

### 6.2 Out of Scope for MVP

- Todo lo listado en §5 Non-Goals.
- Exportación de reportes (CSV/Excel).
- Recordatorios o notificaciones del Bot más allá de las ligadas a confirmación/reemplazo de un Turno (FR-2, FR-3) — sin notificaciones de marketing/promociones.
- Edición del Roster de Turnos de Origen Bot desde el Panel — el Roster permanece de solo lectura (correcciones de nombres/confirmaciones se hacen vía Bot). El Panel sí permite cancelar el Turno completo (FR-15) y registrar su pago (FR-9) independientemente del Origen.

## 7. Success Metrics

**Primary**
- **SM-1**: Al menos el 30% de los Turnos del Complejo (pádel y fútbol 5) tienen Origen Bot durante el período de evaluación del piloto, medido vía FR-7. Validates FR-1, FR-2, FR-3, FR-7.

**Secondary**
- **SM-2**: El Administrador y los Empleados usan el Panel (Pagos + Reportes) como su herramienta principal de control de pagos y ocupación, dejando de depender del registro manual (cuaderno/planillas). Medición cualitativa en el piloto (`[ASSUMPTION]` sobre cómo verificarlo formalmente, ver §9). Validates FR-8, FR-9, FR-10.
- **SM-3**: Se observa una reducción de cupos vacíos / Turnos con Roster incompleto en Turnos de Origen Bot, comparado contra el método anterior (cuaderno/WhatsApp informal). Validates FR-3.

**Counter-metrics (do not optimize)**
- **SM-C1**: El tiempo que un Capitán dedica a armar y confirmar un Roster vía Bot no debe ser mayor que coordinarlo manualmente por WhatsApp/llamadas — si el Bot agrega fricción, SM-1 puede crecer "en papel" sin que el problema real (carga del capitán) se resuelva. Counterbalances SM-1.
- **SM-C2**: El registro de pagos en el Panel (FR-9) no debe agregar pasos respecto del cobro actual en efectivo/transferencia — un Panel que "ordena" pero ralentiza el cobro en el mostrador no cumple su función. Counterbalances SM-2.

## 8. Open Questions

1. **Selección de horario en el Bot (FR-1):** ¿el Bot debe mostrarle al Capitán qué horarios están disponibles, o asume que el Capitán ya coordinó el horario de antemano? Afecta si el Bot necesita "ver" el Calendario del Panel en el MVP.
2. **Edición de Turnos Fijos/instancias generadas (FR-6):** ¿modificar/cancelar una instancia futura de un Turno Fijo afecta solo esa instancia o la serie completa? Relevante para Architecture (modelo de datos de recurrencia).
3. **Medición de SM-2:** ¿cómo se valida en la práctica que el Panel "reemplazó" el cuaderno — encuesta al Dueño, ausencia de registros manuales paralelos, otra señal?
4. **Enfoque técnico del Bot de WhatsApp** (API oficial vs. librería no oficial) — explícitamente diferido a Architecture (ver `.decision-log.md`); debe evaluarse contra la restricción de "sin presupuesto para servicios externos pagos en el MVP" (ver §10 Constraints and Guardrails).
5. **¿Quiénes son los Suplentes de un Roster (FR-3)?** — ¿un grupo que el Capitán define al crear el Turno, o un pool más amplio de Jugadores frecuentes del Complejo? El orden de oferta y el plazo de espera ya tienen un default asumido (ver §9), pero la composición del pool de Suplentes queda abierta.

## 9. Assumptions Index

- §4.1 FR-1 (Out of Scope): el Bot no asiste con selección de Cancha/horario disponible — se asume que el Capitán ya coordinó el horario antes de interactuar con el Bot. Relacionado con Open Question 1.
- §4.1 FR-3: se asume como default que los Suplentes se ofrecen en el orden en que el Capitán los listó al definir el Roster, y que el cupo queda "Sin cubrir" si ninguno confirma dentro de las 2 horas previas al inicio del Turno (o de inmediato si el Turno comienza en menos de 2 horas) — ambos valores configurables a futuro. Queda abierta la composición del pool de Suplentes (Open Question 5).
- §4.2 FR-6: se asume que las instancias futuras generadas por un Turno Fijo pueden modificarse/cancelarse individualmente sin afectar la serie — a confirmar en Architecture. Relacionado con Open Question 2.
- §4.2 FR-6 (NFR): se asume que solo el Dueño puede crear/editar Turnos Fijos (alineado con el rol "Dueño = acceso completo" de `EXPERIENCE.md`); el formulario de Nuevo Turno oculta la opción "Marcar como recurrente" para Empleado.
- §4.2 FR-15: se asume que cancelar un Turno de Origen Bot desde el Panel no dispara una notificación a los Jugadores vía Bot — el Capitán es responsable de avisar al grupo si la cancelación ocurre por fuera del Bot. A confirmar con el dueño durante el piloto.
- §4.3 FR-9 (Out of Scope): se asume que el MVP no procesa pagos online — solo registra pagos cobrados por otros medios, alineado con que el Brief no menciona una pasarela de pago.
- §4.4 FR-10 (Out of Scope): se asume que la exportación de reportes (CSV/Excel) no es necesaria para el piloto — el panel reemplaza el cuaderno, no genera reportes para terceros.
- §4.5 FR-13: se asume que un link/código de invitación expira o se invalida tras su uso — el mecanismo exacto (tiempo de expiración, un solo uso vs. reutilizable) se define en Architecture.
- §7 SM-2: se asume que la validación de "el Panel reemplazó el cuaderno" será cualitativa (conversación con el Dueño durante el piloto) — no hay instrumentación automática prevista para esto en el MVP. Relacionado con Open Question 3.
- §1 Vision / Investigación de mercado: la oportunidad para fútbol 5 se valida por analogía con pádel (mismo tipo de complejo, mismo problema de roster) — la investigación de mercado no recolectó datos específicos de fútbol 5 de forma independiente.
- §4.5 FR-14 (Out of Scope): se asume que la configuración de tarifas/precios por Cancha u horario no es necesaria para el piloto — el MVP no gestiona precios, solo registra pagos (ver FR-9).

## 10. Constraints and Guardrails

**Constraints**
- Desarrollo a cargo de un único desarrollador (Hernan), sin plazo fijo de lanzamiento — pero con expectativa de pasar a producción real con usuarios reales en cuanto el piloto lo permita.
- Sin presupuesto para servicios externos pagos en el MVP — cualquier costo recurrente (ej. WhatsApp Business API oficial) debe evaluarse contra esta restricción al definir el enfoque técnico del Bot (ver Open Question 4).
- Validación contra un único Complejo piloto (7 canchas), con acceso directo al dueño para iteración rápida.

**Guardrails**
- El modelo de datos no debe acoplar la identidad del Jugador al Complejo único del MVP de forma irreversible — preserva la posibilidad de la red multi-complejo descrita en la Visión a 2-3 años, sin implementarla ahora (ver §5 Non-Goals).
- Riesgo de timing: actores establecidos (Playtomic, CanchaFija, ATC) podrían replicar el ángulo de roster/bot si el lanzamiento se demora — priorizar validar el piloto y salir a producción cuanto antes, alineado con las expectativas de lanzamiento real declaradas para este proyecto.

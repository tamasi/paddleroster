---
title: "Experience Spine: retroai — Panel Administrador"
status: final
created: 2026-06-10
updated: 2026-06-11
sources:
  - "{project-root}/_bmad-output/planning-artifacts/briefs/brief-retroai-2026-06-10/brief.md"
  - "{project-root}/_bmad-output/planning-artifacts/briefs/brief-retroai-2026-06-10/addendum.md"
---

# Experience Spine: retroai — Panel Administrador

## Foundation

Multi-surface, mobile-first: el administrador y los empleados de mostrador operan principalmente desde el celular, pero el panel debe funcionar bien en notebook (responsive, no son dos diseños separados). Tailwind CSS es la base; `DESIGN.md` es la referencia de identidad visual — esta spine define cómo se comporta.

Multi-usuario desde el día 1, con dos roles:

- **Dueño**: acceso completo, incluyendo Reportes de Ocupación y Configuración.
- **Empleado de mostrador**: operación diaria — Inicio, Calendario, Pagos, Detalle de Turno, Nuevo Turno. Sin acceso a Reportes ni Configuración.

Modo claro y oscuro disponibles desde el inicio (paleta "Pádel Pro", ver `DESIGN.md`). Tono de voz: "vos", cercano y directo (ej. "Marcá el turno como pagado").

## Information Architecture

| Surface | Reached from | Acceso | Purpose |
|---|---|---|---|
| Login | Apertura de la app (sin sesión) | Todos | Autenticación multi-usuario |
| Inicio | Login / tab "Inicio" | Dueño, Empleado | Resumen del día: turnos próximos, estado de ocupación y pagos del día. Mock: [`mockups/inicio.html`](mockups/inicio.html) |
| Calendario | Tab "Calendario" | Dueño, Empleado | Turnos por cancha/horario (7 canchas: 5 pádel + 2 fútbol 5); punto de entrada para crear un turno manual. Mock: [`mockups/calendario.html`](mockups/calendario.html) |
| Nuevo Turno | Botón "+" / horario vacío en Calendario | Dueño, Empleado | Crear un turno manualmente (reserva que no llegó por el bot) y cargar roster básico |
| Detalle de Turno | Tarjeta de turno en Inicio / Calendario / Pagos | Dueño, Empleado | Drill-down de un turno: roster, estado de confirmación (si vino del bot), monto y registro de pago. Mock (Pendiente → Pagado): [`mockups/detalle-turno.html`](mockups/detalle-turno.html) |
| Pagos | Tab "Pagos" | Dueño, Empleado | Lista de turnos por estado de pago (Pagado/Parcial/Pendiente), con acceso a Detalle de Turno |
| Reportes | Tab "Reportes" | Dueño | Ocupación por cancha, día y horario. Mock: [`mockups/reportes.html`](mockups/reportes.html) |
| Configuración | Menú de usuario (header) | Dueño | Gestión de canchas, usuarios/empleados, datos del complejo |

Bottom navigation (mobile) / barra lateral o superior (notebook): **Inicio · Calendario · Pagos · Reportes** para el dueño; **Inicio · Calendario · Pagos** (3 ítems) para el empleado — Reportes no se muestra como tab si el rol no tiene acceso, en vez de mostrarse deshabilitado. Configuración vive fuera de la navegación principal, en el menú de usuario del `{components.app-header}`, visible solo para el dueño.

La gestión de usuarios/empleados vive dentro de Configuración: lista de usuarios con su rol (Dueño/Empleado), más una acción "Invitar empleado" que genera un link/código de invitación — el empleado lo usa para crear su cuenta y queda asociado al complejo automáticamente, sin que el dueño tenga que cargar credenciales manualmente.

## Voice and Tone

Microcopy en "vos", cercano y directo — sin formalismos ni jerga técnica. La identidad visual y de marca vive en `DESIGN.md.Brand & Style`.

| Do | Don't |
|---|---|
| "Marcá el turno como pagado" | "Proceder a marcar como abonado" |
| "Cancha libre — tocá para crear un turno" | "Slot disponible. Click para reservar." |
| "No hay turnos para hoy" | "Sin resultados" |
| "Turno guardado" | "✓ Operación realizada con éxito" |
| Confirmaciones cortas, en el momento ("Turno guardado", "Pago registrado") | Mensajes largos, alertas modales para acciones de rutina |

## Component Patterns

Comportamiento de los componentes definidos visualmente en `DESIGN.md.Components`.

| Component | Use | Behavioral rules |
|---|---|---|
| `{components.card-turno}` | Inicio, Calendario, Pagos | Tap → abre Detalle de Turno (sheet/modal). Muestra `status-pill` de pago siempre; roster solo como conteo resumido ("4/4 confirmados") en la tarjeta — el detalle vive en Detalle de Turno. |
| Roster row | Detalle de Turno | Una fila por jugador: nombre + estado. Si el turno vino del bot: estado de confirmación (Confirmado / Pendiente / Reemplazo) en `{typography.meta}`, de solo lectura. Si el turno se creó manualmente: nombre editable, sin estado de confirmación (no aplica el flujo del bot). |
| `{components.status-pill-paid}` / `-pending` / `-partial` | Card de turno, Detalle de Turno, Pagos | Reflejan el estado de pago. Cambian únicamente al confirmar una acción en `{components.button-action}` ("Registrar pago") — nunca por edición directa del pill. |
| `{components.button-action}` ("Registrar pago") | Detalle de Turno | Abre un paso de confirmación (monto, "Pago completo" / "Pago parcial"). Tras confirmar, el pill del turno se actualiza en el momento (sin recarga de pantalla) y el sheet puede cerrarse o quedar abierto mostrando el nuevo estado. |
| `{components.occupancy-bar}` | Inicio (resumen del día), Reportes | En Inicio: una barra por cancha, resumen del día. En Reportes: una barra por combinación cancha/horario/día, navegable. Siempre acompañada de la etiqueta numérica (`{typography.numeric}`) — la barra sola no transmite el dato. |
| `{components.bottom-nav}` | Global | Ítems visibles según rol (ver Information Architecture). El orden no cambia entre roles ni breakpoints — solo la cantidad de ítems. |
| `{components.input-field}` | Login, Nuevo Turno, Configuración | Validación inline, error debajo del campo en `{typography.meta}` + `{colors.danger}`. Nunca solo borde rojo sin texto. |
| Botón "Nuevo Turno" (usa `{components.button-primary}`) | Calendario | Flotante (mobile) o en el header de la grilla (notebook). Abre el formulario de Nuevo Turno con cancha/horario pre-cargados si se tocó un slot vacío. |

## State Patterns

| State | Surface | Treatment |
|---|---|---|
| Sin turnos hoy | Inicio | "No hay turnos para hoy" + barra de ocupación en 0% — no es un error, es el estado normal de un día tranquilo. |
| Cancha libre | Calendario | Slot vacío con borde punteado (`{colors.border}`) y texto `{typography.meta}` "Cancha libre — tocá para crear un turno". Tap → Nuevo Turno con cancha/horario pre-cargados. |
| Roster vacío (turno manual recién creado) | Detalle de Turno | "Todavía no cargaste el roster" + acción para agregar nombres. No bloquea el registro de pago. |
| Roster con confirmaciones pendientes (turno vía bot) | Detalle de Turno | Cada jugador muestra su estado (Confirmado/Pendiente/Reemplazo) de solo lectura — el panel **no** permite forzar una confirmación; eso ocurre en WhatsApp. |
| Pago Pendiente / Parcial / Pagado | Card de turno, Detalle de Turno, Pagos | Ver `{components.status-pill-*}` — siempre con texto explícito, nunca solo color (ver Accessibility Floor). |
| Carga inicial | Todas | Skeleton de tarjetas (2-3 placeholders), nunca spinner de pantalla completa. |
| Sin conexión | Todas | Banner no bloqueante: "Sin conexión — mostrando los últimos datos guardados". Los datos en pantalla quedan visibles (no se vacían). |
| Sesión expirada | Cualquier surface autenticada | Redirección a Login con mensaje "Tu sesión expiró, iniciá sesión de nuevo" — sin perder de vista en qué pantalla estaba (vuelve ahí después de loguearse). |

## Interaction Primitives

- **Tap** es la interacción primaria: abrir Detalle de Turno, registrar pago, navegar.
- **Tap en slot vacío del Calendario** → Nuevo Turno con cancha/horario pre-cargados (atajo principal para el flujo de creación manual).
- **Pull-to-refresh** en Inicio y Calendario (mobile) — los datos de pagos/ocupación pueden cambiar entre dispositivos (dueño y empleado usando el panel a la vez).
- **Swipe horizontal entre canchas** en la vista de agenda mobile del Calendario (ver Responsive & Platform).
- **Sheets/modales** (Detalle de Turno, Nuevo Turno) se cierran con gesto de arrastrar hacia abajo (mobile) o botón de cierre explícito (notebook) — nunca tap-fuera accidental para acciones con datos sin guardar (confirmar descarte si hay cambios).
- **Banned**: drag-and-drop para mover turnos entre horarios/canchas (fuera de alcance del MVP — riesgo de error en pantallas chicas), confirmaciones de "deslizar para pagar" (el registro de pago es una acción que merece un paso de confirmación explícito, no un gesto rápido).

## Accessibility Floor

Comportamiento; el contraste visual vive en `DESIGN.md`.

- Contraste AA mínimo 4.5:1 en ambos modos (claro/oscuro) — crítico para uso en mostrador con luz solar directa.
- Todo `status-pill` de pago lleva texto explícito ("Pago Pendiente"/"Pago Parcial"/"Pagado"), nunca solo color — válido también para lectores de pantalla.
- `{components.occupancy-bar}` expone el porcentaje como texto adyacente, no solo como ancho de barra — un lector de pantalla debe poder anunciar "Cancha 3, 75% de ocupación".
- Tap targets ≥ 44px en mobile, incluyendo filas de roster y botones de acción dentro de sheets.
- Formularios (Login, Nuevo Turno, Configuración): orden de foco sigue el orden visual; errores de validación anunciados junto al campo, no solo en un resumen al tope.
- Modo oscuro no es solo "invertir colores" — usa los tokens `-dark` definidos en `DESIGN.md` para mantener el contraste de los `status-pill` y `occupancy-bar`.

## Responsive & Platform

- **Calendario**: en mobile, vista de agenda vertical por cancha con swipe horizontal para cambiar de cancha (1 cancha visible a la vez). En notebook (`md+`), grilla cancha × horario (7 columnas) — mismo dato, distinta disposición. La acción "Nuevo Turno" sobre un slot vacío funciona igual en ambas.
- **Navegación**: `{components.bottom-nav}` fija abajo en mobile; en notebook se reubica como barra lateral o superior persistente, mismos ítems y orden (según rol).
- **Reportes** (solo dueño): en mobile, una barra de ocupación a la vez con scroll vertical y selector de cancha/día; en notebook, varias barras visibles simultáneamente (comparación cancha vs. cancha) — mismo dato, más densidad.
- **Detalle de Turno**: sheet que sube desde abajo en mobile (`{rounded.xl}`); modal centrado en notebook. Mismo contenido y orden de secciones (roster → estado de pago → acción).

## Key Flows

### Flow 1 — Marcela registra un pago (mostrador, celular)

Mocks: [`mockups/inicio.html`](mockups/inicio.html) (paso 2-3) → [`mockups/detalle-turno.html`](mockups/detalle-turno.html) (paso 3-6, antes/después)

1. Llega un jugador del turno de pádel de las 19hs a la cancha.
2. Marcela abre Inicio en su celular y ve la tarjeta del turno de las 19hs con el pill "Pago Pendiente".
3. Toca la tarjeta → se abre el Detalle de Turno (roster, monto, botón "Registrar pago").
4. Cobra en efectivo y toca "Registrar pago".
5. Confirma "Pago completo".
6. **Climax:** el pill cambia a "Pagado" (verde) en el momento, sin recargar — Marcela cierra el sheet y la tarjeta en Inicio ya refleja el cambio. El cuaderno de pagos pendientes deja de existir para este turno.

### Flow 2 — Hernan revisa Reportes de Ocupación (notebook)

Mock: [`mockups/reportes.html`](mockups/reportes.html) (paso 2-4)

1. A la noche, Hernan abre el panel desde la notebook y va a Reportes.
2. Ve las barras de ocupación por cancha y horario, varios días a la vez (vista notebook).
3. Nota que las canchas de fútbol 5 los miércoles a las 14hs vienen vacías hace semanas (barras en gris/bajo, sin segmentos de pago).
4. **Climax:** con ese dato a la vista — sin exportar nada a Excel ni revisar un cuaderno — Hernan decide ofrecer una promo para ese horario. El panel le dio la visibilidad que antes no tenía.

### Flow 3 — Marcela crea un turno manual por una llamada telefónica (mostrador, celular)

Mock: [`mockups/calendario.html`](mockups/calendario.html) (paso 2-3, slot de las 18:00 destacado como "Cancha libre")

1. Suena el teléfono del complejo: alguien pide un turno de pádel para mañana 18hs, grupo de 4.
2. Marcela abre Calendario, navega a mañana, Cancha 3 (pádel), y ve el horario de las 18hs libre ("Cancha libre — tocá para crear un turno").
3. Toca el slot vacío → se abre Nuevo Turno con cancha/horario/deporte pre-cargados.
4. Carga el nombre de quien reservó y, si los tiene, los nombres del grupo (roster básico, sin confirmaciones del bot).
5. Guarda.
6. **Climax:** el horario de las 18hs en Calendario ahora muestra una tarjeta con el `court-tag` y el nombre de quien reservó — la cancha deja de aparecer libre para la próxima persona que llame.

### Flow 4 — Hernan configura un turno fijo recurrente (notebook)

1. Hernan sabe que un grupo juega fútbol 5 todos los martes 20hs hace meses, coordinándose por un grupo de WhatsApp viejo (todavía no usan el bot de retroai).
2. Desde Calendario en notebook, selecciona Cancha 6 (fútbol 5), martes 20hs (slot libre).
3. Abre Nuevo Turno, carga el roster con los nombres que conoce del grupo, y marca el turno como recurrente — el sistema genera automáticamente las instancias futuras cada semana a partir de esta configuración.
4. Guarda.
5. **Climax:** el turno fijo del martes 20hs queda reflejado en el Calendario para las semanas siguientes — Marcela ya no tiene que preguntarse "¿está reservado el martes a las 20hs?" cada semana; el cuaderno de turnos fijos deja de ser necesario.

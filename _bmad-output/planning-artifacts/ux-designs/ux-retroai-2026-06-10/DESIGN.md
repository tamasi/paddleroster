---
title: "Design Spine: retroai — Panel Administrador"
status: final
created: 2026-06-10
updated: 2026-06-11
sources:
  - "{project-root}/_bmad-output/planning-artifacts/briefs/brief-retroai-2026-06-10/brief.md"
  - "{project-root}/_bmad-output/planning-artifacts/briefs/brief-retroai-2026-06-10/addendum.md"
name: "retroai — Panel Administrador"
description: "Panel web/app mobile-first para administradores y empleados de mostrador de un complejo deportivo (5 canchas de pádel + 2 de fútbol 5). Tailwind CSS, paleta 'Pádel Pro' (azul cancha + naranja pelota), modo claro y oscuro."
colors:
  background: '#F0F4F8'
  surface: '#FFFFFF'
  primary: '#0B5FA5'
  primary-foreground: '#FFFFFF'
  accent: '#FF8A1E'
  accent-foreground: '#142433'
  success: '#12A150'
  warning: '#F2A900'
  danger: '#E5483D'
  text-primary: '#142433'
  text-secondary: '#5E7587'
  border: '#DCE6EF'
  pending-bg: '#FFF1DD'
  pending-fg: '#B5740A'
  paid-bg: '#E2F7EC'
  paid-fg: '#0E8045'
  partial-bg: '#FFF1DD'
  partial-fg: '#B5740A'
  background-dark: '#10171F'
  surface-dark: '#1A2530'
  primary-dark: '#5BA3E0'
  primary-foreground-dark: '#0A1620'
  accent-dark: '#FFA64D'
  accent-foreground-dark: '#1A0F00'
  success-dark: '#34C98A'
  warning-dark: '#F0BB5E'
  danger-dark: '#F2746A'
  text-primary-dark: '#EAF2FA'
  text-secondary-dark: '#93A8BD'
  border-dark: '#2A3B4D'
  pending-bg-dark: 'rgba(240,187,94,0.16)'
  pending-fg-dark: '#F0BB5E'
  paid-bg-dark: 'rgba(52,201,138,0.16)'
  paid-fg-dark: '#34C98A'
  partial-bg-dark: 'rgba(240,187,94,0.16)'
  partial-fg-dark: '#F0BB5E'
typography:
  display:
    fontFamily: 'Inter, system-ui, sans-serif'
    fontSize: 24px
    fontWeight: '700'
    lineHeight: '1.2'
  heading:
    fontFamily: 'Inter, system-ui, sans-serif'
    fontSize: 18px
    fontWeight: '700'
    lineHeight: '1.25'
  body:
    fontFamily: 'Inter, system-ui, sans-serif'
    fontSize: 15px
    fontWeight: '400'
    lineHeight: '1.45'
  label:
    fontFamily: 'Inter, system-ui, sans-serif'
    fontSize: 12px
    fontWeight: '700'
    lineHeight: '1.3'
    letterSpacing: '0.04em'
  meta:
    fontFamily: 'Inter, system-ui, sans-serif'
    fontSize: 13px
    fontWeight: '500'
    lineHeight: '1.35'
  numeric:
    fontFamily: 'Inter, system-ui, sans-serif'
    fontSize: 20px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: '-0.01em'
rounded:
  sm: 6px
  md: 10px
  lg: 14px
  xl: 16px
  full: 9999px
  DEFAULT: 10px
spacing:
  '1': 4px
  '2': 8px
  '3': 12px
  '4': 16px
  '5': 20px
  '6': 24px
  '8': 32px
  '10': 40px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
  bottom-nav-height: 64px
components:
  app-header:
    background: '{colors.primary}'
    background-dark: '{colors.background-dark}'
    foreground: '{colors.primary-foreground}'
    foreground-dark: '{colors.text-primary-dark}'
    padding: '{spacing.4}'
  bottom-nav:
    background: '{colors.surface}'
    background-dark: '{colors.surface-dark}'
    border-top: '{colors.border}'
    border-top-dark: '{colors.border-dark}'
    height: '{spacing.bottom-nav-height}'
    active-color: '{colors.primary}'
    active-color-dark: '{colors.primary-dark}'
    inactive-color: '{colors.text-secondary}'
    inactive-color-dark: '{colors.text-secondary-dark}'
  card-turno:
    background: '{colors.surface}'
    background-dark: '{colors.surface-dark}'
    border: '{colors.border}'
    border-dark: '{colors.border-dark}'
    radius: '{rounded.lg}'
    padding: '{spacing.4}'
  court-tag:
    background: '{colors.primary}'
    background-dark: 'rgba(91,163,224,0.16)'
    foreground: '{colors.primary-foreground}'
    foreground-dark: '{colors.primary-dark}'
    radius: '{rounded.sm}'
  status-pill-paid:
    background: '{colors.paid-bg}'
    background-dark: '{colors.paid-bg-dark}'
    foreground: '{colors.paid-fg}'
    foreground-dark: '{colors.paid-fg-dark}'
    radius: '{rounded.full}'
  status-pill-pending:
    background: '{colors.pending-bg}'
    background-dark: '{colors.pending-bg-dark}'
    foreground: '{colors.pending-fg}'
    foreground-dark: '{colors.pending-fg-dark}'
    radius: '{rounded.full}'
  status-pill-partial:
    background: '{colors.partial-bg}'
    background-dark: '{colors.partial-bg-dark}'
    foreground: '{colors.partial-fg}'
    foreground-dark: '{colors.partial-fg-dark}'
    radius: '{rounded.full}'
  button-primary:
    background: '{colors.primary}'
    background-dark: '{colors.primary-dark}'
    foreground: '{colors.primary-foreground}'
    foreground-dark: '{colors.primary-foreground-dark}'
    radius: '{rounded.md}'
    padding: '{spacing.3} {spacing.4}'
  button-action:
    background: '{colors.accent}'
    background-dark: '{colors.accent-dark}'
    foreground: '{colors.accent-foreground}'
    foreground-dark: '{colors.accent-foreground-dark}'
    radius: '{rounded.md}'
    padding: '{spacing.3} {spacing.4}'
  occupancy-bar:
    track: 'rgba(0,0,0,0.06)'
    track-dark: 'rgba(255,255,255,0.06)'
    fill-paid: '{colors.success}'
    fill-paid-dark: '{colors.success-dark}'
    fill-partial: '{colors.warning}'
    fill-partial-dark: '{colors.warning-dark}'
    fill-pending: '{colors.accent}'
    fill-pending-dark: '{colors.accent-dark}'
    radius: '{rounded.full}'
  input-field:
    background: '{colors.surface}'
    background-dark: '{colors.surface-dark}'
    border: '{colors.border}'
    border-dark: '{colors.border-dark}'
    radius: '{rounded.md}'
    padding: '{spacing.3}'
---

# Design Spine: retroai — Panel Administrador

## Brand & Style

retroai (panel administrador) tiene que verse como una herramienta de **gestión seria que vive dentro de un mundo deportivo**. La persona que lo usa — Marcela en el mostrador con el celular en la mano, Hernan en la notebook revisando números — necesita confiar en lo que ve sobre pagos y ocupación tanto como necesita resolver una tarea rápido entre un turno y el siguiente.

La dirección visual elegida, **"Pádel Pro"**, resuelve esa tensión: azul cancha (`{colors.primary}`) como color de marca — técnico, profesional, "deporte de alto nivel" — y naranja pelota (`{colors.accent}`) como único acento cromático para acción y foco. El resto de la interfaz es deliberadamente neutro: superficies blancas/grises claras en modo claro, azul-grisáceo muy oscuro en modo oscuro, tipografía sans-serif geométrica, esquinas redondeadas pero no "juguetonas". La energía deportiva vive en los dos colores de marca y en el vocabulario visual de pills/badges para estados de turno — no en ilustraciones, gradientes ni iconografía decorativa.

Tailwind CSS es la base del sistema: los tokens de este documento se mapean directamente a `theme.extend` (colores, `borderRadius`, `spacing`, `fontFamily`). No se reinventa Tailwind — se lo extiende con la paleta de marca y un puñado de componentes específicos del dominio (tarjeta de turno, pills de estado de pago, barra de ocupación).

La familia tipográfica es `Inter` — estándar de facto en proyectos Tailwind, con excelente legibilidad en pantallas chicas y soporte nativo de variable font.

## Colors

- **Azul Cancha (`{colors.primary}` `#0B5FA5` claro / `{colors.primary-dark}` `#5BA3E0` oscuro)** es el color de marca. Header de la app, navegación activa, botones primarios (acciones de navegación/confirmación neutra), tags de cancha (`court-tag`), enlaces. En modo oscuro se aclara para mantener contraste sobre fondos casi negros — nunca se usa el azul oscuro de modo claro como fondo en modo oscuro.

- **Naranja Pelota (`{colors.accent}` `#FF8A1E` claro / `{colors.accent-dark}` `#FFA64D` oscuro)** es el único acento de **acción primaria sobre datos financieros**: el botón "Marcar como pagado" / "Registrar pago" es el caso de uso canónico. No se usa para navegación, decoración ni para indicar estados (eso lo cubren los pills de pago). Si una pantalla tiene más de un botón naranja visible al mismo tiempo, algo está mal — el naranja significa "esta es la acción que probablemente viniste a hacer".

- **Superficie y fondo (`{colors.background}` / `{colors.surface}` claro, `{colors.background-dark}` / `{colors.surface-dark}` oscuro)**: fondo gris azulado muy claro (`#F0F4F8`) con tarjetas blancas en modo claro; en oscuro, fondo casi negro azulado (`#10171F`) con tarjetas en `#1A2530`. La separación fondo/superficie es sutil — la jerarquía la da el `border` y el espaciado, no contrastes fuertes.

- **Estados de turno — Pagado / Parcial / Pendiente** (ver sección "Estados de Turno" en EXPERIENCE.md para el significado de negocio):
  - **Pagado** → `{colors.paid-bg}` / `{colors.paid-fg}` (verde, deriva de `{colors.success}`).
  - **Parcial** y **Pendiente** comparten el mismo par cromático (`{colors.pending-bg}` / `{colors.pending-fg}`, naranja-ámbar derivado de `{colors.warning}`) — se diferencian por **texto**, no por color, porque ambos representan "todavía hay algo por cobrar" y el usuario necesita leer cuál es cuál sin depender solo del color (ver Accessibility Floor en EXPERIENCE.md).
  - **Danger (`{colors.danger}`)** queda reservado para errores de sistema y confirmaciones destructivas (ej. cancelar un turno) — nunca para "pago pendiente", que no es un error sino un estado normal del negocio.

- **Texto (`{colors.text-primary}` / `{colors.text-secondary}`, y sus pares `-dark`)**: texto primario casi negro-azulado en claro / casi blanco en oscuro; texto secundario gris-azulado para metadatos (horario, cancha, "reservado por"). Mantener el contraste AA mínimo 4.5:1 en ambos modos — crítico porque Marcela puede estar leyendo esto con luz solar directa en el mostrador.

- **Border (`{colors.border}` / `{colors.border-dark}`)**: el único separador visual entre tarjetas y secciones. No usar sombras fuertes para separar contenido (ver Elevation & Depth).

Avoid: agregar un tercer color de marca, usar el naranja para más de una acción visible por pantalla, usar rojo/verde como única señal de estado de pago sin texto acompañante, gradientes decorativos.

## Typography

Escala basada en `Inter` (o equivalente sans-serif geométrica del sistema), con seis roles:

- **`{typography.display}`** (24px / 700) — títulos de pantalla ("Inicio", "Calendario", "Pagos", "Reportes"). Uno por pantalla, en el header.
- **`{typography.heading}`** (18px / 700) — títulos de sección y de tarjeta (ej. nombre de cancha + horario en una tarjeta de turno).
- **`{typography.body}`** (15px / 400) — texto general, descripciones, roster de jugadores.
- **`{typography.label}`** (12px / 700, uppercase, letter-spacing) — etiquetas de pills de estado, tags de cancha, encabezados de tabla/lista en Reportes.
- **`{typography.meta}`** (13px / 500) — metadatos secundarios: duración, "reservado por", timestamps.
- **`{typography.numeric}`** (20px / 700, tabular) — montos de dinero y porcentajes de ocupación. Este rol existe específicamente para que los números financieros tengan **peso visual propio** — un panel de pagos donde los montos se pierden en el cuerpo de texto no cumple su función.

Regla general: nunca más de tres roles tipográficos visibles en una misma tarjeta (ej. `heading` + `meta` + `numeric` en una tarjeta de turno con monto).

## Layout & Spacing

Escala de espaciado en base 4 (`{spacing.1}`–`{spacing.10}`), siguiendo convención Tailwind (`p-1` a `p-10`). Mobile-first: el diseño se construye primero para una columna de ancho completo con `{spacing.margin-mobile}` (16px) de margen lateral, y se expande en `md`/`lg` agregando columnas o ensanchando tarjetas — nunca rediseñando la jerarquía de información.

- **Mobile (`< md`, < 768px)**: layout de una columna. Header fijo arriba (`{components.app-header}`), navegación inferior fija (`{components.bottom-nav}`, altura `{spacing.bottom-nav-height}`). Las tarjetas ocupan el ancho completo menos `{spacing.margin-mobile}` de cada lado.
- **Tablet/Notebook (`md`–`lg`, 768px+)**: el contenido principal pasa a `max-w-3xl` o `max-w-5xl` centrado, con `{spacing.margin-desktop}` (32px) de margen. La navegación inferior puede convertirse en una barra lateral o superior persistente — pero el orden y agrupación de la información (ver Information Architecture en EXPERIENCE.md) no cambia entre breakpoints, solo la disposición.
- **Calendario de 7 canchas**: en mobile se navega cancha por cancha mediante una vista de agenda vertical (lista de turnos del día); en notebook puede mostrarse como grilla cancha × horario. Esta es la superficie donde la diferencia mobile/notebook es más marcada — ver EXPERIENCE.md → Responsive & Platform.

## Elevation & Depth

retroai usa elevación de forma **mínima y funcional**, no decorativa. La jerarquía entre fondo y tarjetas se logra primero con `{colors.border}` (un borde de 1px) y diferencia tonal sutil entre `{colors.background}` y `{colors.surface}`. Sombra (`shadow-sm` de Tailwind, `0 1px 3px rgba(0,0,0,0.08)`) se reserva para:

- Elementos flotantes sobre contenido: navegación inferior fija, modales/sheets de Detalle de Turno, menú de usuario.
- El botón de acción primaria (`{components.button-action}`) cuando está fijo en la parte inferior de un Detalle de Turno (sticky action bar) — para separarlo claramente del contenido que se desplaza debajo.

Tarjetas en reposo (turno, resumen de ocupación, fila de reporte) **no llevan sombra** — solo borde. Esto mantiene la interfaz legible en exteriores con luz fuerte (mostrador) sin que las sombras se "laven".

## Shapes

- **`{rounded.sm}`** (6px) — tags de cancha, inputs pequeños, elementos dentro de una tarjeta.
- **`{rounded.md}`** (10px, `DEFAULT`) — botones, inputs, barras de ocupación (track y fill).
- **`{rounded.lg}`** (14px) — tarjetas de turno, tarjetas de resumen, sheets/modales de Detalle de Turno.
- **`{rounded.xl}`** (16px) — contenedores de pantalla completa en mobile cuando aplica (ej. sheet que sube desde abajo).
- **`{rounded.full}`** (9999px) — pills de estado de pago (Pagado / Parcial / Pendiente) y badges de conteo en Reportes. El pill completamente redondeado es la única forma "blanda" del sistema — reservada exclusivamente para comunicar estado, lo que la hace fácil de reconocer de un vistazo.

## Components

- **App header (`{components.app-header}`)** — Fondo `{colors.primary}` en modo claro (azul cancha sólido) / `{colors.background-dark}` en oscuro (el header se funde con el fondo, evitando un bloque de color brillante en pantallas oscuras). Contiene: título de pantalla (`{typography.display}`), y a la derecha, acceso a perfil/usuario activo (relevante en multi-usuario).

- **Bottom navigation (`{components.bottom-nav}`)** — Fija en mobile, 4 ítems: Inicio, Calendario, Pagos, Reportes. Ítem activo en `{colors.primary}` / `{colors.primary-dark}`, inactivos en `{colors.text-secondary}`. En notebook (`md+`) se reubica como barra lateral o superior persistente, mismos 4 ítems, mismo orden.

- **Card de turno (`{components.card-turno}`)** — Anatomía: `court-tag` (cancha + deporte) arriba, `heading` con horario, `meta` con duración y reservante, lista de jugadores confirmados (`body`), `status-pill` (Pagado/Parcial/Pendiente) y, si corresponde, `button-action` ("Registrar pago"). Es el componente más repetido del sistema — aparece en Inicio (turnos del día), Calendario (por cancha/horario) y como base del Detalle de Turno expandido.

- **Court tag (`{components.court-tag}`)** — Pill rectangular pequeño (`{rounded.sm}`), `{typography.label}` en mayúsculas, fondo `{colors.primary}` / texto `{colors.primary-foreground}` en claro; en oscuro, fondo azul translúcido con texto `{colors.primary-dark}` para evitar bloques sólidos brillantes. Formato: "Cancha N — Pádel" / "Cancha N — Fútbol 5".

- **Status pills (`{components.status-pill-paid}`, `-pending`, `-partial`)** — `{rounded.full}`, `{typography.label}`, con un punto de color (`currentColor`) antes del texto. Pagado en verde; Pendiente y Parcial comparten paleta naranja-ámbar pero **el texto siempre dice la palabra completa** ("Pago Pendiente" / "Pago Parcial") — el color solo refuerza, nunca reemplaza, la lectura.

- **Botón primario (`{components.button-primary}`)** — `{colors.primary}` / `{colors.primary-dark}`, `{rounded.md}`, usado para navegación y confirmaciones neutras (ej. "Ver detalle", "Guardar cambios" en configuración).

- **Botón de acción (`{components.button-action}`)** — `{colors.accent}` / `{colors.accent-dark}`, `{rounded.md}`, ancho completo en mobile dentro de tarjetas/sheets. Reservado para "Registrar pago" / "Marcar como pagado" — la acción que cierra el loop financiero del turno.

- **Barra de ocupación (`{components.occupancy-bar}`)** — Track redondeado (`{rounded.full}`) en gris translúcido, fill segmentado por estado (Pagado=verde, Parcial=ámbar, Pendiente=naranja), con etiqueta y porcentaje (`{typography.numeric}` para el valor). Usado en Inicio (resumen del día) y Reportes (ocupación por cancha/horario).

- **Input field (`{components.input-field}`)** — `{rounded.md}`, borde `{colors.border}`/`{colors.border-dark}`, fondo `{colors.surface}`/`{colors.surface-dark}`. Usado en Login y formularios de configuración.

## Do's and Don'ts

| Do | Don't |
|---|---|
| Usar `{colors.accent}` (naranja) solo para la acción de pago primaria | Usar naranja para navegación, links o decoración |
| Acompañar todo `status-pill` con texto explícito ("Pago Pendiente") | Comunicar estado de pago solo con color |
| Mantener tarjetas con borde, sin sombra, en reposo | Apilar sombras decorativas sobre tarjetas de turno |
| Un solo rol `{typography.numeric}` por tarjeta para el monto/porcentaje destacado | Mezclar dos tamaños "grandes" en la misma tarjeta |
| Mismo orden de navegación (Inicio/Calendario/Pagos/Reportes) en mobile y notebook | Reordenar o renombrar secciones según el breakpoint |
| Modo oscuro con azules/superficies propias (`-dark` tokens) | Aplicar opacidad al azul de modo claro para simular modo oscuro |

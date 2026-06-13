---
story_id: "2.5"
story_key: "2-5-inicio-resumen-del-dia"
epic_id: "2"
title: "Inicio — resumen del día"
status: "ready-for-dev"
last_updated: "2026-06-12"
---

# Story 2.5: Inicio — resumen del día

**As a** Administrador o Empleado del Complejo,
**I want** ver al entrar al Panel un resumen de la Ocupación de hoy por Cancha,
**So that** tenga una vista rápida del estado del día sin entrar al Calendario.

## Acceptance Criteria

- **AC1: Resumen de Ocupación por Cancha**
  - **Given** que estoy autenticado en el Panel
  - **When** abro Inicio
  - **Then** veo una `occupancy-bar` por cada una de las 7 Canchas (5 pádel + 2 fútbol 5)
  - **And** cada barra muestra el resumen de Turnos de hoy (porcentaje de tiempo ocupado sobre el total de horarios operativos)
  - **And** el porcentaje se muestra como texto adyacente (`{typography.numeric}`) para asegurar accesibilidad (UX-DR6/UX-DR10).

- **AC2: Estado vacío "Sin turnos hoy"**
  - **Given** que no hay ningún Turno cargado para hoy
  - **When** abro Inicio
  - **Then** veo el mensaje "No hay turnos para hoy" en lugar de una lista vacía
  - **And** las barras de ocupación se muestran al 0% (UX-DR8).

- **AC3: Pull-to-refresh (Mobile)**
  - **Given** que estoy en mobile
  - **When** deslizo hacia abajo en la pantalla de Inicio
  - **Then** se actualiza la información de ocupación y turnos (UX-DR9).

- **AC4: Acceso Multi-usuario (Dueño y Empleado)**
  - **Given** que soy Empleado o Dueño
  - **When** abro Inicio
  - **Then** veo la misma información (Inicio es una surface compartida sin restricciones de rol, FR-12).

## Developer Context

### Business Logic & Domain Requirements
- **Cálculo de Ocupación**: La ocupación se calcula como `(Suma de horas de turnos hoy / Horas totales operativas del complejo hoy) * 100`. 
- **Horario Operativo**: Por ahora, asumir horario de 08:00 a 00:00 (16 horas totales) si no está definido en el modelo `Complex`.
- **Exclusión de Cancelados**: Los turnos en estado `cancelado` no deben sumar a la ocupación.

### Technical Requirements
- **Controller**: Crear `InicioController#index` (mapeado a `root` o `/inicio`).
- **ViewComponent**: Implementar `OccupancyBarComponent` siguiendo `DESIGN.md`:
  - Track: redondeado (`{rounded.full}`), gris translúcido.
  - Fill: segmentado por estado de pago si es posible, o un color sólido `{colors.success}` si es simplificado para el MVP.
  - Accesibilidad: El porcentaje debe ser texto real, no solo un `aria-label`.
- **Hotwire**:
  - Usar `Turbo Drive` para la navegación.
  - Pull-to-refresh puede implementarse con un Stimulus controller simple o confiando en el comportamiento nativo de Turbo si se usa una estructura de layout adecuada.
- **Tailwind**: Aplicar tokens de la paleta "Pádel Pro" y tipografía `Inter`.

### Architecture Compliance
- **RBAC**: No se requiere policy restrictiva para `Inicio`, pero debe heredar de `AuthenticatedController` (o similar) para asegurar que el usuario esté logueado.
- **ViewComponents**: La lógica de cálculo del ancho de la barra debe vivir en el componente o en un helper, no en la vista.

### File Structure Requirements
- `app/controllers/inicio_controller.rb`
- `app/views/inicio/index.html.erb`
- `app/components/occupancy_bar_component.rb`
- `app/components/occupancy_bar_component.html.erb`
- `test/controllers/inicio_controller_test.rb`
- `test/components/occupancy_bar_component_test.rb`

## Previous Story Intelligence (2.1 - 2.4)
- **Story 2.1** estableció el Calendario. La lógica de búsqueda de turnos por fecha (`Turno.where(date: Date.today)`) ya debería estar disponible o ser similar a la usada en el Calendario.
- **Story 2.4** (en curso por otra instancia) está manejando Turnos Fijos. Asegurarse de que `Inicio` cuente correctamente las instancias generadas de turnos fijos para hoy.

## Project Context Reference
- **Architecture**: `_bmad-output/planning-artifacts/architecture.md`
- **UX Design**: `_bmad-output/planning-artifacts/ux-designs/ux-retroai-2026-06-10/DESIGN.md` y `EXPERIENCE.md`

---
**Status:** ready-for-dev
*Ultimate context engine analysis completed - comprehensive developer guide created*

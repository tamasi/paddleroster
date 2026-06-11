# Reconciliación: prd.md vs EXPERIENCE.md

## Gaps / capacidades sin FR correspondiente

### 1. Gestión de Canchas y Datos del Complejo (Configuración) sin FR
- **EXPERIENCE.md** (Information Architecture, fila "Configuración"): "Gestión de canchas, usuarios/empleados, datos del complejo" — acceso solo Dueño.
- **prd.md** §4.5 (Autenticación y Gestión de Usuarios): solo cubre FR-11 (Login), FR-12 (Roles), FR-13 (Invitación de Empleados) — es decir, solo la parte "usuarios/empleados" de Configuración.
- **Gap:** "Gestión de canchas" (¿alta/baja/edición de las 7 Canchas, nombres, deporte asignado?) y "datos del complejo" (nombre, dirección, etc.) aparecen en la IA de EXPERIENCE.md como responsabilidad del Dueño en Configuración, pero no tienen FR ni mención en §4 ni en §6.1 In Scope del PRD. No está claro si es una omisión, o si se asume que las 7 Canchas son fijas/seed-data para el piloto y por eso no requieren FR. Recomendación: aclarar explícitamente (FR nuevo, `[ASSUMPTION]`, o Non-Goal) si la gestión de canchas/datos del complejo es parte del MVP.

### 2. Estado de Confirmación "Reemplazo" no mencionado explícitamente en FR-2
- **EXPERIENCE.md** (Roster row / State Patterns): el Estado de Confirmación de un jugador puede ser "Confirmado / Pendiente / Reemplazo".
- **prd.md** Glosario (§3, "Estado de Confirmación"): correctamente lista los tres valores (Confirmado, Pendiente, Reemplazo).
- **prd.md** FR-2 (Confirmación individual de asistencia): solo menciona que "El Estado de Confirmación de cada Jugador (Confirmado/Pendiente) se actualiza en tiempo real" — omite "Reemplazo" como posible valor visible en el Detalle de Turno del Panel, aunque FR-3 sí cubre el mecanismo de reemplazo. Es una inconsistencia menor de redacción (no de modelo): el valor "Reemplazo" del Estado de Confirmación queda implícito solo en FR-3 / Glosario, no explícito en FR-2 donde se enumeran los estados visibles.

## Comportamientos de EXPERIENCE.md correctamente cubiertos o apropiadamente fuera de FR (no son gaps)
- Pull-to-refresh, swipe entre canchas, sheets/modales, banner "Sin conexión", "Sesión expirada" con retorno a pantalla previa: son comportamientos de interacción/UX (NFR/diseño), correctamente delegados a EXPERIENCE.md sin necesidad de FR propio — FR-11 sí referencia el comportamiento de sesión expirada.
- Terminología verificada consistente entre ambos documentos: Origen Bot/Manual, Turno Fijo/Recurrente, Roster, Suplente, Estado de Confirmación, Estado de Pago (Pagado/Parcial/Pendiente), Dueño/Empleado, Cancha, Capitán, Jugador, Ocupación — todos alineados 1:1.
- UJ-4 a UJ-7 mirroran correctamente Flow 1-4 de EXPERIENCE.md sin contradicciones.

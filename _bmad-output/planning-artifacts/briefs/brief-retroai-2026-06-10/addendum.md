# Addendum — retroai Product Brief

Contenido adicional que no entra en el brief ejecutivo pero es relevante para el trabajo de PRD/Arquitectura/Sprint Planning posterior.

## Contexto del Complejo Piloto

- 5 canchas de pádel + 2 canchas de fútbol 5.
- Gestión actual informal (cuaderno/planillas/WhatsApp), tanto para turnos como para pagos.
- Hernan tiene relación directa con el dueño/administrador de este complejo — facilita la validación temprana y el acceso a feedback real.

## Restricciones de Desarrollo

- Desarrollador único (Hernan), sin equipo adicional.
- Sin plazo fijo establecido — el ritmo de desarrollo se autogestiona.
- Sin stack tecnológico definido aún (a resolver en fase de Arquitectura).
- Sin presupuesto definido para servicios externos (ej. WhatsApp Business API, pasarelas de pago) — a evaluar según opciones elegidas.

## Personas Detalladas (de la sesión de brainstorming)

### Jugador Frecuente / Capitán de Grupo Fijo
Juega semanalmente con un grupo fijo de 4 (pádel) o más (fútbol 5), siempre en el mismo horario. Es quien organiza, paga y lidia con cancelaciones de último momento. Su mayor dolor es la coordinación manual del roster y encontrar reemplazos rápido.

### Administrador del Complejo
Gestiona 5 canchas de pádel + 2 de fútbol 5. Sus prioridades explícitas: control de pagos pendientes, reportes de ocupación, y gestión de turnos lo más simple y automatizada posible.

### (Futuro) Jugador Ocasional / Visitante
No explorado en profundidad durante el brainstorming — queda como persona a desarrollar cuando se trabaje el matching/red multi-complejo.

## Backlog de Ideas para Fases Posteriores (de la sesión de brainstorming)

Agrupado por tema, con la idea/concepto y su valor potencial. Todas estas ideas fueron generadas y validadas como interesantes en la sesión de brainstorming (`brainstorming-session-2026-06-10-1616.md`), pero quedaron fuera del MVP por priorización, no por descarte.

**Red de Matching de Jugadores (Tema 2 completo):**
- Matching de Jugadores Sueltos para Completar Roster — sugerir jugadores disponibles cuando falta gente para completar el cupo.
- Perfil de Jugador con Filtros de Matching (nivel de juego, calificación/reputación, zona habitual, edad, género) — para que el capitán decida con información antes de aceptar a un desconocido.
- Reemplazo Automático vía Matching + Notificación Grupal — cuando alguien cancela y ofrece su lugar, el sistema busca candidatos del pool de matching y notifica al grupo (con veto del capitán).
- Swipe para Aceptar/Rechazar Candidatos de Matching — interacción rápida tipo "dating app" para revisar candidatos sugeridos.
- Tracking en Vivo + Calificación Post-Partido — sistema de reputación post-turno (puntualidad, nivel, actitud), necesario para que el matching con desconocidos genere confianza.

**Funcionalidades Avanzadas de Administración:**
- Gestión Automatizada de Turnos — reglas automáticas de confirmación, recordatorios, liberación de horarios no confirmados.
- Motor de Precios Dinámicos / Sugerencias de Descuento — el sistema sugiere descuentos para horarios de baja ocupación según datos históricos, con aprobación del admin.
- Notificaciones de "Turno con Descuento Disponible" — push/WhatsApp a jugadores cuando hay turnos con descuento, cerrando el loop entre datos de ocupación → precio → demanda.

**Funcionalidades Cross-cutting:**
- Lista de Espera + Cupos Transferibles — turnos completos generan lista de espera; cupos confirmados pueden transferirse (modelo "venta de entradas").
- Pedido de Refrigerios Pre-configurado para el Turno — el grupo pre-pide al kiosco/buffet del complejo al reservar, listo para retirar al llegar; ingreso adicional para el complejo.

**Visión de Plataforma/Negocio (Conceptos Breakthrough):**
- Modelo Híbrido: Bot de WhatsApp (jugadores) + Dashboard Web/App (administrador) — diferenciar canal según rol en vez de "una sola app para todos". Insight clave: minimizar fricción de adopción para el jugador (canal que ya usa) vs. dar control real al admin.
- Red Multi-Complejo Independiente con Jugadores Compartidos (Marketplace Geográfico) — complejos de distintos dueños/ciudades se suman como nodos de una red; jugadores tienen perfil único válido en toda la red (ej. jugador de Tucumán usando su perfil en un complejo de Buenos Aires).
- Monetización Híbrida: Suscripción a Complejos + Fee de Uso a Jugadores — diversifica ingresos entre ambos lados del marketplace, escalando con el efecto red.

## Decisión de Canal por Rol: Bot de WhatsApp (Jugador) vs. Web/App (Administrador)

Decisión confirmada: el jugador interactúa con retroai exclusivamente a través de un **bot de WhatsApp** (roster, confirmaciones, reemplazos) para minimizar fricción de adopción — sin necesidad de descargar nada ni registrarse. El administrador opera desde un **panel web/app** que requiere mayor profundidad de control (pagos, reportes, gestión de canchas).

**Implicancia para Arquitectura:** el modelo de datos y la lógica de negocio (confirmaciones, reemplazos, estados de turno) deben diseñarse desacoplados del canal desde el inicio — el bot de WhatsApp y el panel web/app del administrador son dos interfaces sobre el mismo modelo subyacente de Turno/Roster. Esto también deja la puerta abierta a agregar una interfaz de jugador (app/web) más adelante sin rediseñar el core, si en el futuro se justifica (ej. funcionalidades de matching más visuales tipo swipe).

**Costo a evaluar:** la integración con WhatsApp Business API (oficial o vía proveedores como Twilio) puede tener costos por mensaje — a investigar en fase de Arquitectura, dado que no hay presupuesto definido para servicios externos.

## Identidad de Jugador Centralizada (Nota para Arquitectura)

Aunque el MVP se construye para un solo complejo, el brainstorming identificó que la visión de red multi-complejo depende de que la identidad/perfil del jugador no esté atada a un complejo específico desde el modelo de datos inicial. Se recomienda tenerlo presente al diseñar las entidades de Jugador/Usuario en la fase de Arquitectura, aunque no se implemente la red en el MVP.

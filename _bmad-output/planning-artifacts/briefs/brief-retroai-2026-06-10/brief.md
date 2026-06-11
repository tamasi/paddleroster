---
title: "Product Brief: retroai"
status: final
created: 2026-06-10
updated: 2026-06-11
---

# Product Brief: retroai

## Executive Summary

Retroai es un sistema de agendamiento de turnos para complejos deportivos (canchas de pádel y fútbol 5), pensado para reemplazar la gestión manual e informal que hoy llevan tanto los grupos de jugadores como los administradores de complejos. Para los jugadores, especialmente los "capitanes" de grupos fijos, retroai convierte la coordinación semanal por WhatsApp/llamadas en un flujo de confirmación y reemplazo auto-gestionado por roster. Para el administrador, convierte el control informal de pagos y ocupación (cuaderno, planillas, WhatsApp) en un panel centralizado con visibilidad real del negocio.

El proyecto nace como una iniciativa personal, con un complejo piloto concreto en mente (5 canchas de pádel + 2 de fútbol 5), donde Hernan busca validar el producto antes de ofrecerlo a otros complejos de la zona, con potencial de crecimiento mediante redes sociales. La apuesta inicial es modesta y de bajo riesgo — un producto enfocado en resolver dolores reales y observables — pero la arquitectura está pensada desde el día 1 para no cerrar la puerta a una visión más ambiciosa: una red de complejos independientes con jugadores compartidos.

Un principio de diseño central de retroai es la **diferenciación de canal por rol**: el jugador interactúa principalmente a través de un **bot de WhatsApp** (cero fricción, sin descargar nada ni registrarse), mientras que el administrador del complejo opera desde un **panel web/app** con la profundidad de control que su rol requiere.

## The Problem

**Para el jugador frecuente/capitán de grupo:**
Organizar el turno semanal fijo (ej: martes 20hs con el mismo grupo de amigos) implica hoy un trabajo manual constante: armar la lista de quiénes van, confirmar uno por uno, y cuando alguien cancela a último momento, buscar un reemplazo llamando o escribiendo a contactos hasta encontrar a alguien disponible. Esta carga recae siempre sobre la misma persona (el capitán), y un cupo sin cubrir significa pagar de más entre menos personas o jugar incompletos.

**Para el administrador del complejo (5 canchas de pádel + 2 de fútbol 5):**
El control de qué turnos están pagos, cuáles tienen pago pendiente o parcial, y qué horarios/canchas quedan vacíos se lleva de forma informal — cuaderno, planillas sueltas, mensajes de WhatsApp. Esto genera dos problemas concretos: (1) dinero que se pierde o es difícil de reclamar por falta de registro claro, y (2) decisiones de negocio (precios, promociones, mantenimiento) tomadas "a ojo" sin datos reales de ocupación por cancha y horario.

**Costo del status quo:** horas semanales de coordinación manual para los jugadores, cupos vacíos que representan ingresos perdidos para el complejo, y fricción/desconfianza cuando los pagos no quedan claros entre el grupo y el administrador.

## The Solution

Retroai resuelve esto con dos piezas centrales (validadas en sesión de brainstorming previa y priorizadas para la primera iteración), cada una entregada por el canal que mejor se ajusta a su usuario:

1. **Roster de Turno con Confirmación Individual y Reemplazo Auto-gestionado (vía Bot de WhatsApp):** el capitán crea el turno (pádel o fútbol 5) y arma el roster de participantes desde WhatsApp. Cada jugador recibe un mensaje/link individual para confirmar su asistencia sin necesidad de registrarse ni instalar nada. Si un jugador no puede asistir, puede ofrecer su lugar directamente desde el bot — descentralizando lo que hoy es responsabilidad exclusiva del capitán.

2. **Panel de Pagos Pendientes + Reportes de Ocupación para el Administrador (vía Web/App):** un dashboard que centraliza el estado de pago de cada turno (pagado, pendiente, parcial) y muestra la ocupación real por cancha, día y horario — para las 5 canchas de pádel y las 2 de fútbol 5 desde el día 1.

El modelo de roster/turno se diseña de forma genérica para que aplique tanto a pádel como a fútbol 5 sin necesitar lógicas separadas, y la lógica de negocio (confirmaciones, reemplazos, estados de turno) se mantiene desacoplada del canal — de modo que el bot de WhatsApp y el panel web/app del administrador operan sobre el mismo modelo subyacente.

## What Makes This Different

La ventaja inicial de retroai no es tecnológica, sino de **acceso y conocimiento de dominio**: Hernan tiene un complejo real (con sus dos tipos de cancha) para co-diseñar y validar el producto con el dueño y los jugadores reales, en vez de construir a ciegas. Esto permite ajustar el producto a fricciones reales antes de intentar venderlo a otros complejos.

A mediano plazo, la diferenciación más fuerte que surgió en el brainstorming es la **gestión unificada multi-deporte** (pádel + fútbol 5 con el mismo modelo de roster) combinada con la visión de red — perfiles de jugador que eventualmente podrían compartirse entre complejos. Esta visión de red no es parte del MVP, pero condiciona decisiones de diseño tempranas (ver Scope y Visión).

**Validado con investigación de mercado** (`research/market-plataformas-reserva-turnos-complejos-deportivos-padel-futbol5-latam-research-2026-06-11.md`): el mercado de reservas/gestión para pádel y fútbol 5 se organiza en dos categorías —apps centradas en el jugador/marketplace de reservas (Playtomic, Easycancha, Padelero) y software de gestión integral para clubes (CanchaFija, ATC, Matchpoint)— y ninguna gestiona el **roster del turno recurrente de un grupo fijo** (confirmación + reemplazo auto-gestionado) como unidad central. Además, Playtomic reconoce estar sub-penetrado en Argentina, y sus usuarios reportan quejas recurrentes por comisiones, cobros incorrectos y soporte deficiente — fricciones que el modelo de retroai (sin costo ni registro para el jugador, vía WhatsApp) evita directamente. El pádel argentino está en pleno crecimiento (2-3M jugadores, +30% de canchas en 3 años), lo que favorece el timing de entrada.

## Who This Serves

**Jugador Frecuente / Capitán de Grupo Fijo:** organiza un turno semanal recurrente con su grupo (pádel o fútbol 5). Necesita armar el roster, que cada jugador confirme por su cuenta, y resolver bajas de último momento sin que toda la responsabilidad caiga sobre él. Éxito para esta persona = dejar de coordinar manualmente por WhatsApp.

**Administrador del Complejo:** gestiona 5 canchas de pádel y 2 de fútbol 5. Necesita saber qué turnos están pagos, cuáles no, y cómo se está usando cada cancha en el tiempo. Éxito para esta persona = reemplazar el cuaderno/planilla por un panel que le dé control y visibilidad real.

**(Futuro, fuera del MVP) Jugador Ocasional / Visitante:** jugador suelto que busca completar un partido en un complejo que no es "el suyo" — relevante cuando la red multi-complejo se desarrolle.

## Success Criteria

El piloto se considerará exitoso si:

- Al menos el 30% de los turnos del complejo (pádel y fútbol 5) se gestionan a través del bot de WhatsApp (roster, confirmaciones, reemplazos), en lugar del método actual (cuaderno/WhatsApp informal sin estructura).
- El administrador adopta el panel web/app de pagos pendientes y reportes de ocupación como su herramienta principal de control, dejando de depender del registro manual.
- Se observa una reducción de cupos vacíos / no-shows gracias al flujo de roster + reemplazo auto-gestionado por WhatsApp.

## Scope

**Incluido en el MVP:**
- Roster de turno con confirmación individual y reemplazo auto-gestionado, vía bot de WhatsApp, aplicable tanto a canchas de pádel (5) como de fútbol 5 (2).
- Panel de administrador (web/app): pagos pendientes/parciales/pagados + reportes de ocupación por cancha, día y horario.
- Modelo de datos y lógica de negocio desacoplados del canal, para que jugador (WhatsApp) y administrador (web/app) operen sobre el mismo turno/roster.

**Explícitamente fuera del MVP (evoluciones futuras, ya identificadas):**
- Matching de jugadores sueltos para completar roster, perfiles con nivel/reputación y calificación post-partido.
- Motor de precios dinámicos / sugerencias de descuento y notificaciones automáticas asociadas.
- Pedido de refrigerios pre-configurado para el turno.
- Red multi-complejo con perfiles de jugador compartidos entre complejos independientes, y modelo de monetización de doble cara (suscripción a complejos + fee de jugador).
- App móvil/web dedicada para el jugador — es una decisión de diseño, no una limitación temporal; se reconsideraría solo si surge una necesidad que WhatsApp no cubra (ej. matching visual tipo swipe).

## Vision

A 2-3 años, retroai podría ser la base operativa de una red de complejos deportivos de barrio — empezando por el complejo piloto y expandiéndose a otros complejos de la zona vía recomendación y redes sociales. Cada complejo gestiona sus propias canchas (pádel, fútbol 5, y potencialmente otros deportes) con el mismo panel de administración, mientras los jugadores mantienen un perfil único que les permite organizarse, completar partidos mediante matching, y eventualmente moverse entre complejos de la red manteniendo su reputación. El modelo de negocio evoluciona de "herramienta para un complejo" a "red con valor de ambos lados del marketplace" — sostenida por una suscripción accesible para los complejos y un fee de uso para los jugadores.

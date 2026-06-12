# retroai

Plataforma de gestión para complejos deportivos (Pádel/Fútbol 5) con integración de Bot de WhatsApp para rosters y confirmaciones automáticas.

## Estructura del Proyecto

- **/**: Monolito de Ruby on Rails 8 (Panel de Administración, Lógica de Negocio, Reportes).
- **/whatsapp-service**: Servicio de Node.js/TypeScript basado en Baileys que actúa como adaptador para la comunicación con WhatsApp.

## Requisitos

- Ruby 3.4.9
- Node.js 22+
- PostgreSQL

## Desarrollo

1. Iniciar Rails: `bin/dev`
2. Iniciar WhatsApp Service: `cd whatsapp-service && npm run dev`

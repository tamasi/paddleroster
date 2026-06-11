---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
lastStep: 8
status: 'complete'
completedAt: '2026-06-11'
inputDocuments:
  - "{project-root}/_bmad-output/planning-artifacts/prds/prd-retroai-2026-06-11/prd.md"
  - "{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-retroai-2026-06-10/DESIGN.md"
  - "{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-retroai-2026-06-10/EXPERIENCE.md"
  - "{project-root}/_bmad-output/planning-artifacts/research/market-plataformas-reserva-turnos-complejos-deportivos-padel-futbol5-latam-research-2026-06-11.md"
  - "{project-root}/_bmad-output/planning-artifacts/briefs/brief-retroai-2026-06-10/brief.md"
  - "{project-root}/_bmad-output/planning-artifacts/briefs/brief-retroai-2026-06-10/addendum.md"
workflowType: 'architecture'
project_name: 'retroai'
user_name: 'Hernan'
date: '2026-06-11'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**

15 FRs (FR-1 a FR-15) organizados en 5 grupos funcionales, todos sobre un modelo de datos compartido entre dos canales:

- **Bot de WhatsApp** (FR-1, FR-2, FR-3): el Capitán crea Turno+Roster vía conversación con el Bot; cada Jugador confirma individualmente; reemplazo auto-gestionado cuando alguien cancela, ofreciendo el cupo a Suplentes en orden con un timeout configurable. Implica: integración con WhatsApp (mensajería saliente/entrante), parseo de respuestas de usuario (botones/palabras clave), validación de números de teléfono.
- **Gestión de Turnos / Calendario** (FR-4, FR-5, FR-6, FR-7, FR-15): vista de Calendario por Cancha/horario (7 Canchas), creación manual de Turno, Turnos Fijos/Recurrentes con generación automática de instancias futuras, registro de Origen (Bot/Manual) para reporting, cancelación de Turno desde el Panel. Implica: modelo de disponibilidad/conflicto de horarios, job de generación de instancias recurrentes.
- **Pagos** (FR-8, FR-9): visualización de Estado de Pago (Pagado/Parcial/Pendiente) y registro de pagos (completo/parcial) con actualización inmediata sin recarga.
- **Reportes** (FR-10): Ocupación por Cancha/día/horario para un período seleccionable, distinguiendo pádel/fútbol 5.
- **Auth/Usuarios** (FR-11 a FR-14): login multi-usuario, roles Dueño/Empleado con accesos diferenciados, invitación de Empleados vía link/código, gestión de Canchas y datos del Complejo.

**Non-Functional Requirements:**

- **Latencia de mensajería del Bot** (FR-3): notificaciones de invitación/confirmación/reemplazo deben llegar "en segundos, no minutos" — la coordinación de un reemplazo de último momento depende de esto.
- **Actualización reactiva del Panel** (FR-9): el Estado de Pago se actualiza "sin necesidad de recargar la pantalla" tras registrar un pago.
- **RBAC**: dos roles (Dueño/Empleado) con accesos diferenciados a nivel de navegación y, para Configuración/Reportes, también a nivel de ruta — "no puede acceder a Configuración por URL/ruta directa" (FR-12).
- **Accesibilidad**: contraste AA mínimo 4.5:1 en ambos modos; todo estado de pago/ocupación con texto explícito, nunca solo color (`EXPERIENCE.md` → Accessibility Floor).
- **Modo claro/oscuro** desde el día 1, con tokens propios por modo (no inversión automática).
- **Responsive mobile-first + notebook**, mismo orden de información en ambos breakpoints (`DESIGN.md`/`EXPERIENCE.md`).
- **Restricción de presupuesto** (§10 PRD): sin presupuesto para servicios externos pagos en el MVP — condiciona directamente el enfoque técnico del Bot de WhatsApp (Open Question 4) y, en general, la elección de hosting/infraestructura.
- **Single Complejo piloto** (7 Canchas) — el sistema no necesita multi-tenancy en el MVP, pero el modelo de datos no debe acoplar la identidad del Jugador al Complejo de forma irreversible (guardrail §10, visión multi-complejo a 2-3 años).
- **Mantenibilidad por desarrollador único** — favorece stack simple, "aburrido", de bajo overhead operativo, sin infraestructura que requiera administración constante.

**Scale & Complexity:**

- Complejidad del proyecto: **baja-media** para un MVP, con **un punto de riesgo/integración significativo**: el enfoque técnico del Bot de WhatsApp (API oficial de Meta vs. librería no oficial tipo Baileys/whatsapp-web.js), explícitamente diferido a esta fase (Open Question 4 del PRD) y condicionado por la restricción de presupuesto.
- Primary domain: **full-stack** — Panel web/app (mobile-first + notebook, modo claro/oscuro, Tailwind) + backend/API + integración Bot WhatsApp, sobre un modelo de datos compartido (Turno, Roster, Jugador, Cancha, Complejo, Usuario, Pago).
- Estimated architectural components: backend/API (lógica de negocio compartida: Turnos, Roster, Confirmaciones, Pagos, Ocupación, Auth/RBAC), capa de persistencia, frontend del Panel (Tailwind, responsive, dark mode), integración del Bot de WhatsApp (canal de mensajería), generador de instancias de Turnos Fijos/Recurrentes (job programado).

### Technical Constraints & Dependencies

- Desarrollo a cargo de un único desarrollador (Hernan), sin plazo fijo de lanzamiento, pero con expectativa de pasar a producción real con usuarios reales en cuanto el piloto lo permita.
- Sin presupuesto para servicios externos pagos en el MVP — cualquier costo recurrente (ej. WhatsApp Business API oficial) debe evaluarse contra esta restricción.
- Validación contra un único Complejo piloto (7 Canchas), con acceso directo al dueño para iteración rápida.
- Sin stack tecnológico definido aún (a resolver en esta fase, según `addendum.md`).
- Identidad de Jugador no debe acoplarse irreversiblemente al Complejo único del MVP (guardrail para visión multi-complejo a 2-3 años).

### Cross-Cutting Concerns Identified

- **Modelo de datos y lógica de negocio compartidos entre canales** (Bot WhatsApp + Panel) — es el principio de diseño central del MVP; toda decisión de arquitectura debe preservar esta separación canal/lógica.
- **Enfoque técnico del Bot de WhatsApp** — afecta mensajería, costos, infraestructura y disponibilidad; es la decisión arquitectónica de mayor incertidumbre y mayor impacto en el resto del sistema.
- **RBAC (Dueño/Empleado)** — atraviesa navegación, rutas y futuras entidades de Configuración.
- **Accesibilidad, modo claro/oscuro y responsive** — atraviesan todo el frontend del Panel, ya especificados en `DESIGN.md`/`EXPERIENCE.md`.
- **Generación de instancias recurrentes (Turnos Fijos)** — requiere un mecanismo de jobs/scheduling, por simple que sea.
- **Restricción de presupuesto** — condiciona la elección del Bot, hosting, y cualquier servicio externo (auth, storage, etc.).
- **Portabilidad futura del perfil de Jugador** (multi-complejo) — guardrail que debe reflejarse en el modelado de entidades desde el día 1, sin implementar la red ahora.

## Starter Template Evaluation

### Primary Technology Domain

Full-stack web (Ruby on Rails) + servicio adaptador Node.js/TypeScript aislado para el Bot de WhatsApp.

### Starter Options Considered

- **Stack Node/TypeScript full-stack (Next.js, NestJS, etc.):** integraría Baileys de forma nativa, pero Hernan tiene experiencia casi nula en TypeScript — implicaría una curva de aprendizaje sobre el 100% del código del proyecto, para un desarrollador único sin plazos de soporte.
- **Ruby on Rails 8 + servicio Node/TS aislado para Baileys (elegido):** aprovecha la experiencia existente de Hernan en Rails para el grueso de la lógica de negocio (Turnos, Roster, Pagos, RBAC, Reportes), y aísla la única pieza que requiere Node/TS (el adaptador de WhatsApp vía Baileys) como un servicio pequeño y reemplazable — coincide con el patrón de "adaptador detrás de una cola" identificado en la ronda de Party Mode.
- Rails 8 incluye **Solid Queue, Solid Cache y Solid Cable** (todos respaldados por PostgreSQL, sin necesitar Redis como servicio aparte) — reduce la superficie operativa para un dev único sin presupuesto.

### Selected Starter: Ruby on Rails 8

**Rationale for Selection:**

- Aprovecha la experiencia real de Hernan con Rails para ~90% del código del proyecto.
- Turbo Streams + Solid Cable cubren el requisito de "Panel sin recarga" (FR-9) sin infraestructura adicional (websockets vía Postgres, no Redis).
- Solid Queue cubre la cola de notificaciones salientes del Bot (outbox con reintentos/backoff) y la generación de instancias de Turnos Fijos recurrentes, sin servicios externos.
- Kamal 2 viene preinstalado en Rails 8 y tiene soporte probado para desplegar en un droplet de DigitalOcean (Rails + Postgres + servicio Baileys en contenedores, todo en un único VPS) — encaja con el "monolito modular en un VPS único" recomendado en Party Mode.
- Baileys (`WhiskeySockets/Baileys`) está activamente mantenido en 2026 y sigue siendo la opción no-oficial de referencia para WhatsApp en Node/TS.

**Initialization Command:**

```bash
rails new retroai --database=postgresql --css=tailwind
```

**Architectural Decisions Provided by Starter:**

**Language & Runtime:**
Ruby on Rails 8 para la aplicación principal (Panel + API + lógica de negocio compartida).

**Styling Solution:**
Tailwind CSS, vía `--css=tailwind` — alineado con los tokens de `DESIGN.md` (paleta "Pádel Pro").

**Build Tooling:**
Pipeline de assets de Rails 8 con Tailwind integrado.

**Testing Framework:**
Minitest (default de Rails) — a confirmar/ajustar en pasos posteriores según la estrategia de testing del dominio (lógica de Roster/reemplazo 100% testeada de forma independiente al Bot).

**Code Organization:**
Estructura convencional de Rails (MVC) para Panel/API. Servicio complementario separado (Node/TypeScript + Baileys) con responsabilidad única: traducir eventos de WhatsApp ↔ tablas `outbox`/`inbox` en PostgreSQL compartido.

**Development Experience:**
Hot reloading estándar de Rails; Kamal 2 preinstalado para despliegue a un droplet de DigitalOcean (Rails + Postgres + servicio Baileys como contenedores adicionales).

**Note:** La inicialización con este comando, junto con la configuración inicial del servicio adaptador de WhatsApp, debería ser la primera historia de implementación.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**

- Modelo de datos desacoplado Player/Complex (con tabla intermedia ComplexPlayer) — afecta el esquema completo desde la primera migración.
- Comunicación Rails ↔ servicio Baileys vía tablas compartidas `whatsapp_outbox`/`whatsapp_inbox` con polling — define el contrato entre los dos componentes del sistema.
- Autenticación con el generador nativo de Rails 8 + Pundit para RBAC — afecta todas las rutas y vistas desde el inicio.

**Important Decisions (Shape Architecture):**

- Hotwire (Turbo + Stimulus) + ViewComponent para el frontend, sin bundler de JS.
- Solid Queue / Solid Cache / Solid Cable (Postgres-backed, sin Redis) para jobs, caché y tiempo real.
- Modelo `Invitation` con token de un solo uso + expiración para FR-13.
- Hosting en droplet de DigitalOcean (4GB/2vCPU) con Kamal 2 + GitHub Actions para CI/CD.
- Alertas de salud del Bot vía bot de Telegram (canal secundario, gratuito).

**Deferred Decisions (Post-MVP):**

- `LISTEN/NOTIFY` de Postgres en lugar de polling para la cola WhatsApp — solo si la latencia de polling cada 2-3seg resulta insuficiente en producción.
- Separación de Postgres a su propio droplet/managed-DB — solo si se concreta la visión multi-complejo.
- Migración del Bot de WhatsApp Baileys → API oficial de Meta — solo si el presupuesto lo permite y/o el riesgo de baneo se materializa.

### Data Architecture

- **Base de datos**: PostgreSQL (vía starter Rails 8).
- **Modelo de entidades**:
  - `Player`: `id`, `phone` (E.164, único), `name` — independiente de `Complex`.
  - `Complex`: `id`, `name`, datos del complejo (FR-14).
  - `Court`: pertenece a `Complex`, con `sport` (pádel/fútbol 5).
  - `ComplexPlayer`: tabla de membresía `player_id` ↔ `complex_id`, con datos locales del Complejo sobre ese jugador.
  - `Turno`: pertenece a `Court`, con `origin` (Bot/Manual) y `recurring_rule_id` (nullable).
  - `RosterEntry`: vincula `Turno` ↔ `Player`, con `confirmation_status` (Pendiente/Confirmado/Reemplazo/Sin cubrir) y `role` (Titular/Suplente).
  - `Payment`: vinculado a `Turno`, con `status` (Pagado/Parcial/Pendiente) y monto.
- **Validación**: validaciones estándar de ActiveRecord (presence, formato E.164, unicidad).
- **Migraciones**: flujo estándar de Rails (`rails generate migration`).
- **Caching**: Solid Cache, uso mínimo (posible cómputo de Reportes de Ocupación).

### Authentication & Security

- **Autenticación**: generador nativo de Rails 8 (`bin/rails generate authentication`) — `User` con `has_secure_password` (bcrypt), modelo `Session` con tracking de IP/user agent.
- **RBAC**: columna `role` en `User` (`owner` / `employee`) + **Pundit** para policies por controller — garantiza que FR-12 (Empleado sin acceso a Configuración por URL directa) se cumpla a nivel de autorización, no solo de navegación.
- **Invitaciones (FR-13)**: modelo `Invitation` con `has_secure_token`, `expires_at`, `used_at`, `invited_by` — single-use + time-limited, con auditoría.
- **Seguridad estándar**: protecciones default de Rails (CSRF, `force_ssl` vía Kamal/Let's Encrypt). `Rack::Attack` para rate-limiting del login.
- **API pública**: ninguna en el MVP.

### API & Communication Patterns

- **Comunicación Rails ↔ servicio Baileys**: vía tablas compartidas en PostgreSQL, sin HTTP API entre servicios.
  - `whatsapp_outbox` (`id`, `phone`, `body`, `status`, `retry_count`, `created_at`): el servicio Node hace polling cada 2-3seg, envía vía Baileys, actualiza `status`.
  - `whatsapp_inbox` (`id`, `phone`, `raw_body`, `processed`, `created_at`): un job recurrente de Solid Queue procesa mensajes entrantes y los traduce a comandos de dominio.
- **Reintentos**: backoff simple en `whatsapp_outbox.retry_count` (ej. 5s/30s/2min); tras N intentos, `status='failed'` y queda visible para revisión manual.
- **Health-check**: el servicio Baileys expone `/health` verificando `connection.state === 'open'`.
- **Alertas**: bot de Telegram (API gratuita) como canal secundario — notifica a Hernan si el health-check falla por más de N minutos o si hay mensajes en `whatsapp_outbox` con `status='failed'` acumulados.
- **Rate limiting**: `Rack::Attack`, solo para login.

### Frontend Architecture

- **Stack**: Hotwire (Turbo Drive + Turbo Frames + Turbo Streams) + Stimulus + Importmap (sin bundler de JS, sin Node en el frontend).
- **Tiempo real ("sin recarga", FR-9)**: Turbo Streams sobre Solid Cable — `broadcast_replace_to` al registrar un pago u otros cambios de estado.
- **Componentes**: ViewComponent, mapeando 1:1 los Component Patterns de `EXPERIENCE.md` (`status-pill`, `card-turno`, `input-field`, etc.).
- **Routing**: rutas RESTful estándar de Rails, alineadas a la Information Architecture (Inicio, Calendario, Pagos, Reportes, Configuración, Detalle de Turno, Nuevo Turno).
- **Modo claro/oscuro**: clase `dark` en `<html>` + Tailwind `dark:`, toggle vía Stimulus persistido en `localStorage`/cookie.
- **Performance**: Importmap (cero build de JS) + Turbo Drive; sin necesidad de optimización adicional a esta escala.

### Infrastructure & Deployment

- **Hosting**: droplet DigitalOcean, 4GB RAM / 2 vCPU (~USD 24/mes), corriendo Rails + Postgres + servicio Baileys como contenedores Docker.
- **CI/CD**: GitHub Actions (free tier) → tests (Minitest) → build de imágenes → push a GitHub Container Registry → Kamal 2 despliega vía SSH con rolling restart.
- **Configuración**: Rails encrypted credentials para secrets; variables de entorno por Kamal.
- **Monitoring/Logging**: `kamal app logs` para logs centralizados; health-check del servicio Baileys + alertas vía bot de Telegram.
- **Escalado**: no aplica para el MVP de un único Complejo; un solo droplet alcanza.

### Decision Impact Analysis

**Implementation Sequence:**

1. `rails new retroai --database=postgresql --css=tailwind` + setup inicial del servicio Node/Baileys (primera historia, per Step 3).
2. Modelo de datos (`Player`, `Complex`, `Court`, `ComplexPlayer`, `Turno`, `RosterEntry`, `Payment`) + migraciones.
3. Autenticación (generador nativo) + RBAC (Pundit) + modelo `Invitation`.
4. Tablas `whatsapp_outbox`/`whatsapp_inbox` + jobs de polling (Solid Queue) + servicio Baileys con health-check.
5. Frontend: ViewComponents de los Component Patterns + vistas del Panel (Inicio, Calendario, Detalle de Turno, Pagos, Reportes, Configuración) con Turbo Streams para FR-9.
6. CI/CD (GitHub Actions + Kamal) + despliegue inicial al droplet DigitalOcean + bot de Telegram para alertas.

**Cross-Component Dependencies:**

- El modelo de datos (Player/Complex/ComplexPlayer) condiciona tanto las vistas del Panel como los comandos de dominio que traduce el job de `whatsapp_inbox`.
- RBAC (Pundit) debe estar definido antes de construir las vistas de Configuración/Reportes, para no tener que retrofittear permisos.
- El health-check del servicio Baileys y las alertas de Telegram dependen de que `whatsapp_outbox`/`whatsapp_inbox` ya existan.

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:** 6 áreas donde agentes de IA podrían tomar decisiones distintas si no se especifica.

### Naming Patterns

**Database Naming Conventions:**

- Tablas: plural, snake_case (convención Rails) — `players`, `complexes`, `complex_players`, `turnos`, `roster_entries`, `payments`, `whatsapp_outbox`, `whatsapp_inbox`.
- Columnas: snake_case — `phone`, `confirmation_status`, `retry_count`.
- Foreign keys: `<modelo_singular>_id` — `player_id`, `complex_id`, `turno_id`.
- Índices: convención automática de Rails (`index_table_on_column`), sin nombres custom salvo necesidad de índice compuesto.
- Nombres de dominio en español donde el Glosario del PRD lo define (`Turno`, `RosterEntry` no — usar inglés para nombres de tabla/clase técnicos, mantener "Turno"/"Roster" como concepto pero `turnos`/`roster_entries` como nombre de tabla, ya que es el nombre que aparece en el Glosario y en `EXPERIENCE.md`).

**API Naming Conventions:**

- No hay API pública. Las rutas internas del Panel siguen las convenciones RESTful de Rails (`resources :turnos`, `resources :payments`, anidadas donde corresponda: `resources :turnos do resources :roster_entries end`).
- Parámetros de ruta: `:id` (convención Rails), no `{id}`.

**Code Naming Conventions:**

- Ruby: `snake_case` para métodos/variables, `CamelCase` para clases/módulos (convención Ruby estándar).
- ViewComponents: `CamelCase` + sufijo `Component` — `StatusPillComponent`, `CardTurnoComponent`, `InputFieldComponent` — mapeando 1:1 los nombres de los Component Patterns en `EXPERIENCE.md`.
- Stimulus controllers: kebab-case en el HTML (`data-controller="dark-mode-toggle"`), `camelCase`/archivo `dark_mode_toggle_controller.js` (convención `stimulus-rails`).
- Servicio Node/Baileys: `camelCase` para variables/funciones (convención TypeScript/JS estándar) — es la única excepción al snake_case, limitada a ese servicio aislado.

### Structure Patterns

**Project Organization:**

- Estructura Rails convencional: `app/models`, `app/controllers`, `app/views`, `app/components` (ViewComponents), `app/javascript` (Stimulus controllers, importmap).
- Tests: `test/models`, `test/controllers`, `test/components` — espejando la estructura de `app/`, según convención Minitest/Rails.
- Lógica de dominio compleja (ej. algoritmo de reemplazo de Suplentes de FR-3) vive en `app/models/concerns/` o Plain Old Ruby Objects en `app/services/` — testeable de forma aislada, sin depender del Bot, tal como recomendó Amelia en Party Mode.
- Servicio Baileys: directorio propio en la raíz del repo, ej. `whatsapp-service/`, completamente separado de `app/` — refuerza el aislamiento del adaptador.

**File Structure Patterns:**

- Configuración de Kamal: `config/deploy.yml` (convención Kamal 2).
- Credenciales: `config/credentials.yml.enc` (convención Rails).
- Migraciones: `db/migrate/`, timestamps automáticos (convención Rails, no renombrar).

### Format Patterns

**API Response Formats:**

- No aplica (sin API pública). Las respuestas son HTML/Turbo Streams.

**Data Exchange Formats (contrato `whatsapp_outbox`/`whatsapp_inbox`):**

- `whatsapp_outbox.body` y `whatsapp_inbox.raw_body`: texto plano (el contenido del mensaje de WhatsApp), no JSON — Baileys trabaja con strings de texto/botones, no con payloads estructurados.
- `whatsapp_outbox.status` / valores posibles: `pending`, `sent`, `failed` (strings, no enums numéricos — legibles desde ambos lenguajes, Ruby y TypeScript, sin necesidad de sincronizar un enum compartido).
- `whatsapp_inbox.processed`: boolean.
- Timestamps: `created_at`/`updated_at` en UTC (default de Rails/Postgres) — el servicio Node debe escribir también en UTC.
- Teléfonos: siempre formato E.164 (`+549...`) en ambas tablas y en `players.phone` — normalización ocurre en el punto de entrada (servicio Node al recibir un mensaje, o el formulario del Panel al cargar un jugador manualmente).

### Communication Patterns

**Event System Patterns:**

- Jobs de Solid Queue: nombre de clase descriptivo en inglés, sufijo `Job` — `ProcessWhatsappInboxJob`, `GenerateRecurringTurnosJob`, `SendWhatsappAlertJob`.
- Turbo Streams: nombre de canal = `"#{model_name}_#{id}"` o un canal por Complejo para actualizaciones del Panel — ej. `turbo_stream_from "complex_#{complex.id}_payments"` para el broadcast de FR-9.

**State Management Patterns:**

- Estado de UI vive en el servidor (Rails) — no hay estado de cliente complejo. Stimulus controllers son "tontos": solo manipulan el DOM local (toggle de tema, validaciones), nunca mantienen estado de negocio.
- `confirmation_status` y `payment_status`: siempre strings legibles en español en la UI (vía helper de presentación), pero almacenados como `enum` de Rails en inglés en el modelo (ej. `enum confirmation_status: { pending: 0, confirmed: 1, replacement: 2, uncovered: 3 }`) — separa el dato del idioma de presentación.

### Process Patterns

**Error Handling Patterns:**

- Errores de validación de formularios: patrón estándar de Rails (`@model.errors`, mostrados inline junto a cada campo) — coincide con el patrón de `input-field` de `EXPERIENCE.md`.
- Errores del servicio Baileys (mensajes en `failed`): no se muestran como error de UI al usuario — quedan visibles en una vista de "Estado del Bot" (Configuración) para Dueño, y disparan la alerta de Telegram.
- Excepciones no controladas: manejo estándar de Rails (`rescue_from` en `ApplicationController`, página de error genérica en producción).

**Loading State Patterns:**

- Turbo Drive maneja el estado de carga global (barra de progreso nativa).
- Para acciones puntuales (ej. marcar pago), usar `data-turbo-submits-with="Guardando..."` en el botón — patrón nativo de Turbo, sin JS adicional.

### Enforcement Guidelines

**All AI Agents MUST:**

- Usar snake_case para todo lo que sea Ruby/Rails (DB, código, archivos), camelCase solo dentro de `whatsapp-service/` (Node/TS).
- Nombrar ViewComponents siguiendo 1:1 los Component Patterns de `EXPERIENCE.md`.
- Mantener toda la lógica de dominio (Roster, reemplazos, pagos) independiente del servicio Baileys — comunicación solo vía `whatsapp_outbox`/`whatsapp_inbox`.
- Usar E.164 para teléfonos en toda tabla/columna que los almacene.
- Usar `enum` de Rails (valores en inglés) para todo campo de estado, con helpers de presentación para el texto en español visible al usuario.

**Pattern Enforcement:**

- Revisión de PRs (aunque sea autorrevisión, dado dev único) contra esta sección antes de mergear.
- Cualquier desviación necesaria se documenta como nueva entrada en esta sección (actualización de `architecture.md`), no como excepción silenciosa.

### Pattern Examples

**Good Examples:**

- `app/models/turno.rb` con `enum confirmation_status: { ... }` y `app/components/status_pill_component.rb` que traduce ese enum a texto/color según `DESIGN.md`.
- `whatsapp-service/src/outbox-poller.ts` leyendo `whatsapp_outbox` cada 2-3seg vía `pg`, sin lógica de negocio — solo traduce `body` a un mensaje de Baileys.

**Anti-Patterns:**

- Guardar JSON estructurado en `whatsapp_outbox.body` (acopla el formato al adaptador — el adaptador debe recibir texto listo para enviar).
- Lógica de "a quién ofrecerle el cupo de Suplente" implementada dentro de `whatsapp-service/` — debe vivir en Rails, el servicio Baileys solo entrega el mensaje que Rails ya decidió enviar.

## Project Structure & Boundaries

### Complete Project Directory Structure

```
retroai/
├── README.md
├── Gemfile
├── Gemfile.lock
├── Rakefile
├── config.ru
├── .ruby-version
├── .gitignore
├── .github/
│   └── workflows/
│       └── deploy.yml
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── sessions_controller.rb          # FR-11 login
│   │   ├── passwords_controller.rb         # FR-11 reset password
│   │   ├── invitations_controller.rb       # FR-13 invitación de empleados
│   │   ├── turnos_controller.rb            # FR-4, FR-5, FR-6, FR-15
│   │   ├── roster_entries_controller.rb    # FR-1, FR-2, FR-3 (vista, no Bot)
│   │   ├── payments_controller.rb          # FR-8, FR-9
│   │   ├── reports_controller.rb           # FR-10
│   │   └── configuracion_controller.rb     # FR-12, FR-14
│   ├── models/
│   │   ├── user.rb                         # FR-11, FR-12
│   │   ├── session.rb                      # generador de auth Rails 8
│   │   ├── invitation.rb                   # FR-13
│   │   ├── player.rb                       # entidad Jugador, portable
│   │   ├── complex.rb                      # FR-14
│   │   ├── court.rb                        # FR-14, Calendario
│   │   ├── complex_player.rb               # tabla de membresía
│   │   ├── turno.rb                        # FR-4 a FR-7, FR-15
│   │   ├── roster_entry.rb                 # FR-1, FR-2, FR-3
│   │   ├── payment.rb                      # FR-8, FR-9
│   │   ├── whatsapp_outbox_message.rb      # cola saliente Bot
│   │   └── whatsapp_inbox_message.rb       # cola entrante Bot
│   ├── services/
│   │   ├── roster_replacement_service.rb   # FR-3: lógica de reemplazo de Suplentes
│   │   ├── whatsapp_inbox_processor.rb     # traduce inbox → comandos de dominio
│   │   └── recurring_turno_generator.rb    # FR-6: genera instancias futuras
│   ├── jobs/
│   │   ├── process_whatsapp_inbox_job.rb
│   │   ├── generate_recurring_turnos_job.rb
│   │   └── send_whatsapp_alert_job.rb      # alertas Telegram
│   ├── policies/
│   │   ├── application_policy.rb
│   │   ├── turno_policy.rb
│   │   ├── report_policy.rb                # FR-10/FR-12: solo Dueño
│   │   └── configuracion_policy.rb         # FR-12: solo Dueño
│   ├── components/
│   │   ├── status_pill_component.rb (+ .html.erb)   # Estado Pago/Confirmación
│   │   ├── card_turno_component.rb (+ .html.erb)    # Calendario/Inicio
│   │   └── input_field_component.rb (+ .html.erb)   # formularios
│   ├── views/
│   │   ├── layouts/
│   │   ├── sessions/
│   │   ├── invitations/
│   │   ├── turnos/                         # Calendario, Nuevo Turno, Detalle
│   │   ├── payments/
│   │   ├── reports/
│   │   └── configuracion/                  # Canchas, Complejo, Empleados
│   ├── javascript/
│   │   ├── application.js
│   │   └── controllers/
│   │       ├── index.js
│   │       └── dark_mode_toggle_controller.js
│   ├── assets/
│   │   └── stylesheets/
│   │       └── application.tailwind.css    # tokens DESIGN.md "Pádel Pro"
│   └── helpers/
│       └── status_presentation_helper.rb   # enum → texto en español
├── config/
│   ├── routes.rb
│   ├── database.yml
│   ├── deploy.yml                          # Kamal 2
│   ├── credentials.yml.enc
│   ├── recurring.yml                       # Solid Queue: jobs recurrentes
│   ├── environments/
│   └── initializers/
│       └── pundit.rb
├── db/
│   ├── migrate/
│   ├── schema.rb
│   └── seeds.rb                            # datos del Complejo piloto (7 canchas)
├── test/
│   ├── models/
│   ├── controllers/
│   ├── components/
│   ├── services/                           # tests de RosterReplacementService, etc.
│   └── fixtures/
└── whatsapp-service/
    ├── package.json
    ├── tsconfig.json
    ├── Dockerfile
    ├── .env.example
    └── src/
        ├── index.ts                        # entrypoint, arranca poller + health server
        ├── baileys-client.ts               # sesión de Baileys, reconexión
        ├── outbox-poller.ts                # lee whatsapp_outbox, envía mensajes
        ├── inbox-writer.ts                 # escribe whatsapp_inbox al recibir mensajes
        ├── health-server.ts                # endpoint /health
        └── db.ts                           # conexión pg compartida con Postgres de Rails
```

### Architectural Boundaries

**API Boundaries:**

- Sin API pública ni externa. El único "límite de API" es interno: el contrato `whatsapp_outbox`/`whatsapp_inbox` entre Rails y `whatsapp-service/` (Step 5).
- Autenticación/autorización: `ApplicationController` (sesión) + Pundit policies por controller — límite en `app/policies/`.

**Component Boundaries:**

- ViewComponents (`app/components/`) son los únicos componentes de presentación reutilizables; las vistas (`app/views/`) los componen pero no duplican su markup.
- Stimulus controllers (`app/javascript/controllers/`) solo manipulan DOM local — no acceden a datos de negocio directamente.
- `app/services/` contiene toda la lógica de dominio que no encaja en un modelo ActiveRecord (reemplazo de Suplentes, generación de recurrentes, traducción inbox→comando) — frontera clara entre "reglas de negocio" y "infraestructura/adaptadores".

**Service Boundaries:**

- `whatsapp-service/` es el único componente fuera del monolito Rails. Su frontera es estrictamente las tablas `whatsapp_outbox`/`whatsapp_inbox` en Postgres — no comparte código, gemas, ni convenciones con `app/`.
- Despliegue: ambos (Rails y `whatsapp-service/`) son contenedores separados gestionados por el mismo `config/deploy.yml` de Kamal, en el mismo droplet.

**Data Boundaries:**

- Esquema único de Postgres compartido por ambos servicios — Rails es dueño del esquema (migraciones viven en `db/migrate/`); `whatsapp-service/` solo lee/escribe en `whatsapp_outbox`/`whatsapp_inbox` (no debe tener migraciones propias).
- Solid Cache/Solid Queue/Solid Cable usan el mismo Postgres (tablas propias generadas por sus gemas) — sin Redis.

### Requirements to Structure Mapping

**Feature/Epic Mapping:**

- **Bot de WhatsApp** (FR-1, FR-2, FR-3): `whatsapp-service/`, `app/models/whatsapp_*_message.rb`, `app/jobs/process_whatsapp_inbox_job.rb`, `app/services/roster_replacement_service.rb`, `app/services/whatsapp_inbox_processor.rb`.
- **Gestión de Turnos/Calendario** (FR-4, FR-5, FR-6, FR-7, FR-15): `app/controllers/turnos_controller.rb`, `app/models/turno.rb`, `app/services/recurring_turno_generator.rb`, `app/jobs/generate_recurring_turnos_job.rb`, `app/views/turnos/`.
- **Pagos** (FR-8, FR-9): `app/controllers/payments_controller.rb`, `app/models/payment.rb`, `app/views/payments/`, broadcasts de Turbo Streams en `app/models/payment.rb` (`broadcast_replace_to`).
- **Reportes** (FR-10): `app/controllers/reports_controller.rb`, `app/policies/report_policy.rb`, `app/views/reports/`.
- **Auth/Usuarios** (FR-11 a FR-14): `app/controllers/sessions_controller.rb`, `passwords_controller.rb`, `invitations_controller.rb`, `configuracion_controller.rb`, `app/models/user.rb`, `invitation.rb`, `complex.rb`, `court.rb`.

**Cross-Cutting Concerns:**

- **RBAC**: `app/policies/` (Pundit) — toda nueva funcionalidad agrega su policy acá.
- **Modelo de datos compartido / portabilidad de Jugador**: `app/models/player.rb`, `complex.rb`, `complex_player.rb` — núcleo del modelo, cualquier feature nueva referencia estas entidades sin acoplar Jugador a Complejo.
- **Accesibilidad/Dark mode/Responsive**: `app/components/` + `app/assets/stylesheets/application.tailwind.css` — los tokens y patrones de `DESIGN.md`/`EXPERIENCE.md` viven acá, no se redefinen por vista.
- **Alertas operativas**: `app/jobs/send_whatsapp_alert_job.rb` + `whatsapp-service/src/health-server.ts`.

### Integration Points

**Internal Communication:**

- Rails ↔ `whatsapp-service/`: vía tablas `whatsapp_outbox`/`whatsapp_inbox` en Postgres (polling cada 2-3seg, Step 5).
- Panel ↔ Servidor: Turbo Drive/Frames/Streams (HTML sobre HTTP + Solid Cable para broadcasts).

**External Integrations:**

- WhatsApp (vía Baileys, en `whatsapp-service/`) — única integración externa de mensajería.
- Telegram Bot API (vía `app/jobs/send_whatsapp_alert_job.rb`) — alertas operativas a Hernan.
- Sin pasarelas de pago ni servicios de auth externos (fuera de alcance del MVP).

**Data Flow:**

1. Capitán envía mensaje a WhatsApp → `whatsapp-service` lo recibe (Baileys) → escribe en `whatsapp_inbox`.
2. `ProcessWhatsappInboxJob` (Solid Queue, Rails) lee `whatsapp_inbox` → `WhatsappInboxProcessor` traduce a comando de dominio (crear Turno, confirmar Roster, etc.) → actualiza modelos (`Turno`, `RosterEntry`, etc.).
3. Cambios de estado relevantes (ej. cupo liberado) → `RosterReplacementService` decide a quién notificar → inserta filas en `whatsapp_outbox`.
4. `whatsapp-service` hace polling de `whatsapp_outbox` → envía vía Baileys → marca `sent`/`failed`.
5. En paralelo, cambios de `Payment`/`Turno` → `broadcast_replace_to` (Turbo Streams/Solid Cable) → Panel se actualiza sin recarga (FR-9).

### File Organization Patterns

**Configuration Files:**

- `config/deploy.yml` (Kamal, define ambos contenedores: Rails + `whatsapp-service`).
- `config/recurring.yml` (Solid Queue: `GenerateRecurringTurnosJob`, `ProcessWhatsappInboxJob`).
- `whatsapp-service/.env.example` documenta variables necesarias (conexión a Postgres, credenciales de sesión Baileys).

**Source Organization:**

- Rails: estructura MVC convencional + `services/`, `jobs/`, `policies/`, `components/` como extensiones estándar de Rails (todas son convenciones ampliamente adoptadas, no inventos del proyecto).
- `whatsapp-service/`: estructura mínima `src/` — sin frameworks adicionales, solo Baileys + cliente `pg` + servidor HTTP mínimo para `/health`.

**Test Organization:**

- `test/services/` es donde vive la cobertura crítica de FR-3 (reemplazo de Suplentes) — debe poder testearse sin levantar `whatsapp-service/` ni Postgres real (fixtures).
- `whatsapp-service/` no requiere suite de tests formal en el MVP — es una capa fina; se valida con fixtures de mensajes grabados si crece en complejidad (Step 5, recomendación de Amelia).

**Asset Organization:**

- Tailwind compilado vía pipeline de Rails 8 (`app/assets/stylesheets/`), sin paso de build de Node.

### Development Workflow Integration

**Development Server Structure:**

- `bin/dev` (Rails 8 default) levanta el servidor Rails + watcher de Tailwind.
- `whatsapp-service/` se levanta aparte (`npm run dev`) durante desarrollo local — requiere apuntar a la misma instancia de Postgres local.

**Build Process Structure:**

- Rails: pipeline de assets estándar (Propshaft + Tailwind), sin bundler JS.
- `whatsapp-service/`: build TypeScript → JS (esbuild/tsc) empaquetado en su propia imagen Docker.

**Deployment Structure:**

- `config/deploy.yml` de Kamal define dos servicios (`web` para Rails, `whatsapp` para el adaptador) + el accesorio Postgres — todos en el mismo droplet de DigitalOcean, desplegados juntos vía GitHub Actions (Step 4).

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**

Todas las decisiones tecnológicas son compatibles entre sí y constituyen combinaciones ampliamente documentadas y probadas en producción: Rails 8 + PostgreSQL + Solid Queue/Cache/Cable (sin Redis) + Kamal 2 + Tailwind + ViewComponent + Pundit es un stack coherente y "aburrido" por diseño. El servicio `whatsapp-service/` (Node/TS + Baileys) es el único componente fuera de este stack, deliberadamente aislado y sin dependencias compartidas — su única superficie de contacto son dos tablas de Postgres, lo que evita conflictos de versiones o convenciones entre Ruby y TypeScript.

**Pattern Consistency:**

Los patrones de naming (snake_case en Rails/DB, camelCase limitado a `whatsapp-service/`), los patrones de comunicación (`whatsapp_outbox`/`whatsapp_inbox` como contrato de texto plano, Turbo Streams para tiempo real) y los patrones de estructura (servicios/jobs/policies como extensiones convencionales de Rails) son consistentes entre sí y con las decisiones de Step 4. No se identifican contradicciones.

**Structure Alignment:**

La estructura de proyecto (Step 6) materializa cada decisión de Step 4 y cada patrón de Step 5: cada FR tiene un destino concreto en el árbol de directorios, los límites de servicio (`whatsapp-service/` vs `app/`) coinciden con los límites de datos (tablas outbox/inbox vs esquema de dominio), y los puntos de integración (polling, Turbo Streams, Telegram) están explícitamente ubicados.

### Requirements Coverage Validation ✅

**Functional Requirements Coverage:**

- **Bot de WhatsApp** (FR-1, FR-2, FR-3): cubierto por `whatsapp-service/` + tablas outbox/inbox + `RosterReplacementService` + `WhatsappInboxProcessor`.
- **Gestión de Turnos/Calendario** (FR-4, FR-5, FR-6, FR-7, FR-15): cubierto por `Turno`, `Court`, `RecurringTurnoGenerator`, `GenerateRecurringTurnosJob`, `turnos_controller`.
- **Pagos** (FR-8, FR-9): cubierto por `Payment` + Turbo Streams/Solid Cable para actualización sin recarga.
- **Reportes** (FR-10): cubierto por `reports_controller` + `ReportPolicy` (acceso restringido a Dueño).
- **Auth/Usuarios** (FR-11 a FR-14): cubierto por el generador de auth de Rails 8, `Invitation`, Pundit, `Complex`/`Court` para FR-14.

**Non-Functional Requirements Coverage:**

- **Latencia "en segundos" (FR-3)**: polling cada 2-3seg en ambas direcciones de la cola WhatsApp — sobradamente dentro del margen de "segundos, no minutos".
- **"Sin recarga" del Panel (FR-9)**: Turbo Streams + Solid Cable, sin infraestructura adicional.
- **RBAC (FR-12)**: Pundit a nivel de policy, no solo de navegación — cubre el caso de acceso directo por URL.
- **Accesibilidad / dark mode / responsive**: ViewComponent + Tailwind, tokens de `DESIGN.md`, sin redefinición ad-hoc por vista.
- **Restricción de presupuesto**: Baileys (gratis) + Solid Queue/Cache/Cable (sin Redis) + GitHub Actions free tier + Telegram Bot API (gratis) + un único droplet DigitalOcean (~USD 24/mes) — el único costo recurrente del proyecto.
- **Single Complejo + portabilidad de Jugador**: modelo `Player`/`Complex`/`ComplexPlayer` desacoplado desde el día 1, sin construir multi-tenancy.
- **Mantenibilidad por dev único**: stack 100% convencional de Rails + un único servicio externo aislado y de bajo overhead operativo.

### Implementation Readiness Validation ✅

**Decision Completeness:**

Las decisiones críticas están documentadas con versiones verificadas (Rails 8, Kamal 2, Baileys/`WhiskeySockets` activo en 2026, Postgres vía starter). La versión exacta de PostgreSQL no se fija explícitamente — se recomienda usar la versión estable más reciente soportada por la imagen Docker de Postgres al momento de iniciar la implementación (decisión de bajo riesgo, no bloqueante).

**Structure Completeness:**

El árbol de proyecto (Step 6) es completo y específico — cubre Rails, `whatsapp-service/`, configuración de Kamal/CI, tests y seeds. Todos los modelos, controllers, jobs, services y policies necesarios para los 15 FRs están nombrados y ubicados.

**Pattern Completeness:**

Los 6 puntos de conflicto identificados en Step 5 (naming DB/API/código, estructura, formatos de intercambio, eventos/estado, manejo de errores/loading) están resueltos con ejemplos concretos y anti-patrones documentados.

### Gap Analysis Results

**Critical Gaps:** ninguno.

**Important Gaps:**

- La composición del pool de Suplentes (Open Question 5 del PRD) y la semántica fina de edición de instancias de Turno Fijo (OQ2 del PRD) son reglas de negocio/UX, no decisiones arquitectónicas — el modelo de datos (`RosterEntry.role`, `Turno.recurring_rule_id`) las soporta sin cambios estructurales, pero quedan pendientes de definición a nivel de FR/historias antes de implementar `RosterReplacementService` y `RecurringTurnoGenerator` en detalle.
- Credenciales del bot de Telegram (token + chat ID) y de la sesión de Baileys (número dedicado) son configuración operativa, no arquitectura — quedan como tareas de setup de la primera historia de implementación.

**Nice-to-Have Gaps:**

- Documentar un runbook breve de "qué hacer si hay que re-escanear el QR de WhatsApp" — mencionado en Party Mode, útil para el dev único pero no bloqueante.

### Validation Issues Addressed

No se encontraron issues críticos ni importantes que requieran resolución antes de implementar. Los "Important Gaps" identificados son decisiones de producto/configuración a resolver durante la creación de épicas e historias (`bmad-create-epics-and-stories`), no architectural blockers.

### Architecture Completeness Checklist

**Requirements Analysis**

- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**Architectural Decisions**

- [x] Critical decisions documented with versions
- [x] Technology stack fully specified
- [x] Integration patterns defined
- [x] Performance considerations addressed

**Implementation Patterns**

- [x] Naming conventions established
- [x] Structure patterns defined
- [x] Communication patterns specified
- [x] Process patterns documented

**Project Structure**

- [x] Complete directory structure defined
- [x] Component boundaries established
- [x] Integration points mapped
- [x] Requirements to structure mapping complete

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION

**Confidence Level:** high

**Key Strengths:**

- Aprovecha la experiencia real de Hernan (Rails) para el ~90% del código, minimizando riesgo de aprendizaje en un proyecto de dev único.
- El Bot de WhatsApp está aislado como adaptador reemplazable, con cola de reintentos y health-check — mitiga el riesgo operativo más alto del proyecto sin sobre-ingeniería.
- Cero servicios pagos adicionales más allá del droplet único — coherente con la restricción de presupuesto.
- El modelo de datos protege la portabilidad de Jugador a futuro sin construir multi-tenancy prematuramente.
- Stack "aburrido" y convencional (Rails 8 + Postgres + Kamal) — bajo overhead operativo para mantenimiento por una sola persona.

**Areas for Future Enhancement:**

- Si la latencia de polling (2-3seg) resultara insuficiente en producción, migrar a `LISTEN/NOTIFY` de Postgres es un cambio acotado a `whatsapp-service/` y los jobs de Solid Queue.
- Si se concreta la visión multi-complejo, separar Postgres a su propio droplet/managed-DB antes de escalar Rails horizontalmente.
- Runbook operativo para re-escaneo de sesión de Baileys (recomendado en Party Mode).

### Implementation Handoff

**AI Agent Guidelines:**

- Seguir todas las decisiones arquitectónicas exactamente como están documentadas en este archivo.
- Usar los patrones de implementación de forma consistente en todos los componentes.
- Respetar la estructura y los límites de proyecto definidos en Step 6.
- Consultar este documento ante cualquier duda arquitectónica.

**First Implementation Priority:**

```bash
rails new retroai --database=postgresql --css=tailwind
```

seguido de la configuración inicial mínima de `whatsapp-service/` (esqueleto del proyecto Node/TS + conexión a Postgres + health-check), según Step 3 y Step 6.

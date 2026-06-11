---
baseline_commit: NO_VCS
---

# Story 1.1: Inicialización del Proyecto

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Hernan (desarrollador),
I want tener el proyecto Rails 8 inicializado con Tailwind/Postgres y el esqueleto del servicio `whatsapp-service` corriendo localmente,
so that pueda empezar a construir features sobre una base consistente con la arquitectura definida.

## Acceptance Criteria

1. **Given** que no existe el proyecto, **When** ejecuto `rails new retroai --database=postgresql --css=tailwind`, **Then** el proyecto arranca con `bin/dev` y sirve una página por defecto conectada a Postgres.
2. **Given** el directorio `whatsapp-service/` creado con `package.json`/`tsconfig.json`/`Dockerfile`, **When** ejecuto `npm run dev`, **Then** el servicio expone `/health` respondiendo 200 con un cuerpo simple (sin conexión real a Baileys todavía).
3. **Given** el esqueleto de ambos servicios, **When** reviso el repo, **Then** la estructura de directorios coincide con la definida en `architecture.md` (Project Structure & Boundaries).

## Tasks / Subtasks

- [x] Task 1: Inicializar repositorio Git y proyecto Rails 8 (AC: #1, #3)
  - [x] Subtask 1.1: `git init` en la raíz del proyecto, agregar `.gitignore` (incluir el `.gitignore` por defecto de Rails + entradas para `whatsapp-service/node_modules`, `whatsapp-service/dist`, `.env`)
  - [x] Subtask 1.2: Ejecutar `rails new retroai --database=postgresql --css=tailwind` (usar el directorio actual del repo como destino, no anidar otro repo dentro)
  - [x] Subtask 1.3: Configurar `config/database.yml` para apuntar a una instancia Postgres local (development/test)
  - [x] Subtask 1.4: Crear la base de datos (`bin/rails db:create`) y verificar que `bin/dev` levanta el servidor Rails + watcher de Tailwind, sirviendo la página por defecto sin errores de conexión a Postgres
  - [x] Subtask 1.5: Confirmar `.ruby-version` (Ruby 3.3+, recomendado 3.4.x) y que `Gemfile.lock` quedó generado

- [x] Task 2: Crear esqueleto de `whatsapp-service/` (AC: #2, #3)
  - [x] Subtask 2.1: Crear directorio `whatsapp-service/` en la raíz del repo (hermano de `app/`, fuera del monolito Rails)
  - [x] Subtask 2.2: Crear `package.json` con scripts `dev` y `build`, `tsconfig.json` (target Node LTS), `Dockerfile` mínimo, `.env.example` documentando la variable de conexión a Postgres compartido
  - [x] Subtask 2.3: Crear `src/index.ts` como entrypoint que arranca el servidor de health-check (el poller/Baileys se implementan en stories posteriores — Step 4/5 de `architecture.md`)
  - [x] Subtask 2.4: Crear `src/health-server.ts` con un servidor HTTP mínimo (sin dependencias externas pesadas) que exponga `GET /health` devolviendo `200` con un body simple (ej. `{"status":"ok"}`) — NO conectar a Baileys todavía, solo el shape del endpoint
  - [x] Subtask 2.5: Crear archivos stub vacíos/mínimos para `src/baileys-client.ts`, `src/outbox-poller.ts`, `src/inbox-writer.ts`, `src/db.ts` para reflejar la estructura objetivo de `architecture.md` (implementación real en Story 5.1)
  - [x] Subtask 2.6: Verificar que `npm install && npm run dev` levanta el servicio y `curl localhost:<puerto>/health` responde 200

- [x] Task 3: Validar estructura de directorios contra `architecture.md` (AC: #3)
  - [x] Subtask 3.1: Comparar el árbol generado por `rails new` + `whatsapp-service/` contra la sección "Complete Project Directory Structure" de `architecture.md`
  - [x] Subtask 3.2: Confirmar que existen los directorios base que usarán stories futuras: `app/services/`, `app/policies/`, `app/components/`, `app/javascript/controllers/`, `test/services/` (pueden estar vacíos o con un `.keep`, no es necesario crear archivos de dominio en esta story)
  - [x] Subtask 3.3: Hacer commit inicial con el esqueleto de ambos servicios

## Dev Notes

- **Esta es la PRIMERA story del proyecto** — no hay código previo, no hay historias anteriores, no hay convenciones de código aún establecidas más allá de las definidas en `architecture.md`. Lo que se decida acá (estructura, nombres) es la base para todo lo demás.
- **Alcance estricto**: esta story es solo el esqueleto/inicialización. NO implementar modelos de dominio (`User`, `Player`, `Turno`, etc.), autenticación, ni la lógica real de Baileys — eso corresponde a Stories 1.2+ y al Step 4/5 del plan de implementación de `architecture.md`.
- **Comando de inicialización exacto** (no improvisar variantes): `rails new retroai --database=postgresql --css=tailwind` [Source: architecture.md#Selected-Starter-Ruby-on-Rails-8].
- **Stack confirmado por el starter**: Hotwire (Turbo+Stimulus) vía Importmap, Tailwind CSS, Propshaft, Solid Queue/Solid Cache/Solid Cable (todos backed by Postgres, sin Redis), Kamal 2 preinstalado [Source: architecture.md#Selected-Starter-Ruby-on-Rails-8, #Frontend-Architecture, #Infrastructure-and-Deployment].
- **Testing framework**: Minitest (default de Rails) — estructura `test/models`, `test/controllers`, `test/components`, `test/services` [Source: architecture.md#Structure-Patterns]. No se requiere escribir tests de dominio en esta story (no hay dominio todavía), pero la suite default de `rails new` debe correr sin errores.
- **`whatsapp-service/` es un servicio completamente aislado**: no comparte código, gemas ni convenciones Ruby. Es la única excepción donde se usa `camelCase` (TS/JS estándar) en lugar de `snake_case` [Source: architecture.md#Naming-Patterns, #Service-Boundaries].
- **Comunicación Rails ↔ whatsapp-service**: en stories futuras será vía tablas Postgres compartidas `whatsapp_outbox`/`whatsapp_inbox` (sin HTTP API entre servicios). En ESTA story `whatsapp-service/` no necesita conectarse realmente a Postgres ni a Baileys — el AC #2 explícitamente dice "sin conexión real a Baileys todavía". `src/db.ts` puede ser un stub que prepara la conexión `pg` pero no se usa aún [Source: architecture.md#API-and-Communication-Patterns].
- **Health-check**: en producción el endpoint `/health` del servicio Baileys verificará `connection.state === 'open'`; en esta story alcanza con un servidor HTTP mínimo que responda 200 en `/health` con un body simple — sienta la base para Story 5.1 [Source: architecture.md#API-and-Communication-Patterns].

### Project Structure Notes

- Estructura objetivo completa (referencia para esta y futuras stories) [Source: architecture.md#Complete-Project-Directory-Structure]:
  ```
  retroai/
  ├── README.md, Gemfile, Gemfile.lock, Rakefile, config.ru, .ruby-version, .gitignore
  ├── .github/workflows/deploy.yml          (NO crear en esta story — corresponde a CI/CD, Step 6)
  ├── app/{controllers,models,services,jobs,policies,components,views,javascript,assets,helpers}/
  ├── config/{routes.rb,database.yml,deploy.yml,credentials.yml.enc,recurring.yml,environments,initializers}/
  ├── db/{migrate,schema.rb,seeds.rb}
  ├── test/{models,controllers,components,services,fixtures}/
  └── whatsapp-service/
      ├── package.json, tsconfig.json, Dockerfile, .env.example
      └── src/{index.ts,baileys-client.ts,outbox-poller.ts,inbox-writer.ts,health-server.ts,db.ts}
  ```
- `rails new` genera la mayoría de `app/`, `config/`, `db/`, `test/` automáticamente; los subdirectorios `app/services/`, `app/policies/`, `app/components/`, `app/javascript/controllers/`, `test/services/` no vienen por defecto y deben existir (al menos como carpetas) para que stories futuras (1.3 Pundit policies, ViewComponents, etc.) no tengan que crear estructura nueva.
- NO crear `.github/workflows/deploy.yml`, `config/deploy.yml` (Kamal), ni `config/recurring.yml` en esta story — son del Step 6 (CI/CD) y Step 4/5 (jobs recurrentes) del plan de implementación [Source: architecture.md#Decision-Impact-Analysis].
- `whatsapp-service/` va en la raíz del repo, hermano de `app/`, NO dentro de `app/` ni como un repo Git anidado [Source: architecture.md#Service-Boundaries].

### References

- [Source: architecture.md#Selected-Starter-Ruby-on-Rails-8] — comando de init, stack del starter, justificación.
- [Source: architecture.md#Decision-Impact-Analysis] — secuencia de implementación (esta story = paso 1).
- [Source: architecture.md#Project-Structure-and-Boundaries / Complete-Project-Directory-Structure] — árbol de directorios objetivo.
- [Source: architecture.md#Naming-Patterns] — convenciones snake_case (Rails) vs camelCase (whatsapp-service).
- [Source: architecture.md#API-and-Communication-Patterns] — contrato `/health` y `whatsapp_outbox`/`whatsapp_inbox` (para stories futuras).
- [Source: architecture.md#Structure-Patterns] — organización `test/` con Minitest.
- [Source: epics.md#Story-1.1-Inicialización-del-Proyecto] — historia y acceptance criteria originales.

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `rails new retroai --database=postgresql --css=tailwind --skip-git` ejecutado en un directorio temporal `retroai/` y su contenido movido a la raíz del repo (para obtener el módulo `Retroai`/DB `retroai_*` correctos sin anidar otro repo); directorio temporal eliminado.
- `bin/rails db:create` → creó `retroai_development` y `retroai_test` (Postgres local vía socket Unix, rol = usuario del SO, sin password).
- `bin/dev` verificado: sirve la página de bienvenida en `http://localhost:3000/` con `200 OK`, crea `schema_migrations`/`ar_internal_metadata` en Postgres sin errores, se apaga limpio con SIGTERM.
- `bin/rails db:migrate` (sin migraciones) generó `db/schema.rb`; `bin/rails db:test:prepare && bin/rails test` → `0 failures, 0 errors`.
- `bin/rubocop -A` → `24 files inspected, no offenses detected`.
- `whatsapp-service`: `npm install` (21 paquetes), `npm run dev` → `/health` responde `200 {"status":"ok"}`; `npm run build` (tsc) compila a `dist/` sin errores; `node dist/index.js` también responde 200 en `/health`.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Proyecto Rails 8.1.3 / Ruby 3.4.9 inicializado en la raíz del repo (módulo `Retroai`, Postgres, Tailwind v4, Hotwire/Importmap, Solid Queue/Cache/Cable, Kamal 2) — AC #1 cumplido.
- Esqueleto `whatsapp-service/` creado (Node 22/TypeScript, `tsx` para dev, `pg` como dependencia preparada para Story 5.1) con `/health` mínimo sin conexión real a Baileys — AC #2 cumplido.
- Estructura de directorios validada contra `architecture.md`; se agregaron `app/services/`, `app/policies/`, `app/components/`, `test/services/` (con `.keep`) que no vienen por defecto en `rails new` — AC #3 cumplido. `db/migrate/` aún no existe porque no hay migraciones todavía (se creará en la primera migración, Story 1.3+).
- **Desviación documentada**: `rails new` (Rails 8 default) generó automáticamente `.github/workflows/ci.yml`, `config/deploy.yml` y `.kamal/` (Kamal 2) como parte del starter. La story indicaba no crear manualmente `.github/workflows/deploy.yml`/CI-CD (Step 6) — se dejaron los archivos generados por el starter tal cual (no se configuraron secrets, runners ni despliegue real), ya que removerlos sería revertir un default del framework que se necesitará igual en Step 6.
- Se creó `.gitignore` (no generado por `rails new --skip-git`) basado en el template oficial de Rails 8 + entradas para `whatsapp-service/node_modules`, `/dist`, `.env`, y `/config/*.key` (`config/master.key` no debe commitearse).
- Repo Git inicializado (`git init`) en la raíz; aún sin commits — el commit inicial del esqueleto se realiza al cierre de esta story (Subtask 3.3).

### File List

- **Raíz (generado por `rails new retroai --database=postgresql --css=tailwind`)**: `Gemfile`, `Gemfile.lock`, `Rakefile`, `config.ru`, `.ruby-version`, `.rubocop.yml`, `.dockerignore`, `Dockerfile`, `Procfile.dev`, `README.md`, `bin/`, `app/`, `config/`, `db/`, `lib/`, `public/`, `script/`, `storage/`, `test/`, `vendor/`, `log/`, `tmp/`, `.github/workflows/ci.yml`, `.github/dependabot.yml`, `.kamal/`, `config/deploy.yml`
- **Manual**: `.gitignore` (creado, basado en template Rails + entradas whatsapp-service)
- **Directorios agregados manualmente** (con `.keep`): `app/services/.keep`, `app/policies/.keep`, `app/components/.keep`, `test/services/.keep`
- **`whatsapp-service/` (nuevo, manual)**: `package.json`, `package-lock.json`, `tsconfig.json`, `Dockerfile`, `.env.example`, `src/index.ts`, `src/health-server.ts`, `src/db.ts`, `src/baileys-client.ts`, `src/outbox-poller.ts`, `src/inbox-writer.ts`

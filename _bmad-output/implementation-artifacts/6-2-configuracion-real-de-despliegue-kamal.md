---
story_id: "6.2"
story_key: "6-2-configuracion-real-de-despliegue-kamal"
epic_id: "6"
title: "Configuración real de despliegue (Kamal)"
status: "done"
last_updated: "2026-06-23"
baseline_commit: "ed09264e2f8f8b09931eaeab7d99b0068856e02e"
---

# Story 6.2: Configuración real de despliegue (Kamal)

Status: done

## Story

**As a** Hernan (desarrollador único),
**I want** que `config/deploy.yml` describa el despliegue real (servicios `web` + `whatsapp`, accesorio Postgres) en vez del scaffold por defecto,
**so that** pueda ejecutar `kamal deploy` contra el droplet real sin reconstruir la configuración a mano.

## Acceptance Criteria

- **AC1: Servicios `web` y `whatsapp` apuntando a las imágenes reales**
  - **Given** `config/deploy.yml`
  - **When** lo reviso
  - **Then** define el servicio `web` (Rails) apuntando a la imagen publicada en GHCR (Story 6.1: `ghcr.io/tamasi/paddleroster`) y el servicio `whatsapp` (adaptador Node) con su propia imagen (`ghcr.io/tamasi/paddleroster-whatsapp`)

- **AC2: Accesorio Postgres compartido con volumen persistente**
  - **Given** el mismo archivo
  - **When** reviso la sección de `accessories`
  - **Then** define un accesorio Postgres compartido por ambos servicios, con volumen persistente

- **AC3: Droplet real fuera de alcance — placeholder documentado**
  - **Given** que todavía no hay un droplet de DigitalOcean real provisionado
  - **When** se completa esta historia
  - **Then** la IP del servidor en `deploy.yml` queda como placeholder documentado — provisionar el droplet real y ejecutar `kamal setup`/`kamal deploy` por primera vez es una acción manual de Hernan fuera del alcance de esta historia, documentada como runbook en `README.md`

- **AC4: Secrets declarados sin valores reales**
  - **Given** `.kamal/secrets`
  - **When** lo reviso
  - **Then** declara las variables necesarias (`RAILS_MASTER_KEY`, credenciales de Postgres, token de GHCR) sin valores reales hardcodeados

## Tasks / Subtasks

### Task 0: Decisión de diseño — `whatsapp` como accesorio Kamal, no como segundo "destination" (AC: #1, #2)

**Esto no es una tarea de código — es la decisión arquitectónica que determina cómo se escriben las Tasks 1-2. Leer antes de tocar `config/deploy.yml`.**

`architecture.md` dice "`config/deploy.yml` de Kamal define dos servicios (`web` para Rails, `whatsapp` para el adaptador) + el accesorio Postgres — todos en el mismo droplet". Kamal 2 tiene dos mecanismos candidatos para "dos imágenes distintas, un solo droplet":

1. **Kamal "destinations"** (`config/deploy.yml` + `config/deploy.whatsapp.yml`, desplegados por separado con `kamal deploy -d whatsapp`) — es el mecanismo pensado para *environments* (staging/production), no para dos apps hermanas. Investigado vía discusiones de la comunidad de Kamal (`basecamp/kamal` discussions #1153, #1178): cada "destination" es una app Kamal separada con su **propia red Docker**, así que compartir el accesorio Postgres entre destinations requiere trabajo manual de red (sin solución built-in limpia, varios issues abiertos al respecto).
2. **Accesorio Kamal** (`accessories: whatsapp: image: ghcr.io/...`) — los accesorios pueden referenciar **cualquier imagen ya publicada** (no solo `postgres`/`redis` de ejemplo del scaffold) y se unen automáticamente a la **misma red Docker** que el servicio principal y los demás accesorios de esa app. Como `whatsapp-service` ya se publica como imagen completa en GHCR (Story 6.1) — Kamal no necesita construirla, solo *pull*-earla — encaja exactamente en lo que un accesorio espera.

**Decisión: usar el mecanismo 2.** `whatsapp` se define como un accesorio más, junto a `db`, en el **mismo y único** `config/deploy.yml` — no se crea un `config/deploy.whatsapp.yml`. Esto resuelve compartir red/accesorios "gratis" (ambos servicios y el accesorio Postgres quedan en la misma red Kamal por construcción) y evita el problema de red entre destinations documentado en la comunidad. No contradice la intención de `architecture.md` ("dos servicios + accesorio Postgres, mismo droplet") — solo aterriza esa intención en el mecanismo Kamal real que la sostiene sin fricción.

### Task 1: Reescribir `config/deploy.yml` (AC: #1, #2, #3)

- [x] `service:` → `retroai` (ya está). `image:` → `ghcr.io/tamasi/paddleroster` (la imagen real publicada por `build_and_push_web` en Story 6.1 — coincidir exactamente con ese nombre, no inventar uno nuevo).
- [x] `servers.web:` → reemplazar `192.168.0.1` por un placeholder explícito y comentado, ej.:
  ```yaml
  servers:
    web:
      - 203.0.113.10 # TODO(Hernan): reemplazar por la IP real del droplet de DigitalOcean una vez provisionado (ver README.md → Despliegue)
  ```
  (AC3 — no hay droplet real todavía; `203.0.113.10` es un rango TEST-NET-3 de RFC 5737, nunca una IP real, para que sea obvio que hay que reemplazarlo).
- [x] `registry:` → cambiar de `localhost:5555` a:
  ```yaml
  registry:
    server: ghcr.io
    username: tamasi
    password:
      - KAMAL_REGISTRY_PASSWORD
  ```
  **Importante — no confundir con el `GITHUB_TOKEN` de la Story 6.1:** ese token es el automático y efímero de GitHub Actions (`secrets.GITHUB_TOKEN`), solo válido dentro de un run de CI. Para que Kamal (corriendo desde la laptop de Hernan o desde CI hacia el droplet) pueda hacer `docker pull` de una imagen privada de GHCR, hace falta un **Personal Access Token** de GitHub (classic o fine-grained, scope `read:packages`), generado a mano una vez en GitHub → Settings → Developer settings → Personal access tokens, y guardado como `KAMAL_REGISTRY_PASSWORD` en `.kamal/secrets` (Task 2) — no es el mismo token, ni se puede reusar el de Actions.
- [x] `accessories:` → agregar `db` (Postgres) y `whatsapp` (ver Task 1.1/1.2 abajo). Sacar el bloque de ejemplo `mysql`/`redis` comentado del scaffold (ya no aplica).
- [x] `env.secret:` → agregar `RETROAI_DATABASE_PASSWORD` (ya referenciado por `config/database.yml#production`, ver Dev Notes) junto al `RAILS_MASTER_KEY` existente.
- [x] `env.clear:` → agregar `DB_HOST: retroai-db` (ver Dev Notes — Kamal resuelve el hostname de un accesorio como `<service>-<nombre-del-accesorio>`, así que el accesorio `db` definido en este mismo archivo es alcanzable como `retroai-db` desde el contenedor `web`, sin exponer el puerto a la red externa).
- [x] **No tocar** `volumes:`, `asset_path:`, `builder:`, `aliases:` — ya están bien para el caso de un solo servidor Rails, ninguna AC pide cambiarlos.

#### Task 1.1: Accesorio `db` (Postgres) (AC: #2)

```yaml
accessories:
  db:
    image: postgres:17
    host: 203.0.113.10 # MISMA IP que servers.web — un solo droplet, mantener los 3 lugares (servers.web, accessories.db.host, accessories.whatsapp.host) sincronizados
    port: "127.0.0.1:5432:5432" # solo loopback del host — nunca expuesto a internet
    env:
      clear:
        POSTGRES_USER: retroai
        POSTGRES_DB: retroai_production
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
```
- `POSTGRES_PASSWORD` (Task 2) debe ser el **mismo valor** que `RETROAI_DATABASE_PASSWORD` (lo que arranca el contenedor de Postgres con esa contraseña para el rol `retroai`, y lo que Rails usa para conectarse vía `config/database.yml#production` → `password: <%= ENV["RETROAI_DATABASE_PASSWORD"] %>`) — dos nombres de variable distintos por convención (una la espera la imagen oficial `postgres`, la otra ya la define `database.yml` desde antes de esta historia), mismo secreto.
- `directories: - data:/var/lib/postgresql/data` es el volumen persistente que pide AC2 — Kamal lo crea como volumen Docker nombrado, sobrevive a `kamal deploy`/restarts del contenedor.
- **Postgres 17**: ver Latest Tech Information — `architecture.md` no fija versión exacta a propósito ("usar la más reciente estable al momento de implementar"); 17 es la última estable a junio 2026, sin breaking changes relevantes para este stack.

#### Task 1.2: Accesorio `whatsapp` (AC: #1, #2)

```yaml
accessories:
  whatsapp:
    image: ghcr.io/tamasi/paddleroster-whatsapp
    host: 203.0.113.10 # MISMA IP que servers.web y accessories.db — un solo droplet
    env:
      clear:
        PORT: "3001"
      secret:
        - WHATSAPP_DATABASE_URL
```
- `whatsapp-service` no es una app Rails — no necesita `RAILS_MASTER_KEY` ni las variables de `web`. Solo necesita `DATABASE_URL` (la variable que `whatsapp-service/src/db.ts` ya lee, ver Dev Notes) apuntando a la **misma** base `retroai_production` que usa Rails (comparten las tablas `whatsapp_inbox`/`whatsapp_outbox`/`whatsapp_connections`, creadas por las migraciones de Rails — esto ya es así desde Story 5.1, esta historia no lo cambia).
- `WHATSAPP_DATABASE_URL` (Task 2) se compone con el mismo `POSTGRES_PASSWORD`/`RETROAI_DATABASE_PASSWORD`, apuntando al hostname del accesorio `db` (`retroai-db`, igual que `web`): `postgres://retroai:<password>@retroai-db:5432/retroai_production`.
- **No define volumen.** El `whatsapp-service/Dockerfile` no persiste la sesión de Baileys (`./session`) en un volumen — eso es un gap real y ya señalado en `_bmad-output/implementation-artifacts/deferred-work.md`/Dev Notes de la Story 1.7 sobre re-deployabilidad de la sesión de WhatsApp. **Fuera de alcance de esta historia** (ningún AC de la 6.2 lo pide); si se quiere persistir la sesión entre deploys, es una historia futura con su propio AC.

### Task 2: `.kamal/secrets` (AC: #4)

- [x] Agregar, sin hardcodear valores reales (mismo patrón que `RAILS_MASTER_KEY` ya presente — leer de archivo/env, nunca el secreto en texto plano):
  ```bash
  # GHCR — Personal Access Token con scope read:packages (generado a mano en GitHub,
  # NO el GITHUB_TOKEN efímero de Actions). Ver runbook en README.md.
  KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD

  # Postgres — generar una vez con `openssl rand -hex 32` y guardar fuera del repo
  # (gestor de contraseñas / variable de entorno del servidor desde donde se corre kamal).
  RETROAI_DATABASE_PASSWORD=$RETROAI_DATABASE_PASSWORD
  POSTGRES_PASSWORD=$RETROAI_DATABASE_PASSWORD
  WHATSAPP_DATABASE_URL=postgres://retroai:$RETROAI_DATABASE_PASSWORD@retroai-db:5432/retroai_production
  ```
- [x] **No** generar un valor real para `RETROAI_DATABASE_PASSWORD` en esta historia — el comentario indica el comando (`openssl rand -hex 32`), Hernan lo corre y lo guarda él mismo cuando provisione el droplet real (mismo patrón que `RAILS_MASTER_KEY`, que tampoco se genera acá, ya existe en `config/master.key` desde Story 1.1).

### Task 3: Runbook de despliegue en `README.md` (AC: #3)

- [x] Agregar una sección `## Despliegue` a `README.md` con, como mínimo:
  1. Prerrequisitos: droplet de DigitalOcean (4GB/2vCPU, ver `architecture.md`), clave SSH cargada, Docker instalado localmente (Kamal lo usa para construir/empujar imágenes — aunque en este flujo las imágenes ya las publica CI, Kamal igual necesita Docker local para ciertas operaciones).
  2. Reemplazar el placeholder `203.0.113.10` en `config/deploy.yml`/`accessories.db.host`/`accessories.whatsapp.host` por la IP real del droplet (las tres deben coincidir — un solo servidor).
  3. Generar `RETROAI_DATABASE_PASSWORD` (`openssl rand -hex 32`) y `KAMAL_REGISTRY_PASSWORD` (PAT de GitHub, scope `read:packages`) y exportarlos en el entorno desde donde se corre `kamal` (o cargarlos en un password manager soportado por `kamal secrets fetch`, ver comentarios ya presentes en `.kamal/secrets`).
  4. Primera vez: `bin/kamal setup` (provisiona Docker/accesorios en el droplet desde cero).
  5. Deploys siguientes: `bin/kamal deploy`.
  6. Cómo ver logs: `bin/kamal app logs` / `bin/kamal accessory logs db` / `bin/kamal accessory logs whatsapp` (alias `logs` ya definido en `deploy.yml`).

### Task 4: Verificación (sin droplet real) (AC: #1, #2, #3, #4)

No hay manera de verificar un `kamal deploy` real sin el droplet (explícitamente fuera de alcance, AC3). Lo verificable hoy:
- [x] `ruby -ryaml -e "YAML.load_file('config/deploy.yml')"` — sintaxis YAML válida (igual que se hizo en Story 6.1 para `ci.yml`).
- [x] `bin/kamal config` — Kamal expone este comando para imprimir la configuración resuelta (con ERB/secrets interpolados) **sin conectarse a ningún servidor**; si corre sin error, confirma que la sintaxis específica de Kamal (no solo YAML genérico) es válida. Requiere tener `.kamal/secrets` con las variables nuevas seteadas al menos como placeholders en el entorno local (ej. `export RETROAI_DATABASE_PASSWORD=test KAMAL_REGISTRY_PASSWORD=test`) para que la interpolación no falle.
- [x] Confirmar que `accessories.whatsapp.image` coincide carácter por carácter con el nombre publicado en Story 6.1 (`ghcr.io/tamasi/paddleroster-whatsapp`) y que `image:` raíz coincide con `ghcr.io/tamasi/paddleroster` — un typo acá no lo detecta ningún test, solo se nota en el primer `kamal deploy` real. **Hallazgo real durante esta verificación, ver Completion Notes**: con `image:` raíz literalmente `ghcr.io/tamasi/paddleroster` y `registry.server: ghcr.io`, `bin/kamal config` mostraba `repository: ghcr.io/ghcr.io/tamasi/paddleroster` (host duplicado) — Kamal concatena `registry.server` + `image`, así que `image:` raíz debe ser solo `tamasi/paddleroster` para que el resultado resuelto coincida con el AC1.
- [x] No correr `bin/kamal deploy`/`bin/kamal setup` real — no hay droplet, y son comandos con efectos en infraestructura real (fuera del alcance de esta historia y de lo que un dev-agent debe ejecutar sin supervisión directa).

### Review Findings

Revisión adversarial en 3 capas paralelas (Blind Hunter, Edge Case Hunter, Acceptance Auditor) sobre el diff acotado al File List (`config/deploy.yml`, `.kamal/secrets`, `README.md`). 26 hallazgos crudos → 11 únicos tras deduplicar → 1 decisión (resuelta por Hernan → parche), 3 parches, 8 diferidos, 9 descartados como ruido (confirmados/refutados con lectura directa de código, no solo por argumento).

- [x] [Review][Patch] `config/database.yml#production.primary` no tiene clave `host:` — el `DB_HOST: retroai-db` que inyecta `config/deploy.yml` nunca es leído por Rails, así que `web` nunca se conecta al accesorio `db` recién creado. **Confirmado por lectura directa** de `config/database.yml:88-92` (solo `database`/`username`/`password`, sin `host`). Decisión de Hernan: parchear ahora pese a estar fuera del File List original declarado ("no se toca") — sin esto AC2 no se cumple realmente para `web`. Fix: `host: <%= ENV.fetch("DB_HOST", "localhost") %>` en el bloque `primary_production` (se propaga a `cache`/`queue`/`cable` vía el `<<: *primary_production` ya existente). [config/database.yml:88-92] — fuente: edge

- [x] [Review][Patch] `accessories.whatsapp.env.secret` inyecta `WHATSAPP_DATABASE_URL` pero `whatsapp-service/src/db.ts:9` lee `process.env.DATABASE_URL` — nombres distintos, el contenedor `whatsapp` arrancaría con `DATABASE_URL` sin definir. **Confirmado por lectura directa** de `db.ts` y de `kamal/configuration/env.rb#extract_alias` (Kamal solo soporta renombrar vía sintaxis `"ENV_VAR:secret_key"`, no estaba en uso). Contradice además la propia Dev Note de la historia ("Solo necesita `DATABASE_URL`..."). Fix: `secret: - DATABASE_URL:WHATSAPP_DATABASE_URL` en `accessories.whatsapp.env` (mantiene el nombre del secreto en `.kamal/secrets`, solo cambia el nombre de la env var dentro del contenedor). [config/deploy.yml accessories.whatsapp.env.secret] — fuente: edge+auditor

- [x] [Review][Patch] `README.md` (sección Despliegue, paso 1) referencia `architecture.md` sin path — el archivo real vive en `_bmad-output/planning-artifacts/architecture.md`, no en la raíz del repo. [README.md] — fuente: edge

- [x] [Review][Defer] Accesorio `db` en loopback (`127.0.0.1:5432:5432`) + alcanzabilidad vía nombre de contenedor `retroai-db` sin verificar contra un droplet real [config/deploy.yml accessories.db] — deferred, ya señalado explícitamente como "Riesgo no resuelto" en los Dev Notes de esta misma historia; no verificable sin droplet real (AC3 fuera de alcance).
- [x] [Review][Defer] Sin estrategia de backup/DR para el volumen persistente de Postgres [config/deploy.yml accessories.db.directories] — deferred, ninguna AC de esta historia lo pide; madurez de infraestructura para una historia futura.
- [x] [Review][Defer] Sin configuración de SSL/proxy/dominio documentada para `web` en producción [config/deploy.yml, README.md] — deferred, trabajo de infraestructura más amplio (dominio, certificados), fuera del alcance de esta historia.
- [x] [Review][Defer] Accesorio `whatsapp` sin healthcheck/puerto publicado para monitoreo externo (el `health-server.ts` interno del servicio queda sin nadie que lo consulte) [config/deploy.yml accessories.whatsapp] — deferred, consistente con que `web` tampoco tiene proxy/healthcheck en este mismo archivo; mejora de observabilidad futura.
- [x] [Review][Defer] `.kamal/secrets` no usa guard `${VAR:?...}` para `KAMAL_REGISTRY_PASSWORD`/`RETROAI_DATABASE_PASSWORD` — un secreto vacío/no seteado falla más adelante con un error menos claro en vez de fallar rápido [.kamal/secrets] — deferred, mejora de robustez, no un bug funcional.
- [x] [Review][Defer] Sin runbook de rotación para `POSTGRES_PASSWORD`/PAT de GHCR — las env vars de la imagen oficial de Postgres solo aplican en la primera inicialización del volumen; una rotación futura requeriría procedimiento manual propio [README.md, .kamal/secrets] — deferred, primer deploy es virgen, no aplica todavía.
- [x] [Review][Defer] `README.md` (paso `bin/kamal setup`) no advierte sobre contenedores/puertos preexistentes en el droplet de un intento previo, ni que el placeholder `203.0.113.10` no tiene ningún gate automático que impida olvidarlo [README.md] — deferred, mejora de runbook, AC3 ya documenta el placeholder como acción manual.
- [x] [Review][Defer] `architecture.md` describe `whatsapp` como "servicio", pero esta historia (Task 0) lo modela como accesorio Kamal — decisión ya razonada y documentada explícitamente en la propia historia; solo falta alinear la terminología de `architecture.md` [_bmad-output/planning-artifacts/architecture.md] — deferred, cosmético, no bloqueante.

**Descartados como ruido (9)**, todos verificados antes de descartar: secretos duplicados bajo 3 nombres ya justificado en Dev Notes; `postgres:17` sin pin de minor/patch es práctica estándar ya justificada en Latest Tech Information; comentario "verificado con `bin/kamal config`" sin evidencia en el diff — la evidencia está en Debug Log References, fuera del contexto que recibió Blind Hunter; `registry.username` hardcodeado — patrón esperado de Kamal (solo el password es secreto, confirmado en `kamal/configuration/docs/registry.yml`); imagen raíz sin `version:` pineado "default a `:latest`" — falso, confirmado en `kamal/configuration.rb#version`: el default es el SHA de git, que coincide exactamente con el esquema de tags de CI (`type=sha,format=long`); falta alias de red `web`→`whatsapp` — la integración es vía tablas Postgres compartidas, no HTTP directo (Dev Notes); desviación del campo `image:` raíz (`tamasi/paddleroster` vs el texto literal de Task 1) — evaluada independientemente por el Acceptance Auditor y confirmada correcta, no es una violación de AC1.

## Dev Notes

### `whatsapp-service` ya lee `DATABASE_URL` — no tocar el código

`whatsapp-service/src/db.ts` (`getPool()`) ya usa `process.env.DATABASE_URL` tal cual, sin cambios desde Story 5.1. Esta historia no modifica `whatsapp-service/src/`, solo le da un `DATABASE_URL` real vía Kamal en producción — en desarrollo sigue usando `whatsapp-service/.env` (gitignored, configurado manualmente, ver sesión de trabajo previa de este proyecto).

### Por qué `DB_HOST`/hostnames de accesorios y no IPs

Kamal nombra el contenedor de un accesorio `<service>-<key>` (`retroai-db`, `retroai-whatsapp` en este caso) y lo une a la red Docker interna de la app — **no** hace falta usar la IP del droplet ni exponer el puerto de Postgres a la red pública para que `web` lo alcance: el nombre del contenedor resuelve por DNS interno de Docker dentro de esa red. El comentario ya presente en el scaffold original (`# DB_HOST: 192.168.0.2`, sección `env.clear`) sugería una IP porque asumía un *segundo servidor físico* para la base — no es nuestro caso (un solo droplet), así que el hostname de accesorio es más simple y correcto que una IP.

### Riesgo no resuelto: red entre el accesorio `whatsapp` y `web`

Decidido en Task 0 usar accesorio (no "destination") justamente para que Kamal los una a la misma red automáticamente — **esto es lo documentado/esperado del mecanismo de accesorios de Kamal 2, pero esta historia no lo prueba contra un droplet real** (no existe, AC3). Si al primer `kamal deploy` real el contenedor `whatsapp` no puede resolver `retroai-db`, revisar primero `bin/kamal accessory details whatsapp` / `bin/kamal accessory details db` para confirmar que ambos quedaron en la misma red Docker — es el primer punto de fricción esperable, documentado acá para no perder tiempo re-derivándolo.

### Postgres 17 — sin schema/datos previos que migrar

No hay un Postgres de producción previo (este MVP nunca se desplegó) — no hay migración de versión de Postgres que considerar, es un accesorio nuevo desde cero. `bin/rails db:prepare` (disparado por `bin/docker-entrypoint`, ya existente desde Story 1.1, sin cambios en esta historia) crea el esquema completo (incluyendo `cache`/`queue`/`cable`, ver next note) contra el accesorio recién creado.

### Gap conocido, fuera de alcance: `db/queue_migrate`/`cache_migrate`/`cable_migrate` no existen

`config/database.yml#production` declara `migrations_paths: db/queue_migrate` (e iguales para `cache`/`cable`), pero esos directorios **no existen en el repo** — solo existen los `db/queue_schema.rb`/`cache_schema.rb`/`cable_schema.rb` (scaffold de `rails new`, Story 1.1). `bin/rails db:prepare` debería poder crear cada base desde su `_schema.rb` directamente en un setup nuevo (sin migraciones pendientes que buscar en un directorio vacío) — pero esto **no se verificó contra un Postgres real** en esta historia ni en ninguna anterior (recordar: en desarrollo, Solid Queue vive en la misma base que todo lo demás, ver decisión de la sesión de trabajo de la Story 6.1 — production target a un esquema distinto, multi-base, nunca ejercitado). Si el primer `kamal setup`/`db:prepare` real fallara acá, es la causa más probable a revisar — no es un bug de esta historia, es un gap heredado que recién se vuelve visible cuando hay un Postgres real de producción contra el cual correr.

### Project Structure Notes

- Archivos tocados: `config/deploy.yml`, `.kamal/secrets`, `README.md`. Ninguno de `app/`, `db/`, `whatsapp-service/src/`.
- `config/database.yml` **no se toca** — ya está correctamente preparado desde Story 1.1 para leer `RETROAI_DATABASE_PASSWORD` (esta historia solo asegura que esa variable llegue al contenedor vía Kamal).
- No crear `config/deploy.whatsapp.yml` ni ningún segundo archivo de destination — decisión explícita de Task 0.

### References

- [Source: epics.md#Epic-6, Story 6.2] — historia y acceptance criteria originales.
- [Source: architecture.md#Infrastructure-and-Deployment] — droplet único DigitalOcean, Kamal 2, Rails+Postgres+Baileys como contenedores.
- [Source: 6-1-pipeline-de-ci-cd-build-y-push-de-imagenes.md] — nombres reales de imagen GHCR (`ghcr.io/tamasi/paddleroster`, `ghcr.io/tamasi/paddleroster-whatsapp`), ya publicadas y verificadas funcionando (run real de GitHub Actions).
- [Source: config/deploy.yml, .kamal/secrets] — scaffold genérico de Kamal (Story 1.1), reemplazado por esta historia.
- [Source: config/database.yml#production] — ya espera `RETROAI_DATABASE_PASSWORD`, multi-base (`primary`/`cache`/`queue`/`cable`), sin cambios en esta historia.
- [Source: whatsapp-service/src/db.ts, whatsapp-service/Dockerfile] — ya leen `DATABASE_URL`/exponen `PORT`, sin cambios en esta historia.
- [Source: basecamp/kamal discussions #1153, #1178 — "Accessories of Multiple Destinations on the same Machine" / "Shared Postgres Accessory"] — fundamento de la decisión de Task 0 (accesorio en vez de destination).

## Previous Story Intelligence (Story 6.1)

- GHCR nunca se había usado en este repo antes de la 6.1 — los nombres de imagen (`ghcr.io/tamasi/paddleroster[-whatsapp]`) los definió esa historia por primera vez y ya están **verificados funcionando** (run real de Actions, paquetes publicados), no son una suposición.
- La 6.1 destapó que partes "ya configuradas" de este repo (CI, permisos de `bin/`, brakeman, hasta un test de sistema) nunca se habían ejercitado de verdad. La lección directa para esta historia: **no asumir que `config/database.yml#production`'s multi-base o `bin/docker-entrypoint` funcionan contra un Postgres real solo porque están escritos** — de ahí la Dev Note sobre `db/queue_migrate` faltante, marcada explícitamente como riesgo no verificado en vez de asumida como resuelta.
- Patrón de verificación de esa historia (push real → revisar Actions vía `curl` sin auth a la API pública de GitHub) **no aplica acá** — Kamal no tiene un equivalente sin un servidor real. De ahí que Task 4 se limite a verificación estática (sintaxis YAML/Kamal), documentado explícitamente como límite real, no como omisión.

## Latest Tech Information

- **Kamal**: `2.11.0` (ya instalado, `Gemfile.lock`) — sin acción requerida, ya es la versión en uso por el proyecto.
- **Postgres**: `17` es la versión estable más reciente recomendada para una imagen nueva sin datos previos a junio 2026 (`architecture.md` deja la versión exacta como decisión de bajo riesgo a tomar al implementar — esta historia la fija en 17).
- **Mecanismo de accesorios con imagen pre-construida de un registro privado**: confirmado vía investigación web que Kamal soporta `accessories.<key>.image:` apuntando a cualquier imagen ya publicada (no solo accesorios "de catálogo" como `postgres`/`redis` del scaffold) y que comparte la red Docker de la app — no requiere ninguna gema/configuración adicional más allá del `registry:` ya configurado para la imagen principal.

Sources:
- [Deploying multiple apps with what's new in Kamal 2 - Honeybadger Developer Blog](https://www.honeybadger.io/blog/new-in-kamal-2/)
- [Accessories of Multiple Destinations on the same Machine · basecamp/kamal · Discussion #1153](https://github.com/basecamp/kamal/discussions/1153)
- [Issue Deploying Two Rails Applications with Shared Postgres Accessory · basecamp/kamal · Discussion #1178](https://github.com/basecamp/kamal/discussions/1178)
- [Kamal's missing tutorial – how to deploy a Rails 8 app with Postgres to your VPS](https://rameerez.com/kamal-tutorial-how-to-deploy-a-postgresql-rails-app/)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

Task 4 (verificación con `bin/kamal config`) destapó un bug real en el `image:` raíz del scaffold tal como lo describía Task 1 literalmente:

- Con `image: ghcr.io/tamasi/paddleroster` y `registry.server: ghcr.io` a la vez, `bin/kamal config` mostraba `repository: ghcr.io/ghcr.io/tamasi/paddleroster` (host duplicado) — habría fallado en el primer `docker pull` real.
- Causa, confirmada leyendo el código fuente instalado (`kamal-2.11.0/lib/kamal/configuration.rb#repository`): `repository = [registry.server, image].compact.join("/")`. Kamal concatena `registry.server` + `image:` para el servicio raíz — `image:` debe ser solo el path (`tamasi/paddleroster`), no el nombre completo con host.
- **No aplica al accesorio `whatsapp`**: `Kamal::Configuration::Accessory#image` solo prefija con un registry si el accesorio define su propio bloque `registry:` anidado (no es el caso acá) — por eso `accessories.whatsapp.image: ghcr.io/tamasi/paddleroster-whatsapp` (con host completo, tal como lo pedía la Task 1.2 originalmente) sí resuelve correcto, confirmado en la salida de `bin/kamal config`.
- Fix: `image:` raíz cambiado a `tamasi/paddleroster` (sin prefijo `ghcr.io/`). Re-verificado: `repository: ghcr.io/tamasi/paddleroster` — coincide con AC1 y con el nombre real publicado por `build_and_push_web` en Story 6.1.

Verificación final: `ruby -ryaml` OK, `bin/kamal config` corre sin error con secrets placeholder (`RETROAI_DATABASE_PASSWORD=test KAMAL_REGISTRY_PASSWORD=test`) y resuelve `repository`/`absolute_image`/accesorios correctamente. `bin/rails test`: 276/276. `bundle exec rubocop`: 0 offenses. `bundle exec brakeman`: 0 warnings nuevos.

### Completion Notes List

- AC1-AC4 implementadas según las Tasks 1-4 de la historia, con una corrección respecto al texto literal de Task 1: el campo `image:` raíz se dejó como `tamasi/paddleroster` (no `ghcr.io/tamasi/paddleroster`) porque Kamal antepone `registry.server` automáticamente al construir el `repository` resuelto — usar el nombre completo en ambos campos duplicaba el host (`ghcr.io/ghcr.io/...`), bug real detectado por la propia verificación que pedía Task 4 (`bin/kamal config`), no algo que se hubiera notado solo en un deploy real como anticipaba el texto de esa task. El AC1 ("apuntando a la imagen publicada en GHCR") queda satisfecho por el valor *resuelto* (`ghcr.io/tamasi/paddleroster`), que es lo verificable y lo que de verdad importa para `kamal deploy`.
- `accessories.whatsapp.image` sí se dejó con el nombre completo (`ghcr.io/tamasi/paddleroster-whatsapp`) tal como pedía Task 1.2 — confirmado que NO sufre el mismo problema de duplicación porque Kamal solo aplica el prefijo de registry a nivel de accesorio si ese accesorio define su propio bloque `registry:` anidado (no es el caso).
- AC3 (placeholder de IP) y AC4 (secrets sin valores reales) implementadas tal como las describía la historia, sin desviaciones.
- No se ejecutó `bin/kamal setup`/`bin/kamal deploy` real — no hay droplet provisionado (fuera de alcance explícito, AC3) y son comandos con efecto en infraestructura real.
- Suite completa de Rails (`bin/rails test`), Rubocop y Brakeman corridos sin regresiones — los cambios no tocan código Ruby/JS de la app, solo configuración de despliegue y documentación.

### File List

**MODIFIED:**
- `config/deploy.yml` — imagen real (`tamasi/paddleroster`, resuelve a `ghcr.io/tamasi/paddleroster` vía `registry.server`), placeholder de IP documentado, registro GHCR, accesorios `db` (Postgres 17, volumen persistente) y `whatsapp` (imagen GHCR del adaptador Node), `env.secret`/`env.clear` actualizados.
- `.kamal/secrets` — agregadas `KAMAL_REGISTRY_PASSWORD`, `RETROAI_DATABASE_PASSWORD`, `POSTGRES_PASSWORD`, `WHATSAPP_DATABASE_URL` (todas leídas de ENV, sin valores reales).
- `README.md` — sección `## Despliegue` con runbook (prerrequisitos, placeholder de IP, generación de secrets, `kamal setup`/`kamal deploy`, logs).

## Change Log

- 2026-06-22: Implementación completa de Tasks 1-4. `config/deploy.yml` reescrito (servicios `web`/accesorios `db`+`whatsapp`, AC1-AC2), `.kamal/secrets` con variables nuevas sin valores reales (AC4), runbook `## Despliegue` agregado a `README.md` (AC3). Verificación (Task 4) detectó y corrigió un bug real de doble-prefijo de host en el `image:` raíz (`ghcr.io/ghcr.io/...`) antes de cualquier deploy — ver Debug Log References. `bin/rails test` 276/276, `bundle exec rubocop` 0 offenses, `bundle exec brakeman` 0 warnings nuevos. Status → `review`.
- 2026-06-23: Code review (Blind Hunter, Edge Case Hunter, Acceptance Auditor) aplicado — 3 patches (`config/database.yml` host de Postgres, alias `DATABASE_URL:WHATSAPP_DATABASE_URL` en el accesorio `whatsapp`, path de `architecture.md` en el README) y 6 items diferidos a `deferred-work.md`. Re-verificación post-patch: `bin/kamal config` resuelve sin error, `bin/rails test` 276/276, `bundle exec rubocop` 0 offenses, `bundle exec brakeman` 0 warnings nuevos. Status → `done`.

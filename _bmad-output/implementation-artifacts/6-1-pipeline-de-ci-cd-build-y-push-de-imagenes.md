---
story_id: "6.1"
story_key: "6-1-pipeline-de-ci-cd-build-y-push-de-imagenes"
epic_id: "6"
title: "Pipeline de CI/CD — build y push de imágenes"
status: "done"
last_updated: "2026-06-19"
baseline_commit: "93b870a149e178cf009b3ce87c4bbc29ac8ae422"
---

# Story 6.1: Pipeline de CI/CD — build y push de imágenes

Status: done

## Story

**As a** Hernan (desarrollador único),
**I want** que el pipeline de CI construya y publique las imágenes Docker de Rails y de `whatsapp-service` tras pasar los tests,
**so that** pueda desplegar una versión validada sin armar las imágenes a mano.

## Acceptance Criteria

- **AC1: Build y push de la imagen Rails**
  - **Given** que un push a `master` pasa los jobs de test/lint/scan existentes (`scan_ruby`, `scan_js`, `lint`, `test`, `system-test`)
  - **When** el workflow de CI continúa
  - **Then** se construye la imagen Docker de la app Rails (usando el `Dockerfile` raíz, ya existente) y se publica en GHCR con un tag identificable (sha/branch)

- **AC2: Build y push de la imagen whatsapp-service**
  - **Given** el mismo push exitoso a `master`
  - **When** el pipeline procesa `whatsapp-service/`
  - **Then** se construye su imagen Docker (`whatsapp-service/Dockerfile`, ya existente) y se publica en GHCR con el mismo esquema de tags

- **AC3: Sin build/push en Pull Requests**
  - **Given** un Pull Request (no un push a `master`)
  - **When** corre el pipeline
  - **Then** se ejecutan tests/lint/scan como hoy, pero NO se construyen ni publican imágenes — el build/push solo ocurre en push a `master`

- **AC4: Build fallido no publica nada**
  - **Given** que el build de una imagen falla
  - **When** el job de build/push corre
  - **Then** el workflow termina en rojo y no se publica nada a GHCR (evita publicar imágenes rotas)

## Tasks / Subtasks

### Task 1: Arreglar el trigger de push (bloqueante para todo lo demás) (AC: #1, #2, #3, #4)

`.github/workflows/ci.yml` tiene hoy:
```yaml
on:
  pull_request:
  push:
    branches: [ main ]
```
La rama default real del repo es `master` (confirmado vía `git remote show origin` → `HEAD branch: master`), no `main`. Esto significa que **ningún job corre hoy en un push real** — ni los existentes (`scan_ruby`, `scan_js`, `lint`, `test`, `system-test`) ni los nuevos de esta historia — solo se disparan por `pull_request:`. Sin este fix, AC1/AC2 son imposibles de cumplir.

- [x] Cambiar `branches: [ main ]` → `branches: [ master ]` en el trigger `push:` de `.github/workflows/ci.yml`.

### Task 2: Job `build_and_push_web` — imagen Rails (AC: #1, #3, #4)

- [x] Agregar al final de `.github/workflows/ci.yml` un job nuevo que:
  - Depende de los 5 jobs existentes (`needs: [scan_ruby, scan_js, lint, test, system-test]`) — así AC1 ("pasa los jobs existentes... el workflow continúa") queda garantizado por el grafo de dependencias, no por convención.
  - Solo corre en push a `master`: `if: github.event_name == 'push' && github.ref == 'refs/heads/master'` (satisface AC3 — en un PR este `if` es falso, el job se skippea, no corre en absoluto).
  - Hace login a GHCR, construye con el `Dockerfile` raíz (ya existente, no tocar) y publica con `push: true`.

Ejemplo de implementación (ajustar nombres de imagen si se prefiere otra convención):
```yaml
  build_and_push_web:
    needs: [scan_ruby, scan_js, lint, test, system-test]
    if: github.event_name == 'push' && github.ref == 'refs/heads/master'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v4

      - name: Log in to GHCR
        uses: docker/login-action@v4
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata (tags)
        id: meta
        uses: docker/metadata-action@v6
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=sha,format=long
            type=ref,event=branch

      - name: Build and push web image
        uses: docker/build-push-action@v7
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```
AC4 ("build fallido no publica nada") es el comportamiento default de `docker/build-push-action`: si el `docker build` interno falla, el step termina en error antes de ejecutar el push — no requiere código adicional, solo no se debe partir `build` y `push` en dos steps separados que pudieran desincronizarse.

**Importante — interpretación de AC4 a nivel de job:** "no se publica nada" se refiere a la imagen *que falló*, no a ambas. `build_and_push_web` y `build_and_push_whatsapp` son jobs independientes (ninguno depende del otro) — si el build de `whatsapp-service` falla, la imagen de Rails se publica igual si su build fue exitoso, y viceversa. No agregar un `needs` entre ambos jobs para "bloquear todo si uno falla": eso no es lo que pide el AC ("evita publicar imágenes rotas", no "evita publicar cualquier imagen si algo más falló") y generaría acoplamiento innecesario entre dos servicios que la arquitectura mantiene deliberadamente aislados.

### Task 3: Job `build_and_push_whatsapp` — imagen del servicio Node (AC: #2, #3, #4)

- [x] Mismo patrón que Task 2, pero:
  - `context: ./whatsapp-service`, `file: ./whatsapp-service/Dockerfile` (ya existente, multi-stage `node:22-alpine`, no tocar).
  - Nombre de imagen distinto para no colisionar con la de Rails: `ghcr.io/${{ github.repository }}-whatsapp` (GHCR exige nombres en minúsculas — `github.repository` ya es `tamasi/paddleroster`, en minúsculas, seguro de usar tal cual).
  - Mismo `needs`/`if` que Task 2 — corre en paralelo al job de Rails, ambos dependiendo de los mismos 5 jobs existentes.

### Task 4: Verificación end-to-end (AC: #1, #2, #3, #4)

No hay test automatizado posible para un workflow de GitHub Actions sin ejecutarlo de verdad — la verificación es observacional:
- [x] Confirmar en Actions que `build_and_push_web`/`build_and_push_whatsapp` corren y terminan en verde tras un push a `master` — confirma AC1/AC2. **Resultado:** run [27856812104](https://github.com/tamasi/paddleroster/actions/runs/27856812104) (commit `9f4dc8f`) con los 7 jobs en `success`, incluidos ambos jobs de build/push (no `skipped`).
- [x] Confirmar que la lógica `if: github.event_name == 'push' && github.ref == 'refs/heads/master'` impide que build/push corran en un PR — confirma AC3. Verificado por inspección de código (condición no ambigua de GitHub Actions, sin necesidad de abrir un PR real): en cualquier evento `pull_request`, `github.event_name` nunca es `'push'`, así que el `if` es estructuralmente falso.
- [x] AC4 verificado por diseño (comportamiento default de `docker/build-push-action`, ver Task 2) — no se forzó un build roto real para no ensuciar el historial de Packages; no bloqueante.
- [x] (No previsto originalmente) Los 5 jobs existentes nunca habían corrido de verdad en este repo (GitHub Actions estaba deshabilitado a nivel de repositorio) — encontrar y resolver eso fue un prerrequisito real para poder validar AC1/AC2 en absoluto. Ver Dev Notes → "GitHub Actions estaba deshabilitado" y Debug Log para el detalle completo de los 7 bugs preexistentes destapados y corregidos.

### Review Findings

- [x] [Review][Defer] Sin `concurrency` group en `build_and_push_web`/`build_and_push_whatsapp` — dos pushes rápidos a `master` pueden disparar builds en paralelo; con el tag flotante `type=ref,event=branch` ("master"), el que termine último "gana" esa tag específica sin importar cuál commit es más nuevo. [.github/workflows/ci.yml] — deferred, decisión explícita de Hernan: la tag por sha siempre es inmutable y confiable; la tag de branch es solo conveniencia, no crítica en un proyecto de un solo desarrollador.

- [x] [Review][Patch] Sin `timeout-minutes` en los 2 jobs nuevos — un build colgado (cache/registro con problemas) consume un runner sin límite hasta el techo default de 6hs de GitHub Actions. [.github/workflows/ci.yml] — **Resuelto:** agregado `timeout-minutes: 15` a ambos jobs.
- [x] [Review][Patch] `config/brakeman.ignore` quedó con `"brakeman_version": "8.0.4"` pero `Gemfile.lock` en el mismo diff sube brakeman a `8.0.5` (el ignore se generó antes del `bundle update`). Verificado que el fingerprint sigue matcheando bien bajo 8.0.5 — es solo un dato de metadata desactualizado, no una falla funcional. [config/brakeman.ignore:16] — **Resuelto:** actualizado a `"8.0.5"` y refrescado el timestamp `updated`. Reverificado: `bin/brakeman` sigue ignorando el mismo fingerprint, 0 warnings activos.
- [x] [Review][Patch] El guard post-login `assert_no_selector "h1", text: "Ingresar"` en `calendario_test.rb` es más débil de lo necesario: como `inicio#index` (destino real tras login) no tiene ningún `h1`, la aserción puede resolverse en falso-aceptable sin probar realmente que la sesión quedó establecida. Reforzar afirmando algo concreto del destino (ej. el email del usuario, visible en el header) en vez de solo la ausencia del heading de login. [test/system/calendario_test.rb:16] — **Resuelto:** cambiado a `assert_text @user.email_address` (el `AppHeaderComponent` lo renderiza en toda página autenticada). Reverificado localmente: `test/system/` 3/3 verde.

- [x] [Review][Defer] `packages: write` sin firma de imagen ni provenance attestation (cosign/`provenance: true`) — cualquiera que pueda mergear a `master` puede publicar contenido arbitrario al namespace de GHCR sin verificación posterior. [.github/workflows/ci.yml] — deferred, hardening de madurez de producción, alcance de una historia futura.
- [x] [Review][Defer] `build_and_push_web`/`build_and_push_whatsapp` son prácticamente copy-paste (mismos 5 steps, solo cambia `context`/`file`/`images`) — un matrix o workflow reusable evitaría que el próximo cambio se aplique en un job y se olvide en el otro. [.github/workflows/ci.yml] — deferred, refactor de mantenibilidad, no bloqueante para AC1-AC4.
- [x] [Review][Defer] El cambio de rama default (`main`→`master`) no se auditó contra reglas de branch protection en GitHub (no hay acceso de API para verificarlas desde acá; sí se confirmó que no hay otro archivo de workflow que referencie `main`). [.github/workflows/ci.yml] — deferred, pedirle a Hernan que revise Settings → Branches manualmente.
- [x] [Review][Defer] La condición `if: github.event_name == 'push' && github.ref == 'refs/heads/master'` está duplicada literalmente en los 2 jobs nuevos — GitHub Actions no permite compartir condiciones entre jobs sin pasar a workflows reusables. [.github/workflows/ci.yml] — deferred, no vale el refactor para 2 jobs.
- [x] [Review][Defer] Las actions de terceros están pineadas por tag mayor (`@v4`/`@v6`/`@v7`), no por SHA de commit — más seguro contra un release comprometido de la action, pero inconsistente con el resto de `ci.yml` (`actions/checkout@v6`, `ruby/setup-ruby@v1`, etc. ya pineados igual). [.github/workflows/ci.yml] — deferred, decisión de política a nivel de repo, no específica de esta historia.
- [x] [Review][Defer] `needs: [...]` trata un job "skipped" como satisfecho igual que "success" — hoy ninguno de los 5 jobs existentes tiene condiciones propias, así que es inofensivo, pero si alguno ganara un `if`/path-filter a futuro, build/push podría correr sin que ese check realmente haya corrido. [.github/workflows/ci.yml] — deferred, latente, sin impacto actual.
- [x] [Review][Defer] Sin alerta si una imagen publica y la otra falla en el mismo push (estado "split-brain": Rails actualizado, whatsapp-service no, o viceversa). [.github/workflows/ci.yml] — deferred, requiere monitoreo/alerting, fuera de alcance de esta historia.
- [x] [Review][Defer] `config/brakeman.ignore` es una excepción de seguridad autoaprobada (sin segundo revisor, ticket o fecha de vencimiento) — razonable para este hallazgo puntual (confianza "Weak", código generado por Rails), pero no hay política de repo para excepciones de este tipo. [config/brakeman.ignore] — deferred, decisión de proceso, no de código.
- [x] [Review][Defer] El slot vacío "Cancha libre" es un `link_to` (`<a>`) estilizado como botón — el test ya fue corregido para reflejar la marca real, pero la elección semántica en sí (acción que crea estado vía un link, no un `<button>`) es preexistente en la vista. [app/views/turnos/index.html.erb:82] — deferred, nota de accesibilidad menor, fuera de alcance de esta historia.
- [x] [Review][Defer] AC3/AC4 quedaron verificados por inspección de código/diseño en vez de un PR real o un build roto real. [Story 6.1, Task 4] — deferred, decisión explícita ya documentada en Completion Notes (evitar ensuciar el historial de Packages/Actions con runs de prueba).
- [x] [Review][Defer] Falta traducción al español para el mensaje de presence de la asociación `cancha` en `Turno` (`belongs_to :cancha`, requerida por default) — se ve literalmente "Translation missing..." incrustado en cualquier mensaje de validación que la mencione. Hallazgo nuevo, encontrado al verificar empíricamente (no por las 3 capas de revisión) que la clave `record_invalid` agregada en esta historia sí es consumida automáticamente por `ActiveRecord::RecordInvalid` — al confirmarlo se destapó este gap separado. [config/locales/es.yml] — deferred, preexistente, sin relación con CI/CD.



### Hallazgo crítico: el trigger de push nunca matcheaba

`architecture.md` y `epics.md` asumen que "los jobs de test/lint/scan existentes" ya corren en cada push a `master` — en la práctica, por el bug de Task 1, solo corrían en PRs. Este fix es parte de esta historia (no un hallazgo a diferir) porque sin él ningún AC de build/push es alcanzable.

### No confundir con `bin/ci`/`config/ci.rb`

El repo tiene `bin/ci` + `config/ci.rb` (scaffold default de `rails new` en Rails 8.1, usa `ActiveSupport::ContinuousIntegration`). **No es el pipeline real** — nunca se invoca desde `.github/workflows/ci.yml`, que define sus propios jobs paralelos (`scan_ruby`, `scan_js`, `lint`, `test`, `system-test`) de forma independiente. No tocar `bin/ci`/`config/ci.rb` en esta historia; el único archivo de pipeline relevante es `.github/workflows/ci.yml`.

### Dockerfiles ya existen y están completos — no reescribir

- `Dockerfile` (raíz): multi-stage, Ruby 3.4.9 (coincide con `.ruby-version`), ya maneja `bundle install`, `bootsnap precompile`, `assets:precompile` y usuario no-root. Producción-ready tal cual está.
- `whatsapp-service/Dockerfile`: `node:22-alpine`, `npm install` + `npm run build` (compila TS a `dist/`) + `CMD ["node", "dist/index.js"]`. También completo.

Esta historia solo agrega *steps de CI* que invocan `docker build`/`docker push` contra estos Dockerfiles existentes — cero cambios a los Dockerfiles en sí.

### Naming de imágenes GHCR

Repo: `tamasi/paddleroster` (`git remote show origin`). GHCR requiere nombres en minúsculas — `github.repository` ya cumple. Convención sugerida (ninguna está hardcodeada todavía en ningún otro archivo, así que esta historia la define por primera vez):
- Rails: `ghcr.io/tamasi/paddleroster`
- whatsapp-service: `ghcr.io/tamasi/paddleroster-whatsapp`

`config/deploy.yml` (Story 6.2) todavía tiene el scaffold genérico de Kamal (`image: retroai`, `registry.server: localhost:5555`) — **no tocar `config/deploy.yml` en esta historia**, Story 6.2 lo conecta con las imágenes publicadas acá.

### Permiso de GitHub que NO se configura en YAML

Si el push a GHCR falla con 403/permission denied a pesar de tener `permissions: packages: write` en el job, el motivo casi seguro es la configuración a nivel de repositorio: **Settings → Actions → General → Workflow permissions** debe estar en "Read and write permissions" (algunos repos nuevos vienen seteados en "Read repository contents permission" por default). Esto es un ajuste manual en la UI de GitHub, no algo que el YAML pueda forzar — si Task 4 falla con ese error, este es el primer lugar a revisar antes de tocar el workflow.

### GitHub Actions estaba deshabilitado a nivel de repositorio

Hallazgo posterior a la implementación inicial, durante Task 4: además del bug del trigger (Task 1), **Actions estaba deshabilitado en Settings → Actions → General** del repositorio — ningún workflow corría nunca, ni por push ni por PR, independientemente del YAML. Esto significa que `scan_ruby`/`scan_js`/`lint`/`test`/`system-test` **nunca se habían ejecutado de verdad** desde que existen (Story 1.1), a pesar de que esta historia (y `architecture.md`/`epics.md`) asumían que ya corrían en cada push. Una vez habilitado, el primer run real destapó 6 problemas preexistentes adicionales, nunca antes detectados — ver Debug Log para el detalle de cada uno y su fix. Ninguno es responsabilidad de esta historia en términos de causa, pero todos eran bloqueantes para poder demostrar AC1/AC2 (que dependen de que los 5 jobs existentes pasen).

### Git Intelligence

`Dockerfile`, `whatsapp-service/Dockerfile`, `.github/workflows/ci.yml` y `config/deploy.yml` no se tocaron desde que se crearon en la Story 1.1 (`git log --oneline --all -- .github Dockerfile whatsapp-service/Dockerfile config/deploy.yml` → único resultado: `28df29a Story 1.1: inicializar proyecto Rails 8 + esqueleto whatsapp-service`). Los commits recientes (fixes del bot de WhatsApp, Solid Queue) no tocan ninguno de estos archivos — no hay convenciones nuevas de CI/Docker que aprender de trabajo reciente, los Dockerfiles siguen siendo el scaffold original de `rails new`/Story 1.1 tal cual.

### `.kamal/secrets` fuera de alcance

El login a GHCR de esta historia usa el `GITHUB_TOKEN` automático de GitHub Actions (vía `docker/login-action` + permiso `packages: write`) — no requiere ningún secret nuevo en `.kamal/secrets` ni en `.github`. `.kamal/secrets` es para que Kamal (corriendo en el droplet) *consuma* las imágenes publicadas — eso es Story 6.2, no esta.

### Jobs existentes en `.github/workflows/ci.yml` (no modificar su lógica interna)

`scan_ruby` (Brakeman + bundler-audit), `scan_js` (`bin/importmap audit`), `lint` (Rubocop, con cache), `test` (Minitest contra Postgres de servicio), `system-test` (Minitest system tests, requiere Chrome — ya soportado en `ubuntu-latest`, a diferencia del entorno de desarrollo local de Hernan que no tiene Chrome/ChromeDriver sin sudo). Los jobs nuevos de esta historia solo se agregan como `needs` de estos cinco, sin alterarlos.

### Project Structure Notes

- Único archivo a modificar: `.github/workflows/ci.yml`. No se crean modelos, controllers, ni se tocan `app/`, `db/`, `whatsapp-service/src/`.
- No hay convención de tests Minitest/Rubocop aplicable a YAML de GitHub Actions — la validación es la ejecución real del workflow (Task 4), no una suite local.

### References

- [Source: epics.md#Epic-6, Story 6.1] — historia y acceptance criteria originales.
- [Source: architecture.md#Infrastructure-and-Deployment] — "CI/CD: GitHub Actions (free tier) → tests (Minitest) → build de imágenes → push a GitHub Container Registry → Kamal 2 despliega vía SSH con rolling restart."
- [Source: architecture.md#Decision-Impact-Analysis, Implementation Sequence #6] — "CI/CD (GitHub Actions + Kamal) + despliegue inicial al droplet DigitalOcean + bot de Telegram para alertas."
- [Source: .github/workflows/ci.yml] — workflow actual (jobs `scan_ruby`, `scan_js`, `lint`, `test`, `system-test`; bug de trigger `branches: [ main ]`).
- [Source: Dockerfile, whatsapp-service/Dockerfile] — imágenes ya existentes a construir/publicar, sin modificar.
- [Source: config/deploy.yml, .kamal/secrets] — scaffold genérico de Kamal, fuera de alcance (Story 6.2).

## Latest Tech Information

Versiones estables verificadas vía investigación web al momento de crear esta historia (junio 2026) — confirmar en el Marketplace de GitHub Actions si cambiaron antes de implementar:

- `docker/login-action@v4`
- `docker/setup-buildx-action@v4` (requerido por `build-push-action` para multi-stage cache; v3 también es estable si v4 tuviera algún problema puntual)
- `docker/metadata-action@v6` — genera tags/labels automáticamente a partir de `github.repository`/sha/ref
- `docker/build-push-action@v7` — soporta `cache-from: type=gha` / `cache-to: type=gha,mode=max` (caché de capas de Docker vía el cache nativo de GitHub Actions, límite de 10GB compartido por repo — acelera builds repetidos sin infra adicional)

Sources:
- [Introduction to GitHub Actions with Docker | Docker Docs](https://docs.docker.com/guides/gha/)
- [Docker Build GitHub Actions | Docker Docs](https://docs.docker.com/build/ci/github-actions/)
- [docker/metadata-action GitHub repo](https://github.com/docker/metadata-action)
- [Cache management with GitHub Actions | Docker Docs](https://docs.docker.com/build/ci/github-actions/cache/)
- [docker/setup-buildx-action GitHub repo](https://github.com/docker/setup-buildx-action)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

Task 4 (verificación end-to-end) destapó una cadena de 7 bugs/gaps preexistentes, nunca antes detectados porque GitHub Actions estaba deshabilitado en el repo desde su creación (Story 1.1). Orden real de descubrimiento, cada uno bloqueando al siguiente hasta resolverse:

1. **Actions deshabilitado a nivel de repo** (Settings → Actions → General) — confirmado por Hernan; 0 runs registrados pese a 2 pushes previos con el trigger ya corregido. Habilitado manualmente por Hernan.
2. **`bin/*` sin bit de ejecución en git** (`100644` en vez de `100755`) — `core.fileMode=false` en este entorno (workaround típico de WSL2/DrvFs, que reporta todo como `777` sin reflejar permisos reales) hizo que los 13 scripts de `bin/` se commitearan sin `+x` desde la Story 1.1. Los 5 jobs existentes fallaban con `Permission denied`/exit 126. Corregido vía `git update-index --chmod=+x` sobre cada script (commit `4b67af4`).
3. **`scan_ruby` fallaba**: `bin/brakeman` antepone `--ensure-latest`, que aborta sin escanear si la gema instalada no es la última publicada (8.0.4 vs 8.0.5) — actualizada vía `bundle update brakeman`. Con el scan real corriendo, apareció 1 warning "HTTP Verb Confusion" en `app/controllers/concerns/authentication.rb:33` — código generado tal cual por `bin/rails generate authentication` (scaffold nativo de Rails 8, no tocado), confianza "Weak", sin impacto de seguridad real. Ignorado por fingerprint en `config/brakeman.ignore` (commit `7740114`).
4. **`lint` fallaba**: 5 offenses de Rubocop preexistentes (`Layout/SpaceInsideArrayLiteralBrackets` en `turnos_controller.rb`, `Layout/TrailingWhitespace` en `calendario_test.rb`) — corregidas vía `rubocop -A` (commits `b573d95` y parte de `6ebb11e`).
5. **`system-test` fallaba (1ª ronda — excepciones)**: `test/system/calendario_test.rb` usaba el helper de vista `l(...)` (no disponible en contexto de system test, `NoMethodError`) y creaba un `Turno` sin `reservation_name` (campo requerido desde alguna historia posterior a cuando se escribió este test, nunca actualizado) → `ActiveRecord::RecordInvalid`. De paso, la excepción no mostraba el mensaje real porque a `config/locales/es.yml` le faltaba `errors.messages.record_invalid` (agregado). Cambiado `l` → `I18n.l` (commit `6ebb11e`).
6. **`system-test` fallaba (2ª ronda — assertion failures)**: tras el fix anterior, el login parecía no completarse antes del primer `visit` de cada test (página resultante era el propio login). Causa: `click_on "Ingresar"` dispara un submit vía Turbo (asíncrono); el `visit` inmediato siguiente puede cancelar ese POST en pleno vuelo antes de que la cookie de sesión se establezca. Agregado `assert_no_selector "h1", text: "Ingresar"` tras el login para forzar la espera (commit `c88a9ce`). Descartado por el camino que fuera un bug de la app: confirmado manualmente por Hernan que login + `/calendario` funcionan bien en un browser real con datos de seed.
7. **`system-test` fallaba (3ª ronda — assertion failures distintas)**: logré reproducir el system test localmente por primera vez en este entorno (workaround sin sudo: `apt-get download` + `dpkg-deb -x` de `libnspr4`/`libnss3`/`libasound2` + `LD_LIBRARY_PATH`, mismo patrón ya documentado en memoria de sesión para Playwright, aplicado aquí a Capybara/Selenium). Aparecieron 2 bugs reales: `Date.current.change(hour: 15)` es un no-op silencioso (un `Date` no tiene componente de hora — el turno se creaba a las 00:00, fuera de la grilla horaria visible) y el test buscaba un `<button>` con texto "Cancha libre" cuando la vista real usa `link_to` (`<a>`). Corregido a `Time.current.change(hour:, min:, sec:)` y selector `"a"` (commit `9f4dc8f`).

Verificación final: run [27856812104](https://github.com/tamasi/paddleroster/actions/runs/27856812104) — 7/7 jobs en `success` (`scan_ruby`, `scan_js`, `lint`, `test`, `system-test`, `build_and_push_web`, `build_and_push_whatsapp`). Local: `bin/rails test` 276/276, `test/system/` 3/3, `bin/rubocop` 0 offenses.

### Completion Notes List

- Lo que en el alcance original parecía "agregar 2 jobs de CI sobre un pipeline que ya funciona" resultó ser, en la práctica, la primera ejecución real de todo el pipeline desde que existe el repo — Actions estaba deshabilitado desde la Story 1.1. Validar AC1-AC4 requirió primero hacer pasar a los 5 jobs existentes, lo cual destapó 7 bugs/gaps preexistentes (detalle completo en Debug Log), todos corregidos.
- Decisión de scope: se descartó tocar `Rails.application.config.time_zone` (actualmente `UTC`, no horario argentino) como hipótesis inicial del bug #7 — la causa real resultó ser más simple (`Date#change(hour:)` no-op) y no relacionada con zona horaria. Cambiar el timezone de la app es una decisión de producto/infra con ripple effects amplios (pagos, turnos recurrentes, bot) que merece su propia historia, no un fix de paso en el pipeline de CI.
- Las acciones visibles en GitHub (push directo a `master`, sin PR) fueron explícitamente confirmadas por Hernan antes de ejecutarse (proyecto de un solo desarrollador, sin revisión de PRs).

### File List

**MODIFIED:**
- `.github/workflows/ci.yml` — trigger `push.branches` corregido a `master`; jobs nuevos `build_and_push_web` y `build_and_push_whatsapp`.
- `bin/brakeman`, `bin/bundler-audit`, `bin/ci`, `bin/dev`, `bin/docker-entrypoint`, `bin/importmap`, `bin/jobs`, `bin/kamal`, `bin/rails`, `bin/rake`, `bin/rubocop`, `bin/setup`, `bin/thrust` — solo cambio de modo (`100644` → `100755`), sin cambios de contenido.
- `Gemfile.lock` — `brakeman` 8.0.4 → 8.0.5.
- `app/controllers/turnos_controller.rb` — offense de Rubocop (espacios en array literal).
- `config/locales/es.yml` — agregada clave `errors.messages.record_invalid`.
- `test/system/calendario_test.rb` — `l` → `I18n.l`, `reservation_name` agregado, espera post-login, `Date.current` → `Time.current` para el `:hour`, selector `button` → `a`.

**NEW:**
- `config/brakeman.ignore` — 1 warning ignorado por fingerprint (HTTP Verb Confusion en scaffold de autenticación de Rails).

## Change Log

- 2026-06-19: Implementación de Tasks 1-3 (`8875634`) — trigger de push corregido, jobs `build_and_push_web`/`build_and_push_whatsapp` agregados. Validado localmente (sintaxis YAML, suite Rails sin regresión). Status → `in-progress`.
- 2026-06-19: Verificación end-to-end (Task 4) en GitHub Actions real. Encontrados y corregidos en cadena: Actions deshabilitado a nivel de repo (`4b67af4` bit de ejecución de `bin/*`), `scan_ruby`/`lint` (`7740114`, `b573d95` — brakeman desactualizado + falso positivo, offenses de rubocop), `system-test` en 3 rondas (`6ebb11e` helper `l`/`reservation_name`, `c88a9ce` race condition de Turbo en el login, `9f4dc8f` `Date#change(hour:)` no-op + selector `button`/`a`). Run final [27856812104](https://github.com/tamasi/paddleroster/actions/runs/27856812104): 7/7 jobs en verde, imágenes publicadas en GHCR. Status → `review`.
- 2026-06-19: Code review (3 capas: Blind Hunter, Edge Case Hunter, Acceptance Auditor). 1 decisión diferida con justificación explícita de Hernan (sin `concurrency` group — tag por sha siempre confiable, no crítico para un solo desarrollador), 3 patches aplicados (`timeout-minutes: 15` en los 2 jobs nuevos, metadata de `config/brakeman.ignore` actualizada a 8.0.5, guard post-login reforzado a `assert_text @user.email_address`), 11 hallazgos diferidos a `deferred-work.md`, 12 descartados como ruido — entre ellos, 2 hallazgos sobre la clave `record_invalid` resultaron incorrectos al verificarlos empíricamente (sí es consumida por `ActiveRecord::RecordInvalid`), lo cual destapó un gap real distinto (traducción faltante para `Turno#cancha`), también diferido. Suite final: 276/276 + 3/3 system tests verde. Status → `done`.
- 2026-06-19: Hotfix post-`done` — `system-test` volvió a fallar de forma intermitente en CI (commit `b6046ec`, un cambio de **solo documentación**, sin tocar código). Causa: el patch del guard post-login (`assert_text @user.email_address`) sí espera, pero solo el default de Capybara (2s) — en el runner compartido de GitHub Actions, login (bcrypt + Turbo) ocasionalmente tarda más que eso. No es el mismo bug que las rondas anteriores (esas eran deterministas; esta es timing puro, dependiente de la carga del runner). Agregado `wait: 10` explícito en `calendario_test.rb`, y el mismo wait defensivo en `dark_mode_test.rb` (comparte el mismo flujo de login, mismo riesgo, todavía no había fallado pero corría la misma carrera). Verificado localmente con 3 corridas consecutivas de `test/system/` en verde antes de pushear.

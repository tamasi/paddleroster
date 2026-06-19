---
story_id: "6.1"
story_key: "6-1-pipeline-de-ci-cd-build-y-push-de-imagenes"
epic_id: "6"
title: "Pipeline de CI/CD — build y push de imágenes"
status: "ready-for-dev"
last_updated: "2026-06-19"
baseline_commit: "93b870a149e178cf009b3ce87c4bbc29ac8ae422"
---

# Story 6.1: Pipeline de CI/CD — build y push de imágenes

Status: ready-for-dev

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
- [ ] Abrir un PR de prueba (o usar el de esta misma historia) y confirmar en la pestaña Actions que `build_and_push_web`/`build_and_push_whatsapp` aparecen como **skipped** (no como "no ejecutado" por error) — confirma AC3.
- [ ] Tras mergear a `master`, confirmar en Actions que ambos jobs corren y terminan en verde, y que las imágenes aparecen en la pestaña **Packages** del repo (`ghcr.io/tamasi/paddleroster` y `ghcr.io/tamasi/paddleroster-whatsapp`) con un tag de sha — confirma AC1/AC2.
- [ ] (Opcional, no bloqueante) Si se quiere validar AC4 sin esperar a un build roto real: introducir temporalmente un error sintáctico en un Dockerfile en una rama de prueba, confirmar que el job termina en rojo y que no aparece un tag nuevo en Packages, y revertir el cambio.

## Dev Notes

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

- Validación de sintaxis YAML local: `ruby -ryaml -e "YAML.load_file('.github/workflows/ci.yml')"` → válido.
- Suite completa tras los cambios: `bin/rails test` → 276/276 verde (sin regresión, no se tocó código Ruby). `bin/rubocop` → 5 offenses, idénticos en cantidad y ubicación a los preexistentes documentados en historias anteriores (ninguno en `.github/workflows/ci.yml`, que no es un archivo Ruby).

### Completion Notes List

- Tasks 1-3 implementadas y validadas localmente (sintaxis YAML + suite de regresión Rails sin tocar). Task 4 (verificación end-to-end) requiere abrir un PR real y mergear a `master` en GitHub — son acciones visibles en el repositorio compartido (push de rama, PR, merge a la rama default), así que quedan pendientes de confirmación explícita de Hernan antes de ejecutarse, en vez de disparase de forma autónoma.

### File List

**MODIFIED:**
- `.github/workflows/ci.yml` (trigger `push.branches` corregido a `master`; jobs nuevos `build_and_push_web` y `build_and_push_whatsapp`)

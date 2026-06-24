---
story_id: "6.3"
story_key: "6-3-rate-limiting-en-el-login-rack-attack"
epic_id: "6"
title: "Rate limiting en el login (Rack::Attack)"
status: "done"
last_updated: "2026-06-24"
baseline_commit: "f828223c541f731d3932123f59753bb44f4303a0"
---

# Story 6.3: Rate limiting en el login (Rack::Attack)

Status: done

## Story

**As a** Hernan (desarrollador único),
**I want** limitar la tasa de intentos de login,
**so that** el sistema esté protegido contra ataques de fuerza bruta sobre las credenciales de Dueño/Empleado.

## Acceptance Criteria

- **AC1: Throttle por IP en intentos de login**
  - **Given** múltiples intentos de login fallidos desde la misma IP en una ventana corta de tiempo
  - **When** se supera el límite configurado
  - **Then** Rack::Attack responde con un throttle (429) en vez de procesar el intento de login

- **AC2: Sin falsos positivos en uso normal**
  - **Given** un intento de login legítimo dentro del límite normal
  - **When** el usuario ingresa sus credenciales
  - **Then** el login funciona exactamente igual que hoy (sin falsos positivos)

- **AC3: Bloqueo temporal, no permanente**
  - **Given** que el límite se superó
  - **When** el usuario reintenta tras la ventana de throttle
  - **Then** puede volver a intentar login normalmente (el bloqueo es temporal, no permanente)

## Tasks / Subtasks

### Task 0: Decisión de diseño — Rack::Attack reemplaza el `rate_limit` nativo de Rails, no convive con él (AC: #1, #2, #3)

**Esto no es una tarea de código — es la decisión que determina cómo se escriben las Tasks 1-3. Leer antes de tocar `SessionsController`.**

`app/controllers/sessions_controller.rb:3` **ya tiene** rate limiting hoy:

```ruby
rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Demasiados intentos. Probá de nuevo en unos minutos." }
```

Esto **no** es trabajo de una historia anterior de rate limiting — es el scaffold por defecto que genera `bin/rails generate authentication` de Rails 8.1 (`ActionController::RateLimiting`, feature nativa desde Rails 8.1), agregado automáticamente en Story 1.2 sin que ninguna historia lo haya pedido explícitamente. `architecture.md` y `epics.md` (Additional Requirements, Epic 6) fueron escritos asumiendo que el rate limiting del login **todavía no existía** ("Rate limiting: Rack::Attack para el login", "ninguno de los dos ejecutado hasta ahora") — ambos quedaron desactualizados frente al scaffold.

Dos mecanismos compitiendo por el mismo propósito, con semánticas distintas:

1. **`rate_limit` nativo (actual):** corre dentro del controller (`before_action`), responde con un **redirect 302** + flash `alert`, ventana 10/3min.
2. **Rack::Attack (pedido por AC1/architecture.md):** corre como middleware Rack, **antes** de llegar al router/controller, responde con **429** por defecto.

**Decisión: remover el `rate_limit` nativo y usar solo Rack::Attack.** Razones:
- AC1 pide literalmente un **429** ("Rack::Attack responde con un throttle (429)") — el mecanismo nativo no lo da por defecto (devuelve 302), así que deja AC1 incumplido tal cual está si se lo deja como está.
- `architecture.md` (`### Authentication & Security`, `### API & Communication Patterns`) menciona `Rack::Attack` por nombre dos veces como la decisión arquitectónica para esto — no "alguna forma de rate limiting", específicamente ese gem.
- Mantener ambos a la vez deja dos ventanas/umbrales/respuestas distintas para el mismo endpoint, sin que ninguna AC lo pida — complejidad sin beneficio para un dev único (NFR-9).
- Quitar la línea no toca la lógica de `new`/`create` (AC2 — "funciona exactamente igual que hoy" — sigue intacto porque no se modifica el cuerpo de esos métodos, solo se borra el decorator de rate limiting).

No se necesita ninguna otra forma de mitigar la pérdida del mensaje de UX ("Demasiados intentos...") — ninguna AC de esta historia pide un mensaje específico, solo el código 429 (ver Dev Notes → "Mensaje de Rack::Attack — por qué no se personaliza").

### Task 1: Agregar el gem `rack-attack` (AC: #1)

- [x] Agregar al `Gemfile`, en el bloque principal (sin `group`, sin `require: false` — necesita correr en development/test/production):
  ```ruby
  # Rate limiting / throttling para proteger el login de fuerza bruta [https://github.com/rack/rack-attack]
  gem "rack-attack", "~> 6.8"
  ```
  Ubicarlo cerca de `gem "pundit"` (sección de seguridad/autorización del Gemfile) por cohesión temática, no es un requisito técnico.
- [x] `bundle install` — actualiza `Gemfile.lock` (agrega `rack-attack` y su única dependencia, `rack`, ya presente en el lockfile vía Rails).
- [x] No se necesita `require: "rack/attack"` explícito ni `Rails.application.config.middleware.use Rack::Attack` en ningún initializer — en una app Rails, el gem se auto-inserta en el stack de middleware vía su propio Railtie al momento de cargarse (confirmado en Latest Tech Information). Si alguna implementación previa que conozcas agrega esa línea, es redundante, no incorrecta, pero no hace falta.

### Task 2: Crear `config/initializers/rack_attack.rb` (AC: #1, #3)

- [x] Crear el archivo con el throttle:
  ```ruby
  Rack::Attack.throttle("logins/ip", limit: 10, period: 3.minutes) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  Rack::Attack.throttled_response_retry_after_header = true
  ```
  - `limit: 10, period: 3.minutes`: mismo umbral que tenía el `rate_limit` nativo que se remueve en Task 3 — preserva el comportamiento de UX ya vigente (no introduce un umbral nuevo y arbitrario sin que ninguna AC lo pida).
  - `req.path == "/session" && req.post?`: el path real de `resource :session` (`config/routes.rb:2`) para el `create` es `POST /session` — verificar que coincide exactamente, no asumir `/login` ni `/sessions` (error común, este proyecto usa singular `resource`, no `resources`).
  - El throttle cuenta **todos** los POST a `/session` desde una IP, no solo los fallidos — es el patrón estándar de Rack::Attack (no puede distinguir éxito/fracaso en este punto del stack, corre antes del controller) y es consistente con AC1: el escenario que describe (fuerza bruta) son mayormente intentos fallidos, pero la mecánica de conteo no necesita ni puede diferenciarlos. No intentar implementar un throttle "solo de fallidos" — no es lo que pide la AC literal y añade complejidad significativa (requeriría inspeccionar la respuesta después de que el controller ya corrió, fuera del modelo simple de `throttle`).
  - `throttled_response_retry_after_header = true`: agrega el header HTTP estándar `Retry-After` a la respuesta 429 — una sola línea, mejora la respuesta sin agregar lógica custom. No confundir con personalizar el cuerpo/mensaje de la respuesta (ver Dev Notes, fuera de alcance).
  - AC1 ("responde con un throttle (429)") queda cubierto por el comportamiento **default** de Rack::Attack sin código adicional — no se necesita un `self.throttled_responder` custom.

### Task 3: Remover el `rate_limit` nativo de `SessionsController` (AC: #1, #2, #3)

- [x] En `app/controllers/sessions_controller.rb:3`, borrar la línea completa:
  ```ruby
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Demasiados intentos. Probá de nuevo en unos minutos." }
  ```
- [x] No tocar nada más del archivo (`allow_unauthenticated_access`, `new`, `create`, `destroy` quedan exactamente igual — AC2 depende de que el flujo normal de login no cambie).

### Task 4: Tests (AC: #1, #2, #3)

**Gotcha crítico antes de escribir el test — leer con atención:**

`config/environments/test.rb:23` tiene `config.cache_store = :null_store`. Rack::Attack usa `Rails.cache` como store por defecto (confirmado en Latest Tech Information) — con `:null_store`, **todo incremento de contador es un no-op y toda lectura devuelve `nil`**, así que el throttle nunca se dispara en el entorno de test tal cual está configurado hoy, sin importar cuántos requests se envíen. Esto es intencional y **no debe cambiarse globalmente** (cambiar `test.rb` a un store real afectaría el comportamiento de caché de toda la suite, no solo este test). La solución es reemplazar el store **solo dentro del test nuevo**, con scope local vía `setup`/`teardown`:

```ruby
setup do
  @original_rack_attack_store = Rack::Attack.cache.store
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
end

teardown do
  Rack::Attack.cache.store = @original_rack_attack_store
end
```

Esto garantiza dos cosas: (a) cada test de este archivo arranca con un store vacío (sin contaminación entre tests del mismo archivo — los requests de integration tests en Rails siempre vienen de `127.0.0.1`, así que sin este aislamiento el conteo de un test se sumaría al del siguiente), y (b) al terminar se restaura el `:null_store` original, así que ningún otro archivo de test (`sessions_controller_test.rb`, `session_expiration_test.rb`, los system tests que hacen login vía UI) se ve afectado — siguen corriendo exactamente igual que hoy, con el throttle deshabilitado de facto como ya ocurre actualmente.

- [x] Crear `test/integration/rate_limiting_test.rb` (mismo patrón/ubicación que `test/integration/session_expiration_test.rb` — comportamiento de varios requests sobre `/session`, no un test de un controller aislado):

  ```ruby
  require "test_helper"

  class RateLimitingTest < ActionDispatch::IntegrationTest
    include ActiveSupport::Testing::TimeHelpers

    setup do
      @user = User.take
      @original_rack_attack_store = Rack::Attack.cache.store
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    end

    teardown do
      Rack::Attack.cache.store = @original_rack_attack_store
    end

    test "throttles after exceeding the login attempt limit from the same IP" do
      10.times do
        post session_path, params: { email_address: @user.email_address, password: "wrong" }
      end

      post session_path, params: { email_address: @user.email_address, password: "wrong" }

      assert_response :too_many_requests
    end

    test "does not throttle login attempts within the normal limit" do
      9.times do
        post session_path, params: { email_address: @user.email_address, password: "wrong" }
      end

      post session_path, params: { email_address: @user.email_address, password: "password" }

      assert_redirected_to root_path
    end

    test "throttle is temporary and clears after the window passes" do
      11.times do
        post session_path, params: { email_address: @user.email_address, password: "wrong" }
      end
      assert_response :too_many_requests

      travel_to 3.minutes.from_now + 1.second do
        post session_path, params: { email_address: @user.email_address, password: "password" }

        assert_redirected_to root_path
      end
    end
  end
  ```
  - Test 1 (AC1): 10 intentos agotan el límite (`limit: 10`), el 11º debe dar 429 (`assert_response :too_many_requests` — Rack ya mapea 429 a ese símbolo).
  - Test 2 (AC2): 9 intentos fallidos + 1 exitoso dentro del límite — el login exitoso debe comportarse exactamente como hoy (redirect a `root_path`, ver `sessions_controller_test.rb` para el mismo patrón de assertion ya usado).
  - Test 3 (AC3): supera el límite, confirma 429, avanza el reloj más allá del `period` (3 minutos) con `travel_to` en su **forma de bloque** (no `travel_to` + `travel_back` manual) — la forma de bloque revierte el tiempo automáticamente al salir, evitando que un test deje el reloj "congelado" para los tests que corran después de este en el mismo worker (riesgo real dado que la suite usa `parallelize(workers: :number_of_processors)`, `test/test_helper.rb:8` — cada worker corre sus tests asignados en secuencia dentro del mismo proceso).
- [x] Confirmar que los tests existentes en `test/controllers/sessions_controller_test.rb` y `test/integration/session_expiration_test.rb` siguen pasando sin modificación — no deberían verse afectados, ya que el `:null_store` global sigue intacto para ellos.

### Task 5: Verificación (AC: #1, #2, #3)

- [x] `bin/rails test test/integration/rate_limiting_test.rb` — los 3 tests nuevos en verde.
- [x] `bin/rails test` — suite completa sin regresiones (línea base: 276/276 antes de esta historia, ver Story 6.2 Debug Log).
- [x] `test/system/` — sin regresiones (login vía UI sigue funcionando; estos tests no activan el throttle porque corren con `:null_store` sin override).
- [x] `bundle exec rubocop` — 0 offenses.
- [x] `bundle exec brakeman` — 0 warnings nuevos (Rack::Attack es un gem de seguridad ampliamente usado, no debería introducir hallazgos).
- [x] `bundle exec bundler-audit check --update` — confirmar que `rack-attack` no tiene CVEs conocidos a la versión instalada.

### Review Findings

- [x] [Review][Patch] Los dos archivos nuevos (`config/initializers/rack_attack.rb`, `test/integration/rate_limiting_test.rb`) parecían tener modo `100755` (ejecutable) en el diff de revisión — **resuelto como falso positivo**: el repo tiene `core.filemode=false`, así que Git ignora el bit de ejecución del filesystem (este entorno corre sobre un mount drvfs/9p que reporta 777 para todo). Confirmado con `git add`: ambos archivos quedan indexados como `100644`, igual que el resto del repo. El `100755` solo aparecía en el diff de revisión por construirse con `git diff --no-index` (que lee el stat crudo, sin pasar por `core.filemode`). Sin impacto real, nada que corregir en el commit. [config/initializers/rack_attack.rb, test/integration/rate_limiting_test.rb]

## Dev Notes

### Por qué Rack::Attack y no ampliar el `rate_limit` nativo

Ver Task 0 — la decisión ya está tomada y justificada ahí (AC1 pide 429 explícitamente vía Rack::Attack por nombre; el mecanismo nativo de Rails 8.1 no da 429 por defecto y `architecture.md` nombra el gem específico, no "alguna forma de rate limiting").

### Mensaje de Rack::Attack — por qué no se personaliza

El `rate_limit` nativo que se remueve mostraba un flash en español ("Demasiados intentos. Probá de nuevo en unos minutos."). La respuesta default de Rack::Attack ante un throttle es un 429 con cuerpo de texto plano genérico, sin pasar por el layout/flash de la app (corre en el middleware stack, antes de que exista un `ActionDispatch::Flash` request). Ninguna AC de esta historia pide un mensaje específico — solo el código 429 (AC1). Personalizar `Rack::Attack.self.throttled_responder` para devolver un body en español es posible pero es trabajo no pedido por ninguna AC; no implementarlo salvo que se identifique un AC futuro que lo requiera.

### Por qué el throttle es por IP y no por email/IP combinado

AC1 dice literalmente "desde la misma IP" — no pide throttle por cuenta/email. Un throttle adicional por email (para mitigar fuerza bruta distribuida entre muchas IPs contra una sola cuenta) es una mejora de seguridad razonable pero fuera del texto literal de la AC y de lo que pide `architecture.md` ("Rack::Attack, solo para login" — sin especificar discriminador). No implementarlo en esta historia; si se quiere a futuro, es una historia separada con su propia AC (anti-scope-creep, NFR-9).

### Gotcha de testing — `config.cache_store = :null_store` en test

Ver Task 4 — es el hallazgo más importante de esta historia a nivel de testing. Sin el override local de `Rack::Attack.cache.store` en `setup`/`teardown`, **cualquier test que intente verificar AC1/AC3 pasará falsamente** (el throttle nunca se activa con `:null_store`, así que un test ingenuo que solo verifique "no debería dar 429 con pocos intentos" pasaría sin haber probado nada real sobre el caso de éxceso de límite). Confirmar manualmente con un break/log temporal si hay dudas de que el store efectivamente cambió antes de confiar en los asserts.

### Compatibilidad con Solid Cache en producción

En producción (`config/environments/production.rb:50` → `config.cache_store = :solid_cache_store`), Rack::Attack usará automáticamente ese store (default `Rails.cache`) sin configuración adicional — Solid Cache ya está respaldado por Postgres (ver `architecture.md` → Starter Template: "Solid Cache... sin necesitar Redis"), consistente con la restricción de presupuesto (NFR-7). No se necesita ni se debe agregar Redis solo para Rack::Attack — sería contradecir una decisión arquitectónica explícita para ahorrar un único gem.

### Project Structure Notes

- Archivos a tocar: `Gemfile`, `Gemfile.lock` (regenerado por `bundle install`), `app/controllers/sessions_controller.rb` (remover 1 línea), nuevo `config/initializers/rack_attack.rb`, nuevo `test/integration/rate_limiting_test.rb`.
- `config/routes.rb` no cambia — el path `/session` ya existe vía `resource :session` (línea 2).
- `architecture.md` no especifica una ubicación de archivo para Rack::Attack; `config/initializers/rack_attack.rb` es la convención estándar del gem (confirmada en Latest Tech Information) y consistente con cómo ya vive `config/initializers/pundit.rb` para la otra pieza de seguridad/autorización del proyecto.
- No crear ningún archivo bajo `app/` — esto es configuración de middleware, no lógica de dominio.

### References

- [Source: epics.md#Epic-6, Story 6.3] — historia y acceptance criteria originales.
- [Source: architecture.md#Authentication-and-Security] — "Rack::Attack para rate-limiting del login."
- [Source: architecture.md#API-and-Communication-Patterns] — "Rate limiting: Rack::Attack, solo para login."
- [Source: app/controllers/sessions_controller.rb:1-21] — `rate_limit` nativo a remover (Task 0/3), resto del controller sin cambios.
- [Source: config/routes.rb:2] — `resource :session` → confirma el path `/session` para el throttle.
- [Source: config/environments/test.rb:23, development.rb:29, production.rb:50] — `cache_store` por entorno (`:null_store`/`:memory_store`/`:solid_cache_store`), determina el comportamiento de Rack::Attack en cada uno.
- [Source: test/test_helper.rb:8] — `parallelize(workers: :number_of_processors)`, motivo por el que `travel_to` debe usarse en forma de bloque (Task 4).
- [Source: test/integration/session_expiration_test.rb] — patrón de integration test sobre `/session` ya establecido en el proyecto, replicado en Task 4.
- [Source: test/controllers/sessions_controller_test.rb] — assertions existentes (`assert_redirected_to root_path`, etc.) que no deben romperse.

## Previous Story Intelligence (Story 6.2)

- Mismo patrón aplicado en esta historia (Task 0): cuando `architecture.md`/`epics.md` describen una intención de alto nivel pero el mecanismo real tiene más de una forma válida de implementarse (Story 6.2: accesorio vs. destination de Kamal; esta historia: Rack::Attack vs. el `rate_limit` nativo ya presente), documentar la decisión explícitamente con su razonamiento en vez de implementar en silencio o dejarlo ambiguo para el dev agent.
- Story 6.2 destapó que asumir que código "ya escrito" funciona contra un entorno real es riesgoso sin verificarlo (`db/queue_migrate` faltante, nunca ejercitado). Lección aplicada acá: no asumir que el `rate_limit` nativo o Rack::Attack "simplemente funcionan" en test — de ahí el Gotcha de `:null_store` documentado explícitamente en Task 4 en vez de asumido.
- Hernan ya validó (Story 6.2 Task 0, decisión del campo `image:` raíz) que tomar una decisión de diseño autónoma con justificación clara — en vez de detener el trabajo para preguntar — es el approach correcto cuando la arquitectura documentada quedó desalineada con el estado real del código. Esta historia sigue el mismo patrón en Task 0 (remover el `rate_limit` nativo sin pedir confirmación previa, con razonamiento explícito).

## Git Intelligence

`git log --oneline -10` muestra únicamente trabajo de Story 6.1 (CI/CD) y Story 6.2 (Kamal) más un hotfix de flakiness en system tests — ningún commit reciente toca `app/controllers/sessions_controller.rb`, `config/routes.rb` ni ningún archivo relacionado a autenticación/login. No hay convenciones nuevas de código de aplicación (Ruby/Ransa) que aprender de trabajo reciente para esta historia — los únicos patrones relevantes ya están documentados arriba (Project Structure Notes, References).

## Latest Tech Information

Versiones e información confirmadas vía investigación web al momento de crear esta historia (junio 2026):

- **`rack-attack`**: última versión estable `6.8.0` — usar `gem "rack-attack", "~> 6.8"`. Compatible con Rack 3.x (el proyecto ya usa `rack (3.2.6)` vía Rails, ver `Gemfile.lock`), sin requerir ninguna otra dependencia nueva.
- **Setup en apps Rails**: el gem se integra automáticamente al middleware stack vía su propio Railtie al cargarse — **no** hace falta `Rails.application.config.middleware.use Rack::Attack` explícito (eso solo es necesario en apps Rack puras sin Rails). Confirmado en el README oficial del gem.
- **Cache store default**: `Rack::Attack.cache.store` usa `Rails.cache` automáticamente si está presente — no requiere configuración adicional para integrarse con Solid Cache en producción.
- **Respuesta default ante throttle**: HTTP 429, sin código adicional — satisface AC1 tal cual.
- **Testing**: el gem expone `Rack::Attack.reset!` para limpiar estado entre tests, pero **no resuelve** el problema de `:null_store` en este proyecto (un store nulo nunca persiste nada que limpiar) — de ahí que Task 4 use el override de `Rack::Attack.cache.store` con un `ActiveSupport::Cache::MemoryStore` real en vez de depender solo de `reset!`.
- **`throttled_response_retry_after_header`**: flag de una línea para agregar el header HTTP `Retry-After` a la respuesta 429 — mejora menor de UX/protocolo, sin lógica custom.

Sources:
- [rack/rack-attack GitHub repository](https://github.com/rack/rack-attack)
- [rack-attack README (rack/rack-attack, main branch)](https://raw.githubusercontent.com/rack/rack-attack/main/README.md)
- [Rate Limiting in Rails with Rack::Attack: A Production Configuration Guide - TTB Software](https://ttb.software/2026/03/21/rails-rate-limiting-rack-attack-production-guide/)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `test/system/` no corría localmente en este sandbox: `chromedriver` fallaba con `error while loading shared libraries: libnspr4.so: cannot open shared object file` (mismo root cause ya documentado en Story 6.1 — sandbox sin `sudo`, libs nativas de Chrome/Chromium faltantes). Resuelto con el workaround ya validado en esa historia: `apt-get download libnspr4 libnss3 libasound2` (no requiere root) + `dpkg-deb -x` de cada `.deb` a un directorio scratch + `LD_LIBRARY_PATH` apuntando ahí al invocar `bin/rails test test/system/`. Confirmado: 3/3 verde, sin regresiones. Directorio scratch eliminado al terminar, no se persiste nada del workaround en el repo.
- Gotcha de `config.cache_store = :null_store` en `test.rb` (documentado en Task 4 de la historia) verificado empíricamente: sin el override local de `Rack::Attack.cache.store` en `setup`/`teardown`, los 3 tests de `rate_limiting_test.rb` no habrían ejercitado el throttle real. Con el override, los 3 tests pasan ejercitando el comportamiento real (10 intentos límite, 11º con 429, ventana de 3 minutos expira con `travel_to`).

### Completion Notes List

- Task 0 (decisión de diseño): documentada y aplicada — se remueve el `rate_limit` nativo de Rails 8.1 (`ActionController::RateLimiting`, devuelve 302) en favor de Rack::Attack (devuelve 429 por defecto, pedido literalmente por AC1 y por nombre en `architecture.md`).
- Tasks 1-3: gem `rack-attack ~> 6.8` agregado (`Gemfile`/`Gemfile.lock`), `config/initializers/rack_attack.rb` creado con throttle `"logins/ip"` (10 intentos / 3 min sobre `POST /session`) + `throttled_response_retry_after_header = true`, línea `rate_limit` removida de `SessionsController` sin tocar el resto del controller.
- Task 4: `test/integration/rate_limiting_test.rb` creado con 3 tests (AC1: 429 al superar el límite; AC2: login normal dentro del límite sigue funcionando; AC3: el throttle es temporal, se libera tras la ventana) con override local de `Rack::Attack.cache.store` a `MemoryStore` en `setup`/`teardown` para evitar el `:null_store` global de test.
- Task 5: verificación completa — `bin/rails test test/integration/rate_limiting_test.rb` 3/3, `bin/rails test` 279/279 (276 base + 3 nuevos, sin regresiones), `test/system/` 3/3 (vía workaround de libs, ver Debug Log References), `bundle exec rubocop` 0 offenses, `bundle exec brakeman` 0 warnings, `bundle exec bundler-audit check --update` sin vulnerabilidades conocidas (incluye `rack-attack`).
- Las 3 AC quedan satisfechas: AC1 (429 vía Rack::Attack), AC2 (login normal sin falsos positivos, verificado en tests de integración y system tests), AC3 (bloqueo temporal, confirmado con `travel_to` más allá del `period`).

### File List

- `Gemfile` — agregado `gem "rack-attack", "~> 6.8"`.
- `Gemfile.lock` — regenerado por `bundle install` (agrega `rack-attack` y resuelve su dependencia `rack`, ya presente).
- `app/controllers/sessions_controller.rb` — removida la línea `rate_limit to: 10, within: 3.minutes, ...` (Task 0/3).
- `config/initializers/rack_attack.rb` — nuevo. Throttle `"logins/ip"` + `throttled_response_retry_after_header`.
- `test/integration/rate_limiting_test.rb` — nuevo. 3 tests de integración cubriendo AC1/AC2/AC3.

## Change Log

- 2026-06-24: Implementación completa de Tasks 1-5. Rack::Attack reemplaza el `rate_limit` nativo de Rails 8.1 en el login (Task 0, decisión documentada). Throttle por IP (10/3min) sobre `POST /session`, mismo umbral que el mecanismo removido. 3 tests de integración nuevos cubren las 3 AC. Verificación: `bin/rails test` 279/279, `test/system/` 3/3 (vía workaround de libs sin sudo para Chrome/ChromeDriver en este sandbox, mismo patrón que Story 6.1), `rubocop` 0 offenses, `brakeman` 0 warnings, `bundler-audit` sin vulnerabilidades. Status → `review`.
- 2026-06-24: Code review (3 capas: Blind Hunter, Edge Case Hunter, Acceptance Auditor). Acceptance Auditor confirmó 0 violaciones de AC (implementación verbatim contra el spec). 1 patch identificado (modo de archivo `100755` en los 2 archivos nuevos) — investigado y resuelto como falso positivo: el repo tiene `core.filemode=false`, Git ya indexa ambos archivos como `100644`; el `100755` era un artefacto de cómo se construyó el diff de revisión (`git diff --no-index`), no un problema real. 16 hallazgos descartados como ruido (mayormente ya justificados explícitamente en Dev Notes de esta misma historia — throttle por IP, sin responder custom, cuenta todos los intentos, cache store en producción — o refutados empíricamente contra la suite verde de 279/279). 0 deferred. Status → `done`.

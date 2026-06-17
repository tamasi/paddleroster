---
story_id: "5.1"
story_key: "5-1-infraestructura-del-bot-de-whatsapp"
epic_id: "4"
title: "Infraestructura del Bot de WhatsApp"
status: "done"
last_updated: "2026-06-16"
baseline_commit: a47585d5335f49801cf8a7dff6ec86bf509f5975
---

# Story 5.1: Infraestructura del Bot de WhatsApp

**As a** Capitán,
**I want** que el Bot de WhatsApp esté conectado y responda a mensajes,
**So that** pueda interactuar con retroai desde WhatsApp sin instalar nada.

## Acceptance Criteria

- **AC1: Mensaje entrante → `whatsapp_inbox` + respuesta de bienvenida**
  - **Given** que `whatsapp-service` está conectado a un número de WhatsApp (vía QR/Baileys)
  - **When** un usuario envía cualquier mensaje al número del Bot
  - **Then** el mensaje queda registrado en `whatsapp_inbox` (phone E.164, raw_body texto plano) y el Bot responde con un mensaje de bienvenida/ayuda

- **AC2: Mensaje saliente en `whatsapp_outbox` → entregado en segundos (NFR-1)**
  - **Given** un mensaje saliente generado desde Rails insertado en `whatsapp_outbox` con `status = 'pending'`
  - **When** el outbox-poller del servicio Node detecta el mensaje (≤3 segundos)
  - **Then** `whatsapp-service` lo entrega al destinatario vía Baileys y actualiza el `status` a `'sent'`

- **AC3: Desconexión de WhatsApp → alerta Telegram (`SendWhatsappAlertJob`)**
  - **Given** que `whatsapp-service` pierde la conexión con WhatsApp
  - **When** esto ocurre (evento `connection === 'close'` de Baileys, no loggedOut)
  - **Then** se inserta un registro en `whatsapp_inbox` con `phone = 'SYSTEM'` y `raw_body = 'BOT_DISCONNECTED'`, que `ProcessWhatsappInboxJob` detecta y traduce en un `SendWhatsappAlertJob`

- **AC4: Mensaje en `whatsapp_inbox` → `ProcessWhatsappInboxJob` asíncrono (Solid Queue)**
  - **Given** un mensaje entrante en `whatsapp_inbox` con `processed = false`
  - **When** el job recurrente `ProcessWhatsappInboxJob` corre (cada 5 segundos en producción)
  - **Then** el mensaje queda marcado `processed = true` (el routing real de comandos llega en Story 5.2)

## Tasks / Subtasks

### Task 1: Migraciones y Modelos Rails
- [x] T1.1: Crear migración `create_whatsapp_outbox` — tabla compartida Rails/Node con contrato de arquitectura
- [x] T1.2: Crear migración `create_whatsapp_inbox` — tabla compartida Rails/Node
- [x] T1.3: Modelo `WhatsappOutboxMessage` (tabla `whatsapp_outbox`) con validaciones y scope
- [x] T1.4: Modelo `WhatsappInboxMessage` (tabla `whatsapp_inbox`) con validaciones y scope
- [x] T1.5: Correr `bin/rails db:migrate` y verificar schema

### Task 2: Jobs Solid Queue
- [x] T2.1: Crear `ProcessWhatsappInboxJob` — procesa `whatsapp_inbox` no procesados, detecta SYSTEM alerts
- [x] T2.2: Crear `SendWhatsappAlertJob` — envía alerta a Telegram vía Bot API (Net::HTTP)
- [x] T2.3: Agregar `ProcessWhatsappInboxJob` a `config/recurring.yml` (production + development)

### Task 3: Tests Rails
- [x] T3.1: Tests de modelos `WhatsappOutboxMessage` y `WhatsappInboxMessage`
- [x] T3.2: Tests de `ProcessWhatsappInboxJob`
- [x] T3.3: Tests de `SendWhatsappAlertJob`
- [x] T3.4: `bin/rails test` — 0 failures, 0 errors (regresión completa)
- [x] T3.5: `bin/rubocop` sobre `.rb` nuevos — 0 offenses

### Task 4: whatsapp-service — Baileys integration (Node/TypeScript)
- [x] T4.1: Agregar dependencias a `package.json`: `@whiskeysockets/baileys`, `@hapi/boom`, `qrcode-terminal`; devDep: `@types/pg`
- [x] T4.2: Actualizar `src/db.ts` — agregar helper `query()` para consultas parametrizadas
- [x] T4.3: Implementar `src/baileys-client.ts` — sesión, conexión, reconexión, exportar `getConnectionState()` y `sendMessage()`
- [x] T4.4: Implementar `src/inbox-writer.ts` — insertar en `whatsapp_inbox` al recibir mensaje de Baileys
- [x] T4.5: Implementar `src/outbox-poller.ts` — polling cada 2.5s, envío, actualización de status y retry_count
- [x] T4.6: Actualizar `src/health-server.ts` — incluir `connection` en el body del response
- [x] T4.7: Actualizar `src/index.ts` — inicializar Baileys + outbox-poller además del health server
- [x] T4.8: Agregar `whatsapp-service/session/` a `.gitignore`

### Task 5: Validación final
- [x] T5.1: `npm run build` en `whatsapp-service/` — 0 errores TypeScript
- [x] T5.2: `bin/rails test` — 193 tests, 590 assertions, 0 failures, 0 errors (superó baseline)
- [x] T5.3: `bin/rubocop` en archivos `.rb` nuevos — 0 offenses

---

## Dev Notes

### Contexto de arquitectura (CRÍTICO — no saltear)

**Contrato compartido Rails ↔ Node:**
La comunicación entre Rails y `whatsapp-service` ocurre EXCLUSIVAMENTE mediante tablas Postgres compartidas — NO hay HTTP entre servicios (architecture.md):
- `whatsapp_outbox`: Rails inserta, Node lee/actualiza
- `whatsapp_inbox`: Node inserta, Rails lee/actualiza
- `DATABASE_URL` en ambos servicios apunta al mismo Postgres

**Formato de teléfono:** Siempre E.164 en la DB (ej. `+5491155556666`). El servicio Node convierte a JID de Baileys quitando el `+` y añadiendo `@s.whatsapp.net`.

**Status strings en `whatsapp_outbox`:** `'pending'`, `'sent'`, `'failed'` son strings, NO enums numéricos de Rails. Esto es intencional para que ambos lenguajes los lean sin compartir un enum. En el modelo usar `validates :status, inclusion:` NO `enum :status`.

---

### Task 1 — Migraciones (detalles exactos)

**T1.1 — `create_whatsapp_outbox`:**
```ruby
create_table :whatsapp_outbox do |t|
  t.string  :phone,       null: false
  t.text    :body,        null: false
  t.string  :status,      null: false, default: "pending"
  t.integer :retry_count, null: false, default: 0
  t.timestamps
end
add_index :whatsapp_outbox, :status
```

**T1.2 — `create_whatsapp_inbox`:**
```ruby
create_table :whatsapp_inbox do |t|
  t.string  :phone,    null: false
  t.text    :raw_body, null: false
  t.boolean :processed, null: false, default: false
  t.timestamps
end
add_index :whatsapp_inbox, :processed
```

---

### Task 1 — Modelos Rails (detalles exactos)

**T1.3 — `app/models/whatsapp_outbox_message.rb`:**
```ruby
# frozen_string_literal: true
class WhatsappOutboxMessage < ApplicationRecord
  self.table_name = "whatsapp_outbox"

  VALID_STATUSES = %w[pending sent failed].freeze

  validates :phone, presence: true
  validates :body, presence: true
  validates :status, inclusion: { in: VALID_STATUSES }
  validates :retry_count, numericality: { greater_than_or_equal_to: 0 }

  scope :pending, -> { where(status: "pending") }
  scope :failed,  -> { where(status: "failed") }
end
```
**IMPORTANTE:** `self.table_name = "whatsapp_outbox"` es obligatorio — Rails inferiría `whatsapp_outbox_messages` por convención, pero la tabla se llama `whatsapp_outbox` para coincidir con el contrato de arquitectura (Node también la necesita con ese nombre exacto).

**T1.4 — `app/models/whatsapp_inbox_message.rb`:**
```ruby
# frozen_string_literal: true
class WhatsappInboxMessage < ApplicationRecord
  self.table_name = "whatsapp_inbox"

  validates :phone, presence: true
  validates :raw_body, presence: true

  scope :unprocessed, -> { where(processed: false) }
end
```

---

### Task 2 — Jobs (detalles exactos)

**T2.1 — `app/jobs/process_whatsapp_inbox_job.rb`:**
```ruby
# frozen_string_literal: true
class ProcessWhatsappInboxJob < ApplicationJob
  queue_as :default

  def perform
    WhatsappInboxMessage.unprocessed.order(created_at: :asc).find_each do |msg|
      process_message(msg)
    end
  end

  private

  def process_message(msg)
    if msg.phone == "SYSTEM" && msg.raw_body == "BOT_DISCONNECTED"
      SendWhatsappAlertJob.perform_later("Bot de WhatsApp desconectado — revisar el servicio.")
    end
    # Story 5.2 agrega aquí el routing de comandos reales
    msg.update!(processed: true)
  end
end
```

**T2.2 — `app/jobs/send_whatsapp_alert_job.rb`:**
```ruby
# frozen_string_literal: true
class SendWhatsappAlertJob < ApplicationJob
  queue_as :default

  def perform(message)
    token   = ENV["TELEGRAM_BOT_TOKEN"]
    chat_id = ENV["TELEGRAM_CHAT_ID"]

    unless token && chat_id
      Rails.logger.warn("SendWhatsappAlertJob: TELEGRAM_BOT_TOKEN o TELEGRAM_CHAT_ID no configurados — alerta no enviada")
      return
    end

    uri = URI("https://api.telegram.org/bot#{token}/sendMessage")
    Net::HTTP.post_form(uri, { chat_id: chat_id, text: "[retroai] #{message}" })
  end
end
```
Requiere `require "net/http"` si no está ya en autoload — verificar si falta (en Rails 8, `Net::HTTP` generalmente disponible en `Gemfile` via `uri` gem).

**T2.3 — `config/recurring.yml`:**
Agregar bajo `production:` Y también bajo una nueva key `development:`:
```yaml
# Agregar al bloque production: existente
production:
  clear_solid_queue_finished_jobs:  # (ya existente, no tocar)
    ...
  process_whatsapp_inbox:
    class: ProcessWhatsappInboxJob
    schedule: every 5 seconds
    queue: default

development:
  process_whatsapp_inbox:
    class: ProcessWhatsappInboxJob
    schedule: every 5 seconds
    queue: default
```

---

### Task 3 — Tests Rails (detalles)

**Baseline previo:** ~170 tests / ~552 assertions. Verificar que no baja.

**Fixtures necesarias:** Crear `test/fixtures/whatsapp_outbox_messages.yml` y `test/fixtures/whatsapp_inbox_messages.yml` para que `fixtures :all` no falle con tabla vacía.
```yaml
# test/fixtures/whatsapp_outbox_messages.yml
one:
  phone: "+5491155556666"
  body: "Hola capitán!"
  status: "pending"
  retry_count: 0

# test/fixtures/whatsapp_inbox_messages.yml
one:
  phone: "+5491155556666"
  raw_body: "Hola Bot"
  processed: false
```

**T3.1 — `test/models/whatsapp_outbox_message_test.rb`:**
```ruby
# frozen_string_literal: true
require "test_helper"
class WhatsappOutboxMessageTest < ActiveSupport::TestCase
  test "valid record" do
    msg = WhatsappOutboxMessage.new(phone: "+549111", body: "test", status: "pending")
    assert msg.valid?
  end
  test "phone required" do
    msg = WhatsappOutboxMessage.new(body: "test", status: "pending")
    assert_not msg.valid?
  end
  test "body required" do
    msg = WhatsappOutboxMessage.new(phone: "+549111", status: "pending")
    assert_not msg.valid?
  end
  test "status must be valid" do
    msg = WhatsappOutboxMessage.new(phone: "+549111", body: "test", status: "unknown")
    assert_not msg.valid?
  end
  test "pending scope returns only pending" do
    WhatsappOutboxMessage.create!(phone: "+1", body: "x", status: "sent")
    pending = WhatsappOutboxMessage.create!(phone: "+2", body: "x", status: "pending")
    assert_includes WhatsappOutboxMessage.pending, pending
  end
end
```

**T3.2 — `test/jobs/process_whatsapp_inbox_job_test.rb`:**
```ruby
# frozen_string_literal: true
require "test_helper"
class ProcessWhatsappInboxJobTest < ActiveSupport::TestCase
  test "marks unprocessed messages as processed" do
    msg = WhatsappInboxMessage.create!(phone: "+549111", raw_body: "Hola", processed: false)
    ProcessWhatsappInboxJob.new.perform
    assert msg.reload.processed
  end
  test "ignores already processed messages" do
    msg = WhatsappInboxMessage.create!(phone: "+549111", raw_body: "ya procesado", processed: true)
    ProcessWhatsappInboxJob.new.perform
    assert msg.reload.processed  # sigue true, no levanta error
  end
  test "BOT_DISCONNECTED message triggers SendWhatsappAlertJob" do
    WhatsappInboxMessage.create!(phone: "SYSTEM", raw_body: "BOT_DISCONNECTED", processed: false)
    assert_enqueued_with(job: SendWhatsappAlertJob) do
      ProcessWhatsappInboxJob.new.perform
    end
  end
end
```

**T3.3 — `test/jobs/send_whatsapp_alert_job_test.rb`:**
```ruby
# frozen_string_literal: true
require "test_helper"
class SendWhatsappAlertJobTest < ActiveSupport::TestCase
  test "silently logs warning when env vars missing" do
    # Sin TELEGRAM_BOT_TOKEN/CHAT_ID — no debe levantar excepción
    assert_nothing_raised do
      SendWhatsappAlertJob.new.perform("Test alert")
    end
  end
end
```
Para el test de que SÍ envía: requeriría mockear `Net::HTTP.post_form` — omitir en Story 5.1, está cubierto por el happy-path en integración real.

**Ejecutar Rubocop solo en `.rb`:**
```bash
bin/rubocop app/models/whatsapp_outbox_message.rb app/models/whatsapp_inbox_message.rb \
            app/jobs/process_whatsapp_inbox_job.rb app/jobs/send_whatsapp_alert_job.rb \
            test/models/whatsapp_outbox_message_test.rb test/models/whatsapp_inbox_message_test.rb \
            test/jobs/process_whatsapp_inbox_job_test.rb test/jobs/send_whatsapp_alert_job_test.rb
```
**NUNCA correr Rubocop en `.erb`** — parsea HTML como Ruby y da falsos positivos.

---

### Task 4 — whatsapp-service Baileys (detalles exactos)

#### T4.1 — Dependencias

Agregar a `package.json`:
```json
"dependencies": {
  "pg": "^8.13.1",
  "@whiskeysockets/baileys": "^6.7.16",
  "@hapi/boom": "^10.0.1",
  "qrcode-terminal": "^0.12.0"
},
"devDependencies": {
  "@types/node": "^22.10.0",
  "@types/pg": "^8.11.0",
  "@types/qrcode-terminal": "^0.12.2",
  "tsx": "^4.19.2",
  "typescript": "^5.7.2"
}
```
Correr `npm install` en `whatsapp-service/`.

**Nota sobre versiones:** Usar `^6.x` de Baileys — si falla, revisar en npmjs.com la versión estable actual de `@whiskeysockets/baileys`. La API de `makeWASocket` + `useMultiFileAuthState` es estable entre 6.x releases.

#### T4.2 — `src/db.ts` (UPDATE)

```typescript
import { Pool } from "pg";
import type { QueryResult, QueryResultRow } from "pg";

let pool: Pool | undefined;

export function getPool(): Pool {
  if (!pool) {
    pool = new Pool({ connectionString: process.env.DATABASE_URL });
  }
  return pool;
}

export async function query<T extends QueryResultRow = QueryResultRow>(
  sql: string,
  params?: unknown[]
): Promise<QueryResult<T>> {
  return getPool().query<T>(sql, params);
}
```

#### T4.3 — `src/baileys-client.ts` (IMPLEMENT)

```typescript
import makeWASocket, {
  DisconnectReason,
  useMultiFileAuthState,
  fetchLatestBaileysVersion,
  type WASocket,
} from "@whiskeysockets/baileys";
import { Boom } from "@hapi/boom";
import qrcode from "qrcode-terminal";
import { onIncomingMessage } from "./inbox-writer.js";
import { query } from "./db.js";

type ConnectionState = "open" | "close" | "connecting";

let connectionState: ConnectionState = "connecting";
let sock: WASocket | null = null;

export function getConnectionState(): ConnectionState {
  return connectionState;
}

export async function sendMessage(phone: string, body: string): Promise<void> {
  if (!sock || connectionState !== "open") {
    throw new Error("WhatsApp not connected");
  }
  const jid = phoneToJid(phone);
  await sock.sendMessage(jid, { text: body });
}

export async function connectToWhatsApp(): Promise<void> {
  const { state, saveCreds } = await useMultiFileAuthState("./session");
  const { version } = await fetchLatestBaileysVersion();

  sock = makeWASocket({
    version,
    auth: state,
    printQRInTerminal: false, // manejamos QR manualmente
    logger: makeSilentLogger(),
  });

  sock.ev.on("creds.update", saveCreds);

  sock.ev.on("connection.update", async (update) => {
    const { connection, lastDisconnect, qr } = update;

    if (qr) {
      console.log("\n📱 Escaneá este QR con WhatsApp para conectar el Bot:\n");
      qrcode.generate(qr, { small: true });
    }

    if (connection === "open") {
      connectionState = "open";
      console.log("✅ Bot de WhatsApp conectado.");
    }

    if (connection === "close") {
      connectionState = "close";
      const statusCode = (lastDisconnect?.error as Boom)?.output?.statusCode;
      const loggedOut = statusCode === DisconnectReason.loggedOut;

      if (loggedOut) {
        console.log("🚪 Bot desconectado permanentemente (logout). Escaneá el QR de nuevo.");
        // Notificar a Rails vía whatsapp_inbox para que SendWhatsappAlertJob se dispare
        await notifyDisconnect();
      } else {
        console.log("🔄 Conexión perdida, reconectando...");
        await notifyDisconnect();
        setTimeout(() => connectToWhatsApp(), 5_000);
      }
    }
  });

  sock.ev.on("messages.upsert", async ({ messages }) => {
    for (const msg of messages) {
      if (!msg.message || msg.key.fromMe) continue;
      const jid = msg.key.remoteJid;
      if (!jid || jid.endsWith("@g.us")) continue; // ignorar grupos por ahora

      const phone = jidToPhone(jid);
      const text =
        msg.message.conversation ??
        msg.message.extendedTextMessage?.text ??
        "";

      if (!text.trim()) continue;

      await onIncomingMessage(phone, text);

      // Respuesta de bienvenida — Story 5.2 reemplazará esto con routing real
      await sendMessage(phone, "¡Hola! Soy el Bot de retroai. Próximamente podré ayudarte a gestionar tu turno.");
    }
  });
}

async function notifyDisconnect(): Promise<void> {
  try {
    await query(
      "INSERT INTO whatsapp_inbox (phone, raw_body, processed, created_at, updated_at) VALUES ($1, $2, false, NOW(), NOW())",
      ["SYSTEM", "BOT_DISCONNECTED"]
    );
  } catch (err) {
    console.error("Error escribiendo BOT_DISCONNECTED en whatsapp_inbox:", err);
  }
}

function phoneToJid(phone: string): string {
  return `${phone.replace("+", "")}@s.whatsapp.net`;
}

function jidToPhone(jid: string): string {
  return `+${jid.replace("@s.whatsapp.net", "")}`;
}

function makeSilentLogger() {
  // Baileys loguea mucho por defecto — silenciar en producción
  const noop = () => {};
  return { level: "silent", trace: noop, debug: noop, info: noop, warn: noop, error: noop, fatal: noop, child: () => makeSilentLogger() } as any;
}
```

**Nota:** `makeWASocket` requiere el logger; si querés ver logs de Baileys en dev, reemplazá `makeSilentLogger()` con el logger de pino:
```typescript
import pino from "pino";
const logger = pino({ level: "warn" });
```
Para Story 5.1, silenciar es más limpio.

#### T4.4 — `src/inbox-writer.ts` (IMPLEMENT)

```typescript
import { query } from "./db.js";

export async function onIncomingMessage(phone: string, rawBody: string): Promise<void> {
  await query(
    "INSERT INTO whatsapp_inbox (phone, raw_body, processed, created_at, updated_at) VALUES ($1, $2, false, NOW(), NOW())",
    [phone, rawBody]
  );
  console.log(`📥 Mensaje de ${phone} registrado en whatsapp_inbox`);
}
```

#### T4.5 — `src/outbox-poller.ts` (IMPLEMENT)

```typescript
import { query } from "./db.js";
import { sendMessage, getConnectionState } from "./baileys-client.js";

const POLL_INTERVAL_MS = 2_500;
const MAX_RETRIES = 3;

interface OutboxRow {
  id: number;
  phone: string;
  body: string;
  retry_count: number;
}

async function pollOutbox(): Promise<void> {
  if (getConnectionState() !== "open") return; // no intentar enviar si no está conectado

  const result = await query<OutboxRow>(
    "SELECT id, phone, body, retry_count FROM whatsapp_outbox WHERE status = 'pending' ORDER BY created_at ASC LIMIT 10"
  );

  for (const row of result.rows) {
    try {
      await sendMessage(row.phone, row.body);
      await query(
        "UPDATE whatsapp_outbox SET status = 'sent', updated_at = NOW() WHERE id = $1",
        [row.id]
      );
      console.log(`📤 Mensaje ${row.id} enviado a ${row.phone}`);
    } catch (err) {
      const newRetryCount = row.retry_count + 1;
      const newStatus = newRetryCount >= MAX_RETRIES ? "failed" : "pending";
      await query(
        "UPDATE whatsapp_outbox SET status = $1, retry_count = $2, updated_at = NOW() WHERE id = $3",
        [newStatus, newRetryCount, row.id]
      );
      console.error(`❌ Error enviando mensaje ${row.id} (intento ${newRetryCount}):`, err);
    }
  }
}

export function startOutboxPoller(): void {
  setInterval(() => {
    pollOutbox().catch((err) => console.error("Error en pollOutbox:", err));
  }, POLL_INTERVAL_MS);
  console.log(`⏱  Outbox poller iniciado (intervalo: ${POLL_INTERVAL_MS}ms)`);
}
```

**Backoff:** La arquitectura describe 5s/30s/2min como backoff. La implementación actual usa MAX_RETRIES=3 con reintentos inmediatos en el próximo poll. Para Story 5.1 esto es suficiente; backoff con delay se puede refinar en Stories posteriores si la latencia lo requiere.

#### T4.6 — `src/health-server.ts` (UPDATE)

```typescript
import { createServer, type Server } from "node:http";
import { getConnectionState } from "./baileys-client.js";

export function startHealthServer(port: number): Server {
  const server = createServer((req, res) => {
    if (req.method === "GET" && req.url === "/health") {
      const connection = getConnectionState();
      const status = connection === "open" ? "ok" : "degraded";
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ status, connection }));
      return;
    }

    res.writeHead(404, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "not_found" }));
  });

  server.listen(port, () => {
    console.log(`whatsapp-service health server listening on port ${port}`);
  });

  return server;
}
```

**Problema de dependencia circular:** `health-server.ts` importa de `baileys-client.ts`. `baileys-client.ts` importa de `inbox-writer.ts` y `db.ts`. `index.ts` importa de todos. No hay ciclos siempre que `db.ts` y `inbox-writer.ts` no importen de `baileys-client.ts` — verificar que `inbox-writer.ts` solo importe de `db.ts`.

#### T4.7 — `src/index.ts` (UPDATE)

```typescript
import { startHealthServer } from "./health-server.js";
import { connectToWhatsApp } from "./baileys-client.js";
import { startOutboxPoller } from "./outbox-poller.js";

const port = Number(process.env.PORT ?? 3001);

startHealthServer(port);
startOutboxPoller();
connectToWhatsApp().catch((err) => {
  console.error("Error fatal iniciando WhatsApp:", err);
  process.exit(1);
});
```

#### T4.8 — `.gitignore`

Agregar debajo de las líneas de `whatsapp-service`:
```
/whatsapp-service/session
```

---

### Gotchas conocidos y decisiones de diseño

1. **`self.table_name` obligatorio en ambos modelos:** Rails convertiría `WhatsappOutboxMessage` en `whatsapp_outbox_messages` — la tabla del contrato es `whatsapp_outbox`. Sin este override la migración crearía la tabla correcta pero el modelo la buscaría con nombre incorrecto.

2. **Status como string, no enum:** Resistir la tentación de usar `enum :status, { pending: 0, sent: 1, failed: 2 }`. El Node.js querying `WHERE status = 'pending'` necesita strings. Un enum Rails guarda integers en la columna.

3. **QR scan en primera ejecución:** Correr `npm run dev` en la carpeta `whatsapp-service/`. El QR aparece en la terminal. Abrir WhatsApp → Configuración → Dispositivos vinculados → Vincular dispositivo. La sesión queda en `whatsapp-service/session/` y se reutiliza en reinicios.

4. **`whatsapp-service/session/` en .gitignore:** Las credenciales de sesión de Baileys NO deben commitearse. La sesión contiene tokens de autenticación de WhatsApp.

5. **Módulo NodeNext en TypeScript:** Los imports DEBEN usar extensión `.js` aunque el archivo fuente sea `.ts`. Ej: `import { query } from "./db.js"` (NO `"./db"`). Ya establecido en Story 1.1.

6. **`ProcessWhatsappInboxJob` sin argumento:** A diferencia de `GenerateRecurringTurnosJob` que recibe `turno_id`, este job no recibe args — es un "sweeper" que procesa todo lo pendiente cada vez que corre. Compatible con el scheduling de Solid Queue.

7. **`assert_enqueued_with` en tests:** Requiere `include ActiveJob::TestHelper` o que el test hereda de `ActiveSupport::TestCase` con el helper ya disponible. Verificar que funciona; si no, usar `assert_performed_with`.

8. **`Net::HTTP` en `SendWhatsappAlertJob`:** Disponible sin require explícito en Rails 8 vía el gem `uri` autoloaded. Si el test falla por NameError, agregar `require "net/http"` en el job.

9. **Instalación de Baileys puede ser lenta:** `npm install @whiskeysockets/baileys` descarga muchas dependencias (incluye libsodium para E2E encryption). Tiempo estimado: 1-3 minutos.

10. **TypeScript strict mode:** `tsconfig.json` tiene `"strict": true`. El logger `as any` en `makeSilentLogger()` es la única excepción necesaria. Evitar otros `any`.

---

### Patrones del proyecto (de Story 4.1 y anteriores)

- `# frozen_string_literal: true` al tope de TODOS los archivos `.rb` nuevos
- Jobs: `class NombreJob < ApplicationJob` + `queue_as :default`
- Tests: `sign_in_as(users(:one))` para owner, `sign_in_as(users(:two))` para employee (no aplica a jobs, pero sí a controllers)
- No correr Rubocop en `.erb`
- No git push (no hay remote)
- Fixtures: `test/fixtures/` para cada tabla nueva (evita errores de `fixtures :all`)

---

### Resumen de archivos por AC

| AC | Archivos clave |
|----|----------------|
| AC1 | `baileys-client.ts` (ev messages.upsert), `inbox-writer.ts`, migración `whatsapp_inbox` |
| AC2 | `outbox-poller.ts`, migración `whatsapp_outbox`, `WhatsappOutboxMessage` model |
| AC3 | `baileys-client.ts` (connection close → INSERT SYSTEM), `ProcessWhatsappInboxJob`, `SendWhatsappAlertJob` |
| AC4 | `ProcessWhatsappInboxJob`, `config/recurring.yml`, `WhatsappInboxMessage` model |

---

## Dev Agent Record

### Implementation Plan
Rails side primero (migraciones → modelos → jobs → tests), luego Node.js (Baileys integration), validación final con build TS + suite Rails completa.

### Debug Log
- **Fixtures con timestamps faltantes:** Las tablas tienen `null: false` en `created_at`/`updated_at`, pero los fixture YAMLs iniciales no incluían esas columnas. Rubocop los rechazó al cargar fixtures. Solución: agregar timestamps explícitos a ambos fixtures.
- **Locale español en validaciones:** Los tests que usaban `assert_includes msg.errors[:phone], "can't be blank"` fallaban porque el locale es `:es` y devuelve `"no puede estar en blanco"`. Solución: cambiar a `assert msg.errors[:phone].present?`.
- **`format_amount` pre-existente eliminado:** `app/views/turnos/_payment_status_section.html.erb` y `card_turno_component.html.erb` llamaban a `format_amount` que había sido removido del helper en Story 4.1. Bloqueaba 9 tests. Solución: restaurar `format_amount` en `status_presentation_helper.rb` usando `number_to_currency`.
- **Rubocop en `.yml`:** Al incluir `config/recurring.yml` en el comando de Rubocop, falla con errores de sintaxis (parsea YAML como Ruby). Solución: excluir archivos `.yml` del comando.
- **npm audit — esbuild vuln:** Dependencia transitiva de Baileys tenía vulnerabilidad high en esbuild. Resuelto con `npm audit fix`.

### Completion Notes
- **Migraciones:** `whatsapp_outbox` y `whatsapp_inbox` creadas con índices en `status` y `processed` respectivamente. Ambas tablas usan `t.timestamps` para tener `created_at`/`updated_at`.
- **Modelos:** Ambos usan `self.table_name` para coincidir con el contrato de arquitectura. Status en outbox es string con `validates :status, inclusion:` (NO enum Rails).
- **Jobs:** `ProcessWhatsappInboxJob` es un "sweeper" sin args que procesa todos los mensajes pendientes. Detecta `phone == "SYSTEM"` para disparar alertas. `SendWhatsappAlertJob` falla silenciosamente sin env vars (seguro en dev/test).
- **Tests:** 23 tests nuevos (16 de modelos + 7 de jobs). Suite total: 193 tests / 590 assertions / 0 failures.
- **Node.js:** `baileys-client.ts` completo con QR display, reconexión automática, manejo de disconnect → notifica a Rails via `whatsapp_inbox`. `outbox-poller.ts` corre cada 2.5s con MAX_RETRIES=3. `health-server.ts` reporta estado de conexión Baileys. `npm run build` compila sin errores.
- **Fix pre-existente:** Restaurado `format_amount` en `status_presentation_helper.rb` — era un bug introducido en Story 4.1 que bloqueaba tests de Payments y CardTurnoComponent.

---

## File List

### NEW
- `db/migrate/20260616152758_create_whatsapp_outbox.rb`
- `db/migrate/20260616153001_create_whatsapp_inbox.rb`
- `app/models/whatsapp_outbox_message.rb`
- `app/models/whatsapp_inbox_message.rb`
- `app/jobs/process_whatsapp_inbox_job.rb`
- `app/jobs/send_whatsapp_alert_job.rb`
- `test/fixtures/whatsapp_outbox.yml`
- `test/fixtures/whatsapp_inbox.yml`
- `test/models/whatsapp_outbox_message_test.rb`
- `test/models/whatsapp_inbox_message_test.rb`
- `test/jobs/process_whatsapp_inbox_job_test.rb`
- `test/jobs/send_whatsapp_alert_job_test.rb`

### UPDATE
- `whatsapp-service/package.json`
- `whatsapp-service/package-lock.json`
- `whatsapp-service/src/db.ts`
- `whatsapp-service/src/baileys-client.ts`
- `whatsapp-service/src/inbox-writer.ts`
- `whatsapp-service/src/outbox-poller.ts`
- `whatsapp-service/src/health-server.ts`
- `whatsapp-service/src/index.ts`
- `config/recurring.yml`
- `db/schema.rb`
- `.gitignore`
- `app/helpers/status_presentation_helper.rb` (fix pre-existente: restaurado `format_amount`)

---

## Change Log

- 2026-06-16: Story 5.1 implementada — infraestructura del Bot de WhatsApp. Tablas `whatsapp_outbox`/`whatsapp_inbox`, modelos Rails, jobs Solid Queue (`ProcessWhatsappInboxJob`, `SendWhatsappAlertJob`), integración completa de Baileys en Node.js (QR, reconexión, inbox-writer, outbox-poller). 193 tests / 0 failures. Fix pre-existente de `format_amount`.

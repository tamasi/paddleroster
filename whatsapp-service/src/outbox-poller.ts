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
  if (getConnectionState() !== "open") return;

  const result = await query<OutboxRow>(
    "SELECT id, phone, body, retry_count FROM whatsapp_outbox WHERE status = 'pending' ORDER BY created_at ASC LIMIT 10 FOR UPDATE SKIP LOCKED"
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
      console.error(
        `❌ Error enviando mensaje ${row.id} (intento ${newRetryCount}):`,
        err
      );
    }
  }
}

export function startOutboxPoller(): void {
  setInterval(() => {
    pollOutbox().catch((err) => console.error("Error en pollOutbox:", err));
  }, POLL_INTERVAL_MS);
  console.log(`⏱  Outbox poller iniciado (intervalo: ${POLL_INTERVAL_MS}ms)`);
}

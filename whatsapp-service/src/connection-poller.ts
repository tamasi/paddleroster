import { query } from "./db.js";
import {
  connectToWhatsApp,
  disconnectWhatsApp,
  getConnectionState,
} from "./baileys-client.js";

const POLL_INTERVAL_MS = 2_500;

interface ConnectionRow {
  id: number;
  requested_action: "connect" | "disconnect";
}

let isPolling = false;

async function pollConnectionRequests(): Promise<void> {
  if (isPolling) return;

  isPolling = true;
  try {
    const result = await query<ConnectionRow>(
      "SELECT id, requested_action FROM whatsapp_connections WHERE requested_action IS NOT NULL LIMIT 1 FOR UPDATE SKIP LOCKED"
    );

    const row = result.rows[0];
    if (!row) return;

    await query(
      "UPDATE whatsapp_connections SET requested_action = NULL, updated_at = NOW() WHERE id = $1",
      [row.id]
    );

    if (row.requested_action === "connect" && getConnectionState() !== "open") {
      await connectToWhatsApp();
    } else if (row.requested_action === "disconnect") {
      await disconnectWhatsApp();
    }
  } catch (err) {
    console.error("Error en pollConnectionRequests:", err);
  } finally {
    isPolling = false;
  }
}

export function startConnectionPoller(): void {
  setInterval(() => {
    pollConnectionRequests().catch((err) =>
      console.error("Error en pollConnectionRequests:", err)
    );
  }, POLL_INTERVAL_MS);
  console.log(`⏱  Connection poller iniciado (intervalo: ${POLL_INTERVAL_MS}ms)`);
}

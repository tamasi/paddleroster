import { query } from "./db.js";

interface ConnectionStatusUpdate {
  status: "disconnected" | "connecting" | "connected";
  phone: string | null;
  qrCode: string | null;
}

export async function upsertConnectionStatus(
  update: ConnectionStatusUpdate
): Promise<void> {
  // INSERT ... SELECT ... ON CONFLICT en vez de un UPDATE puro: si el Bot arranca
  // antes de que el Dueño haya abierto Configuración alguna vez, todavía no existe
  // ninguna fila en whatsapp_connections — un UPDATE sería un no-op silencioso y el
  // primer QR se perdería. Este upsert crea la fila si falta (usando el único
  // Complejo del MVP) y la actualiza si ya existe, sin depender del orden de arranque.
  await query(
    `INSERT INTO whatsapp_connections (complejo_id, status, phone, qr_code, requested_action, created_at, updated_at)
     SELECT id, $1, $2, $3, NULL, NOW(), NOW() FROM complejos ORDER BY id ASC LIMIT 1
     ON CONFLICT (complejo_id) DO UPDATE SET
       status = EXCLUDED.status,
       phone = EXCLUDED.phone,
       qr_code = EXCLUDED.qr_code,
       requested_action = NULL,
       updated_at = NOW()`,
    [update.status, update.phone, update.qrCode]
  );
}

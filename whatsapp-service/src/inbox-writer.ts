import { query } from "./db.js";

export async function onIncomingMessage(phone: string, rawBody: string): Promise<void> {
  await query(
    "INSERT INTO whatsapp_inbox (phone, raw_body, processed, created_at, updated_at) VALUES ($1, $2, false, NOW(), NOW())",
    [phone, rawBody]
  );
  console.log(`📥 Mensaje de ${phone} registrado en whatsapp_inbox`);
}

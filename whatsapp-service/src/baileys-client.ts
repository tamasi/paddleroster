import makeWASocket, {
  DisconnectReason,
  useMultiFileAuthState,
  fetchLatestBaileysVersion,
  type WASocket,
} from "@whiskeysockets/baileys";
import { Boom } from "@hapi/boom";
import qrcodeTerminal from "qrcode-terminal";
import qrcodeImage from "qrcode";
import { onIncomingMessage } from "./inbox-writer.js";
import { query } from "./db.js";
import { upsertConnectionStatus } from "./connection-status.js";

type ConnectionState = "open" | "close" | "connecting";

let connectionState: ConnectionState = "connecting";
let sock: WASocket | null = null;

// Distinto del ConnectionState en memoria de arriba: evita disparar
// connectToWhatsApp() dos veces en paralelo si llega un segundo "connect"
// (vía requested_action) mientras un intento anterior sigue en curso.
let connectionInFlight = false;

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
  if (connectionInFlight) return;
  connectionInFlight = true;

  try {
    await connectToWhatsAppUnguarded();
  } catch (err) {
    connectionInFlight = false;
    throw err;
  }
}

async function connectToWhatsAppUnguarded(): Promise<void> {
  const { state, saveCreds } = await useMultiFileAuthState("./session");
  const { version } = await fetchLatestBaileysVersion();

  sock = makeWASocket({
    version,
    auth: state,
    printQRInTerminal: false,
    logger: makeSilentLogger(),
  });

  sock.ev.on("creds.update", saveCreds);

  sock.ev.on("connection.update", async (update) => {
    const { connection, lastDisconnect, qr } = update;

    if (qr) {
      console.log("\n📱 Escaneá este QR con WhatsApp para conectar el Bot:\n");
      qrcodeTerminal.generate(qr, { small: true });
      const dataUri = await qrcodeImage.toDataURL(qr);
      await upsertConnectionStatus({
        status: "connecting",
        phone: null,
        qrCode: dataUri,
      });
    }

    if (connection === "open") {
      connectionState = "open";
      connectionInFlight = false;
      console.log("✅ Bot de WhatsApp conectado.");
      await upsertConnectionStatus({
        status: "connected",
        phone: sock?.user?.id ? jidToPhone(sock.user.id) : null,
        qrCode: null,
      });
    }

    if (connection === "close") {
      connectionState = "close";
      const statusCode = (lastDisconnect?.error as Boom)?.output?.statusCode;
      const loggedOut = statusCode === DisconnectReason.loggedOut;

      if (loggedOut) {
        connectionInFlight = false;
        console.log(
          "🚪 Bot desconectado permanentemente (logout). Escaneá el QR de nuevo."
        );
        await upsertConnectionStatus({
          status: "disconnected",
          phone: null,
          qrCode: null,
        });
      } else {
        await notifyDisconnect();
        console.log("🔄 Conexión perdida, reconectando en 5 segundos...");
        setTimeout(() => {
          connectionInFlight = false;
          connectToWhatsApp().catch((err) =>
            console.error("Error reconectando:", err)
          );
        }, 5_000);
      }
    }
  });

  sock.ev.on("messages.upsert", async ({ messages }) => {
    for (const msg of messages) {
      if (!msg.message || msg.key.fromMe) continue;
      const jid = msg.key.remoteJid;
      // Ignorar mensajes de grupos por ahora (Story 5.2 maneja comandos específicos)
      if (!jid || jid.endsWith("@g.us")) continue;

      const phone = jidToPhone(jid);
      const text =
        msg.message.conversation ??
        msg.message.extendedTextMessage?.text ??
        "";

      if (!text.trim()) continue;

      await onIncomingMessage(phone, text);

      // Respuesta de bienvenida provisional — Story 5.2 implementa routing real
      await sendMessage(
        phone,
        "¡Hola! Soy el Bot de retroai. Próximamente podré ayudarte a gestionar tu turno."
      ).catch((err) => console.error("Error enviando bienvenida:", err));
    }
  });
}

export async function disconnectWhatsApp(): Promise<void> {
  if (!sock) return;

  try {
    await sock.logout();
  } catch (err) {
    console.error("Error al desconectar:", err);
  } finally {
    // Persistimos "disconnected" acá mismo en vez de depender únicamente del
    // evento connection.update (close/loggedOut) — si logout() falla o el
    // evento se demora, el clic en "Desconectar" del Dueño debe reflejarse
    // igual (AC4). El handler de connection.update lo vuelve a setear, idempotente.
    await upsertConnectionStatus({
      status: "disconnected",
      phone: null,
      qrCode: null,
    });
  }
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

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function makeSilentLogger(): any {
  const noop = (): void => {};
  return {
    level: "silent",
    trace: noop,
    debug: noop,
    info: noop,
    warn: noop,
    error: noop,
    fatal: noop,
    child: () => makeSilentLogger(),
  };
}

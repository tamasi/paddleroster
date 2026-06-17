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

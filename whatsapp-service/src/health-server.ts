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

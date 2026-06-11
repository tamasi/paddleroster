import { startHealthServer } from "./health-server.js";

const port = Number(process.env.PORT ?? 3001);

startHealthServer(port);

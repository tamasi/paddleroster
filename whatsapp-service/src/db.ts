import { Pool } from "pg";

let pool: Pool | undefined;

// Conexión compartida a Postgres (mismo esquema que Rails).
// No se usa todavía en esta story — preparada para outbox-poller/inbox-writer (Story 5.1).
export function getPool(): Pool {
  if (!pool) {
    pool = new Pool({ connectionString: process.env.DATABASE_URL });
  }

  return pool;
}

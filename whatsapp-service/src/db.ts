import { Pool } from "pg";
import type { QueryResult, QueryResultRow } from "pg";

let pool: Pool | undefined;

// Conexión compartida a Postgres (mismo esquema que Rails).
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
  return getPool().query<T>(sql, params as unknown[]);
}

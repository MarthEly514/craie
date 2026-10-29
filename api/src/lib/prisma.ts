import { PrismaClient } from '@prisma/client';

// Re-export the generated types (User, Role, ...) so the rest of the code imports from one place.
export * from '@prisma/client';

/** One client per process; `connectionString` is the PostgreSQL URL (Neon in production). */
export function createPrisma(connectionString: string): PrismaClient {
  return new PrismaClient({ datasources: { db: { url: connectionString } } });
}

import { buildApp } from './app.js';
import { loadEnv } from './config/env.js';
import { startMaintenanceJob } from './jobs/maintenance.js';
import { createPrisma } from './lib/prisma.js';

const env = loadEnv(); // throws (and stops the server) if a variable is missing
const prisma = createPrisma(env.DATABASE_URL);
const app = await buildApp({ env, prisma });

const stopJob = startMaintenanceJob(prisma, app.log);

// Render sends SIGTERM when it restarts or redeploys the service
for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, () => {
    stopJob();
    void app.close().then(() => process.exit(0));
  });
}

try {
  // 0.0.0.0 so that the hosting platform can reach the server
  await app.listen({ port: env.PORT, host: '0.0.0.0' });
} catch (error) {
  app.log.error(error);
  process.exit(1);
}

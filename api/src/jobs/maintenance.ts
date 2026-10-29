import type { FastifyBaseLogger } from 'fastify';
import type { PrismaClient } from '../lib/prisma.js';
import { expireReservations } from '../services/reservations.js';

const EVERY_MINUTE = 60_000;

/**
 * Background housekeeping, once a minute:
 *  - reservations whose end time has passed become "expired" (auto-release);
 *  - expired refresh tokens are deleted.
 * Lists already ignore finished reservations at read time, so this job only keeps the data tidy.
 */
export function startMaintenanceJob(prisma: PrismaClient, log: FastifyBaseLogger): () => void {
  const run = async () => {
    try {
      const expired = await expireReservations(prisma);
      await prisma.refreshToken.deleteMany({ where: { expiresAt: { lt: new Date() } } });
      if (expired > 0) log.info(`${expired} reservation(s) expired`);
    } catch (error) {
      log.error(error, 'maintenance job failed');
    }
  };

  void run();
  const timer = setInterval(run, EVERY_MINUTE);
  timer.unref(); // does not keep the process alive on its own
  return () => clearInterval(timer);
}

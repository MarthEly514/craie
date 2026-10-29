import type { Prisma, PrismaClient } from '../lib/prisma.js';

// Anything that can run queries: the client itself or a transaction.
type Db = PrismaClient | Prisma.TransactionClient;

/** Auto-release: reservations whose end time has passed are marked as expired. */
export async function expireReservations(db: Db, now = new Date()): Promise<number> {
  const { count } = await db.reservation.updateMany({
    where: { status: 'active', endAt: { lte: now } },
    data: { status: 'expired' },
  });
  return count;
}

/** Manual or automatic release (account suspended/deleted, resource deleted). */
export async function releaseActiveReservations(
  db: Db,
  where: Prisma.ReservationWhereInput,
  now = new Date(),
): Promise<number> {
  const { count } = await db.reservation.updateMany({
    where: { ...where, status: 'active' },
    data: { status: 'released', releasedAt: now },
  });
  return count;
}

/**
 * True when the error comes from the database exclusion constraint that forbids
 * two active reservations overlapping on the same resource (see the init migration).
 */
export function isOverlapError(error: unknown): boolean {
  const text = JSON.stringify(error, Object.getOwnPropertyNames(error as object));
  return text.includes('reservations_no_overlap') || text.includes('23P01');
}

// Time rules for reservations.
// Reservations are only allowed for "today" in the school's timezone.
// All dates are stored and exchanged in UTC; only this file knows about the local day.

/** Africa/Porto-Novo is UTC+1 all year (no daylight saving time). Change here if needed. */
export const TIMEZONE_OFFSET_MINUTES = 60;

export const MIN_SLOT_MINUTES = 30;

const MINUTE = 60_000;
const DAY = 24 * 60 * MINUTE;

/** Start (inclusive) and end (exclusive) of the local day containing `now`, as UTC instants. */
export function todayBounds(now: Date = new Date()): { start: Date; end: Date } {
  // Shift the clock so that UTC getters return the local wall-clock time
  const local = new Date(now.getTime() + TIMEZONE_OFFSET_MINUTES * MINUTE);
  const localMidnight = Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate());
  const start = new Date(localMidnight - TIMEZONE_OFFSET_MINUTES * MINUTE);
  return { start, end: new Date(start.getTime() + DAY) };
}

export type SlotError = { code: string; message: string };

/** Returns the first rule broken by this slot, or null when the slot is valid. */
export function validateSlot(startAt: Date, endAt: Date, now: Date = new Date()): SlotError | null {
  if (startAt.getTime() >= endAt.getTime()) {
    return {
      code: 'START_AFTER_END',
      message: "L'heure de début doit être antérieure à l'heure de fin",
    };
  }
  if ((endAt.getTime() - startAt.getTime()) / MINUTE < MIN_SLOT_MINUTES) {
    return {
      code: 'SLOT_TOO_SHORT',
      message: `Le créneau doit durer au moins ${MIN_SLOT_MINUTES} minutes`,
    };
  }
  const { start, end } = todayBounds(now);
  if (startAt < start || endAt > end) {
    return {
      code: 'SLOT_NOT_TODAY',
      message: "Les réservations sont possibles uniquement pour aujourd'hui",
    };
  }
  if (endAt <= now) {
    return { code: 'SLOT_IN_PAST', message: 'Ce créneau est déjà terminé' };
  }
  return null;
}

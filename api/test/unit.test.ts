import { describe, expect, it } from 'vitest';
import { loadEnv } from '../src/config/env.js';
import { generatePassword, hashToken, newRefreshToken } from '../src/lib/security.js';
import { todayBounds, validateSlot } from '../src/lib/time.js';

// 09:00 UTC = 10:00 in Benin (UTC+1)
const now = new Date('2026-10-28T09:00:00.000Z');
const at = (iso: string) => new Date(iso);

describe('todayBounds', () => {
  it('starts at local midnight (23:00 UTC the day before) and lasts 24 hours', () => {
    const { start, end } = todayBounds(now);
    expect(start.toISOString()).toBe('2026-10-27T23:00:00.000Z');
    expect(end.toISOString()).toBe('2026-10-28T23:00:00.000Z');
  });

  it('uses the local day, not the UTC day, late in the evening', () => {
    // 23:30 UTC on the 28th is already 00:30 on the 29th in Benin
    const { start } = todayBounds(at('2026-10-28T23:30:00.000Z'));
    expect(start.toISOString()).toBe('2026-10-28T23:00:00.000Z');
  });
});

describe('validateSlot', () => {
  it('accepts a normal slot today', () => {
    expect(validateSlot(at('2026-10-28T10:00:00Z'), at('2026-10-28T11:00:00Z'), now)).toBeNull();
  });

  it('accepts exactly 30 minutes', () => {
    expect(validateSlot(at('2026-10-28T10:00:00Z'), at('2026-10-28T10:30:00Z'), now)).toBeNull();
  });

  it('rejects a slot shorter than 30 minutes', () => {
    const error = validateSlot(at('2026-10-28T10:00:00Z'), at('2026-10-28T10:29:00Z'), now);
    expect(error?.code).toBe('SLOT_TOO_SHORT');
  });

  it('rejects a start that is not before the end', () => {
    const error = validateSlot(at('2026-10-28T11:00:00Z'), at('2026-10-28T10:00:00Z'), now);
    expect(error?.code).toBe('START_AFTER_END');
  });

  it('rejects another day', () => {
    const error = validateSlot(at('2026-10-29T10:00:00Z'), at('2026-10-29T11:00:00Z'), now);
    expect(error?.code).toBe('SLOT_NOT_TODAY');
  });

  it('rejects a slot that already ended', () => {
    const error = validateSlot(at('2026-10-28T07:00:00Z'), at('2026-10-28T08:00:00Z'), now);
    expect(error?.code).toBe('SLOT_IN_PAST');
  });

  it('accepts a slot that already started but is not over', () => {
    expect(validateSlot(at('2026-10-28T08:00:00Z'), at('2026-10-28T10:00:00Z'), now)).toBeNull();
  });
});

describe('security helpers', () => {
  it('generates passwords of the requested length without look-alike characters', () => {
    const password = generatePassword(12);
    expect(password).toHaveLength(12);
    expect(password).not.toMatch(/[0OIl1]/);
  });

  it('hashes refresh tokens deterministically and never stores the raw token', () => {
    const { token, hash } = newRefreshToken();
    expect(hash).toBe(hashToken(token));
    expect(hash).not.toContain(token);
  });
});

describe('loadEnv', () => {
  const valid = { DATABASE_URL: 'postgresql://x', JWT_SECRET: 'a'.repeat(32) };

  it('applies defaults', () => {
    const env = loadEnv(valid);
    expect(env.PORT).toBe(3000);
    expect(env.NODE_ENV).toBe('development');
  });

  it('refuses to start without JWT_SECRET', () => {
    expect(() => loadEnv({ DATABASE_URL: 'postgresql://x' })).toThrow(/JWT_SECRET/);
  });

  it('refuses a JWT_SECRET that is too short', () => {
    expect(() => loadEnv({ ...valid, JWT_SECRET: 'short' })).toThrow(/32/);
  });
});

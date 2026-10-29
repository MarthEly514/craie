import { createHash, randomBytes, randomInt } from 'node:crypto';
import argon2 from 'argon2';

export const hashPassword = (password: string) => argon2.hash(password);

export const verifyPassword = (hash: string, password: string) =>
  argon2.verify(hash, password).catch(() => false);

// Used when the identifier does not exist, so that the response time does not reveal it.
let dummyHash: Promise<string> | undefined;
export const getDummyHash = () => (dummyHash ??= argon2.hash('not-a-real-password'));

// No look-alike characters (0/O, 1/l/I) so that a password can be read out loud.
const ALPHABET = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export function generatePassword(length = 10): string {
  return Array.from({ length }, () => ALPHABET[randomInt(ALPHABET.length)]).join('');
}

/** Refresh tokens are random strings; only their hash is stored in the database. */
export const hashToken = (token: string) => createHash('sha256').update(token).digest('hex');

export function newRefreshToken(): { token: string; hash: string } {
  const token = randomBytes(48).toString('base64url');
  return { token, hash: hashToken(token) };
}

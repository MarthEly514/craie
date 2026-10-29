import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';
import { createPrisma } from '../src/lib/prisma.js';
import type { PrismaClient, Role } from '../src/lib/prisma.js';
import { hashPassword } from '../src/lib/security.js';

export const TEST_DATABASE_URL = process.env.TEST_DATABASE_URL;
export const hasDb = Boolean(TEST_DATABASE_URL);

export const PASSWORD = 'secret1234';

export type TestContext = { app: FastifyInstance; prisma: PrismaClient };

export async function createTestContext(loginRateLimit = 1000): Promise<TestContext> {
  const prisma = createPrisma(TEST_DATABASE_URL!);
  const app = await buildApp({
    prisma,
    logger: false,
    env: {
      NODE_ENV: 'test',
      PORT: 0,
      DATABASE_URL: TEST_DATABASE_URL!,
      JWT_SECRET: 'test-secret-test-secret-test-secret-123',
      CORS_ORIGIN: '*',
      LOGIN_RATE_LIMIT: loginRateLimit,
    },
  });
  await app.ready();
  return { app, prisma };
}

export async function resetDb(prisma: PrismaClient) {
  await prisma.$executeRawUnsafe(
    'TRUNCATE users, resources, reservations, refresh_tokens RESTART IDENTITY CASCADE',
  );
}

// Hashing is slow on purpose, so it is done once for all test users
let passwordHash: string | undefined;

export async function makeUser(
  prisma: PrismaClient,
  role: Role,
  identifier: string,
  extra: { fullName?: string; filiere?: string; status?: 'active' | 'suspended' } = {},
) {
  passwordHash ??= await hashPassword(PASSWORD);
  return prisma.user.create({
    data: {
      fullName: extra.fullName ?? identifier,
      identifier,
      role,
      filiere: extra.filiere ?? (role === 'responsable' ? 'IM-3' : undefined),
      status: extra.status,
      passwordHash,
    },
  });
}

export const makeRoom = (prisma: PrismaClient, name: string) =>
  prisma.resource.create({
    data: {
      name,
      type: 'room',
      zone: 'Zone master',
      location: 'Zogbadjè',
      amenities: ['Climatiseur'],
    },
  });

export const makeEquipment = (prisma: PrismaClient, name: string, isBroken = false) =>
  prisma.resource.create({
    data: { name, type: 'equipment', category: 'Projecteur', description: 'Test', isBroken },
  });

export async function login(app: FastifyInstance, identifier: string, password = PASSWORD) {
  const res = await app.inject({
    method: 'POST',
    url: '/api/v1/auth/login',
    payload: { identifier, password },
  });
  return { res, body: res.json() as { accessToken: string; refreshToken: string } };
}

/** Logs in and returns the Authorization header. */
export async function authHeader(app: FastifyInstance, identifier: string) {
  const { body } = await login(app, identifier);
  return { authorization: `Bearer ${body.accessToken}` };
}

// "Now" is frozen in the API tests: 09:00 UTC = 10:00 in Benin, far from midnight.
export const FIXED_NOW = new Date('2026-10-28T09:00:00.000Z');

/** A slot today, expressed as UTC hours, e.g. slot(10, 11) = 10:00Z to 11:00Z. */
export const slot = (fromHour: number, toHour: number) => ({
  startAt: `2026-10-28T${String(fromHour).padStart(2, '0')}:00:00.000Z`,
  endAt: `2026-10-28T${String(toHour).padStart(2, '0')}:00:00.000Z`,
});

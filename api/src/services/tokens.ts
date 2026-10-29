import type { FastifyInstance } from 'fastify';
import { ACCESS_TOKEN_TTL } from '../plugin/auth.js';
import { newRefreshToken } from '../lib/security.js';
import type { User } from '../lib/prisma.js';

export const REFRESH_TOKEN_DAYS = 7;

/** Creates a short-lived access token (JWT) and a long-lived refresh token (stored hashed). */
export async function issueTokens(app: FastifyInstance, user: User) {
  const accessToken = app.jwt.sign(
    { sub: user.id, role: user.role },
    { expiresIn: ACCESS_TOKEN_TTL },
  );

  const refresh = newRefreshToken();
  await app.prisma.refreshToken.create({
    data: {
      userId: user.id,
      tokenHash: refresh.hash,
      expiresAt: new Date(Date.now() + REFRESH_TOKEN_DAYS * 24 * 60 * 60 * 1000),
    },
  });

  return { accessToken, refreshToken: refresh.token };
}

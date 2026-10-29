import fastifyJwt from '@fastify/jwt';
import fp from 'fastify-plugin';
import type { FastifyRequest } from 'fastify';
import { AppError, forbidden, unauthorized } from '../lib/errors.js';
import type { Role, User } from '../lib/prisma.js';

export const ACCESS_TOKEN_TTL = '15m';

declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: { sub: string; role: Role };
    user: { sub: string; role: Role };
  }
}

declare module 'fastify' {
  interface FastifyInstance {
    /** preHandler: requires a valid token, and optionally one of the given roles. */
    auth: (...roles: Role[]) => (request: FastifyRequest) => Promise<void>;
  }
  interface FastifyRequest {
    /** The logged-in user, loaded from the database by `app.auth()`. */
    currentUser: User;
  }
}

export default fp<{ secret: string }>(async (app, opts) => {
  await app.register(fastifyJwt, { secret: opts.secret });
  app.decorateRequest('currentUser');

  app.decorate('auth', (...roles: Role[]) => async (request: FastifyRequest) => {
    try {
      await request.jwtVerify();
    } catch {
      throw unauthorized('Session expirée ou invalide');
    }

    // The user is read from the database on every request, so a suspended
    // or deleted account is locked out immediately, even with a valid token.
    const user = await app.prisma.user.findUnique({ where: { id: request.user.sub } });
    if (!user) throw unauthorized('Compte introuvable');
    if (user.status === 'suspended') {
      throw new AppError(401, 'ACCOUNT_SUSPENDED', 'Ce compte est suspendu');
    }
    if (roles.length > 0 && !roles.includes(user.role)) throw forbidden();

    request.currentUser = user;
  });
});

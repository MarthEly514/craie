import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import Fastify from 'fastify';
import type { Env } from './config/env.js';
import { AppError } from './lib/errors.js';
import type { PrismaClient } from './lib/prisma.js';
import authPlugin from './plugin/auth.js';
import prismaPlugin from './plugin/prisma.js';
import authRoutes from './routes/auth.js';
import reservationsRoutes from './routes/reservations.js';
import resourcesRoutes from './routes/resources.js';
import usersRoutes from './routes/users.js';

export const API_PREFIX = '/api/v1';

type BuildOptions = {
  env: Env;
  prisma: PrismaClient;
  logger?: boolean;
};

/**
 * Builds the Fastify application without starting it (server.ts starts it).
 * Keeping the two apart lets the tests call the API without opening a port.
 */
export async function buildApp({ env, prisma, logger = true }: BuildOptions) {
  const app = Fastify({
    logger: logger ? { level: env.NODE_ENV === 'production' ? 'info' : 'debug' } : false,
    trustProxy: true, // behind Render's proxy: use the real client IP (rate limit)
  });

  // Requests are validated with zod inside each route. The JSON schemas declared on the
  // routes only feed the documentation, so Fastify's own validation is switched off.
  app.setValidatorCompiler(() => (data) => ({ value: data }));

  // Every error leaves the API as { code, message } with a message in French.
  // Declared before the routes: a route only inherits handlers that already exist.
  app.setErrorHandler((error: Error & { statusCode?: number }, request, reply) => {
    if (error instanceof AppError) {
      return reply.code(error.statusCode).send({ code: error.code, message: error.message });
    }
    if (error.statusCode === 429) {
      return reply
        .code(429)
        .send({ code: 'RATE_LIMITED', message: 'Trop de tentatives. Réessayez dans une minute.' });
    }
    if (error.statusCode && error.statusCode < 500) {
      return reply.code(400).send({ code: 'BAD_REQUEST', message: 'Requête invalide' });
    }
    request.log.error(error);
    return reply
      .code(500)
      .send({ code: 'INTERNAL_ERROR', message: 'Erreur interne du serveur. Réessayez plus tard.' });
  });

  app.setNotFoundHandler((_request, reply) =>
    reply.code(404).send({ code: 'NOT_FOUND', message: 'Route introuvable' }),
  );

  await app.register(swagger, {
    openapi: {
      info: {
        title: 'Craie API',
        description: 'Gestion des salles et du matériel : comptes, ressources, réservations.',
        version: '1.0.0',
      },
      components: {
        securitySchemes: { bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' } },
      },
    },
  });
  await app.register(swaggerUi, { routePrefix: '/docs' });

  await app.register(cors, {
    origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(','),
  });
  await app.register(rateLimit, { global: false }); // enabled per route (login)

  await app.register(prismaPlugin, { prisma });
  await app.register(authPlugin, { secret: env.JWT_SECRET });

  // Used by Render's health check and by the uptime pinger
  app.get('/health', { schema: { tags: ['System'], summary: 'Le serveur répond' } }, async () => ({
    ok: true,
  }));

  await app.register(
    async (api) => {
      await api.register(authRoutes, { loginRateLimit: env.LOGIN_RATE_LIMIT });
      await api.register(usersRoutes);
      await api.register(resourcesRoutes);
      await api.register(reservationsRoutes);
    },
    { prefix: API_PREFIX },
  );

  return app;
}

import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { AppError, parse, unauthorized } from '../lib/errors.js';
import { getDummyHash, hashToken, verifyPassword } from '../lib/security.js';
import { toUserDto } from '../lib/serializers.js';
import { issueTokens } from '../services/tokens.js';

const loginBody = z.object({
  identifier: z.string().trim().min(1),
  password: z.string().min(1),
});

const tokenBody = z.object({ refreshToken: z.string().min(1) });

const tokensResponse = {
  type: 'object',
  properties: { accessToken: { type: 'string' }, refreshToken: { type: 'string' } },
};

const authRoutes: FastifyPluginAsync<{ loginRateLimit: number }> = async (app, opts) => {
  app.post(
    '/auth/login',
    {
      // Slows down password guessing: max attempts per IP per minute
      config: { rateLimit: { max: opts.loginRateLimit, timeWindow: '1 minute' } },
      schema: {
        tags: ['Auth'],
        summary: 'Connexion (identifiant + mot de passe)',
        body: {
          type: 'object',
          required: ['identifier', 'password'],
          properties: { identifier: { type: 'string' }, password: { type: 'string' } },
        },
      },
    },
    async (request) => {
      const { identifier, password } = parse(loginBody, request.body);

      const user = await app.prisma.user.findUnique({ where: { identifier } });
      // Always run one password check, even for an unknown identifier (same response time)
      const valid = await verifyPassword(user?.passwordHash ?? (await getDummyHash()), password);
      if (!user || !valid) {
        throw new AppError(401, 'INVALID_CREDENTIALS', 'Identifiant ou mot de passe incorrect');
      }
      if (user.status === 'suspended') {
        throw new AppError(
          403,
          'ACCOUNT_SUSPENDED',
          "Ce compte est suspendu. Contactez l'administrateur.",
        );
      }

      const tokens = await issueTokens(app, user);
      return { ...tokens, user: toUserDto(user) };
    },
  );

  // Rotation: each refresh token works once and is replaced by a new pair.
  app.post(
    '/auth/refresh',
    {
      schema: {
        tags: ['Auth'],
        summary: 'Échange un refresh token contre une nouvelle paire de jetons',
        body: {
          type: 'object',
          required: ['refreshToken'],
          properties: { refreshToken: { type: 'string' } },
        },
        response: { 200: tokensResponse },
      },
    },
    async (request) => {
      const { refreshToken } = parse(tokenBody, request.body);
      const stored = await app.prisma.refreshToken.findUnique({
        where: { tokenHash: hashToken(refreshToken) },
        include: { user: true },
      });
      const invalid = () =>
        new AppError(401, 'INVALID_REFRESH_TOKEN', 'Session expirée, reconnectez-vous');

      if (!stored) throw invalid();

      // A token that was already used is presented again: it may have been stolen,
      // so every session of this user is closed.
      if (stored.revokedAt) {
        await app.prisma.refreshToken.updateMany({
          where: { userId: stored.userId, revokedAt: null },
          data: { revokedAt: new Date() },
        });
        throw invalid();
      }
      if (stored.expiresAt <= new Date()) throw invalid();
      if (stored.user.status === 'suspended') {
        throw new AppError(401, 'ACCOUNT_SUSPENDED', 'Ce compte est suspendu');
      }

      // Revoke only if nobody else did in the meantime (two refreshes at the same time)
      const { count } = await app.prisma.refreshToken.updateMany({
        where: { id: stored.id, revokedAt: null },
        data: { revokedAt: new Date() },
      });
      if (count !== 1) throw invalid();

      return issueTokens(app, stored.user);
    },
  );

  app.post(
    '/auth/logout',
    {
      schema: {
        tags: ['Auth'],
        summary: 'Déconnexion : invalide le refresh token',
        body: {
          type: 'object',
          required: ['refreshToken'],
          properties: { refreshToken: { type: 'string' } },
        },
      },
    },
    async (request, reply) => {
      const { refreshToken } = parse(tokenBody, request.body);
      await app.prisma.refreshToken.updateMany({
        where: { tokenHash: hashToken(refreshToken), revokedAt: null },
        data: { revokedAt: new Date() },
      });
      return reply.code(204).send();
    },
  );

  app.get(
    '/me',
    {
      preHandler: app.auth(),
      schema: {
        tags: ['Auth'],
        summary: "Profil de l'utilisateur connecté",
        security: [{ bearerAuth: [] }],
      },
    },
    async (request) => {
      if (!request.currentUser) throw unauthorized();
      return toUserDto(request.currentUser);
    },
  );
};

export default authRoutes;

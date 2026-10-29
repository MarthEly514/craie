import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { AppError, notFound, parse } from '../lib/errors.js';
import type { Prisma } from '../lib/prisma.js';
import { generatePassword, hashPassword } from '../lib/security.js';
import { toUserDto } from '../lib/serializers.js';
import { releaseActiveReservations } from '../services/reservations.js';

const idParams = z.object({ id: z.uuid() });

const listQuery = z.object({
  role: z.enum(['admin', 'gestionnaire', 'responsable']).optional(),
  q: z.string().trim().optional(),
});

const createBody = z.object({
  fullName: z.string().trim().min(1).max(100),
  identifier: z.string().trim().min(1).max(100),
  password: z.string().min(4).max(100),
  // The admin only creates these two kinds of accounts
  role: z.enum(['gestionnaire', 'responsable']),
  filiere: z.string().trim().min(1).max(20).optional(),
  email: z.email().optional(),
});

// Role and identifier cannot be changed after creation
const updateBody = z
  .object({
    fullName: z.string().trim().min(1).max(100),
    filiere: z.string().trim().min(1).max(20),
    status: z.enum(['active', 'suspended']),
  })
  .partial()
  .strict();

const usersRoutes: FastifyPluginAsync = async (app) => {
  // Every route of this file is reserved to the administrator
  const adminOnly = app.auth('admin');
  const tag = ['Users'];
  const security = [{ bearerAuth: [] }];

  app.get(
    '/users',
    {
      preHandler: adminOnly,
      schema: { tags: tag, security, summary: 'Liste des comptes (filtres : role, q)' },
    },
    async (request) => {
      const { role, q } = parse(listQuery, request.query);
      const where: Prisma.UserWhereInput = {
        ...(role && { role }),
        ...(q && {
          OR: [
            { fullName: { contains: q, mode: 'insensitive' } },
            { identifier: { contains: q, mode: 'insensitive' } },
          ],
        }),
      };
      const users = await app.prisma.user.findMany({ where, orderBy: { fullName: 'asc' } });
      return users.map(toUserDto);
    },
  );

  // Fixed path: wins over "/users/:id" below
  app.get(
    '/users/generate-password',
    {
      preHandler: adminOnly,
      schema: { tags: tag, security, summary: 'Génère un mot de passe aléatoire' },
    },
    async () => ({ password: generatePassword() }),
  );

  app.get(
    '/users/:id',
    { preHandler: adminOnly, schema: { tags: tag, security, summary: "Détail d'un compte" } },
    async (request) => {
      const { id } = parse(idParams, request.params);
      const user = await app.prisma.user.findUnique({ where: { id } });
      if (!user) throw notFound('Compte introuvable');
      return toUserDto(user);
    },
  );

  app.post(
    '/users',
    {
      preHandler: adminOnly,
      schema: {
        tags: tag,
        security,
        summary: 'Crée un compte gestionnaire ou responsable',
        body: {
          type: 'object',
          required: ['fullName', 'identifier', 'password', 'role'],
          properties: {
            fullName: { type: 'string' },
            identifier: { type: 'string' },
            password: { type: 'string' },
            role: { type: 'string', enum: ['gestionnaire', 'responsable'] },
            filiere: {
              type: 'string',
              description: 'Obligatoire pour un responsable, interdit sinon',
            },
            email: { type: 'string' },
          },
        },
      },
    },
    async (request, reply) => {
      const body = parse(createBody, request.body);

      if (body.role === 'responsable' && !body.filiere) {
        throw new AppError(
          422,
          'FILIERE_REQUIRED',
          'La filière est obligatoire pour un responsable',
        );
      }
      if (body.role !== 'responsable' && body.filiere) {
        throw new AppError(422, 'FILIERE_NOT_ALLOWED', 'La filière est réservée aux responsables');
      }

      const existing = await app.prisma.user.findUnique({ where: { identifier: body.identifier } });
      if (existing) {
        throw new AppError(409, 'IDENTIFIER_TAKEN', 'Cet identifiant est déjà utilisé');
      }

      const user = await app.prisma.user.create({
        data: {
          fullName: body.fullName,
          identifier: body.identifier,
          email: body.email,
          passwordHash: await hashPassword(body.password),
          role: body.role,
          filiere: body.filiere,
        },
      });
      return reply.code(201).send(toUserDto(user));
    },
  );

  app.patch(
    '/users/:id',
    {
      preHandler: adminOnly,
      schema: {
        tags: tag,
        security,
        summary: 'Modifie le nom, la filière ou le statut (suspension / réactivation)',
        body: {
          type: 'object',
          properties: {
            fullName: { type: 'string' },
            filiere: { type: 'string' },
            status: { type: 'string', enum: ['active', 'suspended'] },
          },
        },
      },
    },
    async (request) => {
      const { id } = parse(idParams, request.params);
      const body = parse(updateBody, request.body);

      const user = await app.prisma.user.findUnique({ where: { id } });
      if (!user) throw notFound('Compte introuvable');

      if (body.filiere !== undefined && user.role !== 'responsable') {
        throw new AppError(422, 'FILIERE_NOT_ALLOWED', 'La filière est réservée aux responsables');
      }
      if (body.status === 'suspended' && user.role === 'admin') {
        throw new AppError(403, 'FORBIDDEN', 'Un compte administrateur ne peut pas être suspendu');
      }

      const updated = await app.prisma.$transaction(async (tx) => {
        const result = await tx.user.update({ where: { id }, data: body });
        if (body.status === 'suspended') {
          // A suspended account loses its reservations and its sessions
          await releaseActiveReservations(tx, { userId: id });
          await tx.refreshToken.updateMany({
            where: { userId: id, revokedAt: null },
            data: { revokedAt: new Date() },
          });
        }
        return result;
      });
      return toUserDto(updated);
    },
  );

  app.delete(
    '/users/:id',
    {
      preHandler: adminOnly,
      schema: { tags: tag, security, summary: "Supprime un compte (l'historique est conservé)" },
    },
    async (request, reply) => {
      const { id } = parse(idParams, request.params);
      const user = await app.prisma.user.findUnique({ where: { id } });
      if (!user) throw notFound('Compte introuvable');
      if (user.role === 'admin') {
        throw new AppError(403, 'FORBIDDEN', 'Un compte administrateur ne peut pas être supprimé');
      }

      await app.prisma.$transaction(async (tx) => {
        await releaseActiveReservations(tx, { userId: id });
        // Reservations keep user_name; their user_id becomes null (ON DELETE SET NULL)
        await tx.user.delete({ where: { id } });
      });
      return reply.code(204).send();
    },
  );
};

export default usersRoutes;

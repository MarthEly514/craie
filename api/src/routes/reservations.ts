import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { AppError, forbidden, notFound, parse } from '../lib/errors.js';
import type { Prisma } from '../lib/prisma.js';
import { toReservationDto } from '../lib/serializers.js';
import { validateSlot } from '../lib/time.js';
import { expireReservations, isOverlapError } from '../services/reservations.js';

const idParams = z.object({ id: z.uuid() });

const listQuery = z.object({
  filter: z.enum(['all', 'room', 'equipment']).default('all'),
  q: z.string().trim().optional(),
});

// ISO 8601 instants such as "2026-10-28T07:00:00.000Z", converted to Date
const instant = z.iso.datetime({ offset: true }).transform((value) => new Date(value));

const createBody = z.object({
  resourceId: z.uuid(),
  startAt: instant,
  endAt: instant,
  motif: z.string().trim().min(1).max(200),
  classe: z.string().trim().max(50).optional(),
});

const reservationsRoutes: FastifyPluginAsync = async (app) => {
  // The administrator has nothing to do with reservations
  const staff = app.auth('gestionnaire', 'responsable');
  const tags = ['Reservations'];
  const security = [{ bearerAuth: [] }];

  app.get(
    '/reservations',
    {
      preHandler: staff,
      schema: {
        tags,
        security,
        summary: 'Réservations en cours (un responsable ne voit que les siennes)',
      },
    },
    async (request) => {
      const { filter, q } = parse(listQuery, request.query);
      const user = request.currentUser;

      const where: Prisma.ReservationWhereInput = {
        status: 'active',
        // Read-time auto-release: a finished reservation is never shown, even before
        // the background job has marked it as expired
        endAt: { gt: new Date() },
        ...(user.role === 'responsable' && { userId: user.id }),
        ...(filter !== 'all' && { resource: { type: filter } }),
        ...(q && {
          OR: [
            { resource: { name: { contains: q, mode: 'insensitive' } } },
            { motif: { contains: q, mode: 'insensitive' } },
            { classe: { contains: q, mode: 'insensitive' } },
            { userName: { contains: q, mode: 'insensitive' } },
          ],
        }),
      };
      const reservations = await app.prisma.reservation.findMany({
        where,
        include: { resource: true },
        orderBy: { startAt: 'asc' },
      });
      return reservations.map(toReservationDto);
    },
  );

  app.post(
    '/reservations',
    {
      preHandler: staff,
      schema: {
        tags,
        security,
        summary: "Réserve une ressource pour un créneau d'aujourd'hui (30 min minimum)",
        body: {
          type: 'object',
          required: ['resourceId', 'startAt', 'endAt', 'motif'],
          properties: {
            resourceId: { type: 'string' },
            startAt: {
              type: 'string',
              description: 'ISO 8601, UTC (ex: 2026-10-28T07:00:00.000Z)',
            },
            endAt: { type: 'string', description: 'ISO 8601, UTC' },
            motif: { type: 'string' },
            classe: {
              type: 'string',
              description:
                'Obligatoire pour un gestionnaire ; ignoré pour un responsable (sa filière est utilisée)',
            },
          },
        },
      },
    },
    async (request, reply) => {
      const body = parse(createBody, request.body);
      const user = request.currentUser;

      // A responsable books for their own filière; a gestionnaire chooses the class
      const classe = user.role === 'responsable' ? (user.filiere ?? '') : (body.classe ?? '');
      if (user.role === 'gestionnaire' && !classe) {
        throw new AppError(422, 'CLASSE_REQUIRED', 'La classe est obligatoire');
      }

      const slotError = validateSlot(body.startAt, body.endAt);
      if (slotError) throw new AppError(422, slotError.code, slotError.message);

      const resource = await app.prisma.resource.findFirst({
        where: { id: body.resourceId, deletedAt: null },
      });
      if (!resource) throw notFound('Ressource introuvable');
      if (resource.isBroken) {
        throw new AppError(409, 'RESOURCE_BROKEN', 'Cette ressource est hors service');
      }

      // Finished reservations must not block a new one
      await expireReservations(app.prisma);

      try {
        const reservation = await app.prisma.reservation.create({
          data: {
            resourceId: resource.id,
            userId: user.id,
            userName: user.fullName,
            classe,
            motif: body.motif,
            startAt: body.startAt,
            endAt: body.endAt,
          },
          include: { resource: true },
        });
        return reply.code(201).send(toReservationDto(reservation));
      } catch (error) {
        // The database refuses overlapping slots, even when two requests arrive at the same time
        if (isOverlapError(error)) {
          throw new AppError(
            409,
            'SLOT_CONFLICT',
            'Ce créneau est déjà réservé pour cette ressource',
          );
        }
        throw error;
      }
    },
  );

  app.post(
    '/reservations/:id/release',
    {
      preHandler: staff,
      schema: { tags, security, summary: 'Libère une réservation (propriétaire ou gestionnaire)' },
    },
    async (request, reply) => {
      const { id } = parse(idParams, request.params);
      const user = request.currentUser;

      const reservation = await app.prisma.reservation.findUnique({ where: { id } });
      if (!reservation) throw notFound('Réservation introuvable');
      if (user.role === 'responsable' && reservation.userId !== user.id) throw forbidden();

      if (reservation.status !== 'active' || reservation.endAt <= new Date()) {
        throw new AppError(409, 'NOT_ACTIVE', "Cette réservation n'est plus active");
      }

      await app.prisma.reservation.update({
        where: { id },
        data: { status: 'released', releasedAt: new Date() },
      });
      return reply.code(204).send();
    },
  );
};

export default reservationsRoutes;

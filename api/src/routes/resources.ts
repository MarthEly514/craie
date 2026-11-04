import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { AppError, notFound, parse } from '../lib/errors.js';
import type { Prisma, Resource } from '../lib/prisma.js';
import { toResourceDto, type Booking } from '../lib/serializers.js';
import { releaseActiveReservations } from '../services/reservations.js';

const idParams = z.object({ id: z.uuid() });

// Time window for `todayBookings` (ISO dates). Default: from now, for 24 hours.
const windowQuery = z.object({
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
});

const listQuery = windowQuery.extend({
  type: z.enum(['room', 'equipment']).optional(),
  zone: z.string().trim().optional(),
  category: z.string().trim().optional(),
  q: z.string().trim().optional(),
});

const text = z.string().trim().min(1).max(200);

// A room and a piece of equipment have different fields
const createBody = z.discriminatedUnion('type', [
  z.object({
    type: z.literal('room'),
    name: text,
    zone: text,
    location: text,
    mapsUrl: z.string().trim().max(500).optional(),
    amenities: z.array(text).default([]),
  }),
  z.object({
    type: z.literal('equipment'),
    name: text,
    category: text,
    description: z.string().trim().max(500).optional(),
    isBroken: z.boolean().default(false),
  }),
]);

const updateBody = z
  .object({
    name: text,
    zone: text,
    location: text,
    mapsUrl: z.string().trim().max(500).nullable(),
    amenities: z.array(text),
    category: text,
    description: z.string().trim().max(500).nullable(),
    isBroken: z.boolean(),
  })
  .partial()
  .strict();

const ROOM_FIELDS = ['zone', 'location', 'mapsUrl', 'amenities'];
const EQUIPMENT_FIELDS = ['category', 'description', 'isBroken'];

const DAY_MS = 24 * 60 * 60 * 1000;
const MAX_WINDOW_MS = 7 * DAY_MS;

/** The window the app asks for (default: now → +24 h). Rejects empty or very long windows. */
function bookingWindow(query: { from?: Date; to?: Date }, now: Date) {
  const from = query.from ?? now;
  const to = query.to ?? new Date(from.getTime() + DAY_MS);
  const length = to.getTime() - from.getTime();
  if (length <= 0 || length > MAX_WINDOW_MS) {
    throw new AppError(
      422,
      'VALIDATION_ERROR',
      'Champ « to » invalide : il doit suivre « from » de 7 jours au maximum',
    );
  }
  return { from, to };
}

// Active reservations that have not ended yet. The lower bound is the earlier of `now` and
// `from`, so the same rows serve both `isTaken` and `todayBookings`.
const activeBookings = (now: Date, from: Date) =>
  ({
    where: {
      status: 'active',
      endAt: { gt: new Date(Math.min(now.getTime(), from.getTime())) },
    },
    select: { startAt: true, endAt: true },
    orderBy: { startAt: 'asc' },
  }) as const;

/**
 * - `isTaken`: the resource has an active reservation that has not ended yet (unchanged).
 * - `todayBookings`: the occupied slots overlapping [from, to]. No names or reasons, so
 *   a responsable can see when a room is busy without seeing who holds it.
 */
const toListDto = (
  r: Resource & { reservations: Booking[] },
  now: Date,
  window: { from: Date; to: Date },
) =>
  toResourceDto(
    r,
    r.reservations.some((b) => b.endAt > now),
    r.reservations.filter((b) => b.startAt < window.to && b.endAt > window.from),
  );

const resourcesRoutes: FastifyPluginAsync = async (app) => {
  const anyRole = app.auth(); // any logged-in user can look at resources
  const gestionnaireOnly = app.auth('gestionnaire');
  const tags = ['Resources'];
  const security = [{ bearerAuth: [] }];

  app.get(
    '/resources',
    {
      preHandler: anyRole,
      schema: {
        tags,
        security,
        summary:
          'Liste des salles et du matériel (filtres : type, zone, category, q). ' +
          '`from`/`to` bornent les créneaux occupés renvoyés dans `todayBookings`.',
      },
    },
    async (request) => {
      const { type, zone, category, q, from: qFrom, to: qTo } = parse(listQuery, request.query);
      const now = new Date();
      const window = bookingWindow({ from: qFrom, to: qTo }, now);
      const where: Prisma.ResourceWhereInput = {
        deletedAt: null,
        ...(type && { type }),
        ...(zone && { zone }),
        ...(category && { category }),
        ...(q && { name: { contains: q, mode: 'insensitive' } }),
      };
      const resources = await app.prisma.resource.findMany({
        where,
        orderBy: { name: 'asc' },
        include: { reservations: activeBookings(now, window.from) },
      });
      return resources.map((r) => toListDto(r, now, window));
    },
  );

  app.get(
    '/resources/:id',
    { preHandler: anyRole, schema: { tags, security, summary: "Détail d'une ressource" } },
    async (request) => {
      const { id } = parse(idParams, request.params);
      const now = new Date();
      const window = bookingWindow(parse(windowQuery, request.query), now);
      const resource = await app.prisma.resource.findFirst({
        where: { id, deletedAt: null },
        include: { reservations: activeBookings(now, window.from) },
      });
      if (!resource) throw notFound('Ressource introuvable');
      return toListDto(resource, now, window);
    },
  );

  app.post(
    '/resources',
    {
      preHandler: gestionnaireOnly,
      schema: {
        tags,
        security,
        summary: 'Crée une salle (type=room) ou un matériel (type=equipment)',
        body: {
          type: 'object',
          required: ['type', 'name'],
          properties: {
            type: { type: 'string', enum: ['room', 'equipment'] },
            name: { type: 'string' },
            zone: { type: 'string' },
            location: { type: 'string' },
            mapsUrl: { type: 'string' },
            amenities: { type: 'array', items: { type: 'string' } },
            category: { type: 'string' },
            description: { type: 'string' },
            isBroken: { type: 'boolean' },
          },
        },
      },
    },
    async (request, reply) => {
      const body = parse(createBody, request.body);
      const resource = await app.prisma.resource.create({ data: body });
      return reply.code(201).send(toResourceDto(resource, false, []));
    },
  );

  app.patch(
    '/resources/:id',
    {
      preHandler: gestionnaireOnly,
      schema: { tags, security, summary: 'Modifie une ressource (le type ne change pas)' },
    },
    async (request) => {
      const { id } = parse(idParams, request.params);
      const body = parse(updateBody, request.body);

      const current = await app.prisma.resource.findFirst({ where: { id, deletedAt: null } });
      if (!current) throw notFound('Ressource introuvable');

      // Refuse fields that do not exist for this kind of resource
      const forbiddenFields = current.type === 'room' ? EQUIPMENT_FIELDS : ROOM_FIELDS;
      const wrong = Object.keys(body).find((key) => forbiddenFields.includes(key));
      if (wrong) {
        throw new AppError(
          422,
          'VALIDATION_ERROR',
          `Le champ « ${wrong} » ne s'applique pas à ce type de ressource`,
        );
      }

      const now = new Date();
      const window = bookingWindow({}, now);
      const updated = await app.prisma.resource.update({
        where: { id },
        data: body,
        include: { reservations: activeBookings(now, window.from) },
      });
      return toListDto(updated, now, window);
    },
  );

  app.delete(
    '/resources/:id',
    {
      preHandler: gestionnaireOnly,
      schema: { tags, security, summary: 'Supprime une ressource et libère ses réservations' },
    },
    async (request, reply) => {
      const { id } = parse(idParams, request.params);
      const resource = await app.prisma.resource.findFirst({ where: { id, deletedAt: null } });
      if (!resource) throw notFound('Ressource introuvable');

      await app.prisma.$transaction(async (tx) => {
        await releaseActiveReservations(tx, { resourceId: id });
        // Soft delete: the row stays, so past reservations still point to it
        await tx.resource.update({ where: { id }, data: { deletedAt: new Date() } });
      });
      return reply.code(204).send();
    },
  );
};

export default resourcesRoutes;
import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { AppError, notFound, parse } from '../lib/errors.js';
import type { Prisma } from '../lib/prisma.js';
import { toResourceDto } from '../lib/serializers.js';
import { releaseActiveReservations } from '../services/reservations.js';

const idParams = z.object({ id: z.uuid() });

const listQuery = z.object({
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

// A resource is "taken" while it has an active reservation that has not ended yet
const takenFilter = (now: Date) =>
  ({ where: { status: 'active', endAt: { gt: now } }, select: { id: true }, take: 1 }) as const;

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
        summary: 'Liste des salles et du matériel (filtres : type, zone, category, q)',
      },
    },
    async (request) => {
      const { type, zone, category, q } = parse(listQuery, request.query);
      const now = new Date();
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
        include: { reservations: takenFilter(now) },
      });
      return resources.map((r) => toResourceDto(r, r.reservations.length > 0));
    },
  );

  app.get(
    '/resources/:id',
    { preHandler: anyRole, schema: { tags, security, summary: "Détail d'une ressource" } },
    async (request) => {
      const { id } = parse(idParams, request.params);
      const resource = await app.prisma.resource.findFirst({
        where: { id, deletedAt: null },
        include: { reservations: takenFilter(new Date()) },
      });
      if (!resource) throw notFound('Ressource introuvable');
      return toResourceDto(resource, resource.reservations.length > 0);
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
      return reply.code(201).send(toResourceDto(resource, false));
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

      const updated = await app.prisma.resource.update({
        where: { id },
        data: body,
        include: { reservations: takenFilter(new Date()) },
      });
      return toResourceDto(updated, updated.reservations.length > 0);
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

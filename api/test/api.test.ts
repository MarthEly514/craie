import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import {
  FIXED_NOW,
  PASSWORD,
  authHeader,
  createTestContext,
  hasDb,
  login,
  makeEquipment,
  makeRoom,
  makeUser,
  resetDb,
  slot,
  type TestContext,
} from './helpers.js';

// These tests need a real PostgreSQL (see README: TEST_DATABASE_URL).
describe.skipIf(!hasDb)('Craie API', () => {
  let ctx: TestContext;
  let app: TestContext['app'];
  let prisma: TestContext['prisma'];

  beforeAll(async () => {
    // Freeze only Date (not timers), so "today" is always the same day at 10:00 in Benin
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(FIXED_NOW);
    ctx = await createTestContext();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await app.close();
    vi.useRealTimers();
  });

  beforeEach(async () => {
    await resetDb(prisma);
    await makeUser(prisma, 'admin', 'admin');
    await makeUser(prisma, 'gestionnaire', 'seth@mail.com', { fullName: 'Seth' });
    await makeUser(prisma, 'responsable', '10080345', { fullName: 'Ariane', filiere: 'IM-3' });
    await makeUser(prisma, 'responsable', '10080346', { fullName: 'Miguel', filiere: 'IM-2' });
  });

  const book = async (who: string, resourceId: string, hours: [number, number], extra = {}) =>
    app.inject({
      method: 'POST',
      url: '/api/v1/reservations',
      headers: await authHeader(app, who),
      payload: { resourceId, ...slot(...hours), motif: 'Cours', ...extra },
    });

  describe('system and authentication', () => {
    it('answers /health', async () => {
      const res = await app.inject({ method: 'GET', url: '/health' });
      expect(res.statusCode).toBe(200);
      expect(res.json()).toEqual({ ok: true });
    });

    it('logs in and returns tokens and the user without any password', async () => {
      const { res, body } = await login(app, '10080345');
      expect(res.statusCode).toBe(200);
      expect(body.accessToken).toBeTruthy();
      expect(body.refreshToken).toBeTruthy();
      const user = (body as unknown as { user: Record<string, unknown> }).user;
      expect(user).toMatchObject({
        fullName: 'Ariane',
        role: 'responsable',
        filiere: 'IM-3',
        status: 'active',
      });
      expect(user).not.toHaveProperty('password');
      expect(user).not.toHaveProperty('passwordHash');
    });

    it('rejects a wrong password and an unknown identifier with the same error', async () => {
      const wrong = await login(app, '10080345', 'nope');
      const unknown = await login(app, 'ghost', PASSWORD);
      expect(wrong.res.statusCode).toBe(401);
      expect(unknown.res.statusCode).toBe(401);
      expect(wrong.res.json()).toEqual(unknown.res.json());
      expect(wrong.res.json().code).toBe('INVALID_CREDENTIALS');
    });

    it('refuses a suspended account at login', async () => {
      await makeUser(prisma, 'responsable', 'suspended1', { status: 'suspended' });
      const { res } = await login(app, 'suspended1');
      expect(res.statusCode).toBe(403);
      expect(res.json().code).toBe('ACCOUNT_SUSPENDED');
    });

    it('requires a token', async () => {
      const res = await app.inject({ method: 'GET', url: '/api/v1/me' });
      expect(res.statusCode).toBe(401);
      expect(res.json().code).toBe('UNAUTHORIZED');
    });

    it('locks out an account suspended after it logged in', async () => {
      const { body } = await login(app, '10080345');
      const user = await prisma.user.findUniqueOrThrow({ where: { identifier: '10080345' } });
      await app.inject({
        method: 'PATCH',
        url: `/api/v1/users/${user.id}`,
        headers: await authHeader(app, 'admin'),
        payload: { status: 'suspended' },
      });

      const me = await app.inject({
        method: 'GET',
        url: '/api/v1/me',
        headers: { authorization: `Bearer ${body.accessToken}` },
      });
      expect(me.statusCode).toBe(401);
      expect(me.json().code).toBe('ACCOUNT_SUSPENDED');

      const refresh = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/refresh',
        payload: { refreshToken: body.refreshToken },
      });
      expect(refresh.statusCode).toBe(401);
    });
  });

  describe('refresh token rotation', () => {
    const refresh = (refreshToken: string) =>
      app.inject({ method: 'POST', url: '/api/v1/auth/refresh', payload: { refreshToken } });

    it('returns a new pair and the old refresh token stops working', async () => {
      const { body } = await login(app, '10080345');

      const first = await refresh(body.refreshToken);
      expect(first.statusCode).toBe(200);
      const renewed = first.json();
      expect(renewed.refreshToken).not.toBe(body.refreshToken);

      const reused = await refresh(body.refreshToken);
      expect(reused.statusCode).toBe(401);
      expect(reused.json().code).toBe('INVALID_REFRESH_TOKEN');
    });

    it('closes every session when an old token is replayed', async () => {
      const { body } = await login(app, '10080345');
      const renewed = (await refresh(body.refreshToken)).json();

      await refresh(body.refreshToken); // replay of the used token
      const afterReplay = await refresh(renewed.refreshToken); // the new one is revoked too
      expect(afterReplay.statusCode).toBe(401);
    });

    it('rejects an unknown token and logs out', async () => {
      expect((await refresh('not-a-token')).statusCode).toBe(401);

      const { body } = await login(app, '10080345');
      const out = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/logout',
        payload: { refreshToken: body.refreshToken },
      });
      expect(out.statusCode).toBe(204);
      expect((await refresh(body.refreshToken)).statusCode).toBe(401);
    });
  });

  describe('role restrictions', () => {
    it('keeps account management for the admin', async () => {
      for (const who of ['seth@mail.com', '10080345']) {
        const res = await app.inject({
          method: 'GET',
          url: '/api/v1/users',
          headers: await authHeader(app, who),
        });
        expect(res.statusCode).toBe(403);
      }
      const ok = await app.inject({
        method: 'GET',
        url: '/api/v1/users',
        headers: await authHeader(app, 'admin'),
      });
      expect(ok.statusCode).toBe(200);
      expect(ok.json()).toHaveLength(4);
    });

    it('keeps resource management for the gestionnaire', async () => {
      const payload = { type: 'room', name: 'Salle X', zone: 'Zone master', location: 'Zogbadjè' };
      for (const who of ['10080345', 'admin']) {
        const res = await app.inject({
          method: 'POST',
          url: '/api/v1/resources',
          headers: await authHeader(app, who),
          payload,
        });
        expect(res.statusCode).toBe(403);
      }
      const ok = await app.inject({
        method: 'POST',
        url: '/api/v1/resources',
        headers: await authHeader(app, 'seth@mail.com'),
        payload,
      });
      expect(ok.statusCode).toBe(201);
      expect(ok.json()).toMatchObject({ name: 'Salle X', type: 'room', isTaken: false });
    });

    it('hides reservations from the admin', async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/reservations',
        headers: await authHeader(app, 'admin'),
      });
      expect(res.statusCode).toBe(403);
    });
  });

  describe('accounts (admin)', () => {
    const create = async (payload: object) =>
      app.inject({
        method: 'POST',
        url: '/api/v1/users',
        headers: await authHeader(app, 'admin'),
        payload,
      });

    it('creates a responsable without ever returning the password', async () => {
      const res = await create({
        fullName: 'Nouvelle Personne',
        identifier: '20250001',
        password: 'abcd1234',
        role: 'responsable',
        filiere: 'GL-2',
      });
      expect(res.statusCode).toBe(201);
      expect(res.json()).toMatchObject({
        fullName: 'Nouvelle Personne',
        role: 'responsable',
        filiere: 'GL-2',
      });
      expect(res.json()).not.toHaveProperty('password');
      expect(res.json()).not.toHaveProperty('passwordHash');
      expect((await login(app, '20250001', 'abcd1234')).res.statusCode).toBe(200);
    });

    it('applies the filière rules and rejects duplicates', async () => {
      const base = { fullName: 'X Y', password: 'abcd1234' };
      const noFiliere = await create({ ...base, identifier: 'a1', role: 'responsable' });
      expect(noFiliere.statusCode).toBe(422);
      const wrongRole = await create({
        ...base,
        identifier: 'a2',
        role: 'gestionnaire',
        filiere: 'IM-3',
      });
      expect(wrongRole.statusCode).toBe(422);
      const admin = await create({ ...base, identifier: 'a3', role: 'admin' });
      expect(admin.statusCode).toBe(422);
      const duplicate = await create({ ...base, identifier: '10080345', role: 'gestionnaire' });
      expect(duplicate.statusCode).toBe(409);
      expect(duplicate.json().code).toBe('IDENTIFIER_TAKEN');
    });

    it('updates name and filière but refuses a filière for a gestionnaire', async () => {
      const ariane = await prisma.user.findUniqueOrThrow({ where: { identifier: '10080345' } });
      const seth = await prisma.user.findUniqueOrThrow({ where: { identifier: 'seth@mail.com' } });
      const headers = await authHeader(app, 'admin');

      const ok = await app.inject({
        method: 'PATCH',
        url: `/api/v1/users/${ariane.id}`,
        headers,
        payload: { fullName: 'Ariane A.', filiere: 'SI-1' },
      });
      expect(ok.json()).toMatchObject({ fullName: 'Ariane A.', filiere: 'SI-1' });

      const bad = await app.inject({
        method: 'PATCH',
        url: `/api/v1/users/${seth.id}`,
        headers,
        payload: { filiere: 'SI-1' },
      });
      expect(bad.statusCode).toBe(422);
    });

    it('suspending an account releases its reservations; reactivating works', async () => {
      const room = await makeRoom(prisma, 'Salle A');
      expect((await book('10080345', room.id, [10, 11])).statusCode).toBe(201);
      const ariane = await prisma.user.findUniqueOrThrow({ where: { identifier: '10080345' } });
      const headers = await authHeader(app, 'admin');

      await app.inject({
        method: 'PATCH',
        url: `/api/v1/users/${ariane.id}`,
        headers,
        payload: { status: 'suspended' },
      });
      const reservation = await prisma.reservation.findFirstOrThrow({
        where: { resourceId: room.id },
      });
      expect(reservation.status).toBe('released');

      await app.inject({
        method: 'PATCH',
        url: `/api/v1/users/${ariane.id}`,
        headers,
        payload: { status: 'active' },
      });
      expect((await login(app, '10080345')).res.statusCode).toBe(200);
    });

    it('deleting an account releases its reservations but keeps the history', async () => {
      const room = await makeRoom(prisma, 'Salle A');
      await book('10080345', room.id, [10, 11]);
      const ariane = await prisma.user.findUniqueOrThrow({ where: { identifier: '10080345' } });

      const res = await app.inject({
        method: 'DELETE',
        url: `/api/v1/users/${ariane.id}`,
        headers: await authHeader(app, 'admin'),
      });
      expect(res.statusCode).toBe(204);

      const reservation = await prisma.reservation.findFirstOrThrow({
        where: { resourceId: room.id },
      });
      expect(reservation).toMatchObject({ status: 'released', userId: null, userName: 'Ariane' });
    });

    it('generates a password', async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/users/generate-password',
        headers: await authHeader(app, 'admin'),
      });
      expect(res.json().password).toHaveLength(10);
    });
  });

  describe('reservations', () => {
    it('books a slot and marks the resource as taken', async () => {
      const room = await makeRoom(prisma, 'Salle A');
      const res = await book('10080345', room.id, [10, 11]);
      expect(res.statusCode).toBe(201);
      expect(res.json()).toMatchObject({
        startAt: '2026-10-28T10:00:00.000Z',
        endAt: '2026-10-28T11:00:00.000Z',
        classe: 'IM-3', // a responsable books for their own filière
        userName: 'Ariane',
        resource: { id: room.id, name: 'Salle A', type: 'room' },
      });

      const list = await app.inject({
        method: 'GET',
        url: '/api/v1/resources',
        headers: await authHeader(app, '10080346'),
      });
      expect(list.json()[0]).toMatchObject({ name: 'Salle A', isTaken: true });
    });

    it('refuses an overlapping slot with 409 SLOT_CONFLICT', async () => {
      const room = await makeRoom(prisma, 'Salle A');
      await book('10080345', room.id, [10, 12]);
      const res = await book('10080346', room.id, [11, 13]);
      expect(res.statusCode).toBe(409);
      expect(res.json().code).toBe('SLOT_CONFLICT');
    });

    it('allows back-to-back slots and the same slot on another resource', async () => {
      const room = await makeRoom(prisma, 'Salle A');
      const other = await makeRoom(prisma, 'Salle B');
      expect((await book('10080345', room.id, [10, 11])).statusCode).toBe(201);
      expect((await book('10080346', room.id, [11, 12])).statusCode).toBe(201);
      expect((await book('10080346', other.id, [10, 11])).statusCode).toBe(201);
    });

    it('lets only one of several simultaneous requests win', async () => {
      const room = await makeRoom(prisma, 'Salle A');
      const results = await Promise.all([
        book('10080345', room.id, [10, 11]),
        book('10080346', room.id, [10, 11]),
        book('seth@mail.com', room.id, [10, 11], { classe: 'GL-1' }),
      ]);
      const codes = results.map((r) => r.statusCode).sort();
      expect(codes).toEqual([201, 409, 409]);
    });

    it('enforces the 30-minute minimum', async () => {
      const room = await makeRoom(prisma, 'Salle A');
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/reservations',
        headers: await authHeader(app, '10080345'),
        payload: {
          resourceId: room.id,
          startAt: '2026-10-28T10:00:00.000Z',
          endAt: '2026-10-28T10:20:00.000Z',
          motif: 'Cours',
        },
      });
      expect(res.statusCode).toBe(422);
      expect(res.json().code).toBe('SLOT_TOO_SHORT');
    });

    it('refuses an inverted slot, another day and a finished slot', async () => {
      const room = await makeRoom(prisma, 'Salle A');
      const post = async (startAt: string, endAt: string) =>
        app.inject({
          method: 'POST',
          url: '/api/v1/reservations',
          headers: await authHeader(app, '10080345'),
          payload: { resourceId: room.id, startAt, endAt, motif: 'Cours' },
        });

      expect((await post('2026-10-28T12:00:00.000Z', '2026-10-28T11:00:00.000Z')).json().code).toBe(
        'START_AFTER_END',
      );
      expect((await post('2026-10-29T10:00:00.000Z', '2026-10-29T11:00:00.000Z')).json().code).toBe(
        'SLOT_NOT_TODAY',
      );
      expect((await post('2026-10-28T07:00:00.000Z', '2026-10-28T08:00:00.000Z')).json().code).toBe(
        'SLOT_IN_PAST',
      );
    });

    it('refuses a broken resource and an unknown one', async () => {
      const broken = await makeEquipment(prisma, 'Projecteur HS', true);
      const res = await book('10080345', broken.id, [10, 11]);
      expect(res.statusCode).toBe(409);
      expect(res.json().code).toBe('RESOURCE_BROKEN');

      const missing = await book('10080345', '00000000-0000-4000-8000-000000000000', [10, 11]);
      expect(missing.statusCode).toBe(404);
    });

    it('requires a class when a gestionnaire books', async () => {
      const room = await makeRoom(prisma, 'Salle A');
      const without = await book('seth@mail.com', room.id, [10, 11]);
      expect(without.statusCode).toBe(422);
      const withClasse = await book('seth@mail.com', room.id, [10, 11], { classe: 'Licence 2 GL' });
      expect(withClasse.statusCode).toBe(201);
      expect(withClasse.json().classe).toBe('Licence 2 GL');
    });

    it('shows a responsable only their own reservations, and a gestionnaire all of them', async () => {
      const a = await makeRoom(prisma, 'Salle A');
      const b = await makeRoom(prisma, 'Salle B');
      await book('10080345', a.id, [10, 11]);
      await book('10080346', b.id, [10, 11]);

      const list = async (who: string, query = '') =>
        (
          await app.inject({
            method: 'GET',
            url: `/api/v1/reservations${query}`,
            headers: await authHeader(app, who),
          })
        ).json() as { userName: string; resource: { type: string } }[];

      expect((await list('10080345')).map((r) => r.userName)).toEqual(['Ariane']);
      expect((await list('10080346')).map((r) => r.userName)).toEqual(['Miguel']);
      expect(await list('seth@mail.com')).toHaveLength(2);
      expect(await list('seth@mail.com', '?filter=equipment')).toHaveLength(0);
      expect(await list('seth@mail.com', '?q=salle b')).toHaveLength(1);
    });

    it('does not list finished reservations, and they no longer block new ones', async () => {
      const room = await makeRoom(prisma, 'Salle A');
      const ariane = await prisma.user.findUniqueOrThrow({ where: { identifier: '10080345' } });
      // Finished at 08:30Z; the background job has not run yet (still "active")
      await prisma.reservation.create({
        data: {
          resourceId: room.id,
          userId: ariane.id,
          userName: 'Ariane',
          motif: 'Ancien cours',
          startAt: new Date('2026-10-28T08:00:00.000Z'),
          endAt: new Date('2026-10-28T08:30:00.000Z'),
        },
      });

      const list = await app.inject({
        method: 'GET',
        url: '/api/v1/reservations',
        headers: await authHeader(app, 'seth@mail.com'),
      });
      expect(list.json()).toHaveLength(0);

      // Starts at 08:15Z (already running) and overlaps the finished one
      const res = await book('10080346', room.id, [9, 10]);
      expect(res.statusCode).toBe(201);
    });

    it('lets the owner or a gestionnaire release, but not another responsable', async () => {
      const room = await makeRoom(prisma, 'Salle A');
      const created = (await book('10080345', room.id, [10, 11])).json();
      const release = async (who: string) =>
        app.inject({
          method: 'POST',
          url: `/api/v1/reservations/${created.id}/release`,
          headers: await authHeader(app, who),
        });

      expect((await release('10080346')).statusCode).toBe(403);
      expect((await release('10080345')).statusCode).toBe(204);
      expect((await release('seth@mail.com')).statusCode).toBe(409); // already released

      // The slot is free again
      expect((await book('10080346', room.id, [10, 11])).statusCode).toBe(201);
    });

    it("lets a gestionnaire release someone else's reservation", async () => {
      const room = await makeRoom(prisma, 'Salle A');
      const created = (await book('10080345', room.id, [10, 11])).json();
      const res = await app.inject({
        method: 'POST',
        url: `/api/v1/reservations/${created.id}/release`,
        headers: await authHeader(app, 'seth@mail.com'),
      });
      expect(res.statusCode).toBe(204);
    });
  });

  describe('resources', () => {
    it('hides a deleted resource and releases its reservations', async () => {
      const room = await makeRoom(prisma, 'Salle A');
      await book('10080345', room.id, [10, 11]);
      const headers = await authHeader(app, 'seth@mail.com');

      const del = await app.inject({
        method: 'DELETE',
        url: `/api/v1/resources/${room.id}`,
        headers,
      });
      expect(del.statusCode).toBe(204);

      const list = await app.inject({ method: 'GET', url: '/api/v1/resources', headers });
      expect(list.json()).toHaveLength(0);
      const detail = await app.inject({
        method: 'GET',
        url: `/api/v1/resources/${room.id}`,
        headers,
      });
      expect(detail.statusCode).toBe(404);

      const reservation = await prisma.reservation.findFirstOrThrow({
        where: { resourceId: room.id },
      });
      expect(reservation.status).toBe('released');
    });

    it('filters by type and refuses fields of the other type', async () => {
      const room = await makeRoom(prisma, 'Salle A');
      await makeEquipment(prisma, 'Projecteur 1');
      const headers = await authHeader(app, 'seth@mail.com');

      const rooms = await app.inject({
        method: 'GET',
        url: '/api/v1/resources?type=room',
        headers,
      });
      expect(rooms.json().map((r: { name: string }) => r.name)).toEqual(['Salle A']);

      const bad = await app.inject({
        method: 'PATCH',
        url: `/api/v1/resources/${room.id}`,
        headers,
        payload: { isBroken: true },
      });
      expect(bad.statusCode).toBe(422);
    });
  });

  describe('errors', () => {
    it('answers unknown routes and bad JSON with { code, message }', async () => {
      const missing = await app.inject({ method: 'GET', url: '/api/v1/nothing' });
      expect(missing.statusCode).toBe(404);
      expect(missing.json()).toMatchObject({ code: 'NOT_FOUND' });

      const invalid = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/login',
        payload: { identifier: '' },
      });
      expect(invalid.statusCode).toBe(422);
      expect(invalid.json().code).toBe('VALIDATION_ERROR');
    });

    it('always sends exactly { code, message }', async () => {
      const unauthorized = await app.inject({ method: 'GET', url: '/api/v1/me' });
      const forbidden = await app.inject({
        method: 'GET',
        url: '/api/v1/users',
        headers: await authHeader(app, '10080345'),
      });
      const badJson = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/login',
        headers: { 'content-type': 'application/json' },
        payload: '{bad',
      });
      for (const res of [unauthorized, forbidden, badJson]) {
        expect(Object.keys(res.json()).sort()).toEqual(['code', 'message']);
      }
    });

    it('limits login attempts per IP', async () => {
      const limited = await createTestContext(3);
      try {
        const attempt = () =>
          limited.app.inject({
            method: 'POST',
            url: '/api/v1/auth/login',
            payload: { identifier: 'ghost', password: 'nope' },
          });
        for (let i = 0; i < 3; i++) expect((await attempt()).statusCode).toBe(401);
        const blocked = await attempt();
        expect(blocked.statusCode).toBe(429);
        expect(blocked.json().code).toBe('RATE_LIMITED');
      } finally {
        await limited.app.close();
      }
    });
  });
});

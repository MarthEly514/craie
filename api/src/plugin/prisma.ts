import fp from 'fastify-plugin';
import type { PrismaClient } from '../lib/prisma.js';

declare module 'fastify' {
  interface FastifyInstance {
    prisma: PrismaClient;
  }
}

/** Makes `app.prisma` available everywhere and closes the connection when the app stops. */
export default fp<{ prisma: PrismaClient }>(async (app, opts) => {
  app.decorate('prisma', opts.prisma);
  app.addHook('onClose', async () => {
    await opts.prisma.$disconnect();
  });
});

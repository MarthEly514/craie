// Fills the database with the first admin account and (optionally) demo data.
//   npm run seed          (development, uses tsx)
//   npm run seed:prod     (after `npm run build`)
// Safe to run several times: existing rows are left untouched.
import 'dotenv/config';
import { createPrisma } from './lib/prisma.js';
import { hashPassword } from './lib/security.js';
import { todayBounds } from './lib/time.js';

const databaseUrl = process.env.DATABASE_URL;
const adminIdentifier = process.env.ADMIN_IDENTIFIER;
const adminPassword = process.env.ADMIN_PASSWORD;

if (!databaseUrl || !adminIdentifier || !adminPassword) {
  console.error('Missing DATABASE_URL, ADMIN_IDENTIFIER or ADMIN_PASSWORD in the environment.');
  process.exit(1);
}

// Demo data is on by default in development and off in production unless asked for.
const isProduction = process.env.NODE_ENV === 'production';
const withDemo = (process.env.SEED_DEMO ?? (isProduction ? 'false' : 'true')) === 'true';

// Demo accounts share one password. "1234" is only a development default.
const demoPassword = process.env.DEMO_PASSWORD ?? (isProduction ? undefined : '1234');
if (withDemo && !demoPassword) {
  console.error('SEED_DEMO=true in production requires DEMO_PASSWORD.');
  process.exit(1);
}

const prisma = createPrisma(databaseUrl);

async function seedUsers() {
  await prisma.user.upsert({
    where: { identifier: adminIdentifier! },
    update: {},
    create: {
      fullName: 'Administrateur',
      identifier: adminIdentifier!,
      passwordHash: await hashPassword(adminPassword!),
      role: 'admin',
    },
  });
  console.log(`Admin account ready (${adminIdentifier})`);
  if (!withDemo) return;

  const passwordHash = await hashPassword(demoPassword!);
  const demoUsers = [
    { fullName: 'Seth AKPLOGAN', identifier: 'seth@mail.com', role: 'gestionnaire' },
    {
      fullName: 'Roman KIKI',
      identifier: 'roman@mail.com',
      role: 'gestionnaire',
      status: 'suspended',
    },
    { fullName: 'Ariane ALIZEE', identifier: '10080345', role: 'responsable', filiere: 'IM-3' },
    { fullName: 'Miguel MIGAN', identifier: '10080346', role: 'responsable', filiere: 'IM-2' },
    { fullName: 'Logan SEN', identifier: '20240002', role: 'responsable', filiere: 'SI-2' },
    {
      fullName: 'Alvine PAGE',
      identifier: '20240004',
      role: 'responsable',
      filiere: 'GL-3',
      status: 'suspended',
    },
  ] as const;
  for (const user of demoUsers) {
    await prisma.user.upsert({
      where: { identifier: user.identifier },
      update: {},
      create: { ...user, passwordHash },
    });
  }
  console.log(`${demoUsers.length} demo users ready`);
}

async function seedResources() {
  const MAPS_URL = 'https://www.google.com/maps/@6.4167,2.3333,17z'; // approximate campus position
  const rooms = ['Salle A2-2', 'Salle A2-1', 'Salle G2', 'Salle F1', 'Salle F2'].map((name) => ({
    name,
    type: 'room' as const,
    zone: 'Zone master',
    location: 'Zogbadjè',
    mapsUrl: MAPS_URL,
    amenities: ['Climatiseur', 'Electricité'],
  }));
  const equipment = [
    ['Projecteur Acer514', 'Projecteur', 'Acer514-12V_610'],
    ['Rallonge_1', 'Rallonge', 'Rallonge 12m'],
    ['Projecteur EpsonP6', 'Projecteur', 'Epson P6-A58'],
    ['Rallonge_3', 'Rallonge', 'Rallonge 16m'],
    ['Projecteur EpsonP8', 'Projecteur', 'Projecteur Epson P8 12V 445Hz'],
    ['Projecteur EpsonC10', 'Projecteur', 'Epson C10-V12'],
    ['Rallonge_5', 'Rallonge', 'Rallonge 15m grise'],
  ].map(([name, category, description]) => ({
    name: name!,
    type: 'equipment' as const,
    category,
    description,
  }));

  for (const data of [...rooms, ...equipment]) {
    const exists = await prisma.resource.findFirst({ where: { name: data.name, deletedAt: null } });
    if (!exists) await prisma.resource.create({ data });
  }
  console.log(`${rooms.length + equipment.length} demo resources ready`);
}

async function seedReservations() {
  // Only on an empty table, so that running the seed again never creates duplicates
  if ((await prisma.reservation.count()) > 0) return;

  // Same as the Flutter demo: from 08:00 to 23:59 today (Benin time)
  const { start } = todayBounds();
  const startAt = new Date(start.getTime() + 8 * 60 * 60_000);
  const endAt = new Date(start.getTime() + (23 * 60 + 59) * 60_000);

  const holders = [
    {
      identifier: '10080345',
      classe: 'IM-3',
      resources: ['Salle A2-2', 'Projecteur EpsonC10', 'Rallonge_5'],
    },
    {
      identifier: 'seth@mail.com',
      classe: 'Licence 2 GL',
      resources: ['Salle F1', 'Salle F2', 'Projecteur EpsonP6', 'Rallonge_3'],
    },
  ];
  for (const holder of holders) {
    const user = await prisma.user.findUniqueOrThrow({ where: { identifier: holder.identifier } });
    for (const name of holder.resources) {
      const resource = await prisma.resource.findFirstOrThrow({ where: { name, deletedAt: null } });
      await prisma.reservation.create({
        data: {
          resourceId: resource.id,
          userId: user.id,
          userName: user.fullName,
          classe: holder.classe,
          motif: 'Cours de bases de donnees',
          startAt,
          endAt,
        },
      });
    }
  }
  console.log('Demo reservations created for today');
}

try {
  await seedUsers();
  if (withDemo) {
    await seedResources();
    await seedReservations();
  }
} finally {
  await prisma.$disconnect();
}

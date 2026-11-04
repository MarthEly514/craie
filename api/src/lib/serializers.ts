import type { Reservation, Resource, User } from './prisma.js';

// Shapes sent to the Flutter app. They match the fromJson() of the Dart models.
// The password hash is never part of any response.

export const toUserDto = (u: User) => ({
  id: u.id,
  fullName: u.fullName,
  identifier: u.identifier,
  email: u.email,
  role: u.role,
  filiere: u.filiere,
  status: u.status,
  mustChangePassword: u.mustChangePassword,
});

/** A time range during which a resource is occupied (no personal data: safe for every role). */
export type Booking = { startAt: Date; endAt: Date };

/**
 * `todayBookings` is only present when the caller passes the occupied slots (resource
 * list / detail). Without it the key is omitted, and the app treats that as "no slots".
 */
export const toResourceDto = (r: Resource, isTaken: boolean, todayBookings?: Booking[]) => ({
  id: r.id,
  name: r.name,
  type: r.type,
  zone: r.zone,
  location: r.location,
  mapsUrl: r.mapsUrl,
  amenities: r.amenities,
  category: r.category,
  description: r.description,
  isBroken: r.isBroken,
  isTaken,
  ...(todayBookings && {
    todayBookings: todayBookings.map((b) => ({
      startAt: b.startAt.toISOString(),
      endAt: b.endAt.toISOString(),
    })),
  }),
});

export const toReservationDto = (r: Reservation & { resource: Resource }) => ({
  id: r.id,
  // A reservation shown in a list is always an active one, so its resource is taken
  resource: toResourceDto(r.resource, true),
  startAt: r.startAt.toISOString(),
  endAt: r.endAt.toISOString(),
  motif: r.motif,
  classe: r.classe,
  userId: r.userId,
  userName: r.userName,
});
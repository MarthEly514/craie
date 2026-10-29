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

export const toResourceDto = (r: Resource, isTaken: boolean) => ({
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

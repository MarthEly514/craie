import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/time_slot.dart';

enum Availability { free, partial, full }

const minSlot = AppConstants.minSlot;

Availability computeAvailability(List<TimeSlot> occupied, DateTime now, DateTime dayEnd) {
  if (!now.isBefore(dayEnd)) return Availability.full; // closed for today

  // Nothing can start before opening time.
  final open = DateTime(now.year, now.month, now.day, AppConstants.openingHour);
  final from = now.isBefore(open) ? open : now;

  final upcoming = occupied.where((s) => s.end.isAfter(from));
  if (upcoming.isEmpty) return Availability.free;
  return freeSlots(occupied, from, dayEnd).isEmpty
      ? Availability.full
      : Availability.partial;
}

List<TimeSlot> freeSlots(List<TimeSlot> occupied, DateTime windowStart, DateTime dayEnd) {
  final sorted = occupied.where((s) => s.end.isAfter(windowStart)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));

  final free = <TimeSlot>[];
  var cursor = windowStart; // = max(now, opening time)

  for (final s in sorted) {
    if (!s.start.isBefore(dayEnd)) break;
    if (s.start.difference(cursor) >= minSlot) free.add(TimeSlot(cursor, s.start));
    if (s.end.isAfter(cursor)) cursor = s.end; // also copes with overlapping slots
  }
  if (dayEnd.difference(cursor) >= minSlot) free.add(TimeSlot(cursor, dayEnd));
  return free;
}
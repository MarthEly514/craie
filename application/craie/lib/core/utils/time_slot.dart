/// A reservation time slot (start/end).
class TimeSlot {
  final DateTime start;
  final DateTime end;

  const TimeSlot(this.start, this.end);

  /// True if both slots share any time; used to detect booking conflicts.
  bool overlaps(TimeSlot other) =>
      start.isBefore(other.end) && other.start.isBefore(end);
}

String formatHm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

const int minSlotMinutes = 30;

/// French error message when [start]..[end] is not a valid slot, else null.
String? validateSlot(DateTime start, DateTime end) {
  if (!start.isBefore(end)) {
    return 'L\'heure de début doit être antérieure à l\'heure de fin';
  }
  if (end.difference(start).inMinutes < minSlotMinutes) {
    return 'Le créneau doit durer au moins $minSlotMinutes minutes';
  }
  return null;
}

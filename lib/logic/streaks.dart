/// Pure streak and calendar-day logic for TaskNest.
///
/// Everything here works on **local calendar dates** (year/month/day
/// triples), never on UTC millisecond arithmetic. Dividing epoch millis by
/// 86,400,000 misplaces the day boundary for every timezone that isn't UTC
/// (and breaks around DST transitions); constructing `DateTime(y, m, d)`
/// lets Dart's calendar handle month/year rollover and DST for us.
///
/// All functions take `now` (or an explicit day) as a parameter so they can
/// be unit-tested with an injected clock.
library;

/// Strips the time-of-day, returning midnight local time on the same
/// calendar date.
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Whether [a] and [b] fall on the same local calendar date.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// The calendar day before [day]. `DateTime` normalises out-of-range values,
/// so month and year boundaries are handled correctly.
DateTime previousDay(DateTime day) =>
    DateTime(day.year, day.month, day.day - 1);

/// The calendar day after [day], with the same rollover guarantees as
/// [previousDay].
DateTime nextDay(DateTime day) => DateTime(day.year, day.month, day.day + 1);

/// Whether [completions] contains an entry on the same calendar day as [day].
bool isCompletedOn(Iterable<DateTime> completions, DateTime day) =>
    completions.any((c) => isSameDay(c, day));

/// The current streak length for a habit, given its completion history.
///
/// A streak is a run of consecutive local calendar days ending today. If the
/// habit hasn't been completed yet *today*, a run ending *yesterday* still
/// counts — the streak is alive until the day is actually missed. A gap of a
/// full calendar day resets the streak to zero.
///
/// Duplicate completions on the same day are collapsed, so completing a
/// habit twice never double-counts.
int currentStreak(Iterable<DateTime> completions, {required DateTime now}) {
  final days = completions.map(dateOnly).toSet();
  final today = dateOnly(now);

  var cursor = days.contains(today) ? today : previousDay(today);
  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = previousDay(cursor);
  }
  return streak;
}

/// The longest run of consecutive local calendar days anywhere in
/// [completions] — the habit's all-time personal best.
///
/// Unlike [currentStreak] this is independent of `now`: past runs still
/// count after the streak has been broken. Duplicate completions on the
/// same day are collapsed, and month/year boundaries are handled by the
/// calendar arithmetic in [nextDay].
int longestStreak(Iterable<DateTime> completions) {
  final days = completions.map(dateOnly).toSet();

  var longest = 0;
  for (final day in days) {
    if (days.contains(previousDay(day))) {
      continue; // Not the start of a run.
    }
    var cursor = day;
    var length = 0;
    while (days.contains(cursor)) {
      length++;
      cursor = nextDay(cursor);
    }
    if (length > longest) {
      longest = length;
    }
  }
  return longest;
}

/// Returns [completions] with [now]'s calendar day added.
///
/// Idempotent: completing the same day twice leaves the list unchanged.
List<DateTime> withCompletion(Iterable<DateTime> completions, DateTime now) {
  final normalized = completions.map(dateOnly).toSet()..add(dateOnly(now));
  return normalized.toList()..sort();
}

/// Returns [completions] with [now]'s calendar day removed (undo).
List<DateTime> withoutCompletion(
  Iterable<DateTime> completions,
  DateTime now,
) {
  final today = dateOnly(now);
  return completions
      .map(dateOnly)
      .toSet()
      .where((d) => d != today)
      .toList()
    ..sort();
}

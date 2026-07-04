import 'package:flutter_test/flutter_test.dart';
import 'package:tasknest/logic/streaks.dart';

void main() {
  group('currentStreak', () {
    test('increments across consecutive local calendar days', () {
      final now = DateTime(2026, 7, 4, 8, 30);
      final completions = [
        DateTime(2026, 7, 2, 21, 15), // two days ago, evening
        DateTime(2026, 7, 3, 6, 5), // yesterday, morning
        DateTime(2026, 7, 4, 8, 0), // today
      ];

      expect(currentStreak(completions, now: now), 3);
    });

    test('resets to zero after a missed day', () {
      final now = DateTime(2026, 7, 4, 12, 0);
      final completions = [
        DateTime(2026, 7, 1),
        DateTime(2026, 7, 2),
        // 3 July missed.
      ];

      expect(currentStreak(completions, now: now), 0);
    });

    test('same-day double completion does not double-count', () {
      final now = DateTime(2026, 7, 4, 22, 0);
      final completions = [
        DateTime(2026, 7, 3, 7, 0),
        DateTime(2026, 7, 4, 9, 0),
        DateTime(2026, 7, 4, 21, 30), // completed twice today
      ];

      expect(currentStreak(completions, now: now), 2);
    });

    test('streak survives today not being completed yet', () {
      // Completed yesterday and the day before, but it is still morning and
      // today's completion hasn't happened — the streak must not read 0.
      final now = DateTime(2026, 7, 4, 7, 0);
      final completions = [
        DateTime(2026, 7, 2),
        DateTime(2026, 7, 3),
      ];

      expect(currentStreak(completions, now: now), 2);
    });

    test('uses local calendar days, not 24-hour windows', () {
      // 23:50 one day and 00:10 the next are 20 minutes apart but land on
      // different calendar days — that is a 2-day streak.
      final now = DateTime(2026, 7, 4, 0, 15);
      final completions = [
        DateTime(2026, 7, 3, 23, 50),
        DateTime(2026, 7, 4, 0, 10),
      ];

      expect(currentStreak(completions, now: now), 2);
    });

    test('handles month and year boundaries', () {
      final now = DateTime(2027, 1, 1, 10, 0);
      final completions = [
        DateTime(2026, 12, 30),
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 1),
      ];

      expect(currentStreak(completions, now: now), 3);
    });

    test('is zero with no completions', () {
      expect(currentStreak(const [], now: DateTime(2026, 7, 4)), 0);
    });

    test('counts a long unbroken chain exactly once per day', () {
      // 100 consecutive days ending 2026-03-20, crossing a year boundary
      // and a (non-leap) February.
      final now = DateTime(2026, 3, 20, 23, 59);
      final completions = <DateTime>[];
      var day = dateOnly(now);
      for (var i = 0; i < 100; i++) {
        completions.add(day);
        day = previousDay(day);
      }

      expect(currentStreak(completions, now: now), 100);
    });
  });

  group('withCompletion', () {
    test('is idempotent for the same calendar day', () {
      final morning = DateTime(2026, 7, 4, 9, 0);
      final evening = DateTime(2026, 7, 4, 21, 0);

      final once = withCompletion(const [], morning);
      final twice = withCompletion(once, evening);

      expect(twice, hasLength(1));
      expect(twice.single, DateTime(2026, 7, 4));
    });

    test('normalises stored values to date-only midnight', () {
      final days = withCompletion(const [], DateTime(2026, 7, 4, 13, 37, 42));

      expect(days.single, DateTime(2026, 7, 4));
    });
  });

  group('withoutCompletion', () {
    test('removes only the given calendar day (undo)', () {
      final days = [
        DateTime(2026, 7, 3),
        DateTime(2026, 7, 4),
      ];

      final undone = withoutCompletion(days, DateTime(2026, 7, 4, 18, 0));

      expect(undone, [DateTime(2026, 7, 3)]);
    });
  });

  group('dateOnly / previousDay', () {
    test('dateOnly strips time but keeps the local date', () {
      expect(dateOnly(DateTime(2026, 7, 4, 23, 59, 59)), DateTime(2026, 7, 4));
      expect(dateOnly(DateTime(2026, 7, 4, 0, 0, 1)), DateTime(2026, 7, 4));
    });

    test('previousDay rolls over month and year boundaries', () {
      expect(previousDay(DateTime(2026, 3, 1)), DateTime(2026, 2, 28));
      expect(previousDay(DateTime(2027, 1, 1)), DateTime(2026, 12, 31));
    });
  });
}

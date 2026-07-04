import 'package:hive_ce/hive.dart';

import '../logic/streaks.dart' as streaks;

/// A recurring daily habit with a completion history.
///
/// [completedDays] holds one date-only `DateTime` per calendar day the habit
/// was completed. All streak math lives in `logic/streaks.dart` and is
/// delegated to from here, so it stays independently unit-testable.
class Habit extends HiveObject {
  Habit({
    required this.id,
    required this.name,
    List<DateTime>? completedDays,
    DateTime? createdAt,
  })  : completedDays = completedDays ?? <DateTime>[],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  List<DateTime> completedDays;
  final DateTime createdAt;

  /// Current streak length as of [now].
  int streak(DateTime now) => streaks.currentStreak(completedDays, now: now);

  /// Whether the habit has been completed on [now]'s calendar day.
  bool isDoneOn(DateTime now) => streaks.isCompletedOn(completedDays, now);

  /// Marks the habit completed (or not) for [now]'s calendar day.
  /// Completing an already-completed day is a no-op.
  void setDoneOn(DateTime now, {required bool done}) {
    completedDays = done
        ? streaks.withCompletion(completedDays, now)
        : streaks.withoutCompletion(completedDays, now);
  }
}

/// Hand-written Hive adapter for [Habit].
///
/// Field indices are part of the on-disk format: never reuse or reorder them,
/// only append.
class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 1;

  @override
  Habit read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      name: fields[1] as String,
      completedDays: (fields[2] as List).cast<DateTime>(),
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.completedDays)
      ..writeByte(3)
      ..write(obj.createdAt);
  }
}

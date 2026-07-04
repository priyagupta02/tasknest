import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/habit.dart';
import '../models/task.dart';

/// Central registry of Hive boxes.
///
/// [open] is awaited in `main()` before `runApp`, so every screen can assume
/// the boxes are already available — reads are synchronous and cold start
/// stays instant (no per-screen loading spinners).
class Boxes {
  Boxes._();

  static const _tasksBox = 'tasks';
  static const _habitsBox = 'habits';
  static const _settingsBox = 'settings';

  /// Settings keys.
  static const reminderEnabledKey = 'reminderEnabled';
  static const reminderHourKey = 'reminderHour';
  static const reminderMinuteKey = 'reminderMinute';

  static Future<void> open() async {
    await Hive.initFlutter();
    Hive
      ..registerAdapter(TaskAdapter())
      ..registerAdapter(HabitAdapter());
    await Future.wait([
      Hive.openBox<Task>(_tasksBox),
      Hive.openBox<Habit>(_habitsBox),
      Hive.openBox<dynamic>(_settingsBox),
    ]);
  }

  static Box<Task> get tasks => Hive.box<Task>(_tasksBox);
  static Box<Habit> get habits => Hive.box<Habit>(_habitsBox);
  static Box<dynamic> get settings => Hive.box<dynamic>(_settingsBox);
}

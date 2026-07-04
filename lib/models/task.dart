import 'package:hive_ce/hive.dart';

/// A single to-do item.
///
/// [dueDay] is stored as a date-only value (midnight, local time); pass it
/// through `dateOnly` from `logic/streaks.dart` before assigning so
/// comparisons stay calendar-based.
class Task extends HiveObject {
  Task({
    required this.id,
    required this.title,
    this.note,
    this.dueDay,
    this.done = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String title;
  String? note;
  DateTime? dueDay;
  bool done;
  final DateTime createdAt;
}

/// Hand-written Hive adapter for [Task].
///
/// Field indices are part of the on-disk format: never reuse or reorder them,
/// only append.
class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      note: fields[2] as String?,
      dueDay: fields[3] as DateTime?,
      done: fields[4] as bool,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.note)
      ..writeByte(3)
      ..write(obj.dueDay)
      ..writeByte(4)
      ..write(obj.done)
      ..writeByte(5)
      ..write(obj.createdAt);
  }
}

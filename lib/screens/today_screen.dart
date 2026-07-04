import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../data/boxes.dart';
import '../logic/streaks.dart';
import '../models/habit.dart';
import '../models/task.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/habit_tile.dart';
import '../widgets/progress_header.dart';
import '../widgets/task_tile.dart';

/// The main screen: today's habits and tasks with a progress header.
///
/// Rebuilds reactively off the Hive boxes via [ValueListenableBuilder], so
/// there is no extra state-management layer to keep in sync.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      floatingActionButton: FloatingActionButton(
        // Unique tag: the tab-switch animation can briefly have two screens
        // (and their FABs) in the tree at once.
        heroTag: 'fab-today',
        onPressed: () => showAddItemSheet(context),
        tooltip: 'Add task or habit',
        child: const Icon(Icons.add_rounded),
      ),
      body: ValueListenableBuilder(
        valueListenable: Boxes.tasks.listenable(),
        builder: (context, Box<Task> taskBox, _) => ValueListenableBuilder(
          valueListenable: Boxes.habits.listenable(),
          builder: (context, Box<Habit> habitBox, _) =>
              _buildBody(context, taskBox, habitBox),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Box<Task> taskBox,
    Box<Habit> habitBox,
  ) {
    final now = DateTime.now();
    final today = dateOnly(now);

    final habits = habitBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Today's plate: tasks due today, plus anything overdue and unfinished.
    final todayTasks = taskBox.values
        .where((t) =>
            t.dueDay != null &&
            (isSameDay(t.dueDay!, today) ||
                (!t.done && t.dueDay!.isBefore(today))))
        .toList()
      ..sort(_compareTasks);

    final doneCount = habits.where((h) => h.isDoneOn(now)).length +
        todayTasks.where((t) => t.done).length;
    final totalCount = habits.length + todayTasks.length;

    if (totalCount == 0) {
      return const EmptyState(
        icon: Icons.wb_sunny_outlined,
        title: 'Nothing on today\'s plate',
        message:
            'Tap + to add a task for today or start a daily habit streak.',
      );
    }

    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        Text(
          DateFormat('EEEE, d MMMM').format(now),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        ProgressHeader(done: doneCount, total: totalCount),
        if (habits.isNotEmpty) ...[
          _SectionHeader(
            title: 'Habits',
            trailing:
                '${habits.where((h) => h.isDoneOn(now)).length}/${habits.length}',
          ),
          for (final habit in habits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HabitTile(
                habit: habit,
                now: now,
                onToggleDone: (done) {
                  habit.setDoneOn(now, done: done);
                  habit.save();
                },
                onLongPress: () => _confirmDeleteHabit(context, habit),
              ),
            ),
        ],
        if (todayTasks.isNotEmpty) ...[
          const _SectionHeader(title: 'Tasks'),
          for (final task in todayTasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              // The done state is part of the key so that a swipe-completed
              // task comes back as a fresh element (Dismissible requires the
              // dismissed element to leave the tree).
              child: TaskTile(
                key: ValueKey('today-${task.id}-${task.done}'),
                task: task,
                onToggleDone: (done) {
                  task.done = done;
                  task.save();
                },
                onDismissComplete: () {
                  task.done = true;
                  task.save();
                },
                onDismissDelete: () => _deleteTask(context, task),
              ),
            ),
        ],
      ],
    );
  }

  int _compareTasks(Task a, Task b) {
    if (a.done != b.done) {
      return a.done ? 1 : -1; // Unfinished first.
    }
    final byDue = a.dueDay!.compareTo(b.dueDay!);
    if (byDue != 0) {
      return byDue;
    }
    return a.createdAt.compareTo(b.createdAt);
  }

  void _deleteTask(BuildContext context, Task task) {
    final messenger = ScaffoldMessenger.of(context);
    final title = task.title;
    task.delete();
    messenger.showSnackBar(
      SnackBar(content: Text('Deleted "$title"')),
    );
  }

  Future<void> _confirmDeleteHabit(BuildContext context, Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${habit.name}"?'),
        content: const Text(
          'This removes the habit and its whole streak history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await habit.delete();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

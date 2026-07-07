import 'package:flutter/material.dart';

import '../data/boxes.dart';
import '../models/task.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_tile.dart';

/// Every task, open ones first, backed by an [AnimatedList] so inserts and
/// removals slide in and out instead of popping.
class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late final List<Task> _tasks;

  static const _insertDuration = Duration(milliseconds: 300);
  static const _moveDuration = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _tasks = Boxes.tasks.values.toList()..sort(_compare);
  }

  /// Open tasks first, then by due day (undated last), then by creation.
  static int _compare(Task a, Task b) {
    if (a.done != b.done) {
      return a.done ? 1 : -1;
    }
    final aDue = a.dueDay;
    final bDue = b.dueDay;
    if (aDue == null || bDue == null) {
      if (aDue != bDue) {
        return aDue == null ? 1 : -1;
      }
    } else {
      final byDue = aDue.compareTo(bDue);
      if (byDue != 0) {
        return byDue;
      }
    }
    return a.createdAt.compareTo(b.createdAt);
  }

  /// Where [task] belongs in the sorted list.
  int _insertionIndexFor(Task task) {
    final index = _tasks.indexWhere((t) => _compare(task, t) < 0);
    return index == -1 ? _tasks.length : index;
  }

  Future<void> _addTask() async {
    final created = await showAddItemSheet(context, mode: AddItemMode.taskOnly);
    if (created is! Task || !mounted) {
      return;
    }
    final index = _insertionIndexFor(created);
    setState(() => _tasks.insert(index, created));
    _listKey.currentState?.insertItem(index, duration: _insertDuration);
  }

  void _toggleDone(Task task, bool done) {
    task.done = done;
    task.save();

    final from = _tasks.indexOf(task);
    _tasks.removeAt(from);
    final to = _insertionIndexFor(task);
    _tasks.insert(to, task);

    if (from != to) {
      // Animate the move: shrink out of the old slot, grow into the new one.
      _listKey.currentState?.removeItem(
        from,
        (context, animation) => _GhostSlot(animation: animation, task: task),
        duration: _moveDuration,
      );
      _listKey.currentState?.insertItem(to, duration: _moveDuration);
    }
    // Rebuild so everything derived from [_tasks] (the empty-state overlay,
    // the app-bar action) stays in sync with the new done state.
    setState(() {});
  }

  void _removeAt(int index, {required bool deleteFromBox}) {
    final task = _tasks.removeAt(index);
    // The Dismissible already animated the swipe-out, so remove instantly.
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => const SizedBox.shrink(),
      duration: Duration.zero,
    );
    if (deleteFromBox) {
      final title = task.title;
      task.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "$title"')),
      );
    }
    setState(() {});
  }

  void _completeAt(int index) {
    final task = _tasks[index];
    task.done = true;
    task.save();
    // Take it out of the swiped slot, then slide it down to its new home
    // among the completed tasks.
    _removeAt(index, deleteFromBox: false);
    final to = _insertionIndexFor(task);
    _tasks.insert(to, task);
    _listKey.currentState?.insertItem(to, duration: _insertDuration);
    setState(() {});
  }

  /// Deletes every completed task after a confirmation.
  ///
  /// Indices are removed highest-first so each index handed to
  /// [AnimatedListState.removeItem] is still valid after the removals above
  /// it; the outgoing tiles animate away as non-interactive [_GhostSlot]s,
  /// just like moves.
  Future<void> _clearCompleted() async {
    final messenger = ScaffoldMessenger.of(context);
    final count = _tasks.where((t) => t.done).length;
    final label = count == 1 ? '1 completed task' : '$count completed tasks';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear $label?'),
        content: const Text(
          'This permanently deletes them — open tasks are untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) {
      return;
    }

    setState(() {
      for (var i = _tasks.length - 1; i >= 0; i--) {
        final task = _tasks[i];
        if (!task.done) {
          continue;
        }
        _tasks.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) =>
              _GhostSlot(animation: animation, task: task),
          duration: _moveDuration,
        );
        task.delete();
      }
    });
    messenger.showSnackBar(SnackBar(content: Text('Cleared $label')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All tasks'),
        actions: [
          IconButton(
            onPressed: _tasks.any((t) => t.done) ? _clearCompleted : null,
            tooltip: 'Clear completed',
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-all-tasks',
        onPressed: _addTask,
        tooltip: 'Add task',
        child: const Icon(Icons.add_rounded),
      ),
      body: Stack(
        children: [
          AnimatedList(
            key: _listKey,
            initialItemCount: _tasks.length,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemBuilder: (context, index, animation) {
              final task = _tasks[index];
              return _AnimatedSlot(
                animation: animation,
                child: TaskTile(
                  key: ValueKey('all-${task.id}-${task.done}'),
                  task: task,
                  onToggleDone: (done) => _toggleDone(task, done),
                  onDismissComplete: () =>
                      _completeAt(_tasks.indexOf(task)),
                  onDismissDelete: () =>
                      _removeAt(_tasks.indexOf(task), deleteFromBox: true),
                ),
              );
            },
          ),
          if (_tasks.isEmpty)
            const EmptyState(
              icon: Icons.checklist_rounded,
              title: 'No tasks yet',
              message: 'Everything you add lands here — tap + to create one.',
            ),
        ],
      ),
    );
  }
}

/// Standard slide/fade/size wrapper for list items entering or leaving.
class _AnimatedSlot extends StatelessWidget {
  const _AnimatedSlot({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return SizeTransition(
      sizeFactor: curved,
      child: FadeTransition(
        opacity: curved,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: child,
        ),
      ),
    );
  }
}

/// Non-interactive stand-in rendered while an item animates out of its old
/// slot during a move (the real, interactive tile lives at the new index).
class _GhostSlot extends StatelessWidget {
  const _GhostSlot({required this.animation, required this.task});

  final Animation<double> animation;
  final Task task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: ListTile(
              leading: Icon(
                task.done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: scheme.outline,
              ),
              title: Text(
                task.title,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

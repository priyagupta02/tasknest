import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../logic/streaks.dart';
import '../models/task.dart';
import 'animated_check.dart';

/// A task row wrapped in a [Dismissible]:
/// swipe right to complete, swipe left to delete.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggleDone,
    required this.onDismissComplete,
    required this.onDismissDelete,
    this.onTap,
  });

  final Task task;
  final ValueChanged<bool> onToggleDone;

  /// Called after the tile is swiped away to the right.
  final VoidCallback onDismissComplete;

  /// Called after the tile is swiped away to the left.
  final VoidCallback onDismissDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey<String>('task-${task.id}'),
      direction: task.done
          ? DismissDirection.endToStart
          : DismissDirection.horizontal,
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: scheme.primary,
        icon: Icons.check_circle_rounded,
        label: 'Done',
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: scheme.error,
        icon: Icons.delete_rounded,
        label: 'Delete',
      ),
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          onDismissComplete();
        } else {
          onDismissDelete();
        }
      },
      child: Card(
        child: ListTile(
          onTap: onTap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: AnimatedCheck(checked: task.done, onChanged: onToggleDone),
          title: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: task.done ? scheme.onSurfaceVariant : scheme.onSurface,
              decoration: task.done
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
            child: Text(task.title),
          ),
          subtitle: _subtitle(context),
        ),
      ),
    );
  }

  Widget? _subtitle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final note = task.note;
    final dueDay = task.dueDay;
    if ((note == null || note.isEmpty) && dueDay == null) {
      return null;
    }

    final children = <Widget>[];
    if (dueDay != null) {
      final today = dateOnly(DateTime.now());
      final overdue = !task.done && dueDay.isBefore(today);
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_rounded,
              size: 14,
              color: overdue ? scheme.error : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _dueLabel(dueDay, today),
              style: TextStyle(
                fontSize: 12,
                color: overdue ? scheme.error : scheme.onSurfaceVariant,
                fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }
    if (note != null && note.isNotEmpty) {
      children.add(
        Text(
          note,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 2),
          children[i],
        ],
      ],
    );
  }

  String _dueLabel(DateTime dueDay, DateTime today) {
    if (isSameDay(dueDay, today)) {
      return 'Today';
    }
    if (isSameDay(dueDay, DateTime(today.year, today.month, today.day + 1))) {
      return 'Tomorrow';
    }
    if (isSameDay(dueDay, previousDay(today))) {
      return 'Yesterday';
    }
    return DateFormat('EEE, d MMM').format(dueDay);
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(color) ==
            Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: onColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: onColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

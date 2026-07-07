import 'package:flutter/material.dart';

import '../models/habit.dart';
import 'animated_check.dart';

/// A habit row with an animated check, a streak-flame counter and the
/// habit's all-time best streak.
class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.now,
    required this.onToggleDone,
    this.onLongPress,
  });

  final Habit habit;

  /// Injected so the tile renders consistently in tests and previews.
  final DateTime now;
  final ValueChanged<bool> onToggleDone;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = habit.isDoneOn(now);
    final streak = habit.streak(now);
    final best = habit.bestStreak();
    final subtitleStyle =
        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);

    return Card(
      child: ListTile(
        onLongPress: onLongPress,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: AnimatedCheck(checked: done, onChanged: onToggleDone),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: done ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
          child: Text(habit.name),
        ),
        subtitle: best > 1
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Every day', style: subtitleStyle),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 13,
                    color: scheme.outline,
                  ),
                  const SizedBox(width: 2),
                  Text('Best $best', style: subtitleStyle),
                ],
              )
            : Text('Every day', style: subtitleStyle),
        trailing: StreakBadge(streak: streak),
      ),
    );
  }
}

/// Flame + count pill. Grows slightly and warms up in colour while a streak
/// is alive.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = streak > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: active ? const Color(0xFFE25822) : scheme.outline,
          ),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              '$streak',
              key: ValueKey<int>(streak),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: active
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

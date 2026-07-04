import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/boxes.dart';
import '../logic/streaks.dart';
import '../models/habit.dart';
import '../models/task.dart';

/// What the add sheet is allowed to create.
enum AddItemMode { taskOnly, taskOrHabit }

/// Opens the bottom sheet for creating a task (and optionally a habit).
/// Returns the created object ([Task] or [Habit]), or null if cancelled.
Future<Object?> showAddItemSheet(
  BuildContext context, {
  AddItemMode mode = AddItemMode.taskOrHabit,
}) {
  return showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _AddItemSheet(mode: mode),
    ),
  );
}

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({required this.mode});

  final AddItemMode mode;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isHabit = false;
  DateTime? _dueDay;
  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _dueDay = dateOnly(DateTime.now());
    _titleController.addListener(() {
      final canSave = _titleController.text.trim().isNotEmpty;
      if (canSave != _canSave) {
        setState(() => _canSave = canSave);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.mode == AddItemMode.taskOrHabit) ...[
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Task'),
                  icon: Icon(Icons.check_circle_outline),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Habit'),
                  icon: Icon(Icons.local_fire_department_outlined),
                ),
              ],
              selected: {_isHabit},
              onSelectionChanged: (selection) =>
                  setState(() => _isHabit = selection.first),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction:
                _isHabit ? TextInputAction.done : TextInputAction.next,
            onSubmitted: (_) => _canSave && _isHabit ? _save() : null,
            decoration: InputDecoration(
              hintText: _isHabit
                  ? 'Habit name (e.g. Read 20 minutes)'
                  : 'What needs doing?',
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _isHabit
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration:
                            const InputDecoration(hintText: 'Note (optional)'),
                      ),
                      const SizedBox(height: 12),
                      _dueDayPicker(theme),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _canSave ? _save : null,
            icon: const Icon(Icons.add_rounded),
            label: Text(_isHabit ? 'Add habit' : 'Add task'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dueDayPicker(ThemeData theme) {
    final today = dateOnly(DateTime.now());
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final isCustom = _dueDay != null &&
        !isSameDay(_dueDay!, today) &&
        !isSameDay(_dueDay!, tomorrow);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Today'),
          selected: _dueDay != null && isSameDay(_dueDay!, today),
          onSelected: (_) => setState(() => _dueDay = today),
        ),
        ChoiceChip(
          label: const Text('Tomorrow'),
          selected: _dueDay != null && isSameDay(_dueDay!, tomorrow),
          onSelected: (_) => setState(() => _dueDay = tomorrow),
        ),
        ChoiceChip(
          avatar: isCustom
              ? null
              : Icon(
                  Icons.event_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
          label: Text(
            isCustom ? DateFormat('EEE, d MMM').format(_dueDay!) : 'Pick date',
          ),
          selected: isCustom,
          onSelected: (_) => _pickCustomDate(today),
        ),
        ChoiceChip(
          label: const Text('No due day'),
          selected: _dueDay == null,
          onSelected: (_) => setState(() => _dueDay = null),
        ),
      ],
    );
  }

  Future<void> _pickCustomDate(DateTime today) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDay ?? today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null && mounted) {
      setState(() => _dueDay = dateOnly(picked));
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    if (_isHabit) {
      final habit = Habit(id: id, name: title);
      Boxes.habits.put(id, habit);
      Navigator.of(context).pop(habit);
      return;
    }

    final note = _noteController.text.trim();
    final task = Task(
      id: id,
      title: title,
      note: note.isEmpty ? null : note,
      dueDay: _dueDay,
    );
    Boxes.tasks.put(id, task);
    Navigator.of(context).pop(task);
  }
}

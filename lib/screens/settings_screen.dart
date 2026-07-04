import 'package:flutter/material.dart';

import '../data/boxes.dart';
import '../services/notification_service.dart';

/// Reminder preferences and app info.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _defaultReminder = TimeOfDay(hour: 9, minute: 0);

  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;

  @override
  void initState() {
    super.initState();
    final settings = Boxes.settings;
    _reminderEnabled =
        settings.get(Boxes.reminderEnabledKey, defaultValue: false) as bool;
    _reminderTime = TimeOfDay(
      hour: settings.get(
        Boxes.reminderHourKey,
        defaultValue: _defaultReminder.hour,
      ) as int,
      minute: settings.get(
        Boxes.reminderMinuteKey,
        defaultValue: _defaultReminder.minute,
      ) as int,
    );
  }

  Future<void> _setReminderEnabled(bool enabled) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = NotificationService.instance;

    if (enabled) {
      final granted = await service.requestPermissions();
      if (!granted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications are blocked for TaskNest. '
              'Allow them in system settings to get reminders.',
            ),
          ),
        );
        return;
      }
      await service.scheduleDailyReminder(_reminderTime);
    } else {
      await service.cancelDailyReminder();
    }

    await Boxes.settings.put(Boxes.reminderEnabledKey, enabled);
    if (mounted) {
      setState(() => _reminderEnabled = enabled);
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: 'Daily reminder time',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _reminderTime = picked);
    await Boxes.settings.put(Boxes.reminderHourKey, picked.hour);
    await Boxes.settings.put(Boxes.reminderMinuteKey, picked.minute);
    if (_reminderEnabled) {
      await NotificationService.instance.scheduleDailyReminder(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _reminderEnabled,
                  onChanged: _setReminderEnabled,
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Daily reminder'),
                  subtitle: const Text(
                    'A once-a-day nudge to check in on your tasks and habits.',
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _reminderEnabled ? 1 : 0.45,
                  child: ListTile(
                    enabled: _reminderEnabled,
                    onTap: _pickReminderTime,
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Reminder time'),
                    subtitle: Text(_reminderTime.format(context)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About TaskNest',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A small, offline-first to-do and habit tracker. '
                    'Your data lives only on this device.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Built with Flutter by Priya Gupta',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  SelectableText(
                    'priyagupta02.github.io',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

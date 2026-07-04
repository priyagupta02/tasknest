# TaskNest

**A cosy nest for your tasks and habits** — an offline-first Flutter app for
daily to-dos and habit streaks, with on-device reminder notifications.

Part of [Priya Gupta's portfolio](https://priyagupta02.github.io).

## Features

- **Tasks** — title, optional note, due day and done state, with swipe-right
  to complete and swipe-left to delete.
- **Daily habits with streaks** — a flame counter tracks consecutive days;
  miss a day and the streak resets.
- **Timezone-safe day boundaries** — "today" is always the device's local
  calendar date (year/month/day), never UTC millisecond division, so streaks
  behave correctly across midnight, DST shifts and travel.
- **Instant cold start** — Hive boxes are opened in `main()` before `runApp`,
  so every screen reads synchronously with no loading spinners.
- **Daily reminder** — pick a time in Settings and a repeating local
  notification is scheduled on-device (no server, no account).
- **Micro-interactions** — animated check "pop", animated list inserts,
  removals and moves, swipe backgrounds, and a live "3 of 5 done" progress
  header.
- **Offline & private** — all data stays on the device.

## Architecture

```
lib/
├── main.dart                  # Hive init + runApp (notifications init after first frame)
├── app.dart                   # Material 3 theme (amber accent) + bottom-nav shell
├── models/                    # Hive entities with hand-written TypeAdapters
│   ├── task.dart
│   └── habit.dart
├── logic/
│   └── streaks.dart           # Pure, clock-injected streak & calendar-day logic
├── data/
│   └── boxes.dart             # Box registry, opened once at startup
├── services/
│   └── notification_service.dart  # flutter_local_notifications wrapper
├── screens/                   # Today, All tasks, Settings
└── widgets/                   # Reusable tiles, sheets, progress header
```

Design notes:

- **State management is Hive itself.** Screens rebuild through
  `ValueListenableBuilder` on the boxes — for an app of this size that is
  simpler and more honest than adding a state-management framework.
- **Streak logic is a pure library** (`lib/logic/streaks.dart`). Every
  function takes `now` as a parameter, so the unit tests inject fixed clocks
  and cover consecutive-day increments, gap resets, same-day double
  completion, and month/year boundaries.
- **Adapters are hand-written** rather than generated, keeping the on-disk
  format explicit and the build free of codegen steps.

## Tech stack

| Concern | Choice |
| --- | --- |
| UI | Flutter, Material 3 |
| Storage | `hive_ce` + `hive_ce_flutter` (typed adapters) |
| Notifications | `flutter_local_notifications` |
| Timezones | `timezone` + `flutter_timezone` |
| Dates | `intl` |

## Running

```sh
flutter pub get
flutter run          # Android or iOS device/simulator
flutter test         # streak-logic unit tests
flutter analyze      # lints clean
```

Android notes: the manifest declares `POST_NOTIFICATIONS`,
`RECEIVE_BOOT_COMPLETED` and `SCHEDULE_EXACT_ALARM`; the reminder uses an
exact alarm when permitted and silently falls back to an inexact one
otherwise. Core-library desugaring is enabled in
`android/app/build.gradle.kts` as required by `flutter_local_notifications`.

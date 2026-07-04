import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'data/boxes.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive opens in a few milliseconds, so awaiting it here keeps cold start
  // instant while guaranteeing every screen sees ready boxes.
  await Boxes.open();

  runApp(const TaskNestApp());

  // Notification/timezone setup isn't needed for first paint — kick it off
  // after runApp so it never delays startup.
  unawaited(NotificationService.instance.init());
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'ui/screens/walk_screen.dart';
import 'domain/companion.dart';
import 'background.dart';
import 'data/db/database.dart';
import 'state/alarm_planner.dart';
import 'state/companion.dart';
import 'state/notifications.dart';
import 'state/providers.dart';
import 'ui/screens/trip_screen.dart';
import 'ui/screens/connections_screen.dart';
import 'ui/screens/messages_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de');
  final db = AppDatabase();
  final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
  // Erst das erste Bild, dann alles Weitere: Nichts davon darf den Start
  // aufhalten (v0.2.0 blieb im Startbild hängen, weil die Einrichtung der
  // Benachrichtigungen vor runApp scheiterte).
  runApp(UncontrolledProviderScope(container: container, child: const GleichDaApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await Notifications.init();
      Notifications.onResponse = (payload, action) => handleNotification(container, payload, action);
      final launch = await Notifications.launchPayload();
      if (launch != null) await handleNotification(container, launch, null);
    } catch (_) {}
    try {
      if (Platform.isAndroid) await registerBackgroundWork();
    } catch (_) {}
    try {
      final settings = await container.read(settingsProvider.future);
      await planAllAlarms(container.read(repositoryProvider), container.read(transitProvider), settings: settings);
    } catch (_) {}
  });
}

/// Tipp auf eine Benachrichtigung bzw. eine ihrer Aktionen.
Future<void> handleNotification(ProviderContainer container, String? payload, String? action) async {
  final nav = navigatorKey.currentState;
  if (payload == 'companion') {
    if (action == 'stop') {
      await container.read(companionProvider.notifier).stop();
      return;
    }
    pushOnce(nav, 'fahrt', (_) => const TripScreen());
    // „Weg zum Steig“: zum Einstieg des nächsten Schritts (auch beim Umsteigen).
    final trip = container.read(lastTripProvider).value?.trip;
    if (action == 'walk' && trip != null) {
      final gps = container.read(companionProvider).freshGps(DateTime.now());
      final step = nextStep(trip, DateTime.now(), gps: gps);
      if (step.boarding) {
        pushOnce(nav, 'weg:${step.where.stop.id}',
            (_) => WalkScreen(target: step.where.stop, platform: step.where.platform, departure: step.when));
      }
    }
    return;
  }
  if (payload != null && payload.startsWith('alarm:')) {
    final id = payload.substring(6);
    final alarm = (await container.read(repositoryProvider).alarms()).where((a) => a.id == id).firstOrNull;
    if (alarm == null) return;
    if (alarm.startCompanion) {
      try {
        final settings = await container.read(settingsProvider.future);
        final trips = await container.read(transitProvider).planTrip(buildQuery(
              from: alarm.from,
              to: alarm.to,
              time: DateTime.now(),
              settings: settings,
            ));
        if (trips.isNotEmpty) {
          await container.read(lastTripProvider.notifier).open(trips.first);
          await container.read(companionProvider.notifier).start();
          nav?.push(MaterialPageRoute(builder: (_) => const TripScreen()));
          return;
        }
      } catch (_) {}
    }
    nav?.push(MaterialPageRoute(
        builder: (_) => ConnectionsScreen(from: alarm.from, to: alarm.to, time: null, arriveBy: false)));
    return;
  }
  if (payload != null && payload.startsWith('message:')) {
    nav?.push(MaterialPageRoute(builder: (_) => const Scaffold(body: MessagesScreen())));
  }
}

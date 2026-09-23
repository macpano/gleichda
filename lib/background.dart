// Hintergrundprüfung (Android WorkManager, etwa alle 15 min): neue Meldungen
// zu abonnierten Linien und Neuplanung der Fahrtenwecker mit Echtzeit.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'data/db/database.dart';
import 'data/efa/efa_client.dart';
import 'data/repository.dart';
import 'data/transit_provider.dart';
import 'data/trias/trias_provider.dart';
import 'data/vrr_provider.dart';
import 'domain/models.dart';
import 'domain/settings.dart';
import 'state/alarm_planner.dart';
import 'state/notifications.dart';

const backgroundTask = 'gleichda-pruefung';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Notifications.init();
    final db = AppDatabase();
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'User-Agent': 'Gleich.da/0.2 (Android; Hintergrund)'},
    ));
    try {
      final repo = Repository(db);
      final provider = VrrProvider(TriasProvider(dio), EfaClient(dio));
      final settings = AppSettings.decode(await repo.setting('settings'));
      await checkSubscriptions(repo, provider);
      await planAllAlarms(repo, provider, settings: settings);
      return true;
    } catch (_) {
      return false;
    } finally {
      dio.close();
      await db.close();
    }
  });
}

bool _inWindow(TimeWindow? w, DateTime now) {
  if (w == null) return true;
  if (!w.weekdays.contains(now.weekday)) return false;
  final m = now.hour * 60 + now.minute;
  if (w.fromMinute != null && m < w.fromMinute!) return false;
  if (w.toMinute != null && m > w.toMinute!) return false;
  return true;
}

/// Benachrichtigt über Meldungen, die seit dem letzten Lauf neu sind und eine
/// abonnierte Linie betreffen. Beim ersten Lauf wird nur gemerkt, nicht
/// gemeldet.
Future<int> checkSubscriptions(Repository repo, TransitProvider provider, {DateTime? now}) async {
  final subs = await repo.subscriptions();
  if (subs.isEmpty) return 0;
  final messages = await provider.messages();
  final seenRaw = await repo.setting('seenMessages');
  final seen = seenRaw == null ? null : (jsonDecode(seenRaw) as List).cast<String>().toSet();
  final t = now ?? DateTime.now();
  var sent = 0;
  if (seen != null) {
    for (final m in messages) {
      if (seen.contains(m.id)) continue;
      final hit = subs.where((s) => m.lineIds.contains(lineKey(s.lineId)) && _inWindow(s.window, t)).toList();
      if (hit.isEmpty) continue;
      await Notifications.showMessage(
        id: 3000 + (m.id.hashCode & 0x0FFFFFFF) % 100000,
        title: 'Linie ${hit.map((s) => s.lineName).join(', ')}: ${m.title}',
        body: m.text ?? m.title,
        payload: 'message:${m.id}',
      );
      sent++;
    }
  }
  await repo.setSetting('seenMessages', jsonEncode(messages.map((m) => m.id).toList()));
  return sent;
}

Future<void> registerBackgroundWork() async {
  try {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      backgroundTask,
      backgroundTask,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } catch (_) {
    // Plattform ohne WorkManager (Tests, iOS ohne Background Fetch).
  }
}

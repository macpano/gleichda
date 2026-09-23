import 'dart:ui' show IsolateNameServer;

import 'package:flutter/services.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Benachrichtigungen: Unterwegs (laufend), Fahrtenwecker, Linienabos.
class Notifications {
  Notifications._();

  static final plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const companionId = 1000;
  static const _icon = 'ic_stat_gleichda';

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Wird bei Tipp auf eine Benachrichtigung bzw. eine Aktion aufgerufen.
  static void Function(String? payload, String? actionId)? onResponse;

  static Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    }
    try {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_icon),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) => onResponse?.call(r.payload, r.actionId),
        onDidReceiveBackgroundNotificationResponse: notificationActionInBackground,
      );
      _ready = true;
      try {
        await _android?.deleteNotificationChannel(channelId: 'unterwegs');
      } catch (_) {}
    } catch (_) {
      // Tests, Plattformen ohne Benachrichtigungen oder fehlendes Symbol:
      // Die App läuft ohne Benachrichtigungen weiter, statt zu hängen.
      _ready = false;
    }
  }

  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    return await _android?.requestNotificationsPermission() ?? true;
  }

  static Future<bool> requestExactAlarms() async {
    if (!_ready) return false;
    return await _android?.requestExactAlarmsPermission() ?? true;
  }

  static Future<String?> launchPayload() async {
    if (!_ready) return null;
    final d = await plugin.getNotificationAppLaunchDetails();
    return d?.didNotificationLaunchApp == true ? d!.notificationResponse?.payload : null;
  }

  // --- Unterwegs ---

  static bool _serviceRunning = false;

  /// Standort erlaubt: Der Vordergrunddienst läuft dann zusätzlich als
  /// Standortdienst, damit GPS auch bei ausgeschaltetem Bildschirm weiterläuft.
  static bool locationAllowed = false;

  /// Zeigt bzw. aktualisiert die laufende Unterwegs-Benachrichtigung.
  /// Kompakt: Linie und Ziel in der Kopfzeile, wo aussteigen, wann, und der
  /// Fortschrittsbalken von Android (kein eigenes Bild mehr – das ergab
  /// einen zweiten Balken).
  static Future<void> showCompanion({
    required String header,
    required String where,
    required String when,
    required int progress,
    Color? alertColor,
    String? reason,
  }) async {
    if (!_ready) return;
    // Eigener Kanal mit normaler Wichtigkeit, aber ohne Ton: Android zeigt
    // „lautlose“ Benachrichtigungen (Importance.low) oft ohne Symbol in der
    // Statusleiste. Kanal-Wichtigkeit lässt sich nachträglich nicht ändern,
    // deshalb ein neuer Kanal.
    final details = AndroidNotificationDetails(
      'unterwegs_2',
      'Unterwegs',
      channelDescription: 'Begleitung während der Fahrt',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false,
      enableVibration: false,
      icon: _icon,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      silent: true,
      category: AndroidNotificationCategory.navigation,
      visibility: NotificationVisibility.public,
      color: alertColor ?? const Color(0xFF0B6E66),
      subText: header,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      actions: const [
        // Ohne die App zu öffnen: läuft in notificationActionInBackground.
        AndroidNotificationAction('stop', 'Beenden', showsUserInterface: false, cancelNotification: true),
      ],
    );
    final body = reason == null ? when : '$when · $reason';
    if (!_serviceRunning && _android != null) {
      try {
        await _android!.startForegroundService(
          id: companionId,
          title: where,
          body: body,
          notificationDetails: details,
          payload: 'companion',
          foregroundServiceTypes: {
            AndroidServiceForegroundType.foregroundServiceTypeSpecialUse,
            if (locationAllowed) AndroidServiceForegroundType.foregroundServiceTypeLocation,
          },
        );
        _serviceRunning = true;
        return;
      } catch (_) {
        // Ohne Dienst weiter als normale Benachrichtigung.
      }
    }
    await plugin.show(
      id: companionId,
      title: where,
      body: body,
      notificationDetails: NotificationDetails(android: details),
      payload: 'companion',
    );
  }

  /// Steht die Unterwegs-Benachrichtigung noch? null, wenn unbekannt.
  static Future<bool?> companionVisible() async {
    if (!_ready || _android == null) return null;
    try {
      final active = await _android!.getActiveNotifications();
      return active.any((n) => n.id == companionId);
    } catch (_) {
      return null;
    }
  }

  static Future<void> stopCompanion() async {
    if (!_ready) return;
    if (_serviceRunning) {
      await _android?.stopForegroundService();
      _serviceRunning = false;
    }
    await plugin.cancel(id: companionId);
  }

  // --- Fahrtenwecker ---

  static Future<void> scheduleAlarm({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!_ready || at.isBefore(DateTime.now())) return;
    const details = AndroidNotificationDetails(
      'wecker',
      'Fahrtenwecker',
      channelDescription: 'Weckt zum tatsächlichen Aufbruchszeitpunkt',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
    );
    AndroidScheduleMode mode = AndroidScheduleMode.exactAllowWhileIdle;
    final canExact = await _android?.canScheduleExactNotifications() ?? true;
    if (!canExact) mode = AndroidScheduleMode.inexactAllowWhileIdle;
    await plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(android: details),
      androidScheduleMode: mode,
      title: title,
      body: body,
      payload: payload,
    );
  }

  static Future<void> cancel(int id) async {
    if (_ready) await plugin.cancel(id: id);
  }

  // --- Linienabos ---

  static Future<void> showMessage({required int id, required String title, required String body, String? payload}) async {
    if (!_ready) return;
    await plugin.show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'abos',
          'Linienabos',
          channelDescription: 'Neue Meldungen zu abonnierten Linien',
          importance: Importance.defaultImportance,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }
}

/// Name, unter dem die laufende App ihren Empfänger für „Beenden“ anmeldet.
const companionPortName = 'gleichda_unterwegs';

/// „Beenden“ in der Unterwegs-Benachrichtigung, ohne die App zu öffnen.
/// Läuft in einem eigenen Hintergrund-Isolate: Läuft die App noch, erfährt
/// sie es über ihren Port und beendet die Begleitung selbst (sonst würde ihr
/// Zeitgeber die Benachrichtigung neu zeigen); sonst hält der Isolate den
/// Dienst direkt an.
@pragma('vm:entry-point')
Future<void> notificationActionInBackground(NotificationResponse r) async {
  if (r.actionId != 'stop') return;
  // Der App Bescheid geben (falls sie läuft) und den Dienst in jedem Fall
  // selbst anhalten – kommt die Nachricht nicht an, merkt die App beim
  // nächsten Takt, dass ihre Benachrichtigung fehlt (companionVisible).
  IsolateNameServer.lookupPortByName(companionPortName)?.send('stop');
  final plugin = FlutterLocalNotificationsPlugin();
  final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  try {
    await android?.stopForegroundService();
  } catch (_) {}
  await plugin.cancel(id: Notifications.companionId);
}

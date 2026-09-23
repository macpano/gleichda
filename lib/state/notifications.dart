import 'package:flutter/services.dart' show Color, Uint8List;
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
      );
      _ready = true;
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

  /// Zeigt bzw. aktualisiert die laufende Unterwegs-Benachrichtigung.
  /// Nur vier Angaben: Linie und Ziel, wo aussteigen, wann, Fortschritt.
  static Future<void> showCompanion({
    required String header,
    required String where,
    required String when,
    required int progress,
    required Uint8List bar,
    Color? alertColor,
    String? reason,
  }) async {
    if (!_ready) return;
    final details = AndroidNotificationDetails(
      'unterwegs',
      'Unterwegs',
      channelDescription: 'Begleitung während der Fahrt',
      importance: Importance.low,
      priority: Priority.low,
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
      styleInformation: BigPictureStyleInformation(
        ByteArrayAndroidBitmap(bar),
        contentTitle: where,
        summaryText: reason == null ? when : '$when · $reason',
        hideExpandedLargeIcon: true,
      ),
      actions: const [
        AndroidNotificationAction('stop', 'Beenden', showsUserInterface: true, cancelNotification: true),
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
          foregroundServiceTypes: {AndroidServiceForegroundType.foregroundServiceTypeSpecialUse},
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

import 'dart:convert';

import '../data/repository.dart';
import '../data/transit_provider.dart';
import '../domain/connections.dart';
import '../domain/models.dart';
import '../domain/settings.dart';
import '../ui/format.dart';
import '../ui/trip_status.dart';
import 'notifications.dart';

/// Nächster Termin eines Weckers nach [now] (höchstens eine Woche voraus).
DateTime? nextOccurrence(Alarm a, DateTime now) {
  for (var d = 0; d <= 7; d++) {
    final day = DateTime(now.year, now.month, now.day + d);
    if (!a.weekdays.contains(day.weekday)) continue;
    final t = day.add(Duration(minutes: a.minuteOfDay));
    if (t.isAfter(now)) return t;
  }
  return null;
}

int alarmNotificationId(String id) => 2000 + (id.hashCode & 0x0FFFFFFF) % 100000;

/// Ergebnis der Planung, für die Anzeige in der Weckerliste.
class AlarmPlan {
  const AlarmPlan({required this.wake, required this.departure, this.line, this.status, this.problem = false});

  final DateTime wake;
  final DateTime departure;
  final String? line;
  final String? status;

  /// Die übliche Fahrt ist gestört; es wurde eine Alternative gewählt.
  final bool problem;

  Map<String, dynamic> toJson() => {
        'wake': wake.toIso8601String(),
        'departure': departure.toIso8601String(),
        'line': line,
        'status': status,
        'problem': problem,
      };

  static AlarmPlan? fromJson(String? s) {
    if (s == null) return null;
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return AlarmPlan(
        wake: DateTime.parse(m['wake'] as String),
        departure: DateTime.parse(m['departure'] as String),
        line: m['line'] as String?,
        status: m['status'] as String?,
        problem: m['problem'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

String _planKey(String id) => 'alarmPlan:$id';

Future<AlarmPlan?> loadPlan(Repository repo, String id) async => AlarmPlan.fromJson(await repo.setting(_planKey(id)));

/// Plant einen Wecker: sucht die Fahrt zum nächsten Termin mit Echtzeit und
/// weckt zum tatsächlichen Aufbruchszeitpunkt (Abfahrt der Verbindung ab
/// Start, also inklusive Fußweg, minus Vorlauf). Bei Störung früher.
Future<AlarmPlan?> planAlarm(Repository repo, TransitProvider p, Alarm a,
    {AppSettings settings = const AppSettings(), DateTime? now}) async {
  final nid = alarmNotificationId(a.id);
  if (!a.enabled) {
    await Notifications.cancel(nid);
    await repo.setSetting(_planKey(a.id), '');
    return null;
  }
  final t = now ?? DateTime.now();
  final occ = nextOccurrence(a, t);
  if (occ == null) return null;
  final arriveBy = a.timeRef == AlarmTimeRef.arriveBy;
  final trips = await p.planTrip(TripQuery(
    from: a.from,
    to: a.to,
    time: arriveBy ? occ : occ.subtract(const Duration(minutes: 1)),
    arriveBy: arriveBy,
    maxResults: 5,
    walkSpeedPercent: settings.walkPace.walkPercent,
    accessible: settings.accessible,
  ));
  if (trips.isEmpty) return null;
  final sorted = [...trips]..sort((x, y) => x.departure.best.compareTo(y.departure.best));
  bool ok(Trip x) =>
      tripIssue(x) == null && isReachable(x, transferMinutes: settings.transferPace.transferMinutes);
  Trip usual;
  if (arriveBy) {
    final fits = sorted.where((x) => !x.arrival.planned.isAfter(occ)).toList();
    usual = fits.isEmpty ? sorted.first : fits.last;
  } else {
    usual = sorted.firstWhere((x) => !x.departure.planned.isBefore(occ), orElse: () => sorted.first);
  }
  var chosen = usual;
  var problem = false;
  if (a.earlierOnDisruption && !ok(usual)) {
    problem = true;
    final earlier = sorted.where((x) => x.departure.best.isBefore(usual.departure.best) && ok(x)).toList();
    final later = sorted.where((x) => !x.departure.best.isBefore(usual.departure.best) && ok(x)).toList();
    chosen = earlier.isNotEmpty ? earlier.last : (later.isNotEmpty ? later.first : usual);
  }
  final dep = chosen.departure.best;
  final wake = dep.subtract(Duration(minutes: a.leadMinutes));
  final ride = chosen.rides.isEmpty ? null : chosen.rides.first;
  final line = ride?.line?.name;
  final delay = ride?.from.departure?.delayMinutes ?? 0;
  final status = problem
      ? '${tripIssue(usual)?.title ?? 'Anschluss gefährdet'} – früher los'
      : !(ride?.from.departure?.hasRealtime ?? false)
          ? 'nur Fahrplan'
          : delay > 0
              ? '+$delay min'
              : 'pünktlich';
  final plan = AlarmPlan(wake: wake, departure: dep, line: line, status: status, problem: problem);
  await repo.setSetting(_planKey(a.id), jsonEncode(plan.toJson()));
  final platform = ride?.from.platform == null ? '' : ', Steig ${ride!.from.platform}';
  await Notifications.scheduleAlarm(
    id: nid,
    at: wake,
    title: problem ? '${a.name}: früher los' : a.name,
    body: [
      'Losgehen in ${a.leadMinutes} min',
      if (line != null) '$line um ${hm(ride!.from.departure!.best)} ab ${ride.from.stop.name}$platform',
      if (problem) status,
    ].join(' · '),
    payload: 'alarm:${a.id}',
  );
  return plan;
}

Future<void> planAllAlarms(Repository repo, TransitProvider p, {AppSettings settings = const AppSettings()}) async {
  for (final a in await repo.alarms()) {
    try {
      await planAlarm(repo, p, a, settings: settings);
    } on ProviderException {
      // Nächster Versuch beim nächsten Lauf.
    }
  }
}

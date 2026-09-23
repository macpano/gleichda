import 'package:intl/intl.dart';

import '../domain/models.dart';

final _hm = DateFormat('HH:mm');

String hm(DateTime t) => _hm.format(t.toLocal());

/// „23 min“, „1 Std 5 min“
String durationText(Duration d) {
  final m = d.inMinutes;
  if (m < 60) return '$m min';
  final h = m ~/ 60, r = m % 60;
  return r == 0 ? '$h Std' : '$h Std $r min';
}

/// „in 6 min“, „jetzt“, „vor 3 min“
String countdown(DateTime t, DateTime now) {
  final m = (t.difference(now).inSeconds / 60).round();
  if (m == 0) return 'jetzt';
  if (m > 0) return m < 60 ? 'in $m min' : 'um ${hm(t)}';
  return m > -60 ? 'vor ${-m} min' : hm(t);
}

/// Enthält der Countdown die Uhrzeit schon („um 02:56“ ab einer Stunde
/// Vorlauf, sonst die bloße Uhrzeit)? Dann nicht noch einmal anhängen –
/// vorher stand „um 02:56 · 02:56“ (Nutzerbefund 24.09.2026).
bool countdownHasTime(DateTime t, DateTime now) => countdown(t, now).contains(hm(t));

/// „in 5 min · 14:32“, aber „um 02:56“ ohne doppelte Uhrzeit.
String countdownWithTime(DateTime t, DateTime now) =>
    countdownHasTime(t, now) ? countdown(t, now) : '${countdown(t, now)} · ${hm(t)}';

/// „vor 12 s“, „vor 3 min“
String ageText(Duration d) {
  if (d.inSeconds < 60) return 'vor ${d.inSeconds.clamp(0, 59)} s';
  if (d.inMinutes < 60) return 'vor ${d.inMinutes} min';
  return 'vor ${d.inHours} Std';
}

/// „heute“, „gestern“, „Montag“, „12.09.“
String dayText(DateTime t, DateTime now) {
  final a = DateTime(t.year, t.month, t.day);
  final b = DateTime(now.year, now.month, now.day);
  final diff = b.difference(a).inDays;
  if (diff == 0) return 'heute';
  if (diff == 1) return 'gestern';
  if (diff < 7) return DateFormat('EEEE', 'de').format(t);
  return DateFormat('dd.MM.').format(t);
}

/// „+3“ bei Verspätung, sonst leer. Platz dafür reserviert die Anzeige.
String delayText(EventTime? t) {
  final d = t?.delayMinutes;
  if (d == null || d <= 0) return '';
  return '+$d';
}

String interchangesText(int n) => switch (n) {
      0 => 'ohne Umstieg',
      1 => '1 Umstieg',
      _ => '$n Umstiege',
    };

String distanceText(double meters) {
  if (meters < 1000) return '${(meters / 10).round() * 10} m';
  return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// „Heute“, „Morgen“ oder der Wochentag.
String relativeDay(DateTime t, DateTime now) {
  final a = DateTime(t.year, t.month, t.day);
  final b = DateTime(now.year, now.month, now.day);
  final diff = a.difference(b).inDays;
  if (diff == 0) return 'Heute';
  if (diff == 1) return 'Morgen';
  return DateFormat('EEEE', 'de').format(t);
}

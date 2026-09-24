import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../format.dart';
import '../time_choice.dart';

/// Beschriftung des Zeit-Schalters: „Jetzt“, „ab 14:30“, „Ankunft 17:30“,
/// „Morgen ab 07:00“.
String timeChipLabel(SearchTime t) {
  if (t.isNow) return 'Jetzt';
  final now = DateTime.now();
  final d = t.time!;
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day).difference(today).inDays;
  final prefix = switch (day) {
    0 => '',
    1 => 'Morgen ',
    _ =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}. ',
  };
  return '$prefix${t.arriveBy ? 'an' : 'ab'} ${hm(d)}';
}

/// Zeitwahl der Suche: gemeinsame Zeitleiste (`showTimeChoice`), das
/// Ergebnis landet im [searchTimeProvider].
Future<void> showTimeSheet(BuildContext context, WidgetRef ref) async {
  final cur = ref.read(searchTimeProvider);
  final r = await showTimeChoice(
    context,
    initial: (time: cur.time, second: cur.arriveBy),
    modes: ('Abfahrt um', 'Ankunft um'),
    secondNeedsTime: true,
  );
  if (r == null) return;
  ref.read(searchTimeProvider.notifier).set(SearchTime(time: r.time, arriveBy: r.time != null && r.second));
}

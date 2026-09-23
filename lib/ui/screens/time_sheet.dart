import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';

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
    _ => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}. ',
  };
  return '$prefix${t.arriveBy ? 'Ankunft' : 'ab'} ${hm(d)}';
}

/// Fenster von unten: Abfahrt/Ankunft, Schnellwahl, Uhrzeit.
// TODO: Tag- und Datumswahl sowie Rad in 5-Minuten-Schritten (Schritt 7).
Future<void> showTimeSheet(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _TimeSheet(),
    );

class _TimeSheet extends ConsumerWidget {
  const _TimeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final t = ref.watch(searchTimeProvider);
    final n = ref.read(searchTimeProvider.notifier);
    final now = DateTime.now();
    DateTime round5(DateTime d) =>
        DateTime(d.year, d.month, d.day, d.hour, (d.minute / 5).ceil() * 5);
    final quick = <(String, DateTime?)>[
      ('Jetzt', null),
      ('in 30 min', round5(now.add(const Duration(minutes: 30)))),
      ('in 1 Std', round5(now.add(const Duration(hours: 1)))),
      ('morgen früh', DateTime(now.year, now.month, now.day + 1, 7)),
    ];
    final explain = t.isNow
        ? 'Verbindungen ab jetzt, laufend aktualisiert'
        : t.arriveBy
            ? 'Verbindungen, die bis ${hm(t.time!)} ankommen'
            : 'Verbindungen ab ${hm(t.time!)}';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text('Zeit', style: context.t.section)),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fertig')),
          ]),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Abfahrt um')),
              ButtonSegment(value: true, label: Text('Ankunft um')),
            ],
            selected: {t.arriveBy},
            onSelectionChanged: (s) => n.set(SearchTime(
                time: t.time ?? (s.first ? round5(now.add(const Duration(hours: 1))) : null),
                arriveBy: s.first)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            for (final q in quick) ...[
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: _selected(t, q.$2) ? c.ink : c.fill,
                      foregroundColor: _selected(t, q.$2) ? c.bg : c.ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.input)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => n.set(SearchTime(time: q.$2, arriveBy: q.$2 != null && t.arriveBy)),
                    child: Text(q.$1, maxLines: 1, style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ),
              if (q != quick.last) const SizedBox(width: 8),
            ],
          ]),
          const SizedBox(height: 12),
          Divider(height: 1, color: c.hair),
          SizedBox(
            height: 48,
            child: Row(children: [
              const Expanded(child: Text('Uhrzeit', style: TextStyle(fontSize: 16))),
              TextButton(
                style: TextButton.styleFrom(backgroundColor: c.fill, foregroundColor: c.ink),
                onPressed: () async {
                  final base = t.time ?? now;
                  final picked = await showTimePicker(
                      context: context, initialTime: TimeOfDay.fromDateTime(base));
                  if (picked == null) return;
                  n.set(SearchTime(
                      time: DateTime(base.year, base.month, base.day, picked.hour, picked.minute),
                      arriveBy: t.arriveBy));
                },
                child: Text(hm(t.time ?? now), style: context.t.number(17)),
              ),
            ]),
          ),
          Text(explain, style: context.t.secondary.copyWith(color: c.muted)),
        ]),
      ),
    );
  }

  bool _selected(SearchTime t, DateTime? q) =>
      q == null ? t.isNow : (!t.isNow && t.time == q);
}

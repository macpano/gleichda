import 'package:flutter/cupertino.dart' show CupertinoDatePicker, CupertinoDatePickerMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

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

DateTime _round5(DateTime d) {
  final m = (d.minute / 5).ceil() * 5;
  return DateTime(d.year, d.month, d.day, d.hour).add(Duration(minutes: m));
}

/// Fenster von unten: Abfahrt/Ankunft, Tag, Schnellwahl, Uhrzeit als Rad in
/// 5-Minuten-Schritten, dazu eine Zeile mit der Wirkung im Klartext.
Future<void> showTimeSheet(BuildContext context, WidgetRef ref) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _TimeSheet(),
    );

class _TimeSheet extends ConsumerStatefulWidget {
  const _TimeSheet();

  @override
  ConsumerState<_TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends ConsumerState<_TimeSheet> {
  late SearchTime _t = ref.read(searchTimeProvider);
  int _wheelKey = 0;

  void _set(SearchTime t, {bool moveWheel = true}) {
    setState(() {
      _t = t;
      if (moveWheel) _wheelKey++;
    });
    ref.read(searchTimeProvider.notifier).set(t);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final now = DateTime.now();
    final base = _t.time ?? _round5(now);
    final today = DateTime(now.year, now.month, now.day);
    final dayIndex = DateTime(base.year, base.month, base.day).difference(today).inDays.clamp(0, 2);
    DateTime onDay(int addDays) => DateTime(today.year, today.month, today.day + addDays, base.hour, base.minute);
    final quick = <(String, DateTime?)>[
      ('Jetzt', null),
      ('in 30 min', _round5(now.add(const Duration(minutes: 30)))),
      ('in 1 Std', _round5(now.add(const Duration(hours: 1)))),
      ('morgen früh', DateTime(now.year, now.month, now.day + 1, 7)),
    ];
    final explain = _t.isNow
        ? 'Verbindungen ab jetzt, laufend aktualisiert'
        : _t.arriveBy
            ? 'Verbindungen, die bis ${hm(_t.time!)} ankommen'
            : 'Verbindungen ab ${hm(_t.time!)}';
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
            selected: {_t.arriveBy},
            onSelectionChanged: (s) => _set(SearchTime(
                time: _t.time ?? (s.first ? _round5(now.add(const Duration(hours: 1))) : null), arriveBy: s.first)),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('Heute')),
              ButtonSegment(value: 1, label: Text('Morgen')),
              ButtonSegment(value: 2, label: Text('Datum')),
            ],
            selected: {_t.isNow ? 0 : (dayIndex >= 2 ? 2 : dayIndex)},
            onSelectionChanged: (s) async {
              if (s.first < 2) {
                _set(SearchTime(time: onDay(s.first), arriveBy: _t.arriveBy));
                return;
              }
              final picked = await showDatePicker(
                context: context,
                initialDate: base,
                firstDate: today,
                lastDate: today.add(const Duration(days: 60)),
              );
              if (picked != null) {
                _set(SearchTime(
                    time: DateTime(picked.year, picked.month, picked.day, base.hour, base.minute),
                    arriveBy: _t.arriveBy));
              }
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            for (final q in quick) ...[
              Expanded(
                child: ChoiceChipX(
                  label: q.$1,
                  selected: q.$2 == null ? _t.isNow : (!_t.isNow && _t.time == q.$2),
                  onTap: () => _set(SearchTime(time: q.$2, arriveBy: q.$2 != null && _t.arriveBy)),
                ),
              ),
              if (q != quick.last) const SizedBox(width: 6),
            ],
          ]),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: CupertinoDatePicker(
              key: ValueKey(_wheelKey),
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              minuteInterval: 5,
              initialDateTime: _round5(base),
              onDateTimeChanged: (d) => _set(
                SearchTime(
                  time: DateTime(base.year, base.month, base.day, d.hour, d.minute),
                  arriveBy: _t.arriveBy,
                ),
                moveWheel: false,
              ),
            ),
          ),
          Text(explain, style: context.t.secondary.copyWith(color: c.muted)),
        ]),
      ),
    );
  }
}

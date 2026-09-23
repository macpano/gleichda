import 'package:flutter/cupertino.dart'
    show CupertinoPicker, FixedExtentScrollController;
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
    _ =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}. ',
  };
  return '$prefix${t.arriveBy ? 'Ankunft' : 'ab'} ${hm(d)}';
}

DateTime _round5(DateTime d) {
  final m = (d.minute / 5).ceil() * 5;
  return DateTime(d.year, d.month, d.day, d.hour).add(Duration(minutes: m));
}

/// Fenster von unten wie im Entwurf „Zeit einstellen“.
Future<void> showTimeSheet(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
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
  late FixedExtentScrollController _hours;
  late FixedExtentScrollController _minutes;

  DateTime get _base => _t.time ?? _round5(DateTime.now());

  @override
  void initState() {
    super.initState();
    _hours = FixedExtentScrollController(initialItem: _base.hour);
    _minutes = FixedExtentScrollController(initialItem: _base.minute ~/ 5);
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _set(SearchTime t, {bool moveWheel = true}) {
    setState(() => _t = t);
    ref.read(searchTimeProvider.notifier).set(t);
    if (moveWheel) {
      // Programmgesteuertes Drehen darf „Jetzt“ nicht in eine feste Zeit
      // verwandeln: Rückmeldungen des Rads währenddessen ignorieren.
      final b = _base;
      _jumping = true;
      if (_hours.hasClients) _hours.jumpToItem(b.hour);
      if (_minutes.hasClients) _minutes.jumpToItem(b.minute ~/ 5);
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumping = false);
    }
  }

  bool _jumping = false;

  void _wheel({int? hour, int? minute}) {
    if (_jumping) return;
    final b = _base;
    _set(
      SearchTime(
        time: DateTime(
          b.year,
          b.month,
          b.day,
          hour ?? b.hour,
          minute ?? (b.minute - b.minute % 5),
        ),
        arriveBy: _t.arriveBy,
      ),
      moveWheel: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final now = DateTime.now();
    final base = _base;
    final today = DateTime(now.year, now.month, now.day);
    final dayIndex = _t.isNow
        ? 0
        : DateTime(
            base.year,
            base.month,
            base.day,
          ).difference(today).inDays.clamp(0, 2);
    DateTime onDay(int add) => DateTime(
      today.year,
      today.month,
      today.day + add,
      base.hour,
      base.minute,
    );
    final quick = <(String, DateTime?)>[
      ('Jetzt', null),
      ('in 30 min', _round5(now.add(const Duration(minutes: 30)))),
      ('in 1 Std', _round5(now.add(const Duration(hours: 1)))),
      ('Morgen früh', DateTime(now.year, now.month, now.day + 1, 6, 30)),
    ];
    final hint = _t.isNow
        ? 'Ohne Angabe sucht Gleich.da ab jetzt und aktualisiert laufend.'
        : _t.arriveBy
        ? 'Gleich.da zeigt Verbindungen, die bis ${hm(base)} ankommen, und rechnet den Fußweg mit ein.'
        : 'Gleich.da zeigt Verbindungen ab ${hm(base)} und rechnet den Fußweg mit ein.';
    Widget picker(
      FixedExtentScrollController ctrl,
      int count,
      String Function(int) label,
      ValueChanged<int> onPick, {
      required bool right,
    }) => CupertinoPicker(
      scrollController: ctrl,
      itemExtent: 34,
      looping: true,
      selectionOverlay: const SizedBox.shrink(),
      onSelectedItemChanged: onPick,
      children: [
        for (var i = 0; i < count; i++)
          Align(
            alignment: right ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: right ? 0 : 8,
                right: right ? 8 : 0,
              ),
              child: Text(
                label(i),
                style: context.t
                    .time(22)
                    .copyWith(
                      color: c.ink,
                      fontFamily: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.fontFamily,
                    ),
              ),
            ),
          ),
      ],
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader('Zeit'),
            const SizedBox(height: 12),
            Segmented<bool>(
              options: const [(false, 'Abfahrt um'), (true, 'Ankunft um')],
              value: _t.arriveBy,
              onChanged: (a) => _set(
                SearchTime(
                  time:
                      _t.time ??
                      (a ? _round5(now.add(const Duration(hours: 1))) : null),
                  arriveBy: a,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final (i, label) in [
                  (0, 'Heute'),
                  (1, 'Morgen'),
                  (2, 'Datum'),
                ]) ...[
                  Expanded(
                    child: PickButton(
                      label: label,
                      accent: true,
                      selected: dayIndex == i,
                      onTap: () async {
                        if (i < 2) {
                          _set(
                            SearchTime(time: onDay(i), arriveBy: _t.arriveBy),
                          );
                          return;
                        }
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: base,
                          firstDate: today,
                          lastDate: today.add(const Duration(days: 60)),
                        );
                        if (picked != null) {
                          _set(
                            SearchTime(
                              time: DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                base.hour,
                                base.minute,
                              ),
                              arriveBy: _t.arriveBy,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Android: große Uhrzeit, ein Tipp öffnet die Material-Uhr;
            // iPhone: Drehrad wie im Entwurf.
            if (!context.isIOS)
              Material(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.card),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.card),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(base),
                      builder: (ctx, child) => MediaQuery(
                        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      _set(SearchTime(
                        time: DateTime(base.year, base.month, base.day, picked.hour, picked.minute),
                        arriveBy: _t.arriveBy,
                      ));
                    }
                  },
                  child: SizedBox(
                    height: 96,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(hm(base), style: context.t.time(44).copyWith(color: _t.isNow ? c.muted : c.ink)),
                      const SizedBox(width: 12),
                      Icon(Icons.edit_outlined, size: 20, color: c.muted),
                    ]),
                  ),
                ),
              )
            else
            Container(
              height: 170,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 66,
                    height: 38,
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.fill,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                  // Nachbarzeilen wie im Entwurf nach oben und unten ausblenden.
                  ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33000000),
                        Color(0xFF000000),
                        Color(0xFF000000),
                        Color(0x33000000),
                      ],
                      stops: [0, 0.4, 0.6, 1],
                    ).createShader(r),
                    child: Row(
                      children: [
                        Expanded(
                          child: picker(
                            _hours,
                            24,
                            (i) => i.toString().padLeft(2, '0'),
                            (i) => _wheel(hour: i),
                            right: true,
                          ),
                        ),
                        SizedBox(
                          width: 22,
                          child: Center(
                            child: Text(
                              ':',
                              style: context.t.time(22).copyWith(color: c.ink),
                            ),
                          ),
                        ),
                        Expanded(
                          child: picker(
                            _minutes,
                            12,
                            (i) => (i * 5).toString().padLeft(2, '0'),
                            (i) => _wheel(minute: i * 5),
                            right: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < quick.length; i++) ...[
                  Expanded(
                    child: PickButton(
                      label: quick[i].$1,
                      selected: quick[i].$2 == null
                          ? _t.isNow
                          : (!_t.isNow && _t.time == quick[i].$2),
                      onTap: () => _set(
                        SearchTime(
                          time: quick[i].$2,
                          arriveBy: quick[i].$2 != null && _t.arriveBy,
                        ),
                      ),
                    ),
                  ),
                  if (i < quick.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                hint,
                style: TextStyle(fontSize: 13, height: 1.4, color: c.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

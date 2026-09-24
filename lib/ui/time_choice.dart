import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'theme.dart';
import 'widgets.dart';

/// Gewählte Zeit: [time] null heißt „jetzt“ (läuft mit); [second] ist die
/// zweite Art – bei der Suche „Ankunft um“, bei der Abfahrtstafel „Ankünfte“.
typedef TimeChoice = ({DateTime? time, bool second});

/// Zeitwahl als Zeitleiste (Entwurf D, 24.09.2026): große Uhrzeit, darunter
/// ein Zeitstrahl zum Wischen in 5-Minuten-Schritten, der über Mitternacht in
/// den nächsten Tag läuft. Ein Tipp auf die Uhrzeit öffnet die genaue
/// Eingabe. Gemeinsam für Suche und Abfahrtstafel.
///
/// [secondNeedsTime]: Die zweite Art braucht eine feste Zeit (eine Ankunft
/// „jetzt“ ergibt keinen Sinn) – beim Umschalten springt die Leiste dann auf
/// eine Stunde später.
Future<TimeChoice?> showTimeChoice(
  BuildContext context, {
  required TimeChoice initial,
  required (String, String) modes,
  bool secondNeedsTime = false,
}) =>
    showModalBottomSheet<TimeChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _TimeChoiceSheet(initial: initial, modes: modes, secondNeedsTime: secondNeedsTime),
    );

/// Auf volle 5 Minuten aufgerundet.
DateTime roundUp5(DateTime d) {
  final m = (d.minute / 5).ceil() * 5;
  return DateTime(d.year, d.month, d.day, d.hour).add(Duration(minutes: m));
}

class _TimeChoiceSheet extends StatefulWidget {
  const _TimeChoiceSheet({required this.initial, required this.modes, required this.secondNeedsTime});

  final TimeChoice initial;
  final (String, String) modes;
  final bool secondNeedsTime;

  @override
  State<_TimeChoiceSheet> createState() => _TimeChoiceSheetState();
}

class _TimeChoiceSheetState extends State<_TimeChoiceSheet> {
  late DateTime? _time = widget.initial.time;
  late bool _second = widget.initial.second;
  final _ruler = GlobalKey<TimeRulerState>();

  DateTime get _shown => _time ?? DateTime.now();

  void _pick(DateTime t) => setState(() => _time = t);

  void _jumpTo(DateTime t) {
    setState(() => _time = t);
    _ruler.currentState?.jumpTo(t);
  }

  String _dayLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(t.year, t.month, t.day).difference(today).inDays;
    final date = '${weekdayShort(t)} ${t.day}.${t.month}.';
    return switch (d) {
      0 => 'Heute, $date',
      1 => 'Morgen, $date',
      -1 => 'Gestern, $date',
      _ => date,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final t = _shown;
    DateTime onDay(int add) => DateTime(today.year, today.month, today.day + add, t.hour, t.minute);
    final day = DateTime(t.year, t.month, t.day).difference(today).inDays;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              'Zeit',
              done: 'Jetzt',
              onDone: () => Navigator.pop(context, (time: null, second: _second && !widget.secondNeedsTime)),
            ),
            const SizedBox(height: 8),
            Segmented<bool>(
              options: [(false, widget.modes.$1), (true, widget.modes.$2)],
              value: _second,
              onChanged: (s) {
                setState(() => _second = s);
                if (s && widget.secondNeedsTime && _time == null) {
                  _jumpTo(roundUp5(now.add(const Duration(hours: 1))));
                }
              },
            ),
            const SizedBox(height: 14),
            // Tag und Uhrzeit, Höhe fest – nichts springt.
            SizedBox(
              height: 20,
              child: Text(
                _time == null ? 'Jetzt · läuft mit' : _dayLabel(t),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: c.muted),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(Radii.card),
              onTap: () async {
                final p = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(t),
                  builder: (ctx, child) => MediaQuery(
                    data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  ),
                );
                if (p != null) _jumpTo(DateTime(t.year, t.month, t.day, p.hour, p.minute));
              },
              child: SizedBox(
                height: 72,
                child: Center(
                  child: Text(
                    hm(t),
                    textScaler: TextScaler.linear(MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3)),
                    style: context.t.time(56).copyWith(color: _time == null ? c.muted : c.ink, height: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TimeRuler(key: _ruler, initial: t, onChanged: _pick),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (i, label) in const [(0, 'Heute'), (1, 'Morgen')]) ...[
                  ChoiceChipX(
                    label: label,
                    selected: _time != null && day == i,
                    onTap: () => _jumpTo(i == 0 && onDay(0).isBefore(now) ? roundUp5(now) : onDay(i)),
                  ),
                  const SizedBox(width: 8),
                ],
                ChoiceChipX(
                  label: day >= 2 ? '${weekdayShort(t)} ${t.day}.${t.month}.' : 'Datum …',
                  selected: _time != null && day >= 2,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: t.isBefore(today) ? today : t,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: TimeRuler.days - 1)),
                    );
                    if (d != null) _jumpTo(DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                  shape: buttonShape(context),
                ),
                onPressed: () => Navigator.pop(context, (time: _time, second: _second)),
                child: const Text('Übernehmen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// „Do“, „Fr“ …
String weekdayShort(DateTime t) => const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][t.weekday - 1];

/// Zeitstrahl zum Wischen: 5-Minuten-Striche, volle Stunden beschriftet,
/// Tageswechsel mit dem Wochentag markiert; die Nadel in der Mitte zeigt die
/// gewählte Zeit. Reicht von heute 0 Uhr bis [days] Tage voraus.
class TimeRuler extends StatefulWidget {
  const TimeRuler({super.key, required this.initial, required this.onChanged});

  final DateTime initial;
  final ValueChanged<DateTime> onChanged;

  /// Abstand zweier 5-Minuten-Striche.
  static const step = 12.0;
  static const days = 60;

  @override
  State<TimeRuler> createState() => TimeRulerState();
}

class TimeRulerState extends State<TimeRuler> {
  late final DateTime _start;
  late final ScrollController _scroll;
  late int _index;
  bool _silent = false;

  int _indexOf(DateTime t) => (t.difference(_start).inMinutes / 5).round().clamp(0, TimeRuler.days * 288 - 1);
  DateTime _timeOf(int i) => DateTime(_start.year, _start.month, _start.day, 0, i * 5);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, now.day);
    _index = _indexOf(widget.initial);
    _scroll = ScrollController(initialScrollOffset: _index * TimeRuler.step)..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final i = (_scroll.offset / TimeRuler.step).round().clamp(0, TimeRuler.days * 288 - 1);
    if (i == _index) return;
    _index = i;
    if (_silent) return;
    // Spürbarer Schritt an jeder vollen Viertelstunde.
    if (i % 3 == 0) HapticFeedback.selectionClick();
    widget.onChanged(_timeOf(i));
  }

  /// Von außen (Heute, Morgen, Datum, genaue Eingabe): hinfahren, ohne
  /// unterwegs Zwischenzeiten zu melden. Minuten außerhalb des 5er-Rasters
  /// bleiben erhalten – die Nadel steht dann am nächsten Strich.
  void jumpTo(DateTime t) {
    final target = _indexOf(t) * TimeRuler.step;
    _silent = true;
    final far = (target - _scroll.offset).abs() > 400 * TimeRuler.step;
    final done = far || MediaQuery.of(context).disableAnimations
        ? Future.sync(() => _scroll.jumpTo(target))
        : _scroll.animateTo(target, duration: Motion.of(context, Motion.page), curve: Motion.curve);
    done.whenComplete(() => _silent = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 76,
      child: LayoutBuilder(
        builder: (context, box) {
          final pad = box.maxWidth / 2 - TimeRuler.step / 2;
          final label = DefaultTextStyle.of(context).style.merge(context.t.number(12));
          return Stack(
            children: [
              // Ränder sanft ausblenden.
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (r) => const LinearGradient(
                  colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
                  stops: [0, 0.15, 0.85, 1],
                ).createShader(r),
                child: ListView.builder(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  physics: const _SnapPhysics(TimeRuler.step),
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  itemExtent: TimeRuler.step,
                  itemCount: TimeRuler.days * 288,
                  // Schrift der App (der Maler kennt sie sonst nicht), ohne
                  // Vergrößerung – die Striche haben feste Abstände.
                  itemBuilder: (context, i) => CustomPaint(
                    painter: _TickPainter(time: _timeOf(i), color: c.muted, accent: c.accent, text: label),
                  ),
                ),
              ),
              // Nadel in der Mitte.
              Center(
                child: IgnorePointer(
                  child: Container(
                    width: 3,
                    height: 76,
                    decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Ein Strich des Zeitstrahls. Beschriftungen ragen bewusst über den
/// eigenen Platz hinaus (nicht beschnitten).
class _TickPainter extends CustomPainter {
  _TickPainter({required this.time, required this.color, required this.accent, required this.text});

  final DateTime time;
  final Color color;
  final Color accent;
  final TextStyle text;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final base = size.height - 22;
    final midnight = time.hour == 0 && time.minute == 0;
    final hour = time.minute == 0;
    final quarter = time.minute % 15 == 0;
    final h = hour ? 24.0 : (quarter ? 15.0 : 8.0);
    final paint = Paint()
      ..color = midnight ? accent : color.withValues(alpha: hour ? 0.9 : 0.55)
      ..strokeWidth = midnight ? 2 : 1.2;
    canvas.drawLine(Offset(x, base), Offset(x, base - (midnight ? 44 : h)), paint);
    void label(String s, double y, TextStyle style) {
      final tp = TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y));
    }

    if (hour) label('${time.hour.toString().padLeft(2, '0')}:00', base + 4, text.copyWith(color: color));
    if (midnight) {
      label('${weekdayShort(time)} ${time.day}.${time.month}.', 0,
          text.copyWith(color: accent, fontWeight: FontWeight.w600, fontSize: 11));
    }
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.time != time || old.color != color || old.accent != accent;
}

/// Rastet nach dem Wischen am nächsten Strich ein.
class _SnapPhysics extends ScrollPhysics {
  const _SnapPhysics(this.step, {super.parent});

  final double step;

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) => _SnapPhysics(step, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final free = super.createBallisticSimulation(position, velocity);
    final end = free?.x(10) ?? position.pixels;
    final target = ((end / step).round() * step).clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 0.5 && velocity.abs() < toleranceFor(position).velocity) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: toleranceFor(position));
  }

  @override
  bool get allowImplicitScrolling => false;
}

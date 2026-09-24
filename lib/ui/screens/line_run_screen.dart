import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transit_provider.dart';
import '../../data/trias/trias_parser.dart' show stopAreaId;
import '../../domain/connections.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../trip_map.dart';
import '../widgets.dart';

/// Ganzer Linienverlauf eines Fahrzeugs: alle Halte von der Start- bis zur
/// Endhaltestelle, Karte oben; der eigene Ein- und Ausstieg hervorgehoben.
/// Liest nur – die zuletzt angesehene Fahrt bleibt, wie sie ist.
class LineRunScreen extends ConsumerStatefulWidget {
  const LineRunScreen({super.key, required this.leg});

  /// Der eigene Abschnitt, dessen Fahrzeug gezeigt wird.
  final Leg leg;

  @override
  ConsumerState<LineRunScreen> createState() => _LineRunScreenState();
}

class _LineRunScreenState extends ConsumerState<LineRunScreen> {
  Trip? _run;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = widget.leg;
    final dep = l.from.departure;
    if (l.line == null || dep == null) {
      setState(() => _error = 'Für diesen Abschnitt ist kein Linienverlauf bekannt.');
      return;
    }
    setState(() => _error = null);
    try {
      final run = await ref.read(transitProvider).tripOfDeparture(
            Departure(
              stop: l.from.stop,
              line: l.line!,
              direction: l.direction ?? '',
              time: dep,
              journeyRef: l.journeyRef,
              operatingDay: l.operatingDay,
            ),
            whole: true,
          );
      if (!mounted) return;
      setState(() {
        _run = run;
        if (run == null) _error = 'Der Linienverlauf ist gerade nicht abrufbar.';
      });
    } on ProviderException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final l = widget.leg;
    final run = _run;
    final stops = run == null ? const <StopTime>[] : [run.legs.first.from, ...run.legs.first.intermediates, run.legs.first.to];
    final board = stopAreaId(l.from.stop.id);
    final alight = stopAreaId(l.to.stop.id);
    final bi = stops.indexWhere((s) => stopAreaId(s.stop.id) == board);
    final ai = stops.lastIndexWhere((s) => stopAreaId(s.stop.id) == alight);
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          const SubpageHeader(title: 'Linienverlauf', backLabel: 'Fahrt'),
          const SizedBox(height: 8),
          Row(children: [
            if (l.line != null) LineBadge(l.line!),
            const SizedBox(width: 10),
            Expanded(child: OneLine('Richtung ${l.direction ?? ''}', style: TextStyle(fontSize: 16, color: c.ink2))),
          ]),
          const SizedBox(height: 14),
          if (_error != null)
            Notice(_error!, action: 'Erneut versuchen', onAction: _load)
          else if (run == null)
            const SkeletonBlock(height: 220, radius: Radii.card)
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.card),
              child: SizedBox(height: 220, child: TripMap(trip: run, now: now)),
            ),
            const SizedBox(height: 14),
            ListGroup(children: [
              for (var k = 0; k < stops.length; k++)
                Builder(builder: (context) {
                  final s = stops[k];
                  final mine = k == bi || k == ai;
                  final between = bi >= 0 && ai >= bi && k >= bi && k <= ai;
                  final passed = isPassed(s, now);
                  // Ankunft und Abfahrt untereinander; am Start nur ab, am Ende
                  // nur an (Nutzerwunsch 24.09.2026).
                  Widget time(String label, EventTime? t) => t == null
                      ? const SizedBox(height: 18)
                      : SizedBox(
                          height: 18,
                          child: Row(children: [
                            SizedBox(
                              width: 20,
                              child: Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
                            ),
                            Text(hm(t.best),
                                style: context.t.number(14).copyWith(
                                    color: passed ? c.muted : timeColor(context, t, status: s.status, neutral: c.ink2))),
                          ]),
                        );
                  return SizedBox(
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        SizedBox(
                          width: 70,
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            time('an', k == 0 ? null : s.arrival ?? s.departure),
                            time('ab', k == stops.length - 1 ? null : s.departure ?? s.arrival),
                          ]),
                        ),
                        Container(
                          width: 4,
                          height: 48,
                          color: between || mine ? lineColor(context, l.line) : c.hair,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OneLine(s.stop.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: mine ? FontWeight.w600 : FontWeight.w400,
                                color: passed ? c.muted : c.ink,
                                decoration: s.status == StopStatus.cancelled ? TextDecoration.lineThrough : null,
                              )),
                        ),
                        if (mine)
                          Text(k == bi ? 'Einstieg' : 'Ausstieg', style: TextStyle(fontSize: 13, color: c.accent)),
                      ]),
                    ),
                  );
                }),
            ]),
          ],
        ],
      ),
    );
  }
}

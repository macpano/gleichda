import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/efa/efa_client.dart' show lineKey;
import '../../data/transit_provider.dart';
import '../../data/trias/trias_parser.dart' show distanceBetween;
import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../../state/location.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';
import 'location_search_screen.dart';

class _StopBoard {
  _StopBoard(this.stop, {this.distance});

  final Location stop;
  final double? distance;
  DepartureBoard? board;
  String? error;
  bool expanded = false;
}

/// Abfahrten: mehrere Haltestellen in der Nähe untereinander, nach
/// Entfernung, mit Zeitwahl und Filter nach Verkehrsmitteln.
class DeparturesScreen extends ConsumerStatefulWidget {
  const DeparturesScreen({super.key, this.initialStop});

  /// Vorgewählte Haltestelle, z. B. aus einem Favoriten.
  final Location? initialStop;

  @override
  ConsumerState<DeparturesScreen> createState() => _DeparturesScreenState();
}

class _DeparturesScreenState extends ConsumerState<DeparturesScreen> {
  List<_StopBoard>? _stops;
  Location? _chosen;
  DateTime? _time;
  DateTime? _updatedAt;
  Set<ModeGroup> _hidden = {};
  bool _loading = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _chosen = widget.initialStop;
    Future.microtask(_load);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_time == null) _refreshBoards();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final p = ref.read(transitProvider);
    var boards = <_StopBoard>[];
    if (_chosen != null) {
      boards.add(_StopBoard(_chosen!));
    } else {
      try {
        final here = await ref.read(locationServiceProvider).current();
        final radius = (ref.read(settingsProvider).value ?? const AppSettings()).walkRadiusMeters;
        final near = await p.searchLocations('', near: here, limit: 6, radiusMeters: radius);
        boards = [
          for (final l in near.take(4)) _StopBoard(l, distance: distanceBetween(l, here)),
        ];
        if (boards.isEmpty) {
          _error = 'Keine Haltestelle im Umkreis von ${distanceText(radius.toDouble())}. '
              'Den Umkreis bestimmt der längste Fußweg unter Mehr → Profil.';
        }
      } on LocationException catch (e) {
        _error = '${e.message} Wähle eine Haltestelle über die Suche.';
      } on ProviderException catch (e) {
        _error = e.message;
      }
    }
    if (!mounted) return;
    setState(() => _stops = boards);
    await _refreshBoards();
  }

  Future<void> _refreshBoards() async {
    final stops = _stops;
    if (stops == null || stops.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final p = ref.read(transitProvider);
    await Future.wait(stops.map((s) async {
      try {
        s.board = await p.departures(s.stop, time: _time, limit: 16);
        s.error = null;
      } on ProviderException catch (e) {
        s.error = e.message;
      }
    }));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _updatedAt = DateTime.now();
    });
  }

  Future<void> _pickStop() async {
    final l = await Navigator.of(context).push<Location>(MaterialPageRoute(
        builder: (_) => const LocationSearchScreen(title: 'Haltestellen', stopsOnly: true)));
    if (l == null) return;
    _chosen = l;
    await _load();
  }

  Future<void> _pickTime() async {
    final picked = await showModalBottomSheet<DateTime?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _DepartureTimeSheet(current: _time),
    );
    if (!mounted) return;
    setState(() => _time = picked);
    await _refreshBoards();
  }

  Future<void> _pickModes() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Verkehrsmittel', style: ctx.t.section),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final g in ModeGroup.values)
                  ChoiceChipX(
                    label: g.label,
                    icon: _hidden.contains(g) ? Icons.close : Icons.check,
                    selected: !_hidden.contains(g),
                    onTap: () {
                      set(() => _hidden.contains(g) ? _hidden.remove(g) : _hidden.add(g));
                      setState(() => _hidden = {..._hidden});
                    },
                  ),
              ]),
            ]),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final walkPace = (ref.watch(settingsProvider).value ?? const AppSettings()).walkPace;
    final stops = _stops;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: pagePadding(context),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text('Abfahrten', style: context.t.screenTitle)),
            if (stops != null && stops.isNotEmpty)
              FreshnessStamp(updatedAt: _updatedAt, now: now, refreshing: _loading,
                  failed: stops.every((s) => s.error != null)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              ChoiceChipX(
                icon: Icons.schedule,
                label: _time == null ? 'Jetzt' : '${relativeDay(_time!, now) == 'Heute' ? '' : '${relativeDay(_time!, now)} '}ab ${hm(_time!)}',
                selected: false,
                onTap: _pickTime,
              ),
              const SizedBox(width: 8),
              ChoiceChipX(
                icon: Icons.filter_list,
                label: _hidden.isEmpty ? 'Alle Verkehrsmittel' : 'ohne ${_hidden.map((g) => g.label).join(', ')}',
                selected: false,
                onTap: _pickModes,
              ),
              const SizedBox(width: 8),
              ChoiceChipX(
                icon: _chosen == null ? Icons.search : Icons.my_location,
                label: _chosen == null ? 'Haltestelle wählen' : 'In der Nähe',
                selected: false,
                onTap: () {
                  if (_chosen == null) {
                    _pickStop();
                  } else {
                    _chosen = null;
                    _load();
                  }
                },
              ),
            ]),
          ),
          const SizedBox(height: 16),
          if (stops == null)
            for (var i = 0; i < 2; i++) ...[
              const SkeletonBlock(height: 22, width: 180),
              const SizedBox(height: 8),
              ListGroup(children: [for (var j = 0; j < 3; j++) const _DepartureSkeleton()]),
              const SizedBox(height: 16),
            ]
          else if (stops.isEmpty)
            Notice(_error ?? 'Keine Haltestellen.', action: 'Haltestelle wählen', onAction: _pickStop)
          else
            for (final s in stops) ...[
              _StopSection(
                data: s,
                now: now,
                hidden: _hidden,
                walkMinutes: s.distance == null
                    ? null
                    : (s.distance! * 1.3 / (1.3 * walkPace.walkPercent / 100) / 60).ceil(),
                onToggle: () => setState(() => s.expanded = !s.expanded),
              ),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}

class _StopSection extends ConsumerWidget {
  const _StopSection({
    required this.data,
    required this.now,
    required this.hidden,
    required this.onToggle,
    this.walkMinutes,
  });

  final _StopBoard data;
  final DateTime now;
  final Set<ModeGroup> hidden;
  final int? walkMinutes;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final all = (data.board?.departures ?? const <Departure>[])
        .where((d) => !hidden.any((g) => g.matches(d.line.mode)))
        .toList();
    final shown = data.expanded ? all : all.take(3).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(
        data.stop.name,
        trailing: Text(
          [
            if (data.distance != null) distanceText(data.distance!),
            if (walkMinutes != null) '$walkMinutes min',
            if (data.distance == null && data.stop.place != null) data.stop.place!,
          ].join(' · '),
          style: context.t.number(13).copyWith(color: c.muted),
        ),
      ),
      ListGroup(children: [
        if (data.board == null && data.error == null)
          for (var j = 0; j < 3; j++) const _DepartureSkeleton()
        else if (data.board == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(data.error!, style: TextStyle(color: c.orange)),
          )
        else if (all.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Keine Abfahrten in der nächsten Zeit.', style: TextStyle(color: c.muted)),
          )
        else ...[
          for (final d in shown) _DepartureRow(d, now: now, next: _nextOfSame(all, d)),
          if (all.length > 3)
            SizedBox(
              height: 44,
              child: TextButton(onPressed: onToggle, child: Text(data.expanded ? 'Weniger' : 'Alle Abfahrten')),
            ),
        ],
      ]),
    ]);
  }

  /// Bei Ausfall: die nächste Fahrt derselben Linie und Richtung.
  static Departure? _nextOfSame(List<Departure> all, Departure d) {
    if (d.status != StopStatus.cancelled) return null;
    return all
        .where((x) =>
            x.line.id == d.line.id &&
            x.direction == d.direction &&
            x.status != StopStatus.cancelled &&
            x.time.best.isAfter(d.time.best))
        .firstOrNull;
  }
}

class _DepartureRow extends ConsumerWidget {
  const _DepartureRow(this.d, {required this.now, this.next});

  final Departure d;
  final DateTime now;
  final Departure? next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final cancelled = d.status == StopStatus.cancelled;
    final sev = d.status == StopStatus.replacement || d.line.mode == TransportMode.replacementBus;
    final color = timeColor(context, d.time, status: d.status, neutral: c.ink);
    final state = cancelled
        ? 'fällt aus'
        : !d.time.hasRealtime
            ? 'Fahrplan'
            : (d.time.delayMinutes ?? 0) > 0
                ? '+${d.time.delayMinutes} min'
                : countdown(d.time.best, now);
    final sub = [
      if (d.platform != null) 'Steig ${d.platform}',
      if (d.plannedPlatform != null && d.platform != d.plannedPlatform) 'statt ${d.plannedPlatform}',
      if (cancelled && next != null) 'nächste ${hm(next!.time.best)}',
      if (sev) 'Ersatzverkehr',
    ].join(' · ');
    return InkWell(
      onTap: () => _lineSheet(context, ref, d.line),
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            LineBadge(d.line, width: 40, height: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                OneLine(d.direction,
                    style: TextStyle(
                        fontSize: 16,
                        color: cancelled ? c.muted : c.ink,
                        decoration: cancelled ? TextDecoration.lineThrough : null)),
                if (sub.isNotEmpty)
                  OneLine(sub, style: TextStyle(fontSize: 13, color: sev ? c.sev : c.muted)),
              ]),
            ),
            SizedBox(
              width: 76,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                FadeText(hm(d.time.best),
                    align: TextAlign.right,
                    style: context.t.time(16).copyWith(
                        color: color, decoration: cancelled ? TextDecoration.lineThrough : null)),
                FadeText(state,
                    align: TextAlign.right,
                    style: context.t.number(12).copyWith(color: d.time.hasRealtime || cancelled ? color : c.muted)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Tipp auf eine Abfahrt: Linie abonnieren.
Future<void> _lineSheet(BuildContext context, WidgetRef ref, Line line) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Consumer(builder: (ctx, ref, _) {
        final key = lineKey(line.id);
        final subs = ref.watch(subscriptionsProvider).value ?? const <Subscription>[];
        final on = subs.any((s) => s.lineId == key);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                LineBadge(line),
                const SizedBox(width: 12),
                Expanded(child: Text(line.longName ?? 'Linie ${line.name}', style: ctx.t.section)),
              ]),
              const SizedBox(height: 12),
              ListGroup(children: [
                SwitchListTile(
                  title: const Text('Linie abonnieren'),
                  subtitle: const Text('Benachrichtigung bei neuen Meldungen'),
                  value: on,
                  onChanged: (v) => v
                      ? ref.read(repositoryProvider).subscribe(Subscription(lineId: key, providerId: 'vrr', lineName: line.name))
                      : ref.read(repositoryProvider).unsubscribe(key),
                ),
              ]),
            ]),
          ),
        );
      }),
    );

class _DepartureTimeSheet extends StatefulWidget {
  const _DepartureTimeSheet({required this.current});

  final DateTime? current;

  @override
  State<_DepartureTimeSheet> createState() => _DepartureTimeSheetState();
}

class _DepartureTimeSheetState extends State<_DepartureTimeSheet> {
  late DateTime? _t = widget.current;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final now = DateTime.now();
    final base = _t ?? now;
    final today = DateTime(now.year, now.month, now.day);
    final dayIndex = DateTime(base.year, base.month, base.day).difference(today).inDays.clamp(0, 2);
    final quick = <(String, int?)>[('Jetzt', null), ('+15 min', 15), ('+30 min', 30), ('+1 Std', 60)];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SheetHeader('Abfahrtszeit', onDone: () => Navigator.pop(context, _t)),
          const SizedBox(height: 12),
          Segmented<int>(
            options: const [(0, 'Heute'), (1, 'Morgen'), (2, 'Datum')],
            value: dayIndex,
            height: 34,
            onChanged: (i) async {
              if (i < 2) {
                setState(() => _t = DateTime(today.year, today.month, today.day + i, base.hour, base.minute));
                return;
              }
              final d = await showDatePicker(
                  context: context, initialDate: base, firstDate: today, lastDate: today.add(const Duration(days: 60)));
              if (d != null) setState(() => _t = DateTime(d.year, d.month, d.day, base.hour, base.minute));
            },
          ),
          const SizedBox(height: 16),
          Row(children: [
            for (var i = 0; i < quick.length; i++) ...[
              Expanded(
                child: PickButton(
                  label: quick[i].$1,
                  selected: quick[i].$2 == null && _t == null,
                  onTap: () => Navigator.pop(
                      context, quick[i].$2 == null ? null : now.add(Duration(minutes: quick[i].$2!))),
                ),
              ),
              if (i < quick.length - 1) const SizedBox(width: 8),
            ],
          ]),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.hair))),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              const Expanded(child: Text('Uhrzeit', style: TextStyle(fontSize: 16))),
              Material(
                color: c.fill,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final p = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(base));
                    if (p != null) setState(() => _t = DateTime(base.year, base.month, base.day, p.hour, p.minute));
                  },
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    child: Text(hm(base), style: context.t.number(17)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _DepartureSkeleton extends StatelessWidget {
  const _DepartureSkeleton();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 56,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            SkeletonBlock(height: 24, width: 40),
            SizedBox(width: 12),
            Expanded(child: SkeletonBlock(height: 16)),
            SizedBox(width: 24),
            SkeletonBlock(height: 16, width: 44),
          ]),
        ),
      );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transit_provider.dart';
import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../../state/location.dart';
import '../../state/providers.dart';
import '../connection_views.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';
import 'time_sheet.dart';
import 'trip_screen.dart';

Set<TransportMode> modesOf(Set<ModeGroup> groups) => {
  for (final g in groups)
    for (final m in TransportMode.values)
      if (g.matches(m)) m,
};

/// Baut die Anfrage aus Suchprofil und persönlichem Profil.
TripQuery buildQuery({
  required Location from,
  required Location to,
  Location? via,
  required DateTime time,
  bool arriveBy = false,
  required AppSettings settings,
  bool usePersonal = true,
  TripOptimization optimization = TripOptimization.fastest,
  bool accessible = false,
}) => TripQuery(
  from: from,
  to: to,
  via: via,
  time: time,
  arriveBy: arriveBy,
  maxResults: 5,
  optimization: optimization,
  excludedModes: usePersonal ? modesOf(settings.excludedModes) : const {},
  accessible: accessible || (usePersonal && settings.accessible),
  walkSpeedPercent: usePersonal ? settings.walkPace.walkPercent : 100,
  maxWalkMinutes: settings.maxWalkMinutes,
);

/// Mehrere Profile parallel, Doppelte entfernt, nach Abfahrt sortiert.
Future<List<Trip>> searchMerged(TransitProvider p, List<TripQuery> queries) async {
  final results = await Future.wait(
    queries.map(
      (q) => p.planTrip(q).catchError((Object e) {
        if (identical(q, queries.first)) throw e;
        return <Trip>[];
      }),
    ),
  );
  return mergeTrips(results.first, results.skip(1).expand((l) => l));
}

/// Ergänzt die Hauptsuche um Treffer anderer Profile – aber nur innerhalb
/// ihres Zeitraums. Die anderen Profile reichen oft weiter in die Zukunft;
/// ohne diese Grenze entstanden Lücken, weil dort nur noch einzelne
/// Verbindungen standen.
List<Trip> mergeTrips(List<Trip> main, Iterable<Trip> extra) {
  final seen = <String>{};
  final out = <Trip>[
    for (final t in main)
      if (seen.add(tripSignature(t))) t,
  ];
  final until = main.isEmpty ? null : main.map((t) => t.departure.planned).reduce((a, b) => a.isAfter(b) ? a : b);
  for (final t in extra) {
    if (until != null && t.departure.planned.isAfter(until)) continue;
    if (seen.add(tripSignature(t))) out.add(t);
  }
  out.sort((a, b) => a.departure.best.compareTo(b.departure.best));
  return out;
}

/// Verbindungen, die schon begonnen haben, fallen weg: Die Auskunft liefert
/// teils Verbindungen, deren Fußweg vor der gesuchten Zeit beginnt.
List<Trip> dropStarted(List<Trip> trips, DateTime from) =>
    trips.where((t) => !t.departure.best.isBefore(from.subtract(const Duration(minutes: 1)))).toList();

String tripSignature(Trip t) =>
    '${t.departure.planned.toIso8601String()}|${t.arrival.planned.toIso8601String()}|${t.rides.map((r) => r.line?.id).join(',')}';

/// Verbindungen als Liste oder Zeitraster.
///
/// Ein gespeichertes Ergebnis aus dem Verlauf erscheint sofort und ist bis
/// zur Aktualisierung als „wird aktualisiert“ markiert.
class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({
    super.key,
    required this.from,
    required this.to,
    required this.time,
    required this.arriveBy,
    this.via,
  });

  final Location from;
  final Location to;
  final Location? via;

  /// null = jetzt
  final DateTime? time;
  final bool arriveBy;

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  List<Trip>? _trips;
  DateTime? _updatedAt;
  bool _loading = true;
  bool _fromCache = false;
  String? _error;
  Timer? _timer;
  bool _loadingMore = false;
  ConnectionSort _sort = ConnectionSort.arrival;

  /// Gesicherte Anschlüsse je Fahrt (EFA), nachgeladen nach jeder Suche.
  Map<String, Set<int>> _guaranteed = const {};

  Future<void> _loadGuaranteed() async {
    final trips = _trips;
    if (trips == null) return;
    final missing = trips.where((t) => !_guaranteed.containsKey(t.id) && t.rides.length > 1).toList();
    if (missing.isEmpty) return;
    try {
      final found = await ref.read(transitProvider).guaranteedForTrips(missing);
      if (mounted && found.isNotEmpty) setState(() => _guaranteed = {..._guaranteed, ...found});
    } catch (_) {
      // Ohne Angabe bleibt es bei der Prüfung nach Uhrzeit.
    }
  }

  /// Gesuchte Zeit (null = jetzt); in der Liste über „Heute ab …“ änderbar.
  late DateTime? _time = widget.time;
  late bool _arriveBy = widget.arriveBy;

  /// Nur stufenlose Wege – braucht eine neue Anfrage.
  bool _accessible = false;
  bool _personal = true;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (_time == null && widget.via == null) {
      final h = await ref.read(repositoryProvider).history(widget.from, widget.to);
      final now = DateTime.now();
      final cached = h?.cached
          ?.where((t) => t.departure.best.isAfter(now.subtract(const Duration(minutes: 2))))
          .toList();
      if (mounted && cached != null && cached.isNotEmpty) {
        setState(() {
          _trips = cached;
          _updatedAt = h!.cachedAt;
          _fromCache = true;
        });
      }
    }
    await _load();
    _scheduleRefresh();
  }

  /// „Jetzt“ läuft alle 30 s mit; eine feste Zeit nicht.
  void _scheduleRefresh() {
    _timer?.cancel();
    if (_time == null) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load(quiet: true));
    }
  }

  /// Tipp auf die Zeitzeile: dasselbe Zeitfenster wie auf der Startseite,
  /// danach sucht die Liste sofort neu.
  Future<void> _pickTime() async {
    ref.read(searchTimeProvider.notifier).set(SearchTime(time: _time, arriveBy: _arriveBy));
    await showTimeSheet(context, ref);
    if (!mounted) return;
    final t = ref.read(searchTimeProvider);
    if (t.time == _time && t.arriveBy == _arriveBy) return;
    setState(() {
      _time = t.time;
      _arriveBy = t.arriveBy;
      _trips = null;
    });
    await _load();
    _scheduleRefresh();
  }

  Future<List<Trip>> _query(DateTime time, {bool arriveBy = false}) async {
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final loc = ref.read(locationServiceProvider);
    final from = await loc.resolve(widget.from);
    final to = await loc.resolve(widget.to);
    TripQuery q(TripOptimization o, {bool accessible = false}) => buildQuery(
      from: from,
      to: to,
      via: widget.via,
      time: time,
      arriveBy: arriveBy,
      settings: settings,
      usePersonal: _personal,
      optimization: o,
      accessible: accessible,
    );
    final p = ref.read(transitProvider);
    // Immer alle Varianten zusammen – die Sortierung wählt nur die
    // Reihenfolge, ohne neue Anfrage.
    return _allProfiles(
      p,
      q(TripOptimization.fastest, accessible: _accessible),
      [
        q(TripOptimization.minChanges, accessible: _accessible),
        q(TripOptimization.leastWalking, accessible: _accessible),
      ],
      time,
      arriveBy,
    );
  }

  /// „Alle“: die schnellste Suche erscheint, sobald sie da ist; die Profile
  /// „wenig Umstiege“ und „wenig Fußweg“ ergänzen die Liste danach.
  Future<List<Trip>> _allProfiles(
    TransitProvider p,
    TripQuery main,
    List<TripQuery> extra,
    DateTime time,
    bool arriveBy,
  ) async {
    final seq = _seq;
    final others = [for (final q in extra) p.planTrip(q).catchError((Object _) => <Trip>[])];
    final first = await p.planTrip(main);
    final shown = arriveBy ? first : dropStarted(first, time);
    if (mounted && seq == _seq && (_trips == null || _fromCache || _trips!.isEmpty)) {
      setState(() {
        _trips = shown;
        _updatedAt = DateTime.now();
        _fromCache = false;
      });
    }
    final rest = await Future.wait(others);
    final merged = mergeTrips(first, rest.expand((l) => l));
    return arriveBy ? merged : dropStarted(merged, time);
  }

  Future<void> _load({bool quiet = false}) async {
    final seq = ++_seq;
    if (!quiet) {
      _autoLoads = 0;
      _laterExhausted = false;
    }
    setState(() {
      _loading = true;
      if (!quiet) _error = null;
    });
    try {
      final at = _time ?? DateTime.now();
      final found = await _query(at, arriveBy: _arriveBy);
      final trips = _arriveBy ? found : dropStarted(found, at);
      if (!mounted || seq != _seq) return;
      setState(() {
        _trips = trips;
        _updatedAt = DateTime.now();
        _fromCache = false;
        _loading = false;
        _error = null;
      });
      _loadGuaranteed();
      if (!_accessible && widget.via == null) {
        await ref.read(repositoryProvider).recordSearch(widget.from, widget.to, result: trips);
      }
    } on ProviderException catch (e) {
      _fail(seq, e.message);
    } on LocationException catch (e) {
      _fail(seq, e.message);
    } catch (_) {
      // Unerwartetes (z. B. Antwort nicht lesbar): nicht ewig „lädt“.
      _fail(seq, 'Auskunft antwortet nicht wie erwartet');
    }
  }

  void _fail(int seq, String message) {
    if (!mounted || seq != _seq) return;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  /// Endloses Scrollen: Kurz vor dem Ende der Liste lädt sie spätere
  /// Verbindungen von selbst nach (höchstens achtmal hintereinander und nur,
  /// solange neue dazukommen – „Später“ bleibt als Knopf und Ladeanzeige).
  int _autoLoads = 0;
  bool _laterExhausted = false;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || n.metrics.extentAfter > 400) return false;
    if (_loadingMore || _laterExhausted || _autoLoads >= 8 || (_trips?.isEmpty ?? true)) return false;
    _autoLoads++;
    _more(later: true);
    return false;
  }

  Future<void> _more({required bool later}) async {
    final trips = _trips;
    if (trips == null || trips.isEmpty || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final at = later
          ? trips.last.departure.planned.add(const Duration(minutes: 1))
          : trips.first.departure.planned.subtract(const Duration(minutes: 40));
      final more = await _query(at);
      if (!mounted) return;
      final ids = trips.map(tripSignature).toSet();
      final add = more
          .where((t) => ids.add(tripSignature(t)) && (later || t.departure.best.isBefore(trips.first.departure.best)))
          .toList();
      if (later) _laterExhausted = add.isEmpty;
      setState(() => _trips = [...trips, ...add]..sort((a, b) => a.departure.best.compareTo(b.departure.best)));
      _loadGuaranteed();
    } on ProviderException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on LocationException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _open(Trip t) {
    ref.read(lastTripProvider.notifier).open(t, updatedAt: _updatedAt);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final grid = settings.connectionsGrid;
    final items = _trips == null
        ? null
        : sortConnections(
            rateConnections(_trips!, transferMinutes: settings.transferPace.transferMinutes, guaranteed: _guaranteed),
            _sort,
          );
    final unreachable = items?.where((i) => !i.reachable).length ?? 0;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: ListView(
            padding: pagePadding(context),
            children: [
              SubpageHeader(
                title: 'Verbindungen',
                backLabel: 'Suche',
                trailing: FreshnessStamp(updatedAt: _updatedAt, now: now, refreshing: _loading, failed: _error != null),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RouteSummary(
                          from: widget.from.label,
                          to: widget.to.label,
                          when: widget.via == null ? null : 'über ${widget.via!.label}',
                        ),
                        // Zeit antippbar: öffnet das Zeitfenster, danach neue Suche.
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _pickTime,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule, size: 16, color: c.accent),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: OneLine(
                                    _time == null
                                        ? 'Heute ab ${hm(now)}'
                                        : '${_arriveBy ? 'Ankunft bis' : 'Ab'} ${dayText(_time!, now)} ${hm(_time!)}',
                                    style: context.t.number(14).copyWith(color: c.accent),
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down, size: 20, color: c.accent),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ViewToggle(
                    grid: grid,
                    onChanged: (g) => updateSettings(ref, (s) => s.copyWith(connectionsGrid: g)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Eine Zeile: Sortierung (Menü, sofort), barrierefrei (neue Suche)
              // und – bei angepasstem Profil – Profil an/aus.
              Row(
                children: [
                  MenuAnchor(
                    builder: (context, menu, _) => ChoiceChipX(
                      icon: Icons.swap_vert,
                      label: _sort.label,
                      selected: _sort != ConnectionSort.arrival,
                      dropdown: true,
                      onTap: () => menu.isOpen ? menu.close() : menu.open(),
                    ),
                    menuChildren: [
                      for (final o in ConnectionSort.values)
                        MenuItemButton(
                          leadingIcon: Icon(o == _sort ? Icons.check : null, size: 18),
                          onPressed: () => setState(() => _sort = o),
                          child: Text(o.label),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  ChoiceChipX(
                    icon: Icons.accessible,
                    label: 'Barrierefrei',
                    selected: _accessible,
                    onTap: () {
                      setState(() {
                        _accessible = !_accessible;
                        _trips = null;
                      });
                      _load();
                    },
                  ),
                  if (!settings.isDefault) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: ChoiceChipX(
                        label: _personal ? 'Profil an' : 'Profil aus',
                        selected: _personal,
                        icon: Icons.person_outline,
                        onTap: () {
                          setState(() => _personal = !_personal);
                          _load();
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              if (_error != null && items != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '$_error. Angezeigt wird der letzte Stand.',
                    style: TextStyle(fontSize: 14, color: c.orange),
                  ),
                ),
              if (items == null && _loading)
                ListGroup(children: [for (var i = 0; i < 4; i++) const _ConnectionSkeleton()])
              else if (items == null)
                Notice(_error ?? 'Keine Verbindungen gefunden.', action: 'Erneut versuchen', onAction: _load)
              else if (items.isEmpty)
                Notice('Keine Verbindungen gefunden.', action: 'Erneut versuchen', onAction: _load)
              else if (grid)
                ConnectionGrid(items: items, onTap: (i) => _open(i.trip))
              else
                ListGroup(
                  indent: 0,
                  children: [
                    MoreButton(label: 'Früher', busy: _loadingMore, onTap: () => _more(later: false)),
                    for (final i in items) ConnectionRow(item: i, stale: _fromCache, onTap: () => _open(i.trip)),
                    MoreButton(label: 'Später', busy: _loadingMore, onTap: () => _more(later: true)),
                  ],
                ),
              if (unreachable > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                  child: Text(
                    unreachable == 1
                        ? '1 Verbindung wegen Verspätung nicht erreichbar.'
                        : '$unreachable Verbindungen wegen Verspätung nicht erreichbar.',
                    style: TextStyle(fontSize: 13, color: c.muted),
                  ),
                ),
              if (grid && items != null && items.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: MoreButton(label: 'Früher', busy: _loadingMore, onTap: () => _more(later: false)),
                    ),
                    Expanded(
                      child: MoreButton(label: 'Später', busy: _loadingMore, onTap: () => _more(later: true)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// „Früher“/„Später“ unter bzw. über Verbindungslisten.
class MoreButton extends StatelessWidget {
  const MoreButton({super.key, required this.label, required this.busy, required this.onTap});

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: TextButton(onPressed: busy ? null : onTap, child: Text(label)),
  );
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.grid, required this.onChanged});

  final bool grid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget b(bool g, String label) => Semantics(
      button: true,
      selected: grid == g,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(g),
        child: Container(
          width: 40,
          height: 32,
          decoration: BoxDecoration(
            color: grid == g ? (dark ? const Color(0xFF3A3F46) : c.surface) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size(18, 16),
            painter: _ViewIconPainter(grid: g, color: grid == g ? c.ink : c.muted),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(Radii.input)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [b(false, 'Liste'), const SizedBox(width: 2), b(true, 'Zeitraster')],
      ),
    );
  }
}

/// Eigene Symbole für die Ansichtswahl: Liste = drei Zeilen wie die
/// Verbindungsbalken, Zeitraster = drei versetzte Spalten wie im Raster.
class _ViewIconPainter extends CustomPainter {
  _ViewIconPainter({required this.grid, required this.color});

  final bool grid;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height;
    if (grid) {
      // Spalten: Beginn und Länge versetzt wie Fahrten in der Zeitachse.
      const cols = [(0.2, 0.05, 0.6), (0.5, 0.3, 0.95), (0.8, 0.15, 0.75)];
      for (final (x, a, b) in cols) {
        canvas.drawLine(Offset(w * x, h * a + 1), Offset(w * x, h * b - 1), p);
      }
    } else {
      const rows = [(0.2, 0.95), (0.5, 0.7), (0.8, 0.85)];
      for (final (y, len) in rows) {
        canvas.drawLine(Offset(1.5, h * y), Offset(w * len, h * y), p);
      }
    }
  }

  @override
  bool shouldRepaint(_ViewIconPainter old) => old.grid != grid || old.color != color;
}

class _ConnectionSkeleton extends StatelessWidget {
  const _ConnectionSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBlock(height: 22, width: 140),
        SizedBox(height: 9),
        SkeletonBlock(height: 22),
        SizedBox(height: 9),
        SkeletonBlock(height: 15, width: 180),
      ],
    ),
  );
}

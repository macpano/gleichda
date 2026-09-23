import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository.dart';
import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../../state/location.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../trip_status.dart';
import '../widgets.dart';
import 'connections_screen.dart';
import 'location_search_screen.dart';
import 'options_sheet.dart';
import 'time_sheet.dart';
import 'trip_screen.dart';

/// Startbildschirm = Suche: Suchfelder, zuletzt angesehene Fahrt,
/// Favoriten, zuletzt gesucht.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: pagePadding(context),
      children: const [
        _Brand(),
        SizedBox(height: 20),
        _SearchCard(),
        SizedBox(height: 24),
        _LastTripSection(),
        _FavoritesSection(),
        _HistorySection(),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 40,
        child: Row(children: [LogoMark(size: 28), SizedBox(width: 10), Wordmark(size: 26)]),
      );
}

// --- Suchfelder ---

class _SearchCard extends ConsumerWidget {
  const _SearchCard();

  Future<void> _pick(BuildContext context, WidgetRef ref, bool isFrom) async {
    final l = await Navigator.of(context).push<Location>(MaterialPageRoute(
        builder: (_) => LocationSearchScreen(title: isFrom ? 'Von' : 'Nach', showNearby: isFrom)));
    if (l == null) return;
    final n = ref.read(routeProvider.notifier);
    isFrom ? n.setFrom(l) : n.setTo(l);
  }

  void _search(BuildContext context, WidgetRef ref) {
    final r = ref.read(routeProvider);
    if (r.from == null || r.to == null) {
      _pick(context, ref, r.from == null);
      return;
    }
    final t = ref.read(searchTimeProvider);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ConnectionsScreen(
            from: r.from!, to: r.to!, via: r.via, time: t.time, arriveBy: t.arriveBy)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final route = ref.watch(routeProvider);
    final time = ref.watch(searchTimeProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    Widget field(String label, Location? value, String hint, bool isFrom) => InkWell(
          onTap: () => _pick(context, ref, isFrom),
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
                const SizedBox(height: 2),
                Row(children: [
                  if (isHere(value)) ...[Icon(Icons.my_location, size: 15, color: c.accent), const SizedBox(width: 6)],
                  Expanded(
                    child: OneLine(value?.name ?? hint,
                        style: TextStyle(fontSize: 16, color: value == null ? c.muted : c.ink)),
                  ),
                ]),
              ],
            ),
          ),
        );
    return Column(children: [
      Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        clipBehavior: Clip.antiAlias,
        child: Row(children: [
          const SizedBox(width: 16),
          const _RouteGlyph(height: 112),
          const SizedBox(width: 12),
          Expanded(
            child: Column(children: [
              field('Von', route.from, 'Haltestelle, Adresse oder Ort', true),
              Divider(height: 1, thickness: 1, color: c.hair),
              field('Nach', route.to, 'Haltestelle, Adresse oder Ort', false),
            ]),
          ),
          IconButton(
            tooltip: 'Start und Ziel tauschen',
            onPressed: route.from == null && route.to == null
                ? null
                : () => ref.read(routeProvider.notifier).swap(),
            icon: Icon(Icons.swap_vert, color: c.muted),
          ),
          const SizedBox(width: 4),
        ]),
      ),
      const SizedBox(height: 10),
      Row(children: [
        _Chip(
          icon: Icons.schedule,
          label: timeChipLabel(time),
          onTap: () => showTimeSheet(context, ref),
        ),
        const SizedBox(width: 8),
        _Chip(
          icon: optionsActive(route, settings) ? Icons.tune : null,
          label: route.via != null ? 'über ${route.via!.name}' : 'Optionen',
          onTap: () => showOptionsSheet(context),
          maxWidth: 130,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 44,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                shape: buttonShape(context),
              ),
              onPressed: () => _search(context, ref),
              child: const Text('Suchen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ]),
    ]);
  }
}

/// Senkrechte Verbindung zwischen Start (Ring) und Ziel (Punkt).
class _RouteGlyph extends StatelessWidget {
  const _RouteGlyph({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: 12,
      height: height,
      child: CustomPaint(painter: _RouteGlyphPainter(c.accent, c.ink, c.muted)),
    );
  }
}

class _RouteGlyphPainter extends CustomPainter {
  _RouteGlyphPainter(this.start, this.end, this.line);

  final Color start;
  final Color end;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final top = size.height / 4, bottom = size.height * 3 / 4;
    canvas.drawCircle(Offset(x, top), 4.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = start);
    final dots = Paint()
      ..color = line
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    for (var y = top + 10; y < bottom - 8; y += 5) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 0.5), dots);
    }
    canvas.drawCircle(Offset(x, bottom), 5, Paint()..color = end);
  }

  @override
  bool shouldRepaint(_RouteGlyphPainter old) =>
      old.start != start || old.end != end || old.line != line;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, this.icon, this.maxWidth});

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // Android: Material-Chip (umrandet); iPhone: graue Fläche.
    final ios = context.isIOS;
    final radius = BorderRadius.circular(ios ? Radii.input : 8);
    return Material(
      color: ios ? c.fill : Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: radius, side: ios ? BorderSide.none : BorderSide(color: c.hair, width: 1)),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          height: 44,
          constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 16, color: c.ink), const SizedBox(width: 6)],
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: context.t.number(15).copyWith(color: c.ink)),
            ),
          ]),
        ),
      ),
    );
  }
}

// --- Zuletzt angesehene Fahrt ---

class _LastTripSection extends ConsumerWidget {
  const _LastTripSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lastTripProvider);
    final s = async.value;
    if (async.isLoading && s == null) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 24),
        child: SkeletonBlock(height: 150, radius: Radii.card),
      );
    }
    if (s == null) return const SizedBox.shrink();
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (s.offline) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.wifi_off_rounded, size: 18, color: c.ink2),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Keine Internetverbindung', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('Du siehst den Stand von ${hm(s.updatedAt)}.',
                      style: context.t.number(13).copyWith(color: c.ink2)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 18),
        ],
        SectionTitle('Zuletzt angesehen',
            trailing: s.offline
                ? Text('Stand ${hm(s.updatedAt)}', style: context.t.number(13).copyWith(color: c.muted))
                : FreshnessStamp(
                    updatedAt: s.updatedAt,
                    now: now,
                    refreshing: s.refreshing,
                    failed: s.failed,
                    realtime: s.hasRealtime,
                  )),
        Dismissible(
          key: ValueKey('last-${s.trip.id}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => ref.read(lastTripProvider.notifier).remove(),
          background: const SizedBox.shrink(),
          secondaryBackground: _SwipeBg(label: 'Entfernen', color: context.c.red, alignEnd: true),
          child: LastTripCard(state: s, now: now),
        ),
      ]),
    );
  }
}

class LastTripCard extends ConsumerWidget {
  const LastTripCard({super.key, required this.state, required this.now});

  final LastTripState state;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final trip = state.trip;
    final first = trip.rides.isEmpty ? trip.legs.first : trip.rides.first;
    final dep = first.from.departure;
    final issue = tripIssue(trip, lost: state.lost);
    final platform = first.from.platform;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const TripScreen())),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              OneLine(first.from.stop.name, style: TextStyle(fontSize: 15, color: c.ink2, height: 1.35)),
              OneLine('nach ${trip.destination.name}',
                  style: TextStyle(fontSize: 15, color: c.ink2, height: 1.35)),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                // Ohne Netz sind die Zeiten nicht live: grau statt farbig.
                if (state.offline)
                  Text(dep == null ? '' : hm(dep.best),
                      style: context.t.time(28).copyWith(color: c.ink2))
                else
                  TimeWithDelay(dep, size: 30, delaySize: 15, status: first.from.status),
                const Spacer(),
                FadeText(_rightText(dep, now),
                    style: state.offline
                        ? context.t.number(15).copyWith(color: c.muted)
                        : context.t.time(17).copyWith(color: c.ink)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                ..._badges(context, trip),
                const SizedBox(width: 6),
                Expanded(
                  child: OneLine(
                    [
                      if (platform != null) 'Steig $platform',
                      'an ${hm(trip.arrival.best)}',
                    ].join(' · '),
                    style: context.t.number(14).copyWith(color: c.muted),
                  ),
                ),
              ]),
            ]),
          ),
          if (issue != null)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.hair))),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: issue.color(context)),
                const SizedBox(width: 8),
                Expanded(child: OneLine(issue.title, style: TextStyle(fontSize: 14, color: issue.color(context)))),
              ]),
            ),
        ]),
      ),
    );
  }

  String _rightText(EventTime? dep, DateTime now) {
    if (dep == null) return '';
    if (!state.offline) return countdown(dep.best, now);
    final d = dep.delayMinutes ?? 0;
    return d > 0 ? 'zuletzt +$d min' : 'zuletzt ${countdown(dep.best, now)}';
  }

  List<Widget> _badges(BuildContext context, Trip trip) {
    final out = <Widget>[];
    final rides = trip.rides.take(3).toList();
    for (var i = 0; i < rides.length; i++) {
      if (i > 0) {
        out.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.chevron_right, size: 14, color: context.c.muted),
        ));
      }
      out.add(LineBadge(rides[i].line));
    }
    if (trip.rides.length > 3) {
      out.add(Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text('+${trip.rides.length - 3}', style: TextStyle(color: context.c.muted)),
      ));
    }
    return out;
  }
}

// --- Favoriten ---

/// Nächste Verbindung eines Favoriten, für die Zeit rechts in der Zeile.
final _favoriteNext = FutureProvider.autoDispose.family<Trip?, (Location, Location)>((ref, r) async {
  final settings = ref.read(settingsProvider).value ?? const AppSettings();
  try {
    final loc = ref.read(locationServiceProvider);
    final trips = await ref.read(transitProvider).planTrip(buildQuery(
          from: await loc.resolve(r.$1),
          to: await loc.resolve(r.$2),
          time: DateTime.now(),
          settings: settings,
        ));
    final now = DateTime.now();
    return trips.where((t) => t.departure.best.isAfter(now)).firstOrNull;
  } catch (_) {
    return null;
  }
});

class _FavoritesSection extends ConsumerStatefulWidget {
  const _FavoritesSection();

  @override
  ConsumerState<_FavoritesSection> createState() => _FavoritesSectionState();
}

class _FavoritesSectionState extends ConsumerState<_FavoritesSection> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Zeiten der Favoriten jede Minute neu.
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      for (final f in ref.read(favoritesProvider).value ?? const <FavoriteItem>[]) {
        if (f.from != null && f.to != null) ref.invalidate(_favoriteNext((f.from!, f.to!)));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favs = (ref.watch(favoritesProvider).value ?? const []).where((f) => f.kind == 'route').toList();
    if (favs.isEmpty) return const SizedBox.shrink();
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionTitle('Favoriten'),
        ListGroup(children: [
          for (final f in favs)
            Dismissible(
              key: ValueKey('fav-${f.id}'),
              direction: DismissDirection.endToStart,
              secondaryBackground: _SwipeBg(label: 'Entfernen', color: c.red, alignEnd: true),
              background: const SizedBox.shrink(),
              onDismissed: (_) => ref.read(repositoryProvider).deleteFavorite(f.id),
              child: InkWell(
                onTap: () => openConnections(context, ref, f.from!, f.to!),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 58),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        OneLine(f.to!.name, style: context.t.listRow),
                        const SizedBox(height: 1),
                        OneLine('${f.from!.name} → ${f.to!.name}', style: TextStyle(fontSize: 13, color: c.muted)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    _FavoriteTime(from: f.from!, to: f.to!),
                  ]),
                ),
              ),
            ),
        ]),
      ]),
    );
  }
}

class _FavoriteTime extends ConsumerWidget {
  const _FavoriteTime({required this.from, required this.to});

  final Location from;
  final Location to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final next = ref.watch(_favoriteNext((from, to)));
    final trip = next.value;
    final dep = trip == null ? null : (trip.rides.isEmpty ? trip.departure : trip.rides.first.from.departure);
    return SizedBox(
      width: 64,
      child: dep == null
          ? (next.isLoading
              ? const Align(alignment: Alignment.centerRight, child: SkeletonBlock(height: 16, width: 44))
              : const SizedBox.shrink())
          : FadeText(hm(dep.best),
              align: TextAlign.right,
              style: context.t.time(16).copyWith(color: timeColor(context, dep, neutral: c.muted))),
    );
  }
}

// --- Zuletzt gesucht ---

class _HistorySection extends ConsumerWidget {
  const _HistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final list = ref.watch(historyProvider).value ?? const <HistoryItem>[];
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionTitle('Zuletzt gesucht'),
      if (list.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('Deine Suchen erscheinen hier und lassen sich mit einem Tipp wiederholen.',
              style: context.t.secondary.copyWith(color: c.muted)),
        )
      else
        ListGroup(children: [
          for (final h in list)
            Dismissible(
              key: ValueKey('hist-${h.key}'),
              background: _SwipeBg(label: 'Favorit', color: c.accent, alignEnd: false),
              secondaryBackground: _SwipeBg(label: 'Löschen', color: c.red, alignEnd: true),
              confirmDismiss: (dir) async {
                final repo = ref.read(repositoryProvider);
                if (dir == DismissDirection.startToEnd) {
                  await repo.toggleFavoriteRoute(h.from, h.to);
                  return false; // Eintrag bleibt im Verlauf
                }
                return true;
              },
              onDismissed: (_) => ref.read(repositoryProvider).deleteHistory(h.key),
              child: InkWell(
                onTap: () => openConnections(context, ref, h.from, h.to),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(child: OneLine('${h.from.name} → ${h.to.name}', style: context.t.listRow)),
                    const SizedBox(width: 12),
                    Text(dayText(h.lastUsed, now), style: TextStyle(fontSize: 13, color: c.muted)),
                  ]),
                ),
              ),
            ),
        ]),
    ]);
  }
}

/// Führt eine gespeicherte Suche mit „jetzt“ erneut aus.
void openConnections(BuildContext context, WidgetRef ref, Location from, Location to) {
  ref.read(routeProvider.notifier)
    ..setFrom(from)
    ..setTo(to);
  Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConnectionsScreen(from: from, to: to, time: null, arriveBy: false)));
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({required this.label, required this.color, required this.alignEnd});

  final String label;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Container(
        color: color,
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      );
}

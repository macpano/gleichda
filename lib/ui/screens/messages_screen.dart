import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/efa/efa_client.dart' show lineKey;
import '../../data/transit_provider.dart';
import '../../data/trias/trias_parser.dart' show stopAreaId;
import '../../domain/models.dart';
import '../../domain/subscriptions.dart';
import '../../domain/product.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets.dart';
import 'line_search_screen.dart';
import 'subscriptions_screen.dart';

enum _Filter { all, myLines, myStops }

/// Gilt erst in der Zukunft (z. B. „ab 25.09.“).
bool _upcoming(Message m, DateTime now) => m.validFrom != null && m.validFrom!.isAfter(now);

/// Abschnitte der Liste: „In deiner Nähe“ (Linien, die hier halten), dann je
/// Verkehrsunternehmen der Umgebung, allgemeine Meldungen, zuletzt
/// „Demnächst“. Ohne Standort eine Liste ohne Titel.
List<(String?, List<Message>)> _sections(List<Message> list, MessagesState state, DateTime now) {
  final current = list.where((m) => !_upcoming(m, now)).toList();
  final upcoming = list.where((m) => _upcoming(m, now)).toList()..sort((a, b) => a.validFrom!.compareTo(b.validFrom!));
  if (state.nearLines.isEmpty && state.areaNetworks.isEmpty) {
    return [(null, current), ('Demnächst', upcoming)];
  }
  final near = current.where(state.isNear).toList();
  final rest = current.where((m) => !state.isNear(m)).toList();
  final byNetwork = <String, List<Message>>{};
  final general = <Message>[];
  for (final m in rest) {
    final net = state.networkOf(m);
    if (net == null) {
      general.add(m);
    } else {
      byNetwork.putIfAbsent(net, () => []).add(m);
    }
  }
  final nets = byNetwork.keys.toList()..sort((a, b) => byNetwork[b]!.length.compareTo(byNetwork[a]!.length));
  return [
    ('In deiner Nähe', near),
    for (final n in nets) (state.operators[n] ?? n.toUpperCase(), byNetwork[n]!),
    ('Allgemein', general),
    ('Demnächst', upcoming),
  ];
}

/// Meldungen: Störungen und Hinweise, gefiltert nach Abos und Haltestellen.
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  _Filter _filter = _Filter.all;

  /// Zusätzlich eingeschränkt auf ein Verkehrsunternehmen (Netzkürzel) und
  /// einen Ort (Gemeindeschlüssel) – beides über „Filter“.
  /// Mehrere möglich; leer heißt alle.
  Set<String> _operators = {};
  Set<String> _places = {};

  Future<void> _openFilter() => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _FilterSheet(
          places: _places,
          operators: _operators,
          onPlaces: (p) => setState(() => _places = p),
          onOperators: (o) => setState(() => _operators = o),
        ),
      );

  Set<String> _myStops() {
    final ids = <String>{};
    for (final f in ref.read(favoritesProvider).value ?? const []) {
      for (final l in [f.stop, f.from, f.to]) {
        if (l != null && l.type == LocationType.stop) ids.add(stopAreaId(l.id));
      }
    }
    for (final h in ref.read(historyProvider).value ?? const []) {
      for (final l in [h.from, h.to]) {
        if (l.type == LocationType.stop) ids.add(stopAreaId(l.id));
      }
    }
    final trip = ref.read(lastTripProvider).value?.trip;
    if (trip != null) {
      for (final r in trip.rides) {
        ids.add(stopAreaId(r.from.stop.id));
        ids.add(stopAreaId(r.to.stop.id));
      }
    }
    for (final p in ref.read(placesProvider).value ?? const <SavedPlace>[]) {
      if (p.location.type == LocationType.stop) ids.add(stopAreaId(p.location.id));
    }
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final async = ref.watch(messagesProvider);
    final subs = ref.watch(subscriptionsProvider).value ?? const <Subscription>[];
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final state = async.value;
    final subKeys = subs.map((s) => s.lineId).toSet();
    final stopKeys = _myStops();
    // Ein Ort, der nach Änderung des Umkreises nicht mehr dazugehört, fällt weg.
    final places = {
      for (final p in _places)
        if (state != null && state.regionNames.containsKey(p)) p,
    };
    final narrowed = places.isNotEmpty || _operators.isNotEmpty;
    final list = (state?.messages ?? const <Message>[])
        .where(
          (m) => switch (_filter) {
            // Alle: in der Nähe und im eigenen Ort; Nachbargemeinden nur mit
            // Linien, die hier halten. Mit Ort oder Unternehmen gilt deren Auswahl.
            _Filter.all => narrowed || state!.isRelevant(m),
            _Filter.myLines => subs.any((s) => subscriptionCovers(s, m)),
            _Filter.myStops => m.stopIds.map(stopAreaId).any(stopKeys.contains),
          },
        )
        .where((m) => places.isEmpty || m.regions.any(places.contains))
        .where((m) => _operators.isEmpty || m.lineIds.any((k) => _operators.contains(networkOf(k))))
        .toList();
    // Je Gruppe durch Komma getrennt, Gruppen durch Punkt: „Hagen, Herdecke · VER“.
    final placeNames = [for (final p in places) state!.regionNames[p]!];
    final operatorNames = [for (final o in _operators) state?.operators[o] ?? o.toUpperCase()];
    final active = [
      if (placeNames.isNotEmpty) placeNames.join(', '),
      if (operatorNames.isNotEmpty) operatorNames.join(', '),
    ];
    final count = placeNames.length + operatorNames.length;
    return RefreshIndicator(
      edgeOffset: MediaQuery.paddingOf(context).top,
      onRefresh: () => ref.read(messagesProvider.notifier).refresh(),
      child: ListView(
        padding: pagePadding(context),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('Meldungen', style: context.t.screenTitle)),
              if (state != null)
                FreshnessStamp(updatedAt: state.at, now: now, failed: state.failed, refreshing: async.isLoading),
            ],
          ),
          const SizedBox(height: 16),
          // Alle Filter in einer Reihe; ein langer Unternehmensname wird gekürzt.
          Row(
            children: [
              for (final (f, label) in const [
                (_Filter.all, 'Alle'),
                (_Filter.myLines, 'Abos'),
                (_Filter.myStops, 'Haltestellen'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChipX(label: label, selected: _filter == f, onTap: () => setState(() => _filter = f)),
                ),
              // Umkreis, Ort und Verkehrsunternehmen: Symbol, bei Auswahl mit
              // deren Zahl; die Namen stehen in der Zeile darunter.
              if (state != null)
                Flexible(
                  child: ChoiceChipX(
                    icon: Icons.tune,
                    label: count == 0 ? '' : '$count',
                    tooltip: 'Filter',
                    selected: active.isNotEmpty,
                    dropdown: true,
                    onTap: _openFilter,
                  ),
                ),
            ],
          ),
          if (active.isNotEmpty)
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  Expanded(
                    child: OneLine(
                      'Nur ${active.join(' · ')}',
                      style: TextStyle(fontSize: 14, color: c.muted),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _places = {};
                      _operators = {};
                    }),
                    child: const Text('Aufheben'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ListGroup(
            children: [
              ValueRow(
                icon: Icons.notifications_none,
                label: 'Abos',
                value: subs.isEmpty ? 'Keine Linien oder Unternehmen' : subs.map((x) => x.lineName).join(', '),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionsScreen())),
              ),
              ValueRow(
                icon: Icons.search,
                label: 'Linie oder Unternehmen suchen',
                labelColor: c.accent,
                chevron: false,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LineSearchScreen())),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state == null && async.isLoading) ...[
            for (var i = 0; i < 4; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SkeletonBlock(height: 92, radius: Radii.card),
              ),
          ] else if (state == null)
            Notice(
              async.error is ProviderException
                  ? (async.error as ProviderException).message
                  : 'Meldungen nicht abrufbar.',
              action: 'Erneut versuchen',
              onAction: () => ref.invalidate(messagesProvider),
            )
          else if (list.isEmpty)
            Notice(switch (_filter) {
              _Filter.myLines =>
                subs.isEmpty
                    ? 'Noch keine Linien abonniert. Über „Linie suchen und abonnieren“ oder eine Linie in einer Meldung.'
                    : 'Keine Meldungen zu deinen Linien.',
              _Filter.myStops => 'Keine Meldungen zu deinen Haltestellen.',
              _Filter.all => narrowed ? 'Keine Meldungen für ${active.join(' · ')}.' : 'Keine aktuellen Meldungen.',
            })
          else ...[
            // In deiner Nähe (Linien, die hier halten) zuerst, dann der Rest
            // des eigenen Orts, zuletzt „Demnächst“ (z. B. Sperrung am Wochenende).
            for (final (title, group) in _sections(list, state, now))
              if (group.isNotEmpty) ...[
                if (title != null) SectionTitle(title, small: true),
                ListGroup(
                  children: [for (final m in group) MessageCard(message: m, subscribed: subKeys)],
                ),
                const SizedBox(height: 16),
              ],
          ],
          if (state != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Quelle: VRR-Auskunft (EFA). „In deiner Nähe“: Linien an Haltestellen im Umkreis von 1,5 km; '
                'darunter die Verkehrsunternehmen der Umgebung. Orte im Umkreis von ${state.radius ~/ 1000} km.',
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            ),
        ],
      ),
    );
  }
}

String validityText(Message m) {
  String d(DateTime t) {
    final l = t.toLocal();
    return '${l.day.toString().padLeft(2, '0')}.${l.month.toString().padLeft(2, '0')}.';
  }

  if (m.validFrom == null && m.validTo == null) return '';
  if (m.validTo == null) {
    return m.validFrom!.isAfter(DateTime.now()) ? 'ab ${d(m.validFrom!)}' : 'seit ${d(m.validFrom!)}';
  }
  if (m.validFrom == null) return 'bis ${d(m.validTo!)}';
  return '${d(m.validFrom!)} – ${d(m.validTo!)}';
}

/// Eine Meldung: betroffene Linien, Zeitraum, Titel, Anfang des Texts.
class MessageCard extends ConsumerWidget {
  const MessageCard({super.key, required this.message, required this.subscribed});

  final Message message;
  final Set<String> subscribed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final m = message;
    final names = <String, String>{};
    for (var i = 0; i < m.lineIds.length && i < m.lineNames.length; i++) {
      names.putIfAbsent(m.lineIds[i], () => m.lineNames[i]);
    }
    final (String kind, Color kindColor) = messageKind(context, m);
    return InkWell(
      onTap: () => showMessageSheet(context, ref, m),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ...names.entries
                    .take(3)
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: LineBadge(
                          Line(id: e.key, name: e.value, mode: _modeGuess(e.value)),
                          height: 22,
                          width: 34,
                        ),
                      ),
                    ),
                if (names.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text('+${names.length - 3}', style: TextStyle(fontSize: 13, color: c.muted)),
                  ),
                Expanded(
                  child: OneLine(
                    kind,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kindColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(validityText(m), style: context.t.number(13).copyWith(color: c.muted)),
              ],
            ),
            const SizedBox(height: 6),
            Text(m.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3)),
            if (m.text != null) ...[
              const SizedBox(height: 2),
              Text(
                m.text!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, height: 1.4, color: c.ink2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Art der Meldung in Farbe: Umleitung orange, Ersatzverkehr violett,
/// Ausfall rot, sonst Hinweis grau.
(String, Color) messageKind(BuildContext context, Message m) {
  final c = context.c;
  (String, Color)? classify(String t) {
    t = t.toLowerCase();
    if (t.contains('ersatzverkehr') || RegExp(r'\bsev\b').hasMatch(t)) return ('Ersatzverkehr', c.sev);
    if (t.contains('umleitung') ||
        t.contains('verlegt') ||
        t.contains('verlegung') ||
        t.contains('haltestellenveränderung')) {
      return ('Umleitung', c.orange);
    }
    if (t.contains('fällt aus') || t.contains('ausfall') || t.contains('entfällt') || t.contains('entfallen')) {
      return ('Ausfall', c.red);
    }
    return null;
  }

  // Der Titel entscheidet; der Text nur, wenn der Titel nichts hergibt.
  return classify(m.title) ?? classify(m.text ?? '') ?? ('Hinweis', c.muted);
}

TransportMode _modeGuess(String name) => guessProduct(name).mode;

/// Meldungsdetail mit ganzem Text und Linienabo je Linie.
Future<void> showMessageSheet(BuildContext context, WidgetRef ref, Message m) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (ctx) => Consumer(
    builder: (ctx, ref, _) {
      final c = ctx.c;
      final subs = (ref.watch(subscriptionsProvider).value ?? const <Subscription>[]).map((s) => s.lineId).toSet();
      final names = <String, String>{};
      for (var i = 0; i < m.lineIds.length && i < m.lineNames.length; i++) {
        names.putIfAbsent(m.lineIds[i], () => m.lineNames[i]);
      }
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(m.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3)),
            const SizedBox(height: 4),
            Text(
              [validityText(m), if (m.source != null) m.source!].where((x) => x.isNotEmpty).join(' · '),
              style: TextStyle(fontSize: 13, color: c.muted),
            ),
            const SizedBox(height: 12),
            if (m.text != null) Text(m.text!, style: TextStyle(fontSize: 16, height: 1.45, color: c.ink)),
            if (names.isNotEmpty) ...[
              const SizedBox(height: 20),
              const SectionTitle('Betroffene Linien', small: true),
              ListGroup(
                children: [
                  for (final e in names.entries)
                    SizedBox(
                      height: 48,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            LineBadge(Line(id: e.key, name: e.value, mode: _modeGuess(e.value))),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => subs.contains(e.key)
                                  ? ref.read(repositoryProvider).unsubscribe(e.key)
                                  : ref
                                        .read(repositoryProvider)
                                        .subscribe(
                                          Subscription(lineId: lineKey(e.key), providerId: 'vrr', lineName: e.value),
                                        ),
                              icon: Icon(subs.contains(e.key) ? Icons.star : Icons.star_border, size: 18),
                              label: Text(subs.contains(e.key) ? 'Abonniert' : 'Abonnieren'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    },
  ),
);

/// Filter der Meldungen: Umkreis, Orte und Verkehrsunternehmen – bei Orten
/// und Unternehmen mehrere zugleich.
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({
    required this.places,
    required this.operators,
    required this.onPlaces,
    required this.onOperators,
  });

  final Set<String> places;
  final Set<String> operators;
  final ValueChanged<Set<String>> onPlaces;
  final ValueChanged<Set<String>> onOperators;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late Set<String> _places = {...widget.places};
  late Set<String> _operators = {...widget.operators};
  int? _loadingRadius;

  Future<void> _setRadius(int m) async {
    setState(() => _loadingRadius = m);
    await ref.read(messagesProvider.notifier).setRadius(m);
    if (mounted) setState(() => _loadingRadius = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final state = ref.watch(messagesProvider).value;
    final places = state?.regionNames ?? const <String, String>{};
    final operators = (state?.operators.entries.toList() ?? [])..sort((a, b) => a.value.compareTo(b.value));
    Widget title(String t) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(t, style: context.t.section),
        );
    // „Alle“ leert die Auswahl, jeder andere Chip schaltet sich selbst um.
    // Die Auswahl wird beim Tippen frisch gelesen, nicht beim Aufbau – sonst
    // ginge bei schnellem Tippen ein Haken verloren.
    Widget chips(String all, Map<String, String> items, Set<String> Function() current, ValueChanged<Set<String>> set) {
      Set<String> chosen() => current().where(items.containsKey).toSet();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChipX(label: all, selected: chosen().isEmpty, onTap: () => set({})),
          for (final e in items.entries)
            ChoiceChipX(
              label: e.value,
              selected: chosen().contains(e.key),
              onTap: () {
                final c = chosen();
                set(c.contains(e.key) ? ({...c}..remove(e.key)) : {...c, e.key});
              },
            ),
        ],
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHeader('Filter'),
              title('Umkreis'),
              Segmented<int>(
                options: [for (final r in messagesRadii) (r, '${r ~/ 1000} km')],
                value: _loadingRadius ?? state?.radius ?? defaultMessagesRadius,
                onChanged: _setRadius,
              ),
              // Platz für den Hinweis ist immer da – nichts springt.
              SizedBox(
                height: 22,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _loadingRadius != null
                        ? 'Orte und Meldungen werden geladen …'
                        : places.length == 1
                            ? '1 Ort'
                            : '${places.length} Orte',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ),
              ),
              if (places.isNotEmpty) ...[
                title('Orte'),
                chips('Alle Orte', places, () => _places, (p) {
                  setState(() => _places = p);
                  widget.onPlaces(p);
                }),
              ],
              if (operators.isNotEmpty) ...[
                title('Unternehmen'),
                chips('Alle', {for (final o in operators) o.key: o.value}, () => _operators, (o) {
                  setState(() => _operators = o);
                  widget.onOperators(o);
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

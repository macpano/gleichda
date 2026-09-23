import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/efa/efa_client.dart' show lineKey;
import '../../data/transit_provider.dart';
import '../../data/trias/trias_parser.dart' show stopAreaId;
import '../../domain/models.dart';
import '../../domain/product.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets.dart';
import 'line_search_screen.dart';
import 'subscriptions_screen.dart';

enum _Filter { all, myLines, myStops }

/// Meldungen: Störungen und Hinweise, gefiltert nach Abos und Haltestellen.
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  _Filter _filter = _Filter.all;

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
    final list = (state?.messages ?? const <Message>[]).where((m) => switch (_filter) {
          _Filter.all => true,
          _Filter.myLines => m.lineIds.any(subKeys.contains),
          _Filter.myStops => m.stopIds.map(stopAreaId).any(stopKeys.contains),
        }).toList();
    return RefreshIndicator(
      onRefresh: () => ref.read(messagesProvider.notifier).refresh(),
      child: ListView(
        padding: pagePadding(context),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text('Meldungen', style: context.t.screenTitle)),
            if (state != null)
              FreshnessStamp(updatedAt: state.at, now: now, failed: state.failed, refreshing: async.isLoading),
          ]),
          const SizedBox(height: 16),
          // Filter als Chips wie bei den Verbindungen – so passen auch lange
          // Namen wie „Meine Haltestellen“ ohne Kürzung.
          Wrap(runSpacing: 8, children: [
              for (final (f, label) in const [
                (_Filter.all, 'Alle'),
                (_Filter.myLines, 'Meine Linien'),
                (_Filter.myStops, 'Meine Haltestellen'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChipX(label: label, selected: _filter == f, onTap: () => setState(() => _filter = f)),
                ),
          ]),
          const SizedBox(height: 16),
          ListGroup(children: [
            ValueRow(
              icon: Icons.notifications_none,
              label: 'Linienabos',
              value: subs.isEmpty ? 'Keine Linien' : subs.map((x) => x.lineName).join(', '),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionsScreen())),
            ),
            ValueRow(
              icon: Icons.search,
              label: 'Linie suchen und abonnieren',
              labelColor: c.accent,
              chevron: false,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LineSearchScreen())),
            ),
          ]),
          const SizedBox(height: 16),
          if (state == null && async.isLoading)
            ...[for (var i = 0; i < 4; i++) const Padding(padding: EdgeInsets.only(bottom: 8), child: SkeletonBlock(height: 92, radius: Radii.card))]
          else if (state == null)
            Notice(
              async.error is ProviderException ? (async.error as ProviderException).message : 'Meldungen nicht abrufbar.',
              action: 'Erneut versuchen',
              onAction: () => ref.invalidate(messagesProvider),
            )
          else if (list.isEmpty)
            Notice(switch (_filter) {
              _Filter.myLines => subs.isEmpty
                  ? 'Noch keine Linien abonniert. Über „Linie suchen und abonnieren“ oder eine Linie in einer Meldung.'
                  : 'Keine Meldungen zu deinen Linien.',
              _Filter.myStops => 'Keine Meldungen zu deinen Haltestellen.',
              _Filter.all => 'Keine aktuellen Meldungen.',
            })
          else
            ListGroup(children: [for (final m in list) MessageCard(message: m, subscribed: subKeys)]),
          if (state != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Quelle: VRR-Auskunft (EFA), Gebiet Wuppertal.',
                  style: TextStyle(fontSize: 12, color: c.muted)),
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
  if (m.validTo == null) return 'seit ${d(m.validFrom!)}';
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            ...names.entries.take(3).map((e) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: LineBadge(Line(id: e.key, name: e.value, mode: _modeGuess(e.value)), height: 22, width: 34),
                )),
            if (names.length > 3)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text('+${names.length - 3}', style: TextStyle(fontSize: 13, color: c.muted)),
              ),
            Expanded(child: OneLine(kind, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kindColor))),
            const SizedBox(width: 8),
            Text(validityText(m), style: context.t.number(13).copyWith(color: c.muted)),
          ]),
          const SizedBox(height: 6),
          Text(m.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3)),
          if (m.text != null) ...[
            const SizedBox(height: 2),
            Text(m.text!, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, height: 1.4, color: c.ink2)),
          ],
        ]),
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
    if (t.contains('umleitung') || t.contains('verlegt') || t.contains('verlegung') || t.contains('haltestellenveränderung')) {
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
      builder: (ctx) => Consumer(builder: (ctx, ref, _) {
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
          builder: (ctx, scroll) => ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
            Text(m.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3)),
            const SizedBox(height: 4),
            Text([validityText(m), if (m.source != null) m.source!].where((x) => x.isNotEmpty).join(' · '),
                style: TextStyle(fontSize: 13, color: c.muted)),
            const SizedBox(height: 12),
            if (m.text != null) Text(m.text!, style: TextStyle(fontSize: 16, height: 1.45, color: c.ink)),
            if (names.isNotEmpty) ...[
              const SizedBox(height: 20),
              const SectionTitle('Betroffene Linien', small: true),
              ListGroup(children: [
                for (final e in names.entries)
                  SizedBox(
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        LineBadge(Line(id: e.key, name: e.value, mode: _modeGuess(e.value))),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => subs.contains(e.key)
                              ? ref.read(repositoryProvider).unsubscribe(e.key)
                              : ref.read(repositoryProvider).subscribe(Subscription(
                                    lineId: lineKey(e.key),
                                    providerId: 'vrr',
                                    lineName: e.value,
                                  )),
                          icon: Icon(subs.contains(e.key) ? Icons.star : Icons.star_border, size: 18),
                          label: Text(subs.contains(e.key) ? 'Abonniert' : 'Abonnieren'),
                        ),
                      ]),
                    ),
                  ),
              ]),
            ],
          ]),
        );
      }),
    );

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../domain/subscriptions.dart';
import '../../domain/product.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets.dart';
import 'line_search_screen.dart';

/// Zeitfenster zur Auswahl. Mehr braucht es im Alltag selten.
final _windows = <(String, TimeWindow?)>[
  ('Immer', null),
  ('Werktags 6–9 Uhr', const TimeWindow(weekdays: [1, 2, 3, 4, 5], fromMinute: 360, toMinute: 540)),
  ('Werktags 15–19 Uhr', const TimeWindow(weekdays: [1, 2, 3, 4, 5], fromMinute: 900, toMinute: 1140)),
  ('Werktags ganztägig', const TimeWindow(weekdays: [1, 2, 3, 4, 5])),
];

String windowLabel(TimeWindow? w) => _windows
    .firstWhere((e) => e.$2 == w, orElse: () => ('Eigenes Zeitfenster', w))
    .$1;

/// Mehr → Linienabos. Neue Meldungen zu diesen Linien kommen als
/// Benachrichtigung (App prüft etwa alle 15 min).
class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final subs = ref.watch(subscriptionsProvider).value ?? const <Subscription>[];
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          const SubpageHeader(title: 'Linienabos', backLabel: 'Zurück'),
          const SizedBox(height: 8),
          ListGroup(children: [
            InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LineSearchScreen())),
              child: SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Icon(Icons.add, size: 20, color: c.accent),
                    const SizedBox(width: 10),
                    Text('Linie hinzufügen', style: TextStyle(fontSize: 16, color: c.accent)),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          if (subs.isEmpty)
            const Notice('Noch nichts abonniert. Über „Linie hinzufügen“ eine Linie oder ein ganzes Verkehrsunternehmen wählen, '
                'oder bei den Abfahrten lange auf eine Linie drücken.')
          else
            ListGroup(children: [
              for (final s in subs)
                Dismissible(
                  key: ValueKey('sub-${s.lineId}'),
                  direction: DismissDirection.endToStart,
                  background: const SizedBox.shrink(),
                  secondaryBackground: Container(
                    color: c.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text('Entfernen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  onDismissed: (_) => ref.read(repositoryProvider).unsubscribe(s.lineId),
                  child: InkWell(
                    onTap: () => _editWindow(context, ref, s),
                    child: SizedBox(
                      height: 56,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(children: [
                          isOperatorSub(s)
                              ? _OperatorBadge(name: s.lineName)
                              : LineBadge(Line(id: s.lineId, name: s.lineName, mode: guessProduct(s.lineName).mode), slot: 56),
                          const SizedBox(width: 12),
                          Expanded(child: OneLine(windowLabel(s.window), style: TextStyle(fontSize: 15, color: c.muted))),
                          IconButton(
                            tooltip: '${isOperatorSub(s) ? s.lineName : 'Linie ${s.lineName}'} abbestellen',
                            icon: Icon(Icons.notifications_off_outlined, size: 20, color: c.muted),
                            onPressed: () => ref.read(repositoryProvider).unsubscribe(s.lineId),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          const SizedBox(height: 16),
          Text(
            'Gleich.da prüft im Hintergrund etwa alle 15 Minuten, ob es neue Meldungen zu deinen Linien gibt. '
            'Android bestimmt den genauen Zeitpunkt; ein Push-Dienst für sofortige Nachrichten folgt später. '
            'Die Abos bleiben auf diesem Gerät.',
            style: context.t.secondary.copyWith(color: c.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<void> _editWindow(BuildContext context, WidgetRef ref, Subscription s) async {
    final picked = await showModalBottomSheet<(String, TimeWindow?)>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Linie ${s.lineName}: benachrichtigen', style: ctx.t.section)),
          ),
          for (final w in _windows)
            ListTile(
              title: Text(w.$1),
              trailing: w.$2 == s.window ? Icon(Icons.check, color: ctx.c.accent) : null,
              onTap: () => Navigator.pop(ctx, w),
            ),
          ListTile(
            title: Text('Abo beenden', style: TextStyle(color: ctx.c.red)),
            onTap: () {
              ref.read(repositoryProvider).unsubscribe(s.lineId);
              Navigator.pop(ctx);
            },
          ),
        ]),
      ),
    );
    if (picked == null) return;
    await ref.read(repositoryProvider).subscribe(s.copyWith(window: picked.$2));
  }
}

/// Zeichen für ein abonniertes Verkehrsunternehmen (statt Linienschild).
class _OperatorBadge extends StatelessWidget {
  const _OperatorBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 24,
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all(color: c.ink2, width: 1.2), borderRadius: BorderRadius.circular(5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.apartment, size: 14, color: c.ink2),
        const SizedBox(width: 4),
        Flexible(child: OneLine(name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.ink2))),
      ]),
    );
  }
}

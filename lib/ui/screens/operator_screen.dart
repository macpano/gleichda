import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../domain/subscriptions.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets.dart';
import 'line_screen.dart' show SubscribeButton;
import 'messages_screen.dart' show MessageCard;

/// Ein Verkehrsunternehmen ansehen: seine aktuellen und angekündigten
/// Meldungen in der Umgebung, oben der Schalter zum Abonnieren.
class OperatorScreen extends ConsumerWidget {
  const OperatorScreen({super.key, required this.network, required this.name});

  final String network;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final state = ref.watch(messagesProvider).value;
    final subs = ref.watch(subscriptionsProvider).value ?? const <Subscription>[];
    final id = operatorSubId(network);
    final now = DateTime.now();
    final mine = (state?.messages ?? const <Message>[])
        .where((m) => m.lineIds.any((k) => networkOf(k) == network))
        .where((m) => m.validTo == null || m.validTo!.isAfter(now))
        .toList();
    final current = [for (final m in mine) if (m.validFrom == null || !m.validFrom!.isAfter(now)) m];
    final upcoming = [for (final m in mine) if (m.validFrom != null && m.validFrom!.isAfter(now)) m]
      ..sort((a, b) => a.validFrom!.compareTo(b.validFrom!));
    final keys = {for (final m in mine) ...m.lineIds};
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          const SubpageHeader(title: 'Verkehrsunternehmen', backLabel: 'Zurück'),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.apartment, size: 22, color: c.ink2),
            const SizedBox(width: 10),
            Expanded(child: OneLine(name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink))),
            const SizedBox(width: 8),
            SubscribeButton(
              subscribed: subs.any((s) => s.lineId == id),
              onToggle: (on) => on
                  ? ref.read(repositoryProvider).subscribe(Subscription(lineId: id, providerId: 'vrr', lineName: name))
                  : ref.read(repositoryProvider).unsubscribe(id),
            ),
          ]),
          const SizedBox(height: 6),
          Text('Abonniert meldet die App neue Störungen auf allen Linien von $name.',
              style: context.t.secondary.copyWith(color: c.muted, height: 1.4)),
          const SizedBox(height: 16),
          if (state == null)
            const SkeletonBlock(height: 92, radius: Radii.card)
          else if (mine.isEmpty)
            Notice('Keine aktuellen Meldungen von $name in deiner Umgebung.')
          else ...[
            if (current.isNotEmpty) ...[
              const SectionTitle('Aktuell'),
              ListGroup(children: [for (final m in current) MessageCard(message: m, subscribed: keys)]),
              const SizedBox(height: 16),
            ],
            if (upcoming.isNotEmpty) ...[
              const SectionTitle('Demnächst'),
              ListGroup(children: [for (final m in upcoming) MessageCard(message: m, subscribed: keys)]),
            ],
          ],
        ],
      ),
    );
  }
}

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
/// Meldungen eines Unternehmens im ganzen Verbund.
final _operatorMessages = FutureProvider.autoDispose.family<List<Message>, String>(
    (ref, network) => ref.watch(transitProvider).messagesForOperator(network));

class OperatorScreen extends ConsumerWidget {
  const OperatorScreen({super.key, required this.network, required this.name});

  final String network;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final async = ref.watch(_operatorMessages(network));
    // Bis der Verbund geladen ist: was in der Umgebung schon bekannt ist.
    final nearby = ref.watch(messagesProvider).value?.messages ?? const <Message>[];
    final source = async.value ?? nearby.where((m) => m.lineIds.any((k) => networkOf(k) == network)).toList();
    final subs = ref.watch(subscriptionsProvider).value ?? const <Subscription>[];
    final id = operatorSubId(network);
    final now = DateTime.now();
    final mine = source
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
          if (async.isLoading && mine.isEmpty)
            const SkeletonBlock(height: 92, radius: Radii.card)
          else if (mine.isEmpty)
            Notice('Keine aktuellen Meldungen von $name.')
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

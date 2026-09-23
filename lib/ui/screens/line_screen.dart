import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/efa/efa_client.dart' show lineKey;
import '../../data/transit_provider.dart';
import '../../domain/models.dart';
import '../../domain/product.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets.dart';
import 'messages_screen.dart' show MessageCard;

/// Eine Linie ansehen, ohne sie abonnieren zu müssen: aktuelle und
/// angekündigte Störungen, oben der Schalter zum Abonnieren.
class LineScreen extends ConsumerStatefulWidget {
  const LineScreen({super.key, required this.line});

  final Line line;

  @override
  ConsumerState<LineScreen> createState() => _LineScreenState();
}

class _LineScreenState extends ConsumerState<LineScreen> {
  List<Message>? _messages;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await ref.read(transitProvider).messagesForLine(lineKey(widget.line.id));
      final now = DateTime.now();
      final open = list.where((m) => m.validTo == null || m.validTo!.isAfter(now)).toList()
        // Laufende zuerst, dann angekündigte nach Beginn.
        ..sort((a, b) {
          final fa = a.validFrom != null && a.validFrom!.isAfter(now);
          final fb = b.validFrom != null && b.validFrom!.isAfter(now);
          if (fa != fb) return fa ? 1 : -1;
          if (fa) return a.validFrom!.compareTo(b.validFrom!);
          return 0;
        });
      if (mounted) setState(() => _messages = open);
    } on ProviderException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final line = widget.line;
    final key = lineKey(line.id);
    final subs = ref.watch(subscriptionsProvider).value ?? const <Subscription>[];
    final subscribed = subs.any((s) => s.lineId == key);
    final messages = _messages;
    final now = DateTime.now();
    final current = [
      for (final m in messages ?? const <Message>[])
        if (m.validFrom == null || !m.validFrom!.isAfter(now)) m,
    ];
    final upcoming = [
      for (final m in messages ?? const <Message>[])
        if (m.validFrom != null && m.validFrom!.isAfter(now)) m,
    ];
    // Ohne Doppelungen („Bus · Bus“) und ohne interne Kennungen („wsw:66“).
    final product = productOf(line).label;
    final info = <String>{
      product,
      if (line.longName != null && line.longName!.isNotEmpty && line.longName != product) line.longName!,
      if (line.operator != null && line.operator!.isNotEmpty && !line.operator!.contains(':')) line.operator!,
    }.join(' · ');
    return Scaffold(
      body: RefreshIndicator(
        edgeOffset: MediaQuery.paddingOf(context).top,
        onRefresh: _load,
        child: ListView(
          padding: pagePadding(context),
          children: [
            const SubpageHeader(title: 'Linie', backLabel: 'Zurück'),
            const SizedBox(height: 8),
            Row(
              children: [
                LineBadge(line),
                const SizedBox(width: 12),
                Expanded(
                  child: OneLine(info, style: TextStyle(fontSize: 14, color: c.ink2)),
                ),
                const SizedBox(width: 8),
                SubscribeButton(
                  subscribed: subscribed,
                  onToggle: (on) => on
                      ? ref
                            .read(repositoryProvider)
                            .subscribe(Subscription(lineId: key, providerId: 'vrr', lineName: line.name))
                      : ref.read(repositoryProvider).unsubscribe(key),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Notice(_error!)
            else if (messages == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.muted),
                  ),
                ),
              )
            else if (messages.isEmpty)
              const Notice('Keine aktuellen Störungen auf dieser Linie.')
            else ...[
              if (current.isNotEmpty) ...[
                const SectionTitle('Aktuell'),
                ListGroup(
                  children: [
                    for (final m in current) MessageCard(message: m, subscribed: {key}),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (upcoming.isNotEmpty) ...[
                const SectionTitle('Demnächst'),
                ListGroup(
                  children: [
                    for (final m in upcoming) MessageCard(message: m, subscribed: {key}),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Abonnieren-Schalter: abonniert = gefüllt mit Haken, ein Tipp bestellt ab.
class SubscribeButton extends StatelessWidget {
  const SubscribeButton({super.key, required this.subscribed, required this.onToggle});

  final bool subscribed;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: 120,
      height: 34,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: subscribed ? c.onAccent : c.accent,
          backgroundColor: subscribed ? c.accent : Colors.transparent,
          side: subscribed ? null : BorderSide(color: c.accent.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: () => onToggle(!subscribed),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(subscribed ? Icons.check : Icons.add, size: 16),
            const SizedBox(width: 4),
            Text(subscribed ? 'Abonniert' : 'Abonnieren', style: const TextStyle(fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}

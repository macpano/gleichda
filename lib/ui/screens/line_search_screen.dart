import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/efa/efa_client.dart' show lineKey;
import '../../data/transit_provider.dart';
import '../../domain/models.dart';
import '../../domain/product.dart';
import '../../state/location.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets.dart';

/// Linie suchen und abonnieren: Nummer eingeben („604“, „CE64“, „S8“),
/// Treffer mit Linienverlauf, rechts abonnieren.
class LineSearchScreen extends ConsumerStatefulWidget {
  const LineSearchScreen({super.key});

  @override
  ConsumerState<LineSearchScreen> createState() => _LineSearchScreenState();
}

class _LineSearchScreenState extends ConsumerState<LineSearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<Line>? _results;
  String? _error;
  bool _loading = false;
  int _query = 0;
  GeoPoint? _here;

  @override
  void initState() {
    super.initState();
    // Standort nur zum Sortieren; ohne ihn sucht die App trotzdem.
    ref.read(locationServiceProvider).current(preferRecent: true).then((p) {
      if (mounted) _here = (lat: p.lat, lon: p.lon);
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _changed(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    final n = ++_query;
    if (q.trim().isEmpty) {
      setState(() {
        _results = null;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await ref.read(transitProvider).searchLines(q, near: _here);
      if (!mounted || n != _query) return;
      setState(() {
        _results = list;
        _error = null;
      });
    } on ProviderException catch (e) {
      if (mounted && n == _query) setState(() => _error = e.message);
    } finally {
      if (mounted && n == _query) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final subs = ref.watch(subscriptionsProvider).value ?? const <Subscription>[];
    final subKeys = subs.map((s) => s.lineId).toSet();
    final results = _results;
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          const SubpageHeader(title: 'Linie suchen', backLabel: 'Zurück'),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: _changed,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            decoration: InputDecoration(
              hintText: 'Liniennummer, z. B. 604, U79, S8, RE1',
              prefixIcon: Icon(Icons.search, color: c.muted, size: 20),
              suffixIcon: _loading
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.muted)),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Notice(_error!)
          else if (results == null)
            Text(
              'Gesucht wird deutschlandweit; Linien in deiner Nähe stehen oben. Abonnierte Linien melden sich, '
              'sobald es neue Störungen oder Umleitungen gibt.',
              style: context.t.secondary.copyWith(color: c.muted, height: 1.4),
            )
          else if (results.isEmpty && !_loading)
            const Notice('Keine Linie gefunden.')
          else
            ListGroup(children: [
              for (final l in results)
                _LineRow(
                  line: l,
                  subscribed: subKeys.contains(lineKey(l.id)),
                  onToggle: (on) => on
                      ? ref.read(repositoryProvider).subscribe(
                          Subscription(lineId: lineKey(l.id), providerId: 'vrr', lineName: l.name))
                      : ref.read(repositoryProvider).unsubscribe(lineKey(l.id)),
                ),
            ]),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.subscribed, required this.onToggle});

  final Line line;
  final bool subscribed;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final product = productOf(line).label;
    final sub = [
      product,
      if (line.longName != null && line.longName!.isNotEmpty)
        line.longName!
      else if (line.operator != null)
        line.operator!,
    ].join(' · ');
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Row(children: [
          LineBadge(line),
          const SizedBox(width: 12),
          Expanded(child: OneLine(sub, style: TextStyle(fontSize: 14, color: c.ink2))),
          const SizedBox(width: 8),
          // Umschalter: abonniert = gefüllt mit Haken, ein Tipp bestellt ab.
          SizedBox(
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
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(subscribed ? Icons.check : Icons.add, size: 16),
                const SizedBox(width: 4),
                Text(subscribed ? 'Abonniert' : 'Abonnieren', style: const TextStyle(fontSize: 13.5)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

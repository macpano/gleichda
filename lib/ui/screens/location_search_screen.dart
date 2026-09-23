import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transit_provider.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets.dart';

/// Suche nach Haltestelle, Adresse oder Ort. Liefert die gewählte Location.
///
/// Vorschläge erscheinen sofort aus dem lokalen Haltestellen-Cache, die
/// Auskunft ergänzt sie nach kurzer Pause.
// TODO: Standort und „In der Nähe“ (Schritt 6).
class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({super.key, required this.title, this.stopsOnly = false});

  final String title;
  final bool stopsOnly;

  @override
  ConsumerState<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<Location> _local = const [];
  List<Location> _online = const [];
  bool _loading = false;
  String? _error;
  int _seq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _changed(String q) async {
    final seq = ++_seq;
    _debounce?.cancel();
    final repo = ref.read(repositoryProvider);
    final local = await repo.searchCachedStops(q);
    if (!mounted || seq != _seq) return;
    setState(() {
      _local = local;
      _error = null;
      _loading = q.trim().length >= 2;
      if (q.trim().isEmpty) _online = const [];
    });
    if (q.trim().length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final res = await ref.read(transitProvider).searchLocations(q, limit: 12);
        if (!mounted || seq != _seq) return;
        await repo.cacheStops(res);
        setState(() {
          _online = res;
          _loading = false;
        });
      } on ProviderException catch (e) {
        if (!mounted || seq != _seq) return;
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    });
  }

  List<Location> get _results {
    final seen = <String>{};
    final out = <Location>[];
    // Online-Treffer zuerst (bessere Sortierung), lokale ergänzen.
    for (final l in [..._online, ..._local]) {
      if (widget.stopsOnly && l.type != LocationType.stop) continue;
      if (seen.add(l.id)) out.add(l);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final q = _ctrl.text.trim();
    final history = ref.watch(historyProvider).value ?? const [];
    final recent = <String, Location>{};
    for (final h in history) {
      recent.putIfAbsent(h.to.id, () => h.to);
      recent.putIfAbsent(h.from.id, () => h.from);
    }
    final results = _results;
    return Scaffold(
      body: Padding(
        padding: pagePadding(context, bottom: 0),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _changed,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 17),
                decoration: InputDecoration(
                  hintText: widget.stopsOnly ? 'Haltestelle' : 'Haltestelle, Adresse, Ort',
                  prefixIcon: Icon(Icons.search, size: 20, color: c.muted),
                  isDense: true,
                ),
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ]),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
              if (q.isEmpty && recent.isNotEmpty) ...[
                const SectionTitle('Zuletzt gesucht', small: true),
                ListGroup(children: [
                  for (final l in recent.values.take(8)) _LocationRow(l, onTap: () => Navigator.pop(context, l)),
                ]),
              ],
              if (q.isNotEmpty) ...[
                SectionTitle(widget.title, small: true, trailing: SizedBox(
                  width: 14, height: 14,
                  child: _loading ? CircularProgressIndicator(strokeWidth: 2, color: c.muted) : null,
                )),
                if (results.isNotEmpty)
                  ListGroup(children: [
                    for (final l in results) _LocationRow(l, onTap: () => Navigator.pop(context, l)),
                  ])
                else if (!_loading)
                  Notice(_error ?? 'Keine Treffer für „$q“.', color: _error != null ? c.orange : null),
                if (_error != null && results.isNotEmpty)
                  Notice('$_error. Angezeigt werden gespeicherte Haltestellen.', color: c.orange),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow(this.l, {required this.onTap});

  final Location l;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final kind = switch (l.type) {
      LocationType.stop => 'Haltestelle',
      LocationType.address => 'Adresse',
      LocationType.poi => 'Ort',
      LocationType.coordinate => 'Standort',
    };
    final sub = [if (l.place != null && l.place!.isNotEmpty) l.place!, kind].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              OneLine(l.name, style: context.t.listRow),
              const SizedBox(height: 1),
              OneLine(sub, style: TextStyle(fontSize: 13, color: c.muted)),
            ]),
          ),
        ]),
      ),
    );
  }
}

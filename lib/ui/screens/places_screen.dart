import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets.dart';
import 'location_search_screen.dart';

String placeKindLabel(PlaceKind k) => switch (k) {
      PlaceKind.home => 'Zuhause',
      PlaceKind.work => 'Arbeit',
      PlaceKind.other => 'Ort',
    };

IconData placeIcon(PlaceKind k) => switch (k) {
      PlaceKind.home => Icons.home_outlined,
      PlaceKind.work => Icons.work_outline,
      PlaceKind.other => Icons.place_outlined,
    };

/// Mehr → Meine Orte: Zuhause, Arbeit und weitere. Nur auf dem Gerät.
class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final places = ref.watch(placesProvider).value ?? const <SavedPlace>[];
    SavedPlace? of(PlaceKind k) => places.where((p) => p.kind == k).firstOrNull;
    final others = places.where((p) => p.kind == PlaceKind.other).toList();

    Widget row(SavedPlace? p, PlaceKind kind) => InkWell(
          onTap: () => editPlace(context, ref, existing: p, kind: kind),
          onLongPress: p == null ? null : () => _delete(context, ref, p),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Icon(placeIcon(kind), color: c.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  OneLine(p?.name ?? placeKindLabel(kind), style: context.t.listRow),
                  OneLine(p == null ? 'Festlegen' : [p.location.name, if (p.location.place != null) p.location.place!].join(', '),
                      style: TextStyle(fontSize: 13, color: p == null ? c.accent : c.muted)),
                ]),
              ),
              const RowChevron(),
            ]),
          ),
        );

    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          const SubpageHeader(title: 'Meine Orte', backLabel: 'Mehr'),
          const SizedBox(height: 8),
          ListGroup(indent: 52, children: [row(of(PlaceKind.home), PlaceKind.home), row(of(PlaceKind.work), PlaceKind.work)]),
          const SizedBox(height: 16),
          const SectionTitle('Weitere Orte', small: true),
          ListGroup(indent: 52, children: [
            for (final p in others) row(p, PlaceKind.other),
            InkWell(
              onTap: () => editPlace(context, ref, kind: PlaceKind.other),
              child: SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Icon(Icons.add, color: c.accent),
                    const SizedBox(width: 12),
                    Text('Ort hinzufügen', style: context.t.listRow.copyWith(color: c.accent)),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Text('Orte erscheinen in der Suche ganz oben und lassen sich in Weckern wählen. '
              'Sie bleiben auf diesem Gerät. Lange drücken zum Löschen.',
              style: context.t.secondary.copyWith(color: c.muted, height: 1.4)),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, SavedPlace p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('„${p.name}“ löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) await ref.read(repositoryProvider).deletePlace(p.id);
  }
}

/// Ort anlegen oder ändern: Ort suchen, bei „weiteren“ Orten auch benennen.
Future<void> editPlace(BuildContext context, WidgetRef ref, {SavedPlace? existing, required PlaceKind kind}) async {
  final loc = await Navigator.of(context).push<Location>(MaterialPageRoute(
      builder: (_) => LocationSearchScreen(title: placeKindLabel(kind), showPlaces: false)));
  if (loc == null || !context.mounted) return;
  var name = existing?.name ?? placeKindLabel(kind);
  if (kind == PlaceKind.other) {
    final ctrl = TextEditingController(text: existing?.name ?? loc.name);
    final entered = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name des Orts'),
        content: TextField(controller: ctrl, autofocus: true, textCapitalization: TextCapitalization.sentences),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Speichern')),
        ],
      ),
    );
    if (entered == null || entered.isEmpty) return;
    name = entered;
  }
  await ref.read(repositoryProvider).savePlace(SavedPlace(
        id: existing?.id ?? (kind == PlaceKind.other ? 'ort-${DateTime.now().millisecondsSinceEpoch}' : kind.name),
        name: name,
        kind: kind,
        location: loc,
      ));
}

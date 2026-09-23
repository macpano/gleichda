import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme.dart';
import '../widgets.dart';

/// Alle Farben und Textstile aus design.md, zum Vergleich hell/dunkel.
class DesignDemoScreen extends StatelessWidget {
  const DesignDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    String hex(Color col) =>
        '#${col.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    final planned = DateTime(2026, 9, 23, 14, 32);
    // TODO: echte Daten – nur Anschauungswerte für diesen Demo-Screen.
    final samples = [
      ('pünktlich', EventTime(planned: planned, estimated: planned, quality: TimeQuality.realtime), StopStatus.normal),
      ('verspätet', EventTime(planned: planned, estimated: planned.add(const Duration(minutes: 3)), quality: TimeQuality.realtime), StopStatus.normal),
      ('nur Fahrplan', EventTime(planned: planned), StopStatus.normal),
      ('Ausfall', EventTime(planned: planned), StopStatus.cancelled),
    ];
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          const SubpageHeader(title: 'Farben und Schriften', backLabel: 'Mehr'),
          const SizedBox(height: 8),
          const Row(children: [LogoMark(size: 44), SizedBox(width: 12), Wordmark(size: 34)]),
          const SizedBox(height: 24),
          const SectionTitle('Farben'),
          ListGroup(children: [
            for (final e in c.named.entries)
              SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: e.value,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: c.hair),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.key, style: t.listRow)),
                    Text(hex(e.value), style: t.number(15).copyWith(color: c.muted)),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 24),
          const SectionTitle('Schrift'),
          ListGroup(children: [
            for (final (label, style) in [
              ('Bildschirmtitel 28', t.screenTitle),
              ('Listenzeile ${t.listRow.fontSize!.round()}', t.listRow),
              ('Sekundärzeile 15', t.secondary),
              ('Label 13', t.label),
              ('Tableiste 11', t.tab),
              ('Zeit 30 · 14:35 11:11', t.time(30)),
              ('Zahlen 15 · 1 234 567', t.number(15)),
            ])
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: OneLine(label, style: style),
              ),
          ]),
          const SizedBox(height: 24),
          const SectionTitle('Zeiten und Linien'),
          ListGroup(children: [
            for (final (label, time, status) in samples)
              SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    TimeWithDelay(time, status: status),
                    const SizedBox(width: 12),
                    Text(label, style: t.secondary.copyWith(color: c.muted)),
                  ]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final (name, mode) in [
                  ('640', TransportMode.bus),
                  ('60', TransportMode.suspension),
                  ('S8', TransportMode.suburbanRail),
                  ('RE7', TransportMode.rail),
                  ('SEV', TransportMode.replacementBus),
                ])
                  LineBadge(Line(id: name, name: name, mode: mode)),
              ]),
            ),
          ]),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../../state/alarm_planner.dart';
import '../../state/notifications.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';
import 'location_search_screen.dart';

const _weekdayShort = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

String minuteText(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

final _planProvider = FutureProvider.autoDispose.family<AlarmPlan?, String>(
    (ref, id) => loadPlan(ref.watch(repositoryProvider), id));

/// Mehr → Fahrtenwecker: wiederkehrende Fahrten, geweckt wird zum
/// tatsächlichen Aufbruchszeitpunkt.
class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final alarms = ref.watch(alarmsProvider).value ?? const <Alarm>[];
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          SubpageHeader(
            title: 'Fahrtenwecker',
            backLabel: 'Mehr',
            trailing: IconButton(
              tooltip: 'Neuer Wecker',
              icon: Icon(Icons.add, color: c.accent),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlarmEditScreen())),
            ),
          ),
          const SizedBox(height: 8),
          if (alarms.isEmpty)
            Notice('Noch kein Wecker. Ein Wecker weckt zur Fahrt, etwa zur Arbeit, und rechnet Gehzeit und Echtzeit mit ein.',
                action: 'Wecker anlegen',
                onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlarmEditScreen())))
          else
            ListGroup(children: [for (final a in alarms) _AlarmRow(a)]),
          const SizedBox(height: 16),
          Text(
            'Gleichda prüft die Fahrt vor dem Wecken mit Echtzeit, etwa alle 15 Minuten. '
            'Fällt die übliche Fahrt aus, weckt der Wecker früher und nennt die Alternative.',
            style: context.t.secondary.copyWith(color: c.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _AlarmRow extends ConsumerWidget {
  const _AlarmRow(this.a);

  final Alarm a;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final plan = ref.watch(_planProvider(a.id)).value;
    final now = DateTime.now();
    final planText = !a.enabled
        ? 'aus'
        : plan == null || plan.wake.isBefore(now)
            ? 'wird geplant'
            : [
                '${relativeDay(plan.wake, now)} ${hm(plan.wake)} wecken',
                if (plan.line != null) '${plan.line} ${plan.status ?? ''}'.trim(),
              ].join(' · ');
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlarmEditScreen(existing: a))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(minuteText(a.minuteOfDay),
                    style: context.t.time(26).copyWith(color: a.enabled ? c.ink : c.muted)),
                const SizedBox(width: 10),
                Expanded(child: OneLine(a.name, style: context.t.listRow.copyWith(color: a.enabled ? c.ink : c.muted))),
              ]),
              const SizedBox(height: 2),
              OneLine('${a.timeRef == AlarmTimeRef.arriveBy ? 'Ankommen' : 'Losfahren'} · ${a.from.name} → ${a.to.name}',
                  style: TextStyle(fontSize: 13, color: c.muted)),
              const SizedBox(height: 6),
              Row(children: [
                for (var d = 1; d <= 7; d++)
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: a.weekdays.contains(d) ? (a.enabled ? c.accent : c.muted) : c.fill,
                    ),
                    child: Text(_weekdayShort[d - 1].substring(0, 1),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: a.weekdays.contains(d) ? c.onAccent : c.muted)),
                  ),
              ]),
              const SizedBox(height: 6),
              OneLine(planText,
                  style: context.t.number(13).copyWith(color: plan?.problem == true ? c.orange : c.muted)),
            ]),
          ),
          Switch(
            value: a.enabled,
            onChanged: (v) async {
              final next = a.copyWith(enabled: v);
              await ref.read(repositoryProvider).saveAlarm(next);
              await _plan(ref, next);
            },
          ),
        ]),
      ),
    );
  }
}

Future<void> _plan(WidgetRef ref, Alarm a) async {
  try {
    await planAlarm(ref.read(repositoryProvider), ref.read(transitProvider), a,
        settings: ref.read(settingsProvider).value ?? const AppSettings());
  } catch (_) {
    // Planung folgt im Hintergrund.
  }
  ref.invalidate(_planProvider(a.id));
}

/// Neuer Wecker bzw. Wecker ändern.
class AlarmEditScreen extends ConsumerStatefulWidget {
  const AlarmEditScreen({super.key, this.existing});

  final Alarm? existing;

  @override
  ConsumerState<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends ConsumerState<AlarmEditScreen> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? 'Zur Arbeit');
  Location? _from;
  Location? _to;
  late AlarmTimeRef _ref = widget.existing?.timeRef ?? AlarmTimeRef.arriveBy;
  late int _minute = widget.existing?.minuteOfDay ?? 8 * 60;
  late Set<int> _days = {...?widget.existing?.weekdays} ;
  late int _lead = widget.existing?.leadMinutes ?? 5;
  late bool _earlier = widget.existing?.earlierOnDisruption ?? true;
  late bool _companion = widget.existing?.startCompanion ?? false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _from = widget.existing?.from;
    _to = widget.existing?.to;
    if (widget.existing == null) {
      _days = {1, 2, 3, 4, 5};
      final places = ref.read(placesProvider).value ?? const <SavedPlace>[];
      _from = places.where((p) => p.kind == PlaceKind.home).firstOrNull?.location;
      _to = places.where((p) => p.kind == PlaceKind.work).firstOrNull?.location;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick(bool from) async {
    final l = await Navigator.of(context).push<Location>(MaterialPageRoute(
        builder: (_) => LocationSearchScreen(title: from ? 'Von' : 'Nach', allowHere: false)));
    if (l != null) setState(() => from ? _from = l : _to = l);
  }

  Future<void> _save() async {
    if (_from == null || _to == null || _days.isEmpty) return;
    setState(() => _saving = true);
    await Notifications.requestPermission();
    await Notifications.requestExactAlarms();
    final a = Alarm(
      id: widget.existing?.id ?? 'wecker-${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim().isEmpty ? 'Wecker' : _name.text.trim(),
      from: _from!,
      to: _to!,
      timeRef: _ref,
      minuteOfDay: _minute,
      weekdays: (_days.toList()..sort()),
      leadMinutes: _lead,
      earlierOnDisruption: _earlier,
      startCompanion: _companion,
      enabled: widget.existing?.enabled ?? true,
    );
    await ref.read(repositoryProvider).saveAlarm(a);
    await _plan(ref, a);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget field(String label, Location? l, bool from) => InkWell(
          onTap: () => _pick(from),
          child: SizedBox(
            height: 56,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
              OneLine(l?.name ?? 'Ort wählen', style: TextStyle(fontSize: 16, color: l == null ? c.accent : c.ink)),
            ]),
          ),
        );
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          SubpageHeader(
            title: widget.existing == null ? 'Neuer Wecker' : 'Wecker',
            backLabel: 'Wecker',
            trailing: widget.existing == null
                ? null
                : IconButton(
                    tooltip: 'Löschen',
                    icon: Icon(Icons.delete_outline, color: c.red),
                    onPressed: () async {
                      await Notifications.cancel(alarmNotificationId(widget.existing!.id));
                      await ref.read(repositoryProvider).deleteAlarm(widget.existing!.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
          ),
          const SizedBox(height: 8),
          ListGroup(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Name', filled: false, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 8)),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Material(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            child: Row(children: [
              const SizedBox(width: 16),
              SizedBox(width: 10, height: 112, child: CustomPaint(painter: MiniRoutePainter(c.muted, c.ink))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(children: [
                  field('Von', _from, true),
                  Divider(height: 1, color: c.hair),
                  field('Nach', _to, false),
                ]),
              ),
              IconButton(
                tooltip: 'Tauschen',
                onPressed: () => setState(() {
                  final f = _from;
                  _from = _to;
                  _to = f;
                }),
                icon: Icon(Icons.swap_vert, color: c.muted),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SegmentedButton<AlarmTimeRef>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: AlarmTimeRef.arriveBy, label: Text('Ankommen um')),
              ButtonSegment(value: AlarmTimeRef.departAt, label: Text('Losfahren um')),
            ],
            selected: {_ref},
            onSelectionChanged: (s) => setState(() => _ref = s.first),
          ),
          const SizedBox(height: 12),
          ListGroup(children: [
            ListTile(
              title: const Text('Uhrzeit'),
              trailing: Text(minuteText(_minute), style: context.t.time(20)),
              onTap: () async {
                final t = await showTimePicker(
                    context: context, initialTime: TimeOfDay(hour: _minute ~/ 60, minute: _minute % 60));
                if (t != null) setState(() => _minute = t.hour * 60 + t.minute);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (var d = 1; d <= 7; d++)
                  InkResponse(
                    onTap: () => setState(() => _days.contains(d) ? _days.remove(d) : _days.add(d)),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _days.contains(d) ? c.accent : c.fill),
                      child: Text(_weekdayShort[d - 1],
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: _days.contains(d) ? c.onAccent : c.ink)),
                    ),
                  ),
              ]),
            ),
            ListTile(
              title: const Text('Vorlauf zum Losgehen'),
              trailing: DropdownButton<int>(
                value: _lead,
                underline: const SizedBox.shrink(),
                items: [for (final m in [0, 5, 10, 15, 20, 30]) DropdownMenuItem(value: m, child: Text('$m min'))],
                onChanged: (v) => setState(() => _lead = v ?? 5),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          ListGroup(children: [
            SwitchListTile(
              title: const Text('Bei Störung früher wecken'),
              value: _earlier,
              onChanged: (v) => setState(() => _earlier = v),
            ),
            SwitchListTile(
              title: const Text('Unterwegs-Modus starten'),
              subtitle: const Text('Beim Öffnen des Weckers wird die Fahrt begleitet.'),
              value: _companion,
              onChanged: (v) => setState(() => _companion = v),
            ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
              ),
              onPressed: _saving || _from == null || _to == null || _days.isEmpty ? null : _save,
              child: Text(_saving ? 'Wird geplant …' : 'Speichern',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

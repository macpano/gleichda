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

const _dayLetters = ['M', 'D', 'M', 'D', 'F', 'S', 'S'];

String minuteText(int m) => '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';

final _planProvider = FutureProvider.autoDispose.family<AlarmPlan?, String>(
    (ref, id) => loadPlan(ref.watch(repositoryProvider), id));

/// Mehr → Fahrtenwecker, wie im Entwurf: je Wecker eine Karte.
class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final alarms = ref.watch(alarmsProvider).value ?? const <Alarm>[];
    void add() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlarmEditScreen()));
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          SubpageHeader(
            title: 'Fahrtenwecker',
            backLabel: 'Mehr',
            trailing: TextButton(onPressed: add, child: const Text('Neu', style: TextStyle(fontSize: 17))),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('Gleich.da prüft deine Fahrt vorher mit Echtzeit und weckt dich, wenn du losmusst.',
                style: context.t.secondary.copyWith(color: c.muted, height: 1.4)),
          ),
          const SizedBox(height: 16),
          for (final a in alarms) ...[_AlarmCard(a), const SizedBox(height: 14)],
          Material(
            color: c.fill,
            borderRadius: BorderRadius.circular(Radii.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.card),
              onTap: add,
              child: SizedBox(
                height: 46,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add, color: c.accent),
                  const SizedBox(width: 8),
                  Text('Wecker hinzufügen',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.accent)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmCard extends ConsumerWidget {
  const _AlarmCard(this.a);

  final Alarm a;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final plan = ref.watch(_planProvider(a.id)).value;
    final now = DateTime.now();
    final on = a.enabled;
    final (String status, Color statusColor) = !on
        ? ('Ausgeschaltet', c.muted)
        : plan == null || plan.wake.isBefore(now)
            ? ('Wird geplant', c.muted)
            : (
                [
                  '${relativeDay(plan.wake, now)} ${hm(plan.wake)} wecken',
                  if (plan.line != null) '${plan.line} ${plan.status ?? ''}'.trim(),
                ].join(' · '),
                plan.problem ? c.orange : (plan.status == 'nur Fahrplan' ? c.muted : c.green),
              );
    return Opacity(
      opacity: on ? 1 : 0.6,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlarmEditScreen(existing: a))),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    OneLine(a.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    OneLine('${a.from.name} → ${a.to.name}', style: TextStyle(fontSize: 15, color: c.muted)),
                  ]),
                ),
                Switch(
                  value: on,
                  onChanged: (v) async {
                    final next = a.copyWith(enabled: v);
                    await ref.read(repositoryProvider).saveAlarm(next);
                    await _plan(ref, next);
                  },
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                for (var d = 1; d <= 7; d++)
                  Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(right: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: a.weekdays.contains(d) ? c.accent : c.fill,
                    ),
                    child: Text(_dayLetters[d - 1],
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: a.weekdays.contains(d) ? c.onAccent : c.muted)),
                  ),
                Expanded(
                  child: Text('${a.timeRef == AlarmTimeRef.arriveBy ? 'an' : 'ab'} ${minuteText(a.minuteOfDay)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: context.t.number(15).copyWith(color: c.muted)),
                ),
              ]),
              const SizedBox(height: 12),
              Divider(height: 1, color: c.hair),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.schedule, size: 18, color: statusColor),
                const SizedBox(width: 8),
                Expanded(child: OneLine(status, style: context.t.number(15).copyWith(color: statusColor))),
              ]),
            ]),
          ),
        ),
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

/// Neuer Wecker bzw. Wecker ändern, wie im Entwurf.
class AlarmEditScreen extends ConsumerStatefulWidget {
  const AlarmEditScreen({super.key, this.existing});

  final Alarm? existing;

  @override
  ConsumerState<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends ConsumerState<AlarmEditScreen> {
  late String _name = widget.existing?.name ?? 'Zur Arbeit';
  Location? _from;
  Location? _to;
  late AlarmTimeRef _ref = widget.existing?.timeRef ?? AlarmTimeRef.arriveBy;
  late int _minute = widget.existing?.minuteOfDay ?? 8 * 60;
  late Set<int> _days = {...?widget.existing?.weekdays};
  late int _lead = widget.existing?.leadMinutes ?? 10;
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

  bool get _valid => _from != null && _to != null && _days.isNotEmpty;

  Future<void> _pick(bool from) async {
    final l = await Navigator.of(context).push<Location>(MaterialPageRoute(
        builder: (_) => LocationSearchScreen(title: from ? 'Von' : 'Nach', allowHere: false, showNearby: from)));
    if (l != null) setState(() => from ? _from = l : _to = l);
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _name);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name'),
        content: TextField(controller: ctrl, autofocus: true, textCapitalization: TextCapitalization.sentences),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    if (v != null && v.isNotEmpty) setState(() => _name = v);
  }

  Future<void> _pickLead() async {
    final v = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SheetHeader('Vorlauf zum Losgehen'),
            const SizedBox(height: 8),
            ListGroup(children: [
              for (final m in [0, 5, 10, 15, 20, 30])
                ValueRow(
                  label: '$m min',
                  chevron: false,
                  trailing: m == _lead ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.check, color: ctx.c.accent),
                  ) : null,
                  onTap: () => Navigator.pop(ctx, m),
                ),
            ]),
          ]),
        ),
      ),
    );
    if (v != null) setState(() => _lead = v);
  }

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    await Notifications.requestPermission();
    await Notifications.requestExactAlarms();
    final a = Alarm(
      id: widget.existing?.id ?? 'wecker-${DateTime.now().millisecondsSinceEpoch}',
      name: _name,
      from: _from!,
      to: _to!,
      timeRef: _ref,
      minuteOfDay: _minute,
      weekdays: _days.toList()..sort(),
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
            height: 52,
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
            trailing: TextButton(
              onPressed: _valid && !_saving ? _save : null,
              child: const Text('Sichern', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          ListGroup(children: [ValueRow(label: 'Name', value: _name, valueColor: c.ink, chevron: false, onTap: _editName)]),
          const SizedBox(height: 14),
          Material(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            child: Row(children: [
              const SizedBox(width: 16),
              SizedBox(width: 10, height: 104, child: CustomPaint(painter: MiniRoutePainter(c.accent, c.ink))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(children: [
                  field('Von', _from, true),
                  Divider(height: 1, color: c.hair),
                  field('Nach', _to, false),
                ]),
              ),
              const SizedBox(width: 16),
            ]),
          ),
          const SizedBox(height: 14),
          Segmented<AlarmTimeRef>(
            options: const [(AlarmTimeRef.arriveBy, 'Ankommen um'), (AlarmTimeRef.departAt, 'Losfahren um')],
            value: _ref,
            onChanged: (v) => setState(() => _ref = v),
          ),
          const SizedBox(height: 14),
          ListGroup(children: [
            ValueRow(
              label: _ref == AlarmTimeRef.arriveBy ? 'Ankunft' : 'Abfahrt',
              trailing: Material(
                color: c.fill,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: TimeOfDay(hour: _minute ~/ 60, minute: _minute % 60));
                    if (t != null) setState(() => _minute = t.hour * 60 + t.minute);
                  },
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    child: Text(minuteText(_minute), style: context.t.time(20)),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          const SectionTitle('Wiederholen', small: true),
          Container(
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (var d = 1; d <= 7; d++)
                Semantics(
                  button: true,
                  selected: _days.contains(d),
                  child: InkResponse(
                    onTap: () => setState(() => _days.contains(d) ? _days.remove(d) : _days.add(d)),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _days.contains(d) ? c.accent : c.fill),
                      child: Text(_dayLetters[d - 1],
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _days.contains(d) ? c.onAccent : c.muted)),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          ListGroup(children: [
            ValueRow(label: 'Vorlauf zum Losgehen', value: '$_lead min', onTap: _pickLead),
            ValueRow(
              label: 'Bei Störung früher wecken',
              trailing: Switch(value: _earlier, onChanged: (v) => setState(() => _earlier = v)),
            ),
            ValueRow(
              label: 'Unterwegs-Modus starten',
              trailing: Switch(value: _companion, onChanged: (v) => setState(() => _companion = v)),
            ),
          ]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('Der Wecker rechnet Gehzeit und Echtzeit mit ein und klingelt früher, wenn deine Fahrt ausfällt.',
                style: TextStyle(fontSize: 13, height: 1.4, color: c.muted)),
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: 20),
            ListGroup(children: [
              ValueRow(
                label: 'Wecker löschen',
                labelColor: c.red,
                chevron: false,
                onTap: () async {
                  await Notifications.cancel(alarmNotificationId(widget.existing!.id));
                  await ref.read(repositoryProvider).deleteAlarm(widget.existing!.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

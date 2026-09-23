// Gemeinsame Bausteine der Oberfläche.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/models.dart';
import 'format.dart';
import 'theme.dart';

/// Linienfarbe nach Verkehrsmittel. Echte Linienfarben liefert die Auskunft
/// nicht; Bus und Schwebebahn folgen design.md, S-Bahn dem Prototyp.
Color lineColor(BuildContext context, Line? line) {
  final c = context.c;
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (line?.mode) {
    TransportMode.bus || TransportMode.onDemand => c.bus,
    TransportMode.suspension => c.schwebe,
    TransportMode.replacementBus => c.sev,
    TransportMode.suburbanRail =>
      dark ? const Color(0xFF23883C) : const Color(0xFF1F7A35),
    TransportMode.rail || TransportMode.longDistanceRail =>
      dark ? const Color(0xFF4A5057) : const Color(0xFF3D434B),
    TransportMode.tram || TransportMode.subway =>
      dark ? const Color(0xFF2E6FB0) : const Color(0xFF235A93),
    _ => c.muted,
  };
}

/// Linienplakette: feste Breite, weiße Liniennummer.
class LineBadge extends StatelessWidget {
  const LineBadge(this.line, {super.key, this.width = 34, this.height = 20});

  final Line? line;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final name = line?.name ?? '';
    return Container(
      constraints: BoxConstraints(minWidth: width),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: lineColor(context, line),
        borderRadius: BorderRadius.circular(Radii.badge * height / 32),
      ),
      child: Text(name,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: context.t.lineNumber.copyWith(fontSize: height < 22 ? 12 : 13.5)),
    );
  }
}

/// Einzeiliger Text, gekürzt mit „…“, nie umbrochen.
class OneLine extends StatelessWidget {
  const OneLine(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(text,
      maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: style);
}

/// Text, der bei Änderung am selben Platz überblendet (150 ms).
class FadeText extends StatelessWidget {
  const FadeText(this.text, {super.key, this.style, this.align = TextAlign.start});

  final String text;
  final TextStyle? style;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final child = Text(text,
        key: ValueKey('$text${style?.color}'),
        maxLines: 1,
        softWrap: false,
        textAlign: align,
        style: style);
    if (MediaQuery.of(context).disableAnimations) return child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      layoutBuilder: (current, previous) => Stack(
        alignment: align == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft,
        children: [...previous, ?current],
      ),
      child: child,
    );
  }
}

/// Farbe einer Zeitangabe: grün pünktlich, orange verspätet, rot Ausfall,
/// neutral ohne Echtzeit.
Color timeColor(BuildContext context, EventTime? t,
    {StopStatus status = StopStatus.normal, Color? neutral}) {
  final c = context.c;
  if (status == StopStatus.cancelled) return c.red;
  if (t == null || !t.hasRealtime) return neutral ?? c.ink;
  final d = t.delayMinutes ?? 0;
  return d > 0 ? c.orange : c.green;
}

/// Zeit mit fest reserviertem Platz für die Verspätung („14:35 +3“).
class TimeWithDelay extends StatelessWidget {
  const TimeWithDelay(this.time,
      {super.key,
      this.size = 19,
      this.delaySize = 13,
      this.status = StopStatus.normal,
      this.neutral});

  final EventTime? time;
  final double size;
  final double delaySize;
  final StopStatus status;
  final Color? neutral;

  @override
  Widget build(BuildContext context) {
    final color = timeColor(context, time, status: status, neutral: neutral);
    final cancelled = status == StopStatus.cancelled;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        FadeText(time == null ? '--:--' : hm(time!.best),
            style: context.t.time(size).copyWith(
                color: color,
                decoration: cancelled ? TextDecoration.lineThrough : null)),
        const SizedBox(width: 4),
        SizedBox(
          width: delaySize * 2.1,
          child: FadeText(delayText(time),
              style: context.t.time(delaySize).copyWith(color: context.c.orange)),
        ),
      ],
    );
  }
}

/// Sanft pulsierender Punkt (2 s Zyklus); ruhig bei „Bewegung reduzieren“.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = (1 - (2 * _c.value - 1).abs());
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 1 - 0.65 * v),
              shape: BoxShape.circle,
            ),
          );
        },
      );
}

/// Zeitstempel „vor 12 s“. Älter als 2 min oder fehlgeschlagen: orange
/// „Daten nicht aktuell“. Beim Laden aus dem Cache: „wird aktualisiert“.
class FreshnessStamp extends StatelessWidget {
  const FreshnessStamp({
    super.key,
    required this.updatedAt,
    required this.now,
    this.refreshing = false,
    this.failed = false,
    this.realtime = true,
  });

  final DateTime? updatedAt;
  final DateTime now;
  final bool refreshing;
  final bool failed;

  /// false: der Stand enthält keine Echtzeit („nur Fahrplan“).
  final bool realtime;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final age = updatedAt == null ? null : now.difference(updatedAt!);
    final stale = failed || age == null || age > const Duration(minutes: 2);
    String text;
    Color color;
    Color dot;
    if (refreshing && (age == null || stale)) {
      text = 'wird aktualisiert';
      color = c.muted;
      dot = c.muted;
    } else if (stale) {
      text = age == null ? 'Daten nicht aktuell' : 'Daten nicht aktuell · ${ageText(age)}';
      color = c.orange;
      dot = c.orange;
    } else if (!realtime) {
      text = 'nur Fahrplan · ${ageText(age)}';
      color = c.muted;
      dot = c.muted;
    } else {
      text = ageText(age);
      color = c.muted;
      dot = c.green;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiveDot(color: dot),
        const SizedBox(width: 6),
        Text(text,
            maxLines: 1,
            style: context.t.number(13).copyWith(color: color)),
      ],
    );
  }
}

/// Gruppierte Liste: Fläche mit 12 px Radius, Trennlinien eingerückt bis zur
/// Textkante, keine unter dem letzten Element.
class ListGroup extends StatelessWidget {
  const ListGroup({super.key, required this.children, this.indent = 16});

  final List<Widget> children;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(Divider(height: 0.5, thickness: 0.5, indent: indent, color: c.hair));
      }
    }
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: items),
    );
  }
}

/// Abschnittsüberschrift über einer Gruppe.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.small = false});

  final String text;
  final Widget? trailing;
  final bool small;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: OneLine(text,
                  style: small
                      ? context.t.label.copyWith(color: context.c.muted)
                      : context.t.section),
            ),
            ?trailing,
          ],
        ),
      );
}

/// Platzhalterblock in der späteren Größe (kein Spinner im Inhalt).
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({super.key, required this.height, this.width, this.radius = 6});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.c.fill,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Hinweis im Inhalt, z. B. bei Fehlern oder leeren Ergebnissen.
class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.action, this.onAction, this.color});

  final String text;
  final String? action;
  final VoidCallback? onAction;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Column(
          children: [
            Text(text,
                textAlign: TextAlign.center,
                style: context.t.secondary.copyWith(color: color ?? context.c.muted)),
            if (action != null)
              TextButton(onPressed: onAction, child: Text(action!)),
          ],
        ),
      );
}

/// Bildmarke: Zug, Straßenbahn, Bus – aus assets/logo.svg bzw. logo-dark.svg.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.23),
      child: SvgPicture.asset(dark ? 'assets/logo-dark.svg' : 'assets/logo.svg',
          width: size, height: size),
    );
  }
}

/// Wortmarke „Gleich.da“: Rubik fett kursiv, der Punkt in Bernstein – wie
/// der Punkt am Bus im Logo.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Rubik',
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
      fontSize: size,
      height: 1,
      letterSpacing: -0.01 * size,
      color: context.c.accent,
    );
    return Semantics(
      label: 'Gleich.da',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(style: style, children: [
            const TextSpan(text: 'Gleich'),
            TextSpan(text: '.', style: style.copyWith(color: AppColors.amber, fontVariations: const [FontVariation('wght', 900)])),
            const TextSpan(text: 'da'),
          ]),
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
  }
}

/// Kopfzeile von Unterseiten: Android Pfeil links, iOS „‹ Ziel“.
class SubpageHeader extends StatelessWidget {
  const SubpageHeader({super.key, required this.title, this.backLabel, this.trailing});

  final String title;
  final String? backLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (context.isIOS) {
      return SizedBox(
        height: 44,
        child: Row(children: [
          SizedBox(
            width: 96,
            child: TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.chevron_left, color: c.accent),
              label: OneLine(backLabel ?? 'Zurück',
                  style: TextStyle(fontSize: 17, color: c.accent)),
            ),
          ),
          Expanded(
              child: Center(
                  child: OneLine(title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
          SizedBox(width: 96, child: Align(alignment: Alignment.centerRight, child: trailing)),
        ]),
      );
    }
    return SizedBox(
      height: 56,
      child: Row(children: [
        Transform.translate(
          offset: const Offset(-8, 0),
          child: IconButton(
            tooltip: 'Zurück',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back, color: c.ink),
          ),
        ),
        Expanded(
            child: OneLine(title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: c.ink))),
        ?trailing,
      ]),
    );
  }
}

/// Oberer Innenabstand der Screens: Status- plus Gestenleiste.
EdgeInsets pagePadding(BuildContext context, {double bottom = 24}) {
  final top = MediaQuery.of(context).padding.top;
  return EdgeInsets.fromLTRB(Space.page, top + 8, Space.page, bottom);
}

/// Start und Ziel untereinander mit kleiner Verlaufslinie (Ring → Punkt).
class RouteSummary extends StatelessWidget {
  const RouteSummary({super.key, required this.from, required this.to, this.when});

  final String from;
  final String to;
  final String? when;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const name = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 10, height: 46, child: CustomPaint(painter: MiniRoutePainter(c.muted, c.ink))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              OneLine(from, style: name),
              OneLine(to, style: name),
            ]),
          ),
        ]),
        if (when != null) ...[
          const SizedBox(height: 2),
          OneLine(when!, style: context.t.number(14).copyWith(color: c.muted)),
        ],
      ]),
    );
  }
}

class MiniRoutePainter extends CustomPainter {
  MiniRoutePainter(this.muted, this.ink);

  final Color muted;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final top = size.height * 0.24, bottom = size.height * 0.76;
    canvas.drawCircle(Offset(x, top), 3.8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = muted);
    final p = Paint()
      ..color = muted
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var y = top + 6; y <= bottom - 6; y += 5) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 0.5), p);
    }
    canvas.drawCircle(Offset(x, bottom), 4.2, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(MiniRoutePainter old) => old.muted != muted || old.ink != ink;
}

/// Auswahl-Chip: gewählt dunkel gefüllt, sonst Fläche `fill`.
class ChoiceChipX extends StatelessWidget {
  const ChoiceChipX({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = selected ? c.bg : c.ink;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.ink : c.fill,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
              Flexible(
                child: Text(label,
                    maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: fg)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Fahrzeugsymbol im Stil des Logos (assets/glyphs), Körper in [color].
class VehicleGlyph extends StatelessWidget {
  const VehicleGlyph(this.mode, {super.key, required this.color, this.width = 30});

  final TransportMode? mode;
  final Color color;
  final double width;

  static String assetFor(TransportMode? m) => switch (m) {
        TransportMode.tram => 'assets/glyphs/tram.svg',
        TransportMode.subway => 'assets/glyphs/ubahn.svg',
        TransportMode.suspension => 'assets/glyphs/schwebebahn.svg',
        TransportMode.rail || TransportMode.suburbanRail || TransportMode.longDistanceRail => 'assets/glyphs/zug.svg',
        TransportMode.ferry => 'assets/glyphs/faehre.svg',
        _ => 'assets/glyphs/bus.svg',
      };

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        assetFor(mode),
        width: width,
        height: width * 36 / 62,
        theme: SvgTheme(currentColor: color),
      );
}

/// Umschalter wie im Canvas: Fläche `fill`, gewählte Option weiß abgehoben.
class Segmented<T> extends StatelessWidget {
  const Segmented({super.key, required this.options, required this.value, required this.onChanged, this.height = 36});

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(Radii.input)),
      child: Row(children: [
        for (final (v, label) in options)
          Expanded(
            child: Semantics(
              button: true,
              selected: v == value,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 150),
                  height: height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v == value ? (dark ? const Color(0xFF3A3F46) : c.surface) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15, color: c.ink, fontWeight: v == value ? FontWeight.w600 : FontWeight.w400)),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Wahlknopf in fester Größe (Tag, Schnellwahl): gewählt gefüllt.
class PickButton extends StatelessWidget {
  const PickButton({super.key, required this.label, required this.selected, required this.onTap, this.accent = false});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Gewählt in Petrol statt Schwarz (Tag).
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bg = selected ? (accent ? c.accent : c.ink) : c.fill;
    final fg = selected ? (accent ? c.onAccent : c.bg) : c.ink;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(Radii.input),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.input),
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.t.number(14).copyWith(
                  color: fg, fontWeight: selected && accent ? FontWeight.w600 : FontWeight.w400, fontSize: accent ? 15 : 14)),
        ),
      ),
    );
  }
}

/// Kopf eines Fensters von unten: Titel links, „Fertig“ rechts.
class SheetHeader extends StatelessWidget {
  const SheetHeader(this.title, {super.key, this.done = 'Fertig', this.onDone});

  final String title;
  final String done;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: Row(children: [
          Expanded(child: OneLine(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          GestureDetector(
            onTap: onDone ?? () => Navigator.pop(context),
            child: Text(done, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.c.accent)),
          ),
        ]),
      );
}

/// Zeile in Einstellungsgruppen: Beschriftung links, Wert rechts, feste Höhe.
class ValueRow extends StatelessWidget {
  const ValueRow({super.key, required this.label, this.value, this.onTap, this.trailing, this.labelColor, this.chevron = true, this.valueColor});

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? labelColor;
  final Color? valueColor;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: EdgeInsets.only(left: 16, right: trailing != null ? 8 : 16),
        child: Row(children: [
          OneLine(label, style: TextStyle(fontSize: 16, color: labelColor ?? c.ink)),
          const SizedBox(width: 12),
          Expanded(
            child: value == null
                ? const SizedBox.shrink()
                : Text(value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 16, color: valueColor ?? c.muted)),
          ),
          ?trailing,
          if (trailing == null && chevron && onTap != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: c.chevron),
          ],
        ]),
      ),
    );
  }
}

/// Aktuelle Position (Haltestellenverlauf und Karte): Punkt in Linienfarbe mit weißem Rand und
/// ruhigem Puls (still bei „Bewegung reduzieren“).
class PositionDot extends StatefulWidget {
  const PositionDot({super.key, required this.color});

  final Color color;

  @override
  State<PositionDot> createState() => _PositionDotState();
}

class _PositionDotState extends State<PositionDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
      _c.value = 0.35;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 24,
        height: 24,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _PositionDotPainter(widget.color, context.c.surface, _c.value),
          ),
        ),
      );
}

class _PositionDotPainter extends CustomPainter {
  _PositionDotPainter(this.color, this.ring, this.t);

  final Color color;
  final Color ring;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final o = size.center(Offset.zero);
    canvas.drawCircle(o, 7 + 5 * t, Paint()..color = color.withValues(alpha: 0.28 * (1 - t)));
    canvas.drawCircle(o, 8, Paint()..color = ring);
    canvas.drawCircle(o, 6, Paint()..color = color);
    canvas.drawCircle(o, 2.2, Paint()..color = ring);
  }

  @override
  bool shouldRepaint(_PositionDotPainter old) => old.t != t || old.color != color;
}

import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Farben aus docs/design.md, Abschnitt 1. Jede Farbe hat eine Bedeutung.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.hair,
    required this.fill,
    required this.accent,
    required this.onAccent,
    required this.green,
    required this.orange,
    required this.red,
    required this.bus,
    required this.schwebe,
    required this.bar,
    required this.indicator,
    required this.sev,
    required this.orangeTint,
    required this.orangeText,
    required this.redTint,
    required this.redText,
    required this.walk,
    required this.walkText,
    required this.chevron,
  });

  final Color bg;
  final Color surface;
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color hair;
  final Color fill;
  final Color accent;
  final Color onAccent;
  final Color green;
  final Color orange;
  final Color red;
  final Color bus;
  final Color schwebe;
  final Color bar;
  final Color indicator;

  /// Violett für Schienenersatzverkehr.
  final Color sev;

  /// Hinterlegung und Text des Abweichungs-Banners (aus dem Prototyp).
  final Color orangeTint;
  final Color orangeText;
  final Color redTint;
  final Color redText;

  /// Fußwege in der Zeitleiste der Verbindungsliste.
  final Color walk;
  final Color walkText;
  final Color chevron;

  /// Bernstein: Scheinwerfer im Logo, i-Punkt der Wortmarke.
  static const amber = Color(0xFFE8A94F);

  static const light = AppColors(
    bg: Color(0xFFF4F5F6),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF111418),
    ink2: Color(0xFF3D434B),
    muted: Color(0xFF5F6670),
    hair: Color(0xFFE4E6E9),
    fill: Color(0xFFE9EBEE),
    accent: Color(0xFF0B6E66),
    onAccent: Color(0xFFFFFFFF),
    green: Color(0xFF1A7F3C),
    orange: Color(0xFFB25400),
    red: Color(0xFFC0272D),
    bus: Color(0xFF9B1B43),
    schwebe: Color(0xFF0A5CB0),
    bar: Color(0xFFFFFFFF),
    indicator: Color(0xFFD3EAE7),
    sev: Color(0xFF6D4AA8),
    orangeTint: Color(0xFFFFF3E6),
    orangeText: Color(0xFF7F3D00),
    redTint: Color(0xFFFCEBEC),
    redText: Color(0xFF8A1A1F),
    walk: Color(0xFFE3E5E8),
    walkText: Color(0xFF4A5058),
    chevron: Color(0xFFB3B8BE),
  );

  static const dark = AppColors(
    bg: Color(0xFF0E1012),
    surface: Color(0xFF181B1F),
    ink: Color(0xFFECEEF0),
    ink2: Color(0xFFC3C8CE),
    muted: Color(0xFF9AA1A9),
    hair: Color(0xFF272B30),
    fill: Color(0xFF22262B),
    accent: Color(0xFF49B7AA),
    onAccent: Color(0xFF06201D),
    green: Color(0xFF5CC27F),
    orange: Color(0xFFF0A451),
    red: Color(0xFFF2766F),
    bus: Color(0xFFA8214D),
    schwebe: Color(0xFF1767C2),
    bar: Color(0xFF131619),
    indicator: Color(0xFF1F3B38),
    sev: Color(0xFFA78BDA),
    orangeTint: Color(0xFF2A1F12),
    orangeText: Color(0xFFF3C48E),
    redTint: Color(0xFF2C1415),
    redText: Color(0xFFF6B0AC),
    walk: Color(0xFF2A2E34),
    walkText: Color(0xFFAEB4BB),
    chevron: Color(0xFF5C636B),
  );

  /// Alle Rollen mit Namen, für den Demo-Screen.
  Map<String, Color> get named => {
        'bg': bg,
        'surface': surface,
        'ink': ink,
        'ink2': ink2,
        'muted': muted,
        'hair': hair,
        'fill': fill,
        'accent': accent,
        'onAccent': onAccent,
        'green': green,
        'orange': orange,
        'red': red,
        'bus': bus,
        'schwebe': schwebe,
        'bar': bar,
        'indicator': indicator,
        'sev': sev,
        'amber': amber,
      };

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      t < 0.5 ? this : (other as AppColors? ?? this);
}

/// Abstände in Vielfachen von 4.
abstract final class Space {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;

  /// Seitenrand, alle Screens gleich.
  static const double page = 16;

  /// Mindest-Tapfläche.
  static const double tap = 44;
}

abstract final class Radii {
  /// Karten und Gruppen: weich gerundet (v0.3: 16 statt 14 px, feiner).
  static const double card = 16;
  static const double input = 10;
  static const double badge = 8;
  static const double logo = 22;
}

/// Textstile aus docs/design.md, Abschnitt 2. Zahlen immer mit gleich
/// breiten Ziffern.
@immutable
class AppText extends ThemeExtension<AppText> {
  const AppText._(this.isIOS);

  factory AppText.forPlatform(TargetPlatform p) =>
      AppText._(p == TargetPlatform.iOS || p == TargetPlatform.macOS);

  final bool isIOS;

  static const tabular = [FontFeature.tabularFigures()];

  /// Bildschirmtitel: 28 px, halbfett, leicht enger (v0.3: feiner als die
  /// 32 px fett des Canvas).
  TextStyle get screenTitle => const TextStyle(
      fontSize: 28, fontWeight: FontWeight.w600, height: 1.1, letterSpacing: -0.5);
  TextStyle get listRow =>
      TextStyle(fontSize: isIOS ? 16 : 15, fontWeight: FontWeight.w400);
  TextStyle get secondary =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  TextStyle get label =>
      const TextStyle(fontSize: 13, fontWeight: FontWeight.w400);
  TextStyle get tab =>
      const TextStyle(fontSize: 11, fontWeight: FontWeight.w400);
  TextStyle get section =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  /// Zeiten: Gewicht 600, gleich breite Ziffern.
  TextStyle time(double size) => TextStyle(
      fontSize: size, fontWeight: FontWeight.w600, fontFeatures: tabular);

  /// Sonstige Zahlen: gleich breite Ziffern, normales Gewicht.
  TextStyle number(double size) => TextStyle(
      fontSize: size, fontWeight: FontWeight.w400, fontFeatures: tabular);

  /// Liniennummern auf der Plakette.
  TextStyle get lineNumber => const TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: Colors.white,
      fontFeatures: tabular,
      height: 1);

  @override
  AppText copyWith() => this;

  @override
  AppText lerp(ThemeExtension<AppText>? other, double t) => this;
}

ThemeData buildTheme(Brightness brightness, TargetPlatform platform) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final text = AppText.forPlatform(platform);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.accent,
    onSecondary: c.onAccent,
    error: c.red,
    onError: Colors.white,
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.muted,
    outline: c.hair,
    outlineVariant: c.hair,
    surfaceContainerHighest: c.fill,
    secondaryContainer: c.indicator,
    onSecondaryContainer: c.accent,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    platform: platform,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerColor: c.hair,
    splashFactory: NoSplash.splashFactory,
    visualDensity: VisualDensity.compact,
    highlightColor: c.fill.withValues(alpha: 0.6),
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: c.ink,
          displayColor: c.ink,
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle:
          TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: c.ink),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.bar,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 62,
      indicatorColor: c.indicator,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          size: 22, color: s.contains(WidgetState.selected) ? c.accent : c.muted)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontSize: 11,
          fontWeight:
              s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? c.ink : c.muted)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.bg,
      dragHandleColor: brightness == Brightness.dark ? const Color(0xFF3A3F46) : const Color(0xFFC9CDD2),
      dragHandleSize: const Size(36, 5),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.fill,
      hintStyle: TextStyle(color: c.muted),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    // Schalter: iPhone wie im Canvas (weißer Knopf, ohne Rand); Android im
    // Material-Stil (umrandet, eingeschaltet mit Haken im Knopf).
    switchTheme: platform == TargetPlatform.iOS
        ? SwitchThemeData(
            thumbColor: const WidgetStatePropertyAll(Colors.white),
            trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
                ? c.accent
                : (brightness == Brightness.dark ? const Color(0xFF3A3F46) : const Color(0xFFD3D6DA))),
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            thumbIcon: const WidgetStatePropertyAll(null),
          )
        : SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected) ? c.onAccent : c.muted),
            trackColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected) ? c.accent : c.fill),
            trackOutlineColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected) ? c.accent : c.muted),
            thumbIcon: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
                ? Icon(Icons.check, size: 16, color: c.accent)
                : null),
          ),
    // Große Knöpfe auf Android als Kapsel (Material).
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: platform == TargetPlatform.iOS
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card))
            : const StadiumBorder(),
      ),
    ),
    listTileTheme: ListTileThemeData(
      titleTextStyle: TextStyle(fontSize: 15, color: c.ink),
      subtitleTextStyle: TextStyle(fontSize: 13, color: c.muted),
      minVerticalPadding: 8,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CompanionAwareTransitions(SlidePageTransitionsBuilder()),
      TargetPlatform.iOS: CompanionAwareTransitions(CupertinoPageTransitionsBuilder()),
    }),
    extensions: [c, text],
  );
}

/// Eine Bewegungssprache für die ganze App: wenige Dauern, eine Kurve.
/// Seitenwechsel und die Unterwegs-Leiste teilen sich dieselbe Animation,
/// kleinere Übergänge (Einblenden, Aufklappen) sind kürzer.
abstract final class Motion {
  /// Seitenwechsel; die Unterwegs-Leiste läuft exakt mit.
  static const page = Duration(milliseconds: 250);

  /// Einblenden von Inhalten, Aufklappen, Leiste erscheint.
  static const medium = Duration(milliseconds: 170);

  /// Zustandswechsel (Farbe, Deckkraft).
  static const short = Duration(milliseconds: 120);

  /// Ausklingend: schnell los, weich an.
  static const curve = Curves.easeOutCubic;

  /// Nur bei „Bewegung reduzieren“ aus.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.of(context).disableAnimations ? Duration.zero : d;
}

/// Höhe der Unterwegs-Leiste, solange sie sichtbar ist (sonst 0). Jede Seite
/// außer der Startseite hält unten diesen Platz frei – in der Seite selbst,
/// damit er beim Wechsel mitgleitet und die Startseite dahinter ruhig bleibt.
final companionReserve = ValueNotifier<double>(0);

/// Screenwechsel: horizontales Schieben ([Motion.page], [Motion.curve]);
/// iPhone wie gewohnt. Bei „Bewegung reduzieren“ ohne Übergang.
class SlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlidePageTransitionsBuilder();

  @override
  Duration get transitionDuration => Motion.page;

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context,
      Animation<double> animation, Animation<double> secondary, Widget child) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final inCurve = CurvedAnimation(parent: animation, curve: Motion.curve);
    final outCurve = CurvedAnimation(parent: secondary, curve: Motion.curve);
    return SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(inCurve),
      child: SlideTransition(
        position: Tween(begin: Offset.zero, end: const Offset(-0.25, 0)).animate(outCurve),
        child: child,
      ),
    );
  }
}

/// Hält unter jeder Seite außer der ersten den Platz der Unterwegs-Leiste
/// frei und gibt dann an [inner] weiter.
class CompanionAwareTransitions extends PageTransitionsBuilder {
  const CompanionAwareTransitions(this.inner);

  final PageTransitionsBuilder inner;

  @override
  Duration get transitionDuration => inner.transitionDuration;

  @override
  Duration get reverseTransitionDuration => inner.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context,
          Animation<double> animation, Animation<double> secondary, Widget child) =>
      inner.buildTransitions(route, context, animation, secondary,
          route.isFirst ? child : _CompanionReserve(child: child));
}

class _CompanionReserve extends StatelessWidget {
  const _CompanionReserve({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bar = Theme.of(context).extension<AppColors>()!.bar;
    // Immer derselbe Aufbau – sonst ginge beim Losfahren der Zustand der Seite verloren.
    return ValueListenableBuilder<double>(
      valueListenable: companionReserve,
      child: child,
      builder: (context, h, child) {
        // Die Tastatur verdeckt die Leisten mit – sie zählt nur, soweit sie
        // über den freigehaltenen Platz hinausreicht.
        final mq = MediaQuery.of(context);
        final kb = math.max(0.0, mq.viewInsets.bottom - h);
        return Column(children: [
          Expanded(
            child: MediaQuery(
              data: mq.copyWith(
                padding: h > 0 ? mq.padding.copyWith(bottom: 0) : mq.padding,
                viewPadding: h > 0 ? mq.viewPadding.copyWith(bottom: 0) : mq.viewPadding,
                viewInsets: mq.viewInsets.copyWith(bottom: kb),
              ),
              child: child!,
            ),
          ),
          ColoredBox(color: bar, child: SizedBox(width: double.infinity, height: h)),
        ]);
      },
    );
  }
}

extension ThemeX on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColors>()!;
  AppText get t => Theme.of(this).extension<AppText>()!;
  bool get isIOS => Theme.of(this).platform == TargetPlatform.iOS;
}

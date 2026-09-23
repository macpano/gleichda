import 'dart:convert';

import 'models.dart';

enum Pace { slow, normal, fast }

extension PaceLabel on Pace {
  String get label => switch (this) {
        Pace.slow => 'Langsam',
        Pace.normal => 'Normal',
        Pace.fast => 'Schnell',
      };

  /// Gehgeschwindigkeit in Prozent der Normalgeschwindigkeit (TRIAS WalkSpeed).
  int get walkPercent => switch (this) {
        Pace.slow => 70,
        Pace.normal => 100,
        Pace.fast => 130,
      };

  /// Mindestzeit für einen Umstieg am selben Halt, in Minuten.
  int get transferMinutes => switch (this) {
        Pace.slow => 5,
        Pace.normal => 3,
        Pace.fast => 1,
      };
}

/// Suchprofil der Verbindungssuche.
enum SearchProfile { all, fastest, fewChanges, lessWalking, accessible }

extension SearchProfileLabel on SearchProfile {
  String get label => switch (this) {
        SearchProfile.all => 'Alle',
        SearchProfile.fastest => 'Schnellste',
        SearchProfile.fewChanges => 'Wenig Umstiege',
        SearchProfile.lessWalking => 'Wenig Fußweg',
        SearchProfile.accessible => 'Barrierefrei',
      };
}

/// Verkehrsmittel-Gruppen für Filter, wie in den Suchoptionen des Entwurfs.
enum ModeGroup { bus, suspension, suburbanRail, regional, longDistance, tram }

extension ModeGroupX on ModeGroup {
  String get label => switch (this) {
        ModeGroup.bus => 'Bus',
        ModeGroup.suspension => 'Schwebebahn',
        ModeGroup.suburbanRail => 'S-Bahn',
        ModeGroup.regional => 'Regionalzug',
        ModeGroup.longDistance => 'Fernverkehr',
        ModeGroup.tram => 'Straßen- und U-Bahn',
      };

  bool matches(TransportMode m) => switch (this) {
        ModeGroup.bus => m == TransportMode.bus ||
            m == TransportMode.replacementBus ||
            m == TransportMode.onDemand,
        ModeGroup.suspension => m == TransportMode.suspension,
        ModeGroup.suburbanRail => m == TransportMode.suburbanRail,
        ModeGroup.regional => m == TransportMode.rail,
        ModeGroup.longDistance => m == TransportMode.longDistanceRail,
        ModeGroup.tram => m == TransportMode.tram || m == TransportMode.subway,
      };
}

/// Wählbare Grenzen für den längsten Fußweg, in Minuten.
const walkLimitChoices = [5, 10, 15, 20, 30];

/// Persönliches Profil und Einstellungen. Nur auf dem Gerät gespeichert.
class AppSettings {
  const AppSettings({
    this.transferPace = Pace.normal,
    this.walkPace = Pace.normal,
    this.accessible = false,
    this.excludedModes = const {},
    this.maxWalkMinutes = 15,
    this.useLocation = true,
    this.connectionsGrid = false,
    this.companionGps = false,
  });

  final Pace transferPace;
  final Pace walkPace;
  final bool accessible;
  final Set<ModeGroup> excludedModes;

  /// Längster Fußweg zu Beginn und am Ende einer Verbindung, in Minuten.
  /// Bestimmt auch den Umkreis für „In der Nähe“.
  final int maxWalkMinutes;

  /// Umkreis, der in [maxWalkMinutes] zu Fuß erreichbar ist: 80 m je Minute
  /// (4,8 km/h) bei normalem Tempo, nie unter 300 m.
  int get walkRadiusMeters => (maxWalkMinutes * 80 * walkPace.walkPercent / 100).round().clamp(300, 5000);

  /// Standort für Suche und Abfahrten verwenden (nur bei Nutzung).
  final bool useLocation;

  /// Zuletzt gewählte Ansicht der Verbindungen: Zeitraster statt Liste.
  final bool connectionsGrid;

  /// GPS im Unterwegs-Modus (optional).
  final bool companionGps;

  AppSettings copyWith({
    Pace? transferPace,
    Pace? walkPace,
    bool? accessible,
    Set<ModeGroup>? excludedModes,
    int? maxWalkMinutes,
    bool? useLocation,
    bool? connectionsGrid,
    bool? companionGps,
  }) =>
      AppSettings(
        transferPace: transferPace ?? this.transferPace,
        walkPace: walkPace ?? this.walkPace,
        accessible: accessible ?? this.accessible,
        excludedModes: excludedModes ?? this.excludedModes,
        maxWalkMinutes: maxWalkMinutes ?? this.maxWalkMinutes,
        useLocation: useLocation ?? this.useLocation,
        connectionsGrid: connectionsGrid ?? this.connectionsGrid,
        companionGps: companionGps ?? this.companionGps,
      );

  /// Kurzbeschreibung für „Mehr → Profil“.
  String get summary {
    final parts = <String>[
      if (accessible) 'barrierefrei',
      if (walkPace != Pace.normal) 'gehen ${walkPace.label.toLowerCase()}',
      if (transferPace != Pace.normal) 'umsteigen ${transferPace.label.toLowerCase()}',
      if (maxWalkMinutes != 15) 'höchstens $maxWalkMinutes min zu Fuß',
      if (excludedModes.isNotEmpty) 'ohne ${excludedModes.map((m) => m.label).join(', ')}',
    ];
    return parts.isEmpty ? 'Standard' : parts.join(', ');
  }

  bool get isDefault => summary == 'Standard';

  String encode() => jsonEncode({
        'transferPace': transferPace.name,
        'walkPace': walkPace.name,
        'accessible': accessible,
        'excludedModes': excludedModes.map((m) => m.name).toList(),
        'maxWalkMinutes': maxWalkMinutes,
        'useLocation': useLocation,
        'connectionsGrid': connectionsGrid,
        'companionGps': companionGps,
      });

  static AppSettings decode(String? s) {
    if (s == null) return const AppSettings();
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      T pick<T extends Enum>(List<T> values, Object? v, T def) =>
          values.firstWhere((e) => e.name == v, orElse: () => def);
      return AppSettings(
        transferPace: pick(Pace.values, m['transferPace'], Pace.normal),
        walkPace: pick(Pace.values, m['walkPace'], Pace.normal),
        accessible: m['accessible'] == true,
        // Unbekannte Namen (ältere Fassungen) überspringen statt Bus auszuschließen.
        excludedModes: {
          for (final e in (m['excludedModes'] as List?) ?? const [])
            ...ModeGroup.values.where((g) => g.name == e),
        },
        maxWalkMinutes: (m['maxWalkMinutes'] as num?)?.toInt() ?? 15,
        useLocation: m['useLocation'] != false,
        connectionsGrid: m['connectionsGrid'] == true,
        companionGps: m['companionGps'] == true,
      );
    } catch (_) {
      return const AppSettings();
    }
  }
}

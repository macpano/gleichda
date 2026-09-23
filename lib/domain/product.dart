// Produkte (Linienarten) im VRR und wie sie angezeigt werden.
//
// Grundlage sind die TRIAS-Angaben je Fahrt, gemessen am 23.09.2026 an
// Wuppertal Hbf, Oberbarmen und Düsseldorf Hbf (test/fixtures/trias_se_*):
//   bus/localBus „Bus“ 601 · bus/mobilityBus „SB“ CE64, SB69 ·
//   bus/localBus „Bus“ SB67 · bus/demandAndResponseBus „AST-Verkehr“ AST02 ·
//   bus/unknown „Ersatzverkehr“ „SEV S 6“ · rail/suburbanRailway „S 8“ ·
//   rail/local „RE 1 (RRX)“, „RB 48“ · rail/highSpeedRail „ICE“ (Nummer im
//   Namen „ICE 955 InterCityExpress“) · rail/international „IC“ ·
//   rail/rackAndPinionRailway „Schwebebahn“ ohne Liniennamen ·
//   metro „U75“ · tram/cityTram „704“.
import 'models.dart';

/// Linienart, wie Fahrgäste sie kennen.
enum Product {
  bus,
  expressBus, // SB, Schnellbus
  cityExpress, // CE
  nightBus, // NE, N
  onDemand, // AST, Taxibus
  replacement, // SEV
  suspension, // Schwebebahn
  tram,
  subway, // U-Bahn, Stadtbahn
  suburban, // S-Bahn
  regional, // RE, RB
  longDistance, // IC, ICE, EC
  ferry,
  other,
}

extension ProductLabel on Product {
  /// Bezeichnung in Klartext, z. B. für „Schnellbus SB69“.
  String get label => switch (this) {
        Product.bus => 'Bus',
        Product.expressBus => 'Schnellbus',
        Product.cityExpress => 'CityExpress',
        Product.nightBus => 'Nachtexpress',
        Product.onDemand => 'Anruf-Sammeltaxi',
        Product.replacement => 'Ersatzverkehr',
        Product.suspension => 'Schwebebahn',
        Product.tram => 'Straßenbahn',
        Product.subway => 'U-Bahn',
        Product.suburban => 'S-Bahn',
        Product.regional => 'Regionalzug',
        Product.longDistance => 'Fernzug',
        Product.ferry => 'Fähre',
        Product.other => '',
      };

  TransportMode get mode => switch (this) {
        Product.bus || Product.expressBus || Product.cityExpress || Product.nightBus => TransportMode.bus,
        Product.onDemand => TransportMode.onDemand,
        Product.replacement => TransportMode.replacementBus,
        Product.suspension => TransportMode.suspension,
        Product.tram => TransportMode.tram,
        Product.subway => TransportMode.subway,
        Product.suburban => TransportMode.suburbanRail,
        Product.regional => TransportMode.rail,
        Product.longDistance => TransportMode.longDistanceRail,
        Product.ferry => TransportMode.ferry,
        Product.other => TransportMode.other,
      };
}

/// Ergebnis der Erkennung: Linienart und Liniennummer für die Plakette.
class ProductInfo {
  const ProductInfo(this.product, this.name);

  final Product product;
  final String name;
}

/// Erkennt Linienart und Anzeigenamen aus den Angaben der Auskunft.
///
/// [ptMode] und [submode] sind TRIAS PtMode und *Submode, [modeName] der
/// Name des Verkehrsmittels („Bus“, „SB“, „Schwebebahn“, „ICE 955 …“),
/// [published] der veröffentlichte Linienname, [lineRef] die Linienkennung.
ProductInfo classifyLine({
  String? ptMode,
  String? submode,
  String? modeName,
  String? published,
  String? lineRef,
}) {
  final pub = _tidy(published ?? '');
  final name = (modeName ?? '').trim();
  final nameLower = name.toLowerCase();
  final pubUpper = pub.toUpperCase();

  Product product;
  if (nameLower.contains('ersatzverkehr') || pubUpper.startsWith('SEV') || submode == 'railReplacementBus' ||
      submode == 'replacementRailService') {
    product = Product.replacement;
  } else if (nameLower.contains('schwebebahn') || submode == 'rackAndPinionRailway') {
    product = Product.suspension;
  } else if (ptMode == 'rail' || ptMode == 'intercityRail' || ptMode == 'urbanRail') {
    if (submode == 'suburbanRailway' || RegExp(r'^S\d').hasMatch(pubUpper)) {
      product = Product.suburban;
    } else if (const {'highSpeedRail', 'international', 'longDistance', 'interregionalRail'}.contains(submode) ||
        RegExp(r'^(ICE|IC|EC|ECE|RJX?|NJ|FLX|TGV|THA)\b').hasMatch(pubUpper)) {
      product = Product.longDistance;
    } else if (nameLower.contains('stadtbahn') || nameLower.contains('u-bahn')) {
      product = Product.subway;
    } else if (nameLower.contains('straßenbahn')) {
      product = Product.tram;
    } else {
      product = Product.regional;
    }
  } else if (ptMode == 'metro' || ptMode == 'underground') {
    product = Product.subway;
  } else if (ptMode == 'tram') {
    product = Product.tram;
  } else if (ptMode == 'water' || ptMode == 'ferry') {
    product = Product.ferry;
  } else if (ptMode == 'bus' || ptMode == 'coach' || ptMode == 'trolleyBus') {
    if (submode == 'demandAndResponseBus' || pubUpper.startsWith('AST') || nameLower.contains('ast-') ||
        nameLower.contains('taxi')) {
      product = Product.onDemand;
    } else if (pubUpper.startsWith('CE')) {
      product = Product.cityExpress;
    } else if (pubUpper.startsWith('SB')) {
      product = Product.expressBus;
    } else if (RegExp(r'^N[E]?\d').hasMatch(pubUpper)) {
      product = Product.nightBus;
    } else {
      product = Product.bus;
    }
  } else {
    product = Product.other;
  }

  // Liniennummer: veröffentlicht, bei Fernzügen mit Zugnummer, bei der
  // Schwebebahn aus der Linienkennung („wsw:64060“ → „60“).
  var display = pub;
  if (product == Product.longDistance && RegExp(r'^[A-Z]{2,3}$').hasMatch(pubUpper)) {
    final m = RegExp(r'^([A-Z]{2,3})\s+(\d+)').firstMatch(name);
    if (m != null) display = '${m[1]} ${m[2]}';
  }
  if (display.isEmpty || (product == Product.suspension && !RegExp(r'\d').hasMatch(display))) {
    final parts = lineRef?.split(':') ?? const [];
    final m = parts.length > 1 ? RegExp(r'^\d{2}(\d{3})$').firstMatch(parts[1]) : null;
    display = m != null ? int.parse(m[1]!).toString() : (name.isNotEmpty ? name : '?');
  }
  return ProductInfo(product, display);
}

/// „S 8“ → „S8“, „RE 1 (RRX)“ → „RE1“, „SEV S 6“ → „SEV S6“; Zugnummern
/// hinter IC/ICE bleiben mit Leerzeichen („IC 2440“).
String _tidy(String p) {
  var s = p.trim().replaceAll(RegExp(r'\s*\([^)]*\)'), '').replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceAll(RegExp(r'\s+(InterCity|InterCityExpress|EuroCity)$', caseSensitive: false), '');
  s = s.replaceAllMapped(RegExp(r'\b(S|RE|RB|U|SB|CE|NE|AST) (\d)'), (m) => '${m[1]}${m[2]}');
  return s;
}

/// Linienart einer Linie; ältere gespeicherte Fahrten tragen noch keine und
/// werden aus Name und Verkehrsmittel erschlossen.
Product productOf(Line line) =>
    Product.values.asNameMap()[line.product] ?? guessProduct(line.name, mode: line.mode);

/// Linienart nur aus dem Liniennamen, etwa bei Störungsmeldungen und Abos.
Product guessProduct(String name, {TransportMode? mode}) {
  final n = _tidy(name).toUpperCase();
  if (n.startsWith('SEV') || mode == TransportMode.replacementBus) return Product.replacement;
  if (RegExp(r'^S\d').hasMatch(n)) return Product.suburban;
  if (RegExp(r'^(RE|RB)\d').hasMatch(n)) return Product.regional;
  if (RegExp(r'^(ICE|IC|EC|ECE|FLX)\b').hasMatch(n)) return Product.longDistance;
  if (RegExp(r'^U\d').hasMatch(n)) return Product.subway;
  if (n.startsWith('AST')) return Product.onDemand;
  if (n.startsWith('CE')) return Product.cityExpress;
  if (n.startsWith('SB')) return Product.expressBus;
  if (RegExp(r'^NE?\d').hasMatch(n)) return Product.nightBus;
  return switch (mode) {
    TransportMode.suspension => Product.suspension,
    TransportMode.tram => Product.tram,
    TransportMode.subway => Product.subway,
    TransportMode.suburbanRail => Product.suburban,
    TransportMode.rail => Product.regional,
    TransportMode.longDistanceRail => Product.longDistance,
    TransportMode.onDemand => Product.onDemand,
    TransportMode.ferry => Product.ferry,
    // Die Schwebebahn heißt im VRR schlicht „60“.
    null when n == '60' => Product.suspension,
    _ => Product.bus,
  };
}

/// Linie zum Vorlesen und für Benachrichtigungen: „Bus 604“, „Schwebebahn 60“,
/// „Tram 704“, aber „SB69“, „CE64“, „S8“, „RE4“, „ICE 955“, „SEV S6“ – steht
/// das Produkt schon im Namen, kommt kein Wort davor.
String lineTitle(Line line) {
  final p = productOf(line);
  if (RegExp(r'^[A-Za-z]').hasMatch(line.name)) return line.name;
  final word = switch (p) {
    Product.bus || Product.expressBus || Product.cityExpress || Product.nightBus => 'Bus',
    Product.onDemand => 'AST',
    Product.replacement => 'SEV',
    Product.tram => 'Tram',
    Product.subway => 'Stadtbahn',
    Product.suspension => 'Schwebebahn',
    Product.suburban => 'S',
    Product.regional || Product.longDistance => 'Zug',
    Product.ferry => 'Fähre',
    Product.other => '',
  };
  return [word, line.name].where((x) => x.isNotEmpty).join(' ');
}

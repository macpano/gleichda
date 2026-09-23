import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/trias/trias_parser.dart';
import 'package:gleichda/domain/models.dart';
import 'package:gleichda/domain/product.dart';

Map<String, Product> _products(String fixture) {
  final board = parseStopEvents(
    File('test/fixtures/$fixture.xml').readAsStringSync(),
    const Location(id: 'x', providerId: 'x', name: 'x'),
  );
  return {for (final d in board.departures) d.line.name: productOf(d.line)};
}

void main() {
  test('Wuppertal Hbf: Bus, Schnellbus, CityExpress, Schwebebahn, Züge', () {
    final p = _products('trias_se_hbf_produkte');
    expect(p['601'], Product.bus);
    expect(p['SB66'], Product.expressBus);
    expect(p['SB67'], Product.expressBus, reason: 'Auskunft nennt hier nur „Bus“');
    expect(p['CE64'], Product.cityExpress, reason: 'Auskunft nennt CE als „SB“');
    expect(p['60'], Product.suspension);
    expect(p['S8'], Product.suburban);
    expect(p['RE4'], Product.regional);
    expect(p['RB48'], Product.regional);
    expect(p['ICE 955'], Product.longDistance);
    expect(p['IC 2440'], Product.longDistance);
    expect(p.keys.where((n) => n.contains('(') || n.contains('  ')), isEmpty);
  });

  test('Oberbarmen: Anruf-Sammeltaxi', () {
    final p = _products('trias_se_oberbarmen');
    expect(p['AST02'], Product.onDemand);
    expect(p['AST11'], Product.onDemand);
  });

  test('Düsseldorf: SEV, U-Bahn, Straßenbahn, RRX ohne Zusatz', () {
    final p = _products('trias_se_duesseldorf');
    expect(p['SEV S6'], Product.replacement);
    expect(p['SEV RE6X'], Product.replacement);
    expect(p['U75'], Product.subway);
    expect(p['704'], Product.tram);
    expect(p['738'], Product.bus);
    expect(p['RE1'], Product.regional);
    expect(p['SB55'], Product.expressBus);
  });

  test('Produkt aus dem Namen allein', () {
    expect(guessProduct('SEV S 6'), Product.replacement);
    expect(guessProduct('CE65'), Product.cityExpress);
    expect(guessProduct('NE5'), Product.nightBus);
    expect(guessProduct('60'), Product.suspension);
    expect(guessProduct('625'), Product.bus);
    expect(guessProduct('RE 1 (RRX)'), Product.regional);
  });

  test('Linientitel ohne doppeltes Produkt', () {
    Line l(String n, TransportMode m, [Product? p]) => Line(id: n, name: n, mode: m, product: p?.name);
    expect(lineTitle(l('604', TransportMode.bus, Product.bus)), 'Bus 604');
    expect(lineTitle(l('60', TransportMode.suspension, Product.suspension)), 'Schwebebahn 60');
    expect(lineTitle(l('SB69', TransportMode.bus, Product.expressBus)), 'SB69');
    expect(lineTitle(l('ICE 955', TransportMode.longDistanceRail, Product.longDistance)), 'ICE 955');
    expect(lineTitle(l('704', TransportMode.tram, Product.tram)), 'Tram 704');
  });
}

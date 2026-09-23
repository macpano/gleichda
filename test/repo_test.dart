import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/db/database.dart';
import 'package:gleichda/data/repository.dart';
import 'package:gleichda/data/trias/trias_parser.dart';

void main() {
  test('Verlauf, Favoriten und zuletzt angesehene Fahrt', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final trips = parseTrips(File('test/fixtures/trias_trip_alter_markt_vohwinkel.xml').readAsStringSync());
    final t = trips.first;
    await r.saveLastTrip(t);
    final saved = await r.lastTrip();
    expect(saved!.trip, t);
    await r.recordSearch(t.origin, t.destination, result: trips);
    await r.recordSearch(t.origin, t.destination);
    final h = await r.watchHistory().first;
    expect(h.length, 1);
    expect(h.first.cached!.length, trips.length);
    await r.toggleFavoriteRoute(t.origin, t.destination);
    expect((await r.watchFavorites().first).length, 1);
    await r.toggleFavoriteRoute(t.origin, t.destination);
    expect((await r.watchFavorites().first), isEmpty);
    await r.cacheStops([t.origin.copyWith(place: 'Wuppertal')]);
    expect(await r.searchCachedStops(t.origin.name.substring(0, 4)), isNotEmpty, reason: t.origin.toString());
    await db.close();
  });
}

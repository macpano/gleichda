# Gleichda – Projektregeln

Fahrplan-App für den VRR, später international erweiterbar. iOS und Android aus
einer Codebasis. Diese Datei gilt für jede Sitzung in diesem Projekt.

## Vor der Arbeit lesen

- `docs/konzept.md` – vollständige Anforderungen, Screen für Screen. Das ist die
  Quelle der Wahrheit für Funktionen und Verhalten.
- `docs/design.md` – Farben, Maße, Schrift, Layoutregeln. Verbindlich, exakte
  Werte.
- `docs/prompts.md` – die Reihenfolge, in der gebaut wird.

## Technische Festlegungen

- **Flutter (Dart)**, eine Codebasis für iOS und Android.
- State-Management: Riverpod. Netzwerk: dio. Lokale Datenbank: Drift (SQLite).
  Karte: MapLibre oder flutter_map mit OSM-Kacheln. Standort: geolocator.
- **Kein eigener Server.** Die App spricht die Datenquellen direkt vom Gerät an.
  Einzige erlaubte Ausnahme ist später ein kleiner serverloser Dienst
  (Cloudflare Worker + FCM-Themen) für Linienabo-Push.
- Datenquelle Nummer eins: **TRIAS (VDV 431)**, der offene VDV-Standard, den
  der VRR über OpenService anbietet. Anfragen: `LocationInformationRequest`,
  `StopEventRequest`, `TripRequest`, `TripInfoRequest`.
- Zweite Quelle: **VRR EFA OpenService** (proprietär, Mentz, rapidJSON),
  nur dort, wo TRIAS nachweislich weniger liefert – vor allem
  `XML_ADDINFO_REQUEST` für Störungsmeldungen; dazu
  `XML_STOPFINDER_REQUEST`, `XML_DM_REQUEST`, `XML_TRIP_REQUEST2`,
  `XML_TRIPSTOPTIMES_REQUEST`, immer mit `useRealtime=1` und
  `outputFormat=rapidJSON`. Testserver `openservice-test.vrr.de/static02/`.
- Dritte Quelle: **GTFS-RT** von gtfs.de bzw. DELFI für flächendeckende
  Echtzeit und Service-Alerts; DELFI-GTFS für Haltestellen, Steige und
  Linienverlauf.
- Jede Datenquelle liegt hinter der Schnittstelle `TransitProvider`
  (`searchLocations`, `departures`, `planTrip`, `refreshTrip`, `messages`).
  Kein Protokolldetail verlässt seinen Adapter; die App kennt nur die eigenen
  Modelle. `TriasProvider` ist der Standard, `EfaProvider`, `GtfsRtProvider`
  und später `MotisProvider` müssen ohne Änderung an der UI eingehängt
  werden können.
- Alles Persönliche bleibt auf dem Gerät. Kein Konto, keine Werbung, kein
  Tracking, keine Analytics-SDKs.

## Arbeitsweise

- Schritt für Schritt, ein Thema pro Schritt. Nach jedem lauffähigen Schritt
  `flutter analyze`, dann committen.
- Netzwerkcode kommt mit Tests gegen aufgezeichnete Antworten (Fixtures) in
  `test/fixtures/`. Keine Tests, die den Testserver live brauchen.
- Keine Platzhalterdaten in der UI ohne Kennzeichnung im Code (`// TODO: echte
  Daten`), damit nichts Gefaktes im Build landet.
- Wenn etwas im Konzept unklar ist: nachfragen statt raten, aber vorher in
  `docs/konzept.md` nachsehen.

## Regeln für die Oberfläche

Diese vier werden am häufigsten verletzt, deshalb hier noch einmal:

1. **Nichts springt.** Platz für `+3` ist immer reserviert, Zeilenhöhen sind
   fest, Echtzeit ändert nur Text und Farbe.
2. **Gleich breite Ziffern** für alle Zeiten und Zahlen.
3. **Namen einzeilig kürzen** mit `…`, nie umbrechen.
4. **iPhone und Android haben dieselben Screens**, gleiche Anzahl, gleicher
   Inhalt. Unterschiede nur bei Schrift, Zurück-Pfeil, unterer Navigation und
   den Rändern.

Farbe hat immer Bedeutung: Petrol = Aktion, grün = pünktlich, orange =
verspätet oder Umleitung, rot = Ausfall, violett = SEV, grau = nur Fahrplan,
keine Echtzeit. Keine Verläufe, keine Schatten, Systemschrift.

## Rechtliches, das im Build stehen muss

- Fußzeile unter „Mehr“: „Fahrplandaten: VRR, DELFI e. V. Alle Angaben ohne
  Gewähr.“
- Vor Produktivnutzung von TRIAS bzw. EFA Zugang bei
  `opendata-oepnv@vrr.de` anfragen. Bis dahin nur Testserver.
- Karte: „© OpenStreetMap-Mitwirkende“ (ODbL) sichtbar einblenden.
- Transitous/MOTIS nur, solange das Projekt Open Source und nicht kommerziell
  ist; User-Agent mit Kontaktadresse setzen.

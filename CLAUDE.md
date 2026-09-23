# Gleich.da – Projektregeln

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

## Auslieferung (Obtainium)

- Repository: https://github.com/macpano/gleich.da (öffentlich seit 23.09.2026; bis v0.2.2 hieß es
  `gleichda`, GitHub leitet die alte Adresse weiter).
  Obtainium verfolgt die GitHub-Releases, ohne Token.
- Commits nur mit der anonymen Adresse 325691885+macpano@users.noreply.github.com
  (in der Repo-Konfiguration gesetzt) – keine private E-Mail im öffentlichen Verlauf.
- Neue Version: `bash tool/release.sh <Version> "<Neuerungen>"` – erhöht die
  Build-Nummer, prüft, baut die signierte APK, taggt `v<Version>` und legt das Release an.
- Signiert mit demselben Schlüssel wie Linienlog (`android/key.properties`, nicht im Repo).
  Ohne diesen Schlüssel lassen sich Updates nicht über die installierte App spielen.

## Stand (v0.3.1, 23.09.2026)

- Umgesetzt sind die Schritte 1–15 in Grundform; was fehlt, steht in `docs/abgleich.md`.
- Der geteilte Chat liegt nur lokal als `docs/chat-verlauf.txt` (in .gitignore, persönliche Angaben – nie einchecken).
- Bildschirmfotos ohne Handy: `flutter test test_screens --update-goldens` → `test_screens/out/*.png`.
  In Widget-Tests die Drift-Datenbank nicht schließen (wartet sonst auf Abfragen aus der Testzone).
- Hintergrund: `lib/background.dart` (WorkManager ≈ 15 min: Linienabos, Wecker nachplanen).
  Unterwegs-Benachrichtigung als Vordergrunddienst (`specialUse`), Fortschrittsbalken als Bild.
- Produkte (SB, CE, AST, SEV, ICE-Nummer …) erkennt `lib/domain/product.dart` aus TRIAS-Submode,
  Verkehrsmittelname und Linienname; Tests gegen `test/fixtures/trias_se_*.xml`.
- Fußweg-Grenze: TRIAS `IndividualTransportOptions/MaxDuration` in Origin und Destination
  (wirkt nur auf Start und Ziel); Umsteigewege filtert die App selbst.
- Release-Builds entfernen Ressourcen, die nur per Name geladen werden – `res/raw/keep.xml` hält
  `ic_stat_gleichda` (fehlte in v0.2.0, App hing am Startbild).
- Selbst-Aktualisierung ohne Obtainium (`lib/state/updates.dart`): GitHub-Release prüfen, APK nach
  `files/updates` laden (Größe + „PK“ geprüft), Meldung `UpdateToast`, Installation über den
  MethodChannel `de.gleichda/update` in `MainActivity.kt` (FileProvider `${applicationId}.updates`).
- Unterwegs ist kein eigener Bildschirm (Konzept: „einen Tipp entfernt in der Fahrt“), sondern
  `CompanionBar` als feste Leiste unten in der Fahrt (mit „Beenden“); Karte `lib/ui/trip_map.dart`. TRIAS liefert keinen Linienverlauf
  (LegProjection leer, geprüft 23.09.) – die Karte verbindet die Haltestellen (Koordinaten aus der EFA).
- Name **Gleich.da** (seit v0.3.0) überall, wo man ihn sieht. Technische Kennungen bleiben
  `gleichda` (Dart-Paket, `de.gleichda.app`, Datenbank): Eine neue App-Kennung wäre für Android eine
  andere App – Updates und gespeicherte Daten gingen verloren.
- Linienwege: EFA `XML_TRIP_REQUEST2` liefert je Abschnitt `coords` (dicht, entlang Straße/Gleis);
  Zuordnung über Linie + Fahrtnummer wie bei der Echtzeit (`VrrProvider.legPaths`).
- Abfahrt → ganze Fahrt: `tripOfDeparture` über `XML_TRIPSTOPTIMES_REQUEST`.
- Liniensuche: `XML_SERVINGLINES_REQUEST mode=line` sucht deutschlandweit; begrenzt auf WSW,
  „Wuppertal“ in der Beschreibung und DB-Züge im NRW-Bereich (Kennung `9xE..`), dazu alle Linien an
  Hbf, Vohwinkel, Oberbarmen. `XML_LINELIST_REQUEST` liefert auf dem Testserver nichts.
- Unterwegs per GPS (`locateOnLeg` in `lib/domain/companion.dart`): Position auf die Haltestellenfolge
  gelegt, ≤ 250 m sonst Uhrzeit. Fahrzeugpositionen der Betriebe sind nicht offen – das Fahrzeug ist die
  eigene Position.
- Fußwege: FOSSGIS-OSRM `routing.openstreetmap.de/routed-foot/route/v1/driving/…` (Pfad heißt „driving“,
  gerechnet wird für Fußgänger), `lib/data/walk_route.dart`.
- Benachrichtigung: Android blendet lautlose Benachrichtigungen (Importance.low) oft aus der Statusleiste
  aus – deshalb Kanal `unterwegs_2` mit normaler Wichtigkeit ohne Ton. „Beenden“ läuft über
  `notificationActionInBackground` und den Port `gleichda_unterwegs`, ohne die App zu öffnen.
- Kartenkacheln vorläufig FOSSGIS (`tile.openstreetmap.de`), offene Entscheidung im Konzept.

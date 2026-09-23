# Abgleich Chat-Verlauf ↔ App (Stand 23.09.2026, v0.2.0)

Quelle: geteilter Chat (`docs/chat-verlauf.txt`), Klick-Prototyp, `docs/konzept.md`.
✅ = in der App, ◐ = teilweise, ☐ = offen.

## Suchen
- ✅ Startseite mit Logo, Von/Nach untereinander mit Mini-Verlaufslinie
- ✅ App-Icon (Konvoi auf Petrol, adaptiv) und Startbild hell/dunkel
- ✅ „Von“ mit „Mein Standort“ vorbelegt, Suche ab Koordinate
- ✅ Leere Suche: Mein Standort, Meine Orte, Haltestellen in der Nähe mit Entfernung, zuletzt gesucht
- ✅ Gleichnamige Haltestellen nach Trefferqualität und Entfernung, mit Ort und Entfernung
- ✅ Zeit einstellen: Abfahrt/Ankunft, Heute/Morgen/Datum, Schnellwahl, Uhrzeit-Rad in 5-min-Schritten, Klartextzeile
- ✅ Suchoptionen: Zwischenhalt, Profil, Verkehrsmittel, barrierefreie Wege
- ✅ Zuletzt angesehene Fahrt: sofort aus dem Speicher, 30 s live (EFA TripStopTimes)
- ✅ Favoriten und Zuletzt gesucht, Wischen: links löschen, rechts Favorit
- ✅ Live-Abfahrten an Favoriten: Verbindungen zeigen die nächste Abfahrt, Lieblingshaltestellen (Stern im Abfahrtsmonitor)
  die nächsten drei Abfahrten auf der Startseite (0.4.12)
- ☐ Gelernte Gewohnheiten

## Verbindungen
- ✅ Liste mit Zeitleisten-Balken, Echtzeit farbig, „nur Fahrplan“
- ✅ Suchprofile als Chips (Alle = drei Profile parallel, zusammengeführt), Profil an/aus je Suche
- ✅ Etiketten „schnellste“, „ohne Umstieg“, „wenigste Umstiege“
- ✅ Früher und Später
- ✅ Zeitraster wie in Öffi, Umschalter Liste/Zeitraster, Wahl dauerhaft gespeichert
- ✅ Anschlussprüfung: sicher/knapp/nicht erreichbar, nicht erreichbare ausgegraut am Ende mit Hinweis
- ✅ Endloses Scrollen: spätere Verbindungen laden kurz vor dem Listenende von selbst (0.4.12)

## Fahren
- ✅ Fahrtverlauf: Plan/Ist, Steig und Steigwechsel, Zwischenhalte einklappbar, entfällt/Umleitung
- ✅ Passierte Halte grau, aktuelle Position mit Fahrzeugsymbol
- ✅ Anschlussprüfung je Umstieg im Verlauf
- ✅ Abweichungs-Banner mit „Alternativen anzeigen“; Alternativen-Screen (nächste Fahrt derselben Linie, schneller/gleich schnell, etwas später, Zeitdifferenz)
- ✅ Losfahren → Unterwegs-Modus: nächster Schritt groß, laufende Benachrichtigung (Linie und Ziel, wo aussteigen, in min + Uhrzeit, Fortschritt mit Fahrzeugsymbol, „Beenden“), Vordergrunddienst
- ✅ Weg zum Steig: Karte (OSM/FOSSGIS), Standort, Ziel-Steig aus der EFA, andere Steige grau, Richtung und Entfernung, „Loslaufen in n min“, Übergabe an Karten-App
- ✅ SEV: violett in Abfahrten, im Fahrtverlauf „Ersatzhaltestelle“ mit dem Satz aus der Meldung direkt am Einstieg;
  ohne Angabe ehrlicher Hinweis (0.4.12). Offen: Plausibilitätsprüfung der Koordinaten
- ✅ Abbiegehinweise im Fußweg; Pfeil in Laufrichtung (GPS-Kurs statt Magnetkompass); Tipp auf ein Linienschild zeigt
  den ganzen Linienverlauf des Fahrzeugs mit Karte (0.4.12)

## Informieren
- ✅ Abfahrten in der Nähe: bis zu vier Haltestellen nach Entfernung mit Gehzeit, „Alle Abfahrten“, Zeitwahl, Verkehrsmittel-Filter, Ausfall mit nächster Fahrt
- ✅ Meldungen: Liste aus EFA XML_ADDINFO_REQUEST (Wuppertal), Filter Meine Linien/Meine Halte/Alle, Detail mit ganzem Text
- ✅ Linienabos: aus Meldung oder Abfahrt, Zeitfenster, Hintergrundprüfung (WorkManager ≈ 15 min) mit Benachrichtigung
- ☐ Serverloser Push-Dienst (Cloudflare Worker + FCM)

## Meine Fahrten
- ✅ Fahrtenwecker: Liste mit Schalter, Wochentagen, nächstem Weckzeitpunkt und Status; Neuer Wecker (Name, Von/Nach, Ankommen/Losfahren um, Wochentage, Vorlauf, bei Störung früher, Unterwegs-Modus starten)
- ✅ Meine Orte: Zuhause, Arbeit, weitere; oben in der Suche, in Weckern vorbelegt

## Mehr
- ✅ Fahrtenwecker, Meine Orte, Favoriten und Verlauf, Profil, Linienabos, Erscheinungsbild,
  Umsteigezeit, Gehgeschwindigkeit, barrierefreie Wege, Standort, Verlauf löschen,
  Datenquellen, Datenschutz, Impressum (Angaben folgen), Pflichtangabe

## Zustände
- ✅ Laden als Platzhalter, Fehler mit „Erneut versuchen“ und letztem Stand, „Daten nicht aktuell“ nach 2 min
- ✅ Eigener Offline-Zustand mit grauen Zeiten und „Stand von hh:mm“

## Später (laut Chat)
- Erster Start mit Standort-Erklärung, Haltestellen-Detail, Widget, große Schrift prüfen,
  Englisch, iOS (Live Activity, Dynamic Island).

## v0.2.1 (23.09.2026)
- ✅ Start hing am Startbild: Benachrichtigungssymbol fiel im Release-Build weg (`res/raw/keep.xml`), Initialisierung erst nach dem ersten Bild
- ✅ Startbild wie im Canvas (Logo auf hellem bzw. dunklem Grund)
- ✅ Aktualisierung: prüft beim Start und alle 6 h das neueste GitHub-Release, lädt und installiert auf Wunsch
- ✅ Produkte: Bus, Schnellbus (SB), CityExpress (CE), Nachtexpress, AST, SEV, Schwebebahn, Straßenbahn, U-Bahn, S-Bahn, RE/RB, IC/ICE mit Zugnummer (`lib/domain/product.dart`)
- ✅ Fortschrittsbalken in der App wie in der Benachrichtigung
- ✅ Fußweg höchstens 5–30 min (Profil, Suchoptionen); bestimmt auch den Umkreis „In der Nähe“; Fußwege in der Verbindungsleiste mit Minuten

## v0.2.2 (23.09.2026)
- ✅ Unterwegs ohne eigenen Bildschirm: „Losfahren“ startet die Benachrichtigung, die Fahrt zeigt oben den nächsten Schritt mit Karte
- ✅ Karte der Fahrt (Symbol oben in der Fahrt): Linien über die Haltestellen, Fahrzeug geschätzt aus Fahrplan/Echtzeit, eigener Standort
- ✅ Positionspunkt statt Bus im Haltestellenverlauf
- ✅ Verbindungen: Abfahrt – Ankunft ohne Lücke, Linien in kurzen Abschnitten mit voller Nummer
- ✅ Selbst-Aktualisierung: lädt beim Öffnen im Hintergrund, Meldung „Update verfügbar“ mit „Installieren“
- ✅ Echter Linienverlauf auf der Karte (seit v0.3.0 aus der EFA-Verbindungsauskunft)

## v0.3.0 (23.09.2026)
- ✅ Name „Gleich.da“ überall (Wortmarke mit Bernstein-Punkt, App-Name, Texte, Repository)
- ✅ Linienwege auf der Karte (EFA), kleine Namensnennung
- ✅ Abfahrt antippen öffnet die ganze Fahrt; lange drücken abonniert die Linie
- ✅ Meldungen: „Alle“ zuerst, Linie suchen und abonnieren (auch unter Linienabos)
- ✅ Fahrt: Pfeil zum Aufklappen der Zwischenhalte, „nächster Halt“ nur bei aktiver Begleitung,
  Uhrzeiten brechen bei großer Schrift nicht mehr um, Karte nur über das Kartensymbol
- ✅ Benachrichtigung kompakt, nur der Android-Fortschrittsbalken
- ✅ Feineres Design: kleinere Titel und Knöpfe, schmalere Liniennummern, Haarlinien, niedrigere Leiste

## v0.3.1 (23.09.2026)
- ✅ Unterwegs per GPS: nächster Halt, Halte bis zum Ausstieg und Fortschritt aus der eigenen Position
  (`locateOnLeg`), sonst Uhrzeit; „nächster Halt“ nie, wenn er der Ausstieg ist
- ✅ Karte: Fahrzeug = eigene GPS-Position während der Begleitung (keine Schätzung mehr)
- ✅ Benachrichtigung mit Symbol in der Statusleiste (Kanal `unterwegs_2`, normale Wichtigkeit ohne Ton),
  „Beenden“ ohne die App zu öffnen, Vordergrunddienst auch als Standortdienst
- ✅ Verbindungssuche: schnellste Suche sofort, andere Profile nur im gleichen Zeitraum, keine
  begonnenen Verbindungen, Standort aus letzter Position (< 2 min)
- ✅ Zielsuche ohne „In der Nähe“, Suchtreffer nach Entfernung sortiert
- ✅ Fußnavigation entlang von Gehwegen (FOSSGIS-Router) mit Abbiegehinweisen, neu berechnet bei Abweichung
- ✅ Hinweise in der Fahrt eingeklappt, Streifen hinter der Statusleiste, Versionsabgleich bei jedem Öffnen

## v0.3.2 (23.09.2026)
- ✅ Unterwegs als schmale Zeile mit feinem Fortschrittsstrich, ausblendbar
- ✅ Eigene Symbole für Liste/Zeitraster

## v0.3.3 (23.09.2026)
- ✅ Unterwegs als feste Leiste am unteren Rand mit „Beenden“ und Fortschrittsstrich (statt Karte oben, die
  den Verlauf verschob und wegscrollte); Inhalt mittig ausgerichtet

## v0.3.4 (23.09.2026)
- ✅ Liniensuche deutschlandweit, nach Standort sortiert (Linien an Haltestellen in der Nähe, dann gleicher Betrieb bzw. DB-Region)
- ✅ Meldungen für den eigenen Ort (Gemeindeschlüssel der nächsten Haltestelle), zuletzt genutzter Ort auch im Hintergrund
- ✅ Volle Haltestellennamen mit Ort im Fahrtverlauf („Wuppertal Hbf“ statt „Hbf“)
- ✅ „Meine Haltestellen“ ausgeschrieben, Einstellungswerte einheitlich groß
- ✅ Linienabos sichtbar abbestellbar (Symbol je Zeile, „Abo beenden“, Umschalter in der Suche)
- ✅ Fußnavigation: Lage nur vorwärts, nur echte Abbiegungen, Kehrtwende am Ziel übersprungen; Zentrieren-Knopf mit Mitführen
- ✅ Beenden über die Benachrichtigung doppelt abgesichert (Dienst stoppt selbst, App erkennt fehlende Benachrichtigung)

## v0.4.0 (23.09.2026)
- ✅ Android im Material-Stil über die gemeinsamen Bausteine: Einstellungszeilen mit Symbol, Akzent-Abschnittstitel,
  Filterchips (auch Meldungen), Segmentknopf, Material-Schalter, Kontrollkästchen, Kapselknöpfe, Material-Uhr

## v0.4.1 (23.09.2026)
- ✅ Orte überall mit Ort angezeigt (`Location.label`: „Wuppertal Hbf“, „Hofaue 12, Wuppertal“); die Echtzeit-Aktualisierung
  übernimmt volle EFA-Namen und heilt so gespeicherte Fahrten mit Kurznamen
- ✅ Zuletzt angesehene Fahrt verschwindet 2 min nach der Ankunft, auch bei offener App

## v0.4.2 (23.09.2026)
- ✅ Fahrtverlauf: Linie und volles Ziel in einer eigenen Zeile, Zwischenhalte und Echtzeit darunter (vorher abgeschnitten)
- ✅ Über eine Abfahrt geöffnete Fahrt zeigt Linie und Ziel oben im Kopf

## v0.4.3 (23.09.2026)
- ✅ Abfahrten: drei Knöpfe ohne Scrollen – Ort (öffnet immer die Suche, „Mein Standort“ = in der Nähe), Verkehrsmittel,
  Uhrzeit (v0.4.4); vorher ließ sich nach Wahl einer Haltestelle keine andere mehr suchen

## v0.4.5 (23.09.2026)
- ✅ Weiterfahrt im selben Fahrzeug erkannt (TRIAS `InterchangeMode remainInVehicle`, EFA „nicht umsteigen“): kein Umstieg,
  keine Anschlusswarnung, im Verlauf „Weiterfahrt im selben Fahrzeug · sitzen bleiben“, Unterwegs als eine Fahrt
- ✅ Alternativen: „Spätere Verbindungen“
- ✅ Suchprofile und Meldungsfilter ohne seitliches Scrollen (Umbruch), „Mein Standort“ nie als Ziel,
  Von/Nach bündig untereinander

## v0.4.6 (23.09.2026)
- ✅ Verbindungen: statt fünf Profil-Chips eine Zeile – Sortierung als Menü (Abfahrt, Schnellste, Wenig Umstiege,
  Wenig Fußweg; sortiert sofort ohne neue Anfrage, weil alle Varianten aus einer Suche kommen) und „Barrierefrei“

## v0.4.7 (23.09.2026)
- ✅ Verbindungen standardmäßig nach „Schnellste“ sortiert
- ✅ Fußnavigation beim Umsteigen: Gehsymbol in jeder Umsteigezeile (zum Steig des Anschlusses, mit dessen Abfahrt),
  in der Unterwegs-Leiste vor jedem Einsteigen und als Knopf „Weg zum Steig“ in der Benachrichtigung

## v0.4.8 (23.09.2026, nach Rückmeldungen von Timo)
- ✅ Sortierung „Früheste Ankunft“ als Standard, „Kürzeste Fahrzeit“ statt „Schnellste“; Von–bis inklusive Fußweg;
  keine doppelten Etiketten („ohne Umstieg“)
- ✅ Umstieg „nicht erreichbar“ erst, wenn nicht einmal der Umsteigeweg (am selben Halt 1 min) passt; die persönliche
  Umsteigezeit bedeutet nur „knapp“. Hinweise „Anschluss wird gehalten“ liefert die Auskunft nicht (geprüft)
- ✅ Weiterfahrt im selben Fahrzeug in der Übersicht nicht mehr als Fußweg, zählt nicht zu „min zu Fuß“
- ✅ Über eine Abfahrt geöffnete Fahrt ohne „ohne Umstieg“
- ✅ Suchtreffer: Haltestellen immer vor Orten und Adressen
- ✅ Meldungen: Gemeinden im Umkreis von 5 km (EFA `XML_COORD_REQUEST`, voller Gemeindeschlüssel aus `placeID`),
  Abschnitt „Demnächst“ für künftige Sperrungen, Linien je Meldung einmal
- ✅ Weg zum Steig aus der Ferne (> 2 km): Vorschau des Umsteigewegs statt Führung vom Standort
- ✅ Schnellziele Zuhause/Arbeit unter der Suche
- ✅ Verbindungen: Zeitzeile („Heute ab …“) antippbar, öffnet das Zeitfenster und sucht neu
- ✅ Schalter „Vorabversionen erhalten“ (Mehr → Aktualisierung), Lizenz GPL-3.0

## v0.4.9 (23.09.2026)
- ✅ Unterwegs: Ankunft über 1 min vorbei = erledigt (kein Rücksprung des Balkens), GPS nur wenn plausibel
  (nicht weit hinter der Uhrzeit), Benachrichtigung zeigt bis zum Ende „Angekommen“

## v0.4.10 (23.09.2026)
- ✅ Aus dem Abfahrtsmonitor geöffnet: „Fahrtverlauf“ mit Linie und Ziel oben, „ab … · an …“, Zwischenhalte sofort aufgeklappt

## 0.4.11-vorab.1 (23.09.2026)
- ✅ Reiter „Karte“ (Suche · Karte · Abfahrten · Meldungen · Mehr): Haltestellen im Ausschnitt ab Zoom 14,5,
  Tipp zeigt Abfahrten, Tipp auf eine Abfahrt zeigt die Fahrt mit Linienweg und Halten, „Fahrtverlauf“ öffnet sie

## 0.4.11-vorab.2 (23.09.2026)
- ✅ Unterwegs-Leiste app-weit unten (MaterialApp-`builder` → `appFrame`), in jeder Ansicht an derselben Stelle;
  Tipp: vor dem Einsteigen Weg zum Steig, sonst die Fahrt

## 0.4.11-vorab.3 (23.09.2026)
- ✅ Meldungen nach Nähe: „In deiner Nähe“ = Linien an Haltestellen im Umkreis von 1,5 km, „Weitere in der Umgebung“ =
  Linien derselben Verkehrsbetriebe; fremde Betriebe (unter Hagen z. B. MVG aus Iserlohn/Hemer) und Nachbarorte ohne
  Bezug fallen weg. Gemessen Hagen-Boele: 82 → 2 Meldungen (539 und 518/519 Herdecke)

## 0.4.11-vorab.4 (23.09.2026)
- ✅ Meldungen je Verkehrsunternehmen der Umgebung: „In deiner Nähe“, dann ein Abschnitt je Betrieb, dessen Linien im
  Umkreis von 2,5 km halten (Gemeinden weiter aus 5 km), dann „Allgemein“ und „Demnächst“
- ✅ Linie suchen: Tipp auf eine Linie zeigt ihre aktuellen und angekündigten Störungen, ohne sie zu abonnieren
  (Abonnieren oben rechts). Alle Meldungen (EFA ohne Ortsfilter, ≈ 4 MB) höchstens alle 10 min
- ✅ Karte: Haltestellen an der Mitte ihrer echten Steige (EFA `XML_COORD_REQUEST` `type_1=BUS_POINT`); die
  TRIAS-Mitte lag an großen Haltestellen bis zu 120 m daneben. Ab Zoom 16,5 jeder Steig einzeln mit Nummer,
  Tipp zeigt nur dessen Abfahrten
- ✅ Reiter unten verschieben sich nie: Auf der Startseite steht die Unterwegs-Leiste über den Reitern, in
  Unterseiten ganz unten

## 0.4.11-vorab.5 (23.09.2026, nach Rückmeldungen von Timo)
- ✅ Gesicherte Anschlüsse: „Anschluss wartet“ im Fahrtverlauf statt „knapp“/„nicht erreichbar“.
  TRIAS meldet sie nur als Fußweg (`InterchangeMode walk`); die EFA führt einen eigenen Abschnitt mit Produktklasse 98
  „gesicherter Anschluss“. Beim Öffnen einer Fahrt wird dieselbe Verbindung bei der EFA gesucht (alle Fahrten gleich).
  Live geprüft: Oberbarmen Bf → Hannoverstraße, 602 → 632 an der Weiherstraße (`test_live/gesichert_live_test.dart`)
- ✅ Fehler behoben: Über „Früher“ geladene, schon angekommene Fahrten zeigten beim Öffnen „Keine Fahrt geöffnet“ –
  die erste Aktualisierung räumte sie als „angekommen“ weg. Jetzt bleiben sie, solange man sie ansieht
- Geprüft: Die Meldung zur 511 (Hagen Stadtmitte/Volme Galerie) steht seit vorab.4 wieder in der Liste (Abschnitt VER),
  in Hagen-Boele, Hagen-Vorhalle und Herdecke (`test_live/meldungen_live_test.dart`)

## 0.4.11-vorab.6 (23.09.2026)
- ✅ Bildmarke in der App: Zug, Straßenbahn und Bus wieder versetzt. flutter_svg verrechnete `skewX` mit den
  verschachtelten `translate` der Fahrzeuge falsch (alle bündig links); jetzt eine `matrix` je Fahrzeug
  (`assets/logo.svg`, `logo-dark.svg`, `appicon.svg`)

## 0.4.11-vorab.7 (23.09.2026)
- ✅ Karte steiggenau: Ein Tipp auf einen Steig fragt die Abfahrten mit dessen voller Kennung ab
  (`de:05124:11376:91:2`); TRIAS liefert dann nur diesen Steig (live 15/15). Vorher wurde nach der Steignummer
  gefiltert – am Hbf gibt es „2“ mehrfach (Busbahnhof `…:2:2`, Gleis `…:91:2`). Gleiswechsel stehen beim geplanten
  Steig (`test_live/steig_live_test.dart`)

## 0.4.11-vorab.8 (23.09.2026)
- ✅ Gesicherter Anschluss kurz „Anschluss wartet“ (wie „Anschluss sicher/knapp“); „… wartet in der Regel“ wurde
  bei großer Schrift abgeschnitten

## 0.4.11-vorab.9 (23.09.2026)
- ✅ Unterwegs-Leiste: ein Tipp öffnet immer die Fahrt (vorher vor dem Einsteigen nur den Fußweg); zum Weg das Laufsymbol
- ✅ Eine einzige Leiste in `appFrame`, die beim Ansichtwechsel in 260 ms an ihren Platz gleitet (über den Reitern ↔
  ganz unten); über Blättern von unten auf der Startseite tritt sie zurück
- ✅ Keine doppelten Ansichten: `pushOnce` (Fahrt, Karte, Weg zum Steig) springt zu einer offenen Ansicht zurück,
  statt sie erneut zu öffnen – vorher musste man teils mehrmals zurück
- ✅ Karte: Hinweis nach Zoomstufe statt nach leerer Liste; Laden auch nach Bewegung per Knopf; bei Fehler
  „Haltestellen nicht geladen · erneut laden“; nur die neueste Anfrage zählt

## 0.4.11-vorab.10 (23.09.2026)
- ✅ Alle Fußwege auf der Karte als Gehweg (FOSSGIS): Start → Einstieg, Umstiege, Ausstieg → Zieladresse; Start- und
  Zieladresse als Punkt. TRIAS gibt Adressen ohne Lage zurück – `withEndpoints` übernimmt sie aus der Suche. Die Lage
  der Haltestellen kommt erst mit der EFA-Aktualisierung; deshalb wird eine geöffnete Fahrt sofort aktualisiert und die
  Gehwege hängen an der Lage ihrer Enden (`WalkPathKey`). Live: Alter Markt → Friedrich-Ebert-Str. 100, letzter Weg 146 m
  (`test_live/fussweg_ziel_live_test.dart`)
- ✅ Fußweg zum Ziel mit Laufsymbol (Weg zum Ziel auf der Karte)
- ✅ Startseite: Die Fahrt bleibt bis zur Ankunft an der Zieladresse – `tripEnd` = letzte Fahrt mit Echtzeit + Fußweg
  (vorher Planzeit des Fußwegs, bei Verspätung zu früh weg)

## 0.4.11-vorab.11 (23.09.2026)
- ✅ „Erneut versuchen“ zeigt eine Ladeanzeige (`Notice` wartet auf die Aktion); vorher suchte der Knopf neu, änderte
  aber sichtbar nichts, wenn die Liste schon leer war – wirkte tot. Unerwartete Fehler in der Verbindungssuche enden
  jetzt mit Hinweis statt endlosem Laden
- ✅ Eine Fahrt wird nicht weggeräumt, solange ihre Ansicht offen ist (`tripViewers`). Vom Standort zur eigenen
  Adresse liefert die Auskunft nah am Ziel nur einen Fußweg von 0–6 min (live, `test_live/nah_am_ziel_live_test.dart`);
  zwei Minuten danach stand mitten in der Ansicht „Keine Fahrt geöffnet“
- Geprüft: Die Auskunft liefert bei gleicher Anfrage stabil Ergebnisse (27/27), eine leere Liste ließ sich nicht
  nachstellen (`test_live/verbindungen_wiederholt_live_test.dart`)

## 0.4.11-vorab.12 (23.09.2026)
- ✅ Vom Standort nach Hause fand die Suche teils gar nichts: Liegt man nah am Ziel und ist der Fußweg länger als die
  Fußweg-Grenze, antwortet TRIAS mit Code `-4000` statt mit einem Fußweg (live: 150 m, Grenze 3 min). Jetzt gilt
  `-4000` als „keine Verbindung“, und ohne Treffer sucht die App einmal ohne Fußweg-Grenze – der Fußweg erscheint.
  „Erneut versuchen“ bekam vorher jedes Mal dieselbe Fehlantwort
- Bildschirmfoto `verbindungen_fussweg`: reiner Fußweg in der Verbindungsliste

## 0.4.12-vorab.1 (23.09.2026)
- ✅ Begleitung zu Fuß bis zur Zieladresse (Phase `toDestination`): nach dem letzten Ausstieg „Zu Fuß zum Ziel“ mit
  Laufsymbol und Weg; angekommen per GPS ≤ 40 m an der Adresse (höchstens 10 min Nachlauf), ohne GPS nach Uhrzeit.
  Auch reine Fußwege. Die Fahrt bleibt währenddessen auf der Startseite
- ✅ Gesicherte Anschlüsse in der Verbindungsliste („Anschluss wartet“): eine EFA-Anfrage je Paar aus erstem Einstieg
  und letztem Ausstieg (höchstens drei), live geprüft
- ✅ Endloses Scrollen in der Verbindungsliste
- ✅ Lieblingshaltestellen mit Live-Abfahrten auf der Startseite

## 0.4.12-vorab.2 (23.09.2026)
- ✅ Ersatzverkehr: Hinweis „Ersatzhaltestelle“ am Einstieg mit dem Meldungssatz (`sevStopHint`)
- ✅ Linienverlauf: Tipp aufs Linienschild in der Fahrt → alle Halte des Fahrzeugs mit Karte, Ein-/Ausstieg markiert
  (`tripOfDeparture(whole: true)`, live: 611 ab Alter Markt 9 → ganz 37 Halte)
- ✅ Fußweg: eigener Punkt als Pfeil in Laufrichtung
- ✅ Erster Start: Erklärung zum Standort, bevor Android fragt (Standortabfragen warten darauf)
- ✅ Große Schrift geprüft (150 %, Bildschirmfotos `gross_*`): feste Zeilenhöhen wachsen mit (`textGrowth`),
  Sortier-/Barrierefrei-Knöpfe brechen um statt überzulaufen

## 0.4.12-vorab.3 (23.09.2026)
- ✅ Reiter in der Reihenfolge Suche · Abfahrten · Karte · Meldungen · Mehr (Nutzervorgabe)

## 0.4.12-vorab.4 (24.09.2026)
- ✅ Keine Verbindung jetzt → die App weicht aus: ohne Profil-Einschränkungen (falls das Profil alles aussortiert hat),
  sonst die nächste mögliche Verbindung in 1 h, 3 h oder am nächsten Morgen ab 5 Uhr, mit Hinweis „Jetzt gibt es keine
  Verbindung. Die nächste fährt …“ (`_searchWithFallback`)
- ✅ Aktualisieren-Kreisel beim Herunterziehen unter der Statusleiste statt dahinter (`edgeOffset`)
- ✅ Bewegungssprache `Motion` (Seite 320 ms, Einblenden 220 ms, Zustand 150 ms, easeOutCubic):
  Die Unterwegs-Leiste hängt an der Animation der Seite über der Startseite (`firstPageAnimation`) – exakt gleichzeitig
  beim Öffnen, Zurückgehen und bei der Zurück-Geste. Den Platz unten hält die Seite selbst frei
  (`CompanionAwareTransitions`), die Startseite dahinter bewegt sich nicht mehr. Leiste erscheint beim Losfahren von
  unten, tritt unter Blättern und Dialogen zurück
- ✅ Weitere Übergänge: Reiterwechsel überblendet (`_FadeTabs`), Platzhalter → Ergebnis überblendet (`FadeSwitch`,
  Verbindungen und Abfahrten), Zwischenhalte klappen weich auf (`AnimatedSize`), Fahrt auf der Karte schiebt sich von
  unten herein; alle Einzeldauern auf `Motion` vereinheitlicht

## 0.4.12-vorab.5 (24.09.2026)
- ✅ **Deutschlandweit über Transitous** (`lib/data/motis/motis_provider.dart`, MOTIS 2): Orte (`/geocode`, Haltestellen im
  Umkreis über `/map/stops`), Abfahrten (`/stoptimes`), Verbindungen (`/plan` mit Linienweg, Zwischenhalten, Echtzeit,
  Umsteigen im selben Fahrzeug), Aktualisieren (Neusuche, Abgleich über die Fahrten), Linienverlauf (`/trip`).
  Verkehrsmittel nach GTFS-Routentyp (MOTIS führt die Münchner S-Bahn als METRO)
- ✅ `AutoProvider` wählt je Anfrage: in NRW der VRR (Echtzeit, Steige, Meldungen, gesicherte Anschlüsse), außerhalb und
  für Transitous-Orte Transitous; findet der VRR nichts, sucht Transitous. Live: München (U3, U6→U1→U3, Abfahrten,
  Linienverlauf 21 Halte), Berlin Standort → Kurfürstendamm 21 (S7 + Fußweg bis zur Adresse), Wuppertal weiter VRR
  (`test_live/transitous_live_test.dart`)
- ✅ Namensnennung unter Mehr → Datenquellen und in der Fußzeile (transitous.org/sources); User-Agent mit Repo-Adresse
- Grenzen: Meldungen, Steigpläne und gesicherte Anschlüsse nur im VRR

## 0.4.12-vorab.6 (24.09.2026)
- ✅ Startseite: Suchen-Knopf wurde bei langer Zeitangabe („Morgen Ankunft 11:38“) zu einem Punkt zusammengedrückt. Die
  Zeile wird jetzt ausgemessen: Suchen behält seine Breite, „Optionen“ zeigt dann nur das Symbol, Zeit kürzer
  („Morgen an 11:38“)

## 0.4.12-vorab.7 (24.09.2026)
- ✅ Startseite: Die Messung der Suchzeile nutzte nicht die Schrift der Umgebung und zeigte „Optionen“ schon bei „Jetzt“
  nur als Symbol. `tool/release.sh` lässt jetzt auch die Bildschirmfoto-Tests laufen (fehlte – so rutschte das durch)

## 0.4.12-vorab.8 (24.09.2026)
- ✅ Reiterwechsel ohne Überlagerung: Die Überblendung ließ zwei Reiter halbdurchsichtig übereinander stehen (Reiter haben
  keinen eigenen Hintergrund). Jetzt „fade through“: der alte verschwindet sofort, der neue blendet ein und rückt leicht
  nach oben (`_FadeTabs`, Bildschirmfoto `reiterwechsel` mitten im Wechsel)

## 0.4.12-vorab.9 (24.09.2026)
- ✅ Übergänge sauberer: `FadeSwitch` ohne Überblendung (Platzhalter und Ergebnis lagen kurz übereinander) – der neue
  Zustand blendet ein und rückt leicht nach oben, wie beim Reiterwechsel. Zwischenhalte werden auf- und zugezogen
  (`AnimatedAlign` mit `heightFactor`, geklippt), statt erst zu verschwinden und dann Leere schrumpfen zu lassen

## 0.4.12-vorab.10 (24.09.2026)
- ✅ Verspätung in angezeigten Minuten (`delayMinutes` schneidet auf die Minute ab): 00:40:50 statt 00:40 ist pünktlich –
  vorher „+1“ und die gleiche Zeit durchgestrichen
- ✅ Fahrtverlauf-Kopf „00:40 – 00:48 · 8 min“ statt „ab <langer Name> 00:40 · an …“ (Ankunft war abgeschnitten)
- ✅ Jede Fahrtansicht heißt „fahrt“: Die Unterwegs-Leiste öffnet eine offene Fahrt nicht erneut
- ✅ Fußweg: sofort die zuletzt bekannte Position, dann der Positionsstrom (`ensureAllowed`, `lastKnown`); vorher bis zu
  12 s Warten auf einen frischen GPS-Fix
- ✅ Meldungen aus TRIAS als Klartext (`htmlToText` für Titel und Text; vorher „&auml;“, „<strong>“)
- ✅ Mehr → Rückmeldung: „Funktion vorschlagen“ und „Fehler melden“ (`FeedbackScreen`), Versand über FormSubmit an eine
  Kennung statt Adresse (`feedbackEndpoint`) – noch leer, bis die Kennung eingerichtet ist

## 0.4.12-vorab.11 (24.09.2026)
- ✅ Rückmeldeformular freigeschaltet: FormSubmit-Kennung eingetragen (statt Adresse), Test über die Kennung angenommen

## 0.4.13-vorab.1 (24.09.2026)
- ✅ Rückmeldung meldete „Senden hat nicht geklappt“, obwohl die Nachricht ankam: FormSubmit schickt JSON als
  `text/html`, die App erwartete JSON. Jetzt als Text gelesen und selbst ausgewertet (`feedbackAccepted`)
- ✅ Name und Zeichen dezent abgehoben: Logo 34, Wortmarke 30, darunter leise „Bus und Bahn in Echtzeit“

## 0.4.13-vorab.2 (24.09.2026)
- ✅ Zeichen neu gestaffelt: Die Fahrzeuge steigen nach rechts oben an, wie die kursive Wortmarke (Nutzerwunsch). Versatz
  je Fahrzeug halbiert (12/6/0 statt 0/12/24), weil die Schrägstellung ihn in diese Richtung verstärkt; Breite wie vorher,
  mittig. `logo.svg`, `logo-dark.svg`, `appicon.svg`, `icon/foreground.svg`; App-Symbol und Startbild neu erzeugt
  (Chrome headless, `flutter_launcher_icons`, `flutter_native_splash`)
- ✅ Kopf der Startseite: Wortmarke und Leitsatz genau so hoch wie das Logo (oben und unten bündig, gemessen)

## 0.4.13-vorab.3 (24.09.2026)
- ✅ Kopf: Wortmarke 35 und Leitsatz 13,5 näher zusammen (Abstand 13 → 8), weiter oben und unten bündig mit dem Logo (44)
- ✅ **Anschlussüberwachung** während der Begleitung (`_watch` in `state/companion.dart`): alle 15 s der nächste
  bevorstehende Umstieg (`upcomingMissed`, gesicherte Anschlüsse ausgenommen) und Ausfälle. Bei einem Problem sucht die
  App im Hintergrund eine Alternative (höchstens alle 2 min), ab dem nächsten Halt im Fahrzeug, der Umsteigehaltestelle
  bzw. vor dem Einsteigen ab dem Standort (`alternativeStart`, auch die Alternativen-Seite). Einmal je Problem ein
  Hinweis mit Ton („Anschluss in X nicht erreichbar – Alternative: 604 um 18:42 ab …“), Tipp öffnet die Alternativen;
  die laufende Benachrichtigung nennt sie ebenfalls. Wählt man eine Alternative, begleitet die App sie weiter
- ✅ **Begleitung übersteht das Schließen der App:** Die Flutter-Engine hängt nicht mehr am Fenster
  (`MainActivity.provideFlutterEngine` + `FlutterEngineCache`, `shouldDestroyEngineWithHost = false`) und läuft weiter,
  solange der Vordergrunddienst den Prozess hält. Beendet Android die App ganz, setzt sie beim nächsten Start fort
  (Einstellung `unterwegs`)

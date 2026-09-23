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
- ☐ Live-Abfahrten direkt an Favoriten, gelernte Gewohnheiten

## Verbindungen
- ✅ Liste mit Zeitleisten-Balken, Echtzeit farbig, „nur Fahrplan“
- ✅ Suchprofile als Chips (Alle = drei Profile parallel, zusammengeführt), Profil an/aus je Suche
- ✅ Etiketten „schnellste“, „ohne Umstieg“, „wenigste Umstiege“
- ✅ Früher und Später
- ✅ Zeitraster wie in Öffi, Umschalter Liste/Zeitraster, Wahl dauerhaft gespeichert
- ✅ Anschlussprüfung: sicher/knapp/nicht erreichbar, nicht erreichbare ausgegraut am Ende mit Hinweis
- ☐ Endloses Scrollen statt Knöpfen

## Fahren
- ✅ Fahrtverlauf: Plan/Ist, Steig und Steigwechsel, Zwischenhalte einklappbar, entfällt/Umleitung
- ✅ Passierte Halte grau, aktuelle Position mit Fahrzeugsymbol
- ✅ Anschlussprüfung je Umstieg im Verlauf
- ✅ Abweichungs-Banner mit „Alternativen anzeigen“; Alternativen-Screen (nächste Fahrt derselben Linie, schneller/gleich schnell, etwas später, Zeitdifferenz)
- ✅ Losfahren → Unterwegs-Modus: nächster Schritt groß, laufende Benachrichtigung (Linie und Ziel, wo aussteigen, in min + Uhrzeit, Fortschritt mit Fahrzeugsymbol, „Beenden“), Vordergrunddienst
- ✅ Weg zum Steig: Karte (OSM/FOSSGIS), Standort, Ziel-Steig aus der EFA, andere Steige grau, Richtung und Entfernung, „Loslaufen in n min“, Übergabe an Karten-App
- ◐ SEV violett in Abfahrten; eigene SEV-Halte-Darstellung mit Meldungstext am Halt fehlt
- ☐ Abbiegehinweise (Stufe 2), Kompass, Tap auf Linie zeigt ganzen Linienverlauf

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

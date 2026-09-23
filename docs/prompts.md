# Startanleitung und Prompts

## So fängst du an

1. Entpacke den Ordner, zum Beispiel nach `C:\Projekte\gleichda`.
2. Terminal in diesem Ordner öffnen, dann:
   ```
   git init
   git add .
   git commit -m "Konzept und Gestaltungsvorgaben"
   claude
   ```
3. Erste Eingabe in Claude Code:
   ```
   Lies CLAUDE.md, docs/konzept.md und docs/design.md vollständig
   und fasse in zehn Sätzen zusammen, was wir bauen. Frage nach,
   wo etwas widersprüchlich ist. Schreibe noch keinen Code.
   ```
   Wenn die Zusammenfassung passt, geht es mit Schritt 1 weiter.

Nach jedem Schritt: `flutter analyze`, App starten, ansehen, committen.
Erst dann den nächsten Prompt. Ein Schritt pro Sitzung ist völlig in Ordnung.

Der Klick-Prototyp mit allen Ansichten liegt auf der Design-Leinwand:
https://claude.ai/artifact/2F8acd9UzXAB53dQxJoaK8 – öffne ihn nebenher und
vergleiche jeden gebauten Screen damit.

## Schritt 1 – Gerüst und Theme

```
Lege ein Flutter-Projekt "gleichda" im aktuellen Ordner an
(Bundle-ID de.gleichda.app, Android und iOS).
Baue aus docs/design.md das Theme: eine Datei lib/ui/theme.dart mit
AppColors für hell und dunkel, exakt den dort genannten Hex-Werten,
den Textstilen mit tabularFigures für alle Zahlen, den Abständen und
Radien als Konstanten. ThemeMode folgt dem System.
Dazu ein Demo-Screen, der alle Farben und Textstile zeigt, damit ich
hell und dunkel vergleichen kann.
```

## Schritt 2 – Datenmodell

```
Baue die Modelle aus dem Abschnitt "Datenmodell" in docs/konzept.md:
Location, Departure, Trip, Leg, StopTime, Message, Subscription, Alarm,
SavedPlace. Mit freezed und json_serializable, null-sicher, jedes Feld
für Echtzeitqualität (geplant / Echtzeit / geschätzt) explizit.
Dazu Drift-Tabellen für Verlauf, Favoriten, Abos, gespeicherte Orte,
zuletzt angesehene Fahrt und den Haltestellen-Cache.
```

## Schritt 3 – TransitProvider und TriasProvider

```
Definiere die abstrakte Klasse TransitProvider mit searchLocations,
departures, planTrip, refreshTrip und messages – nur eigene Modelle,
keine Protokolltypen in der Signatur.
Implementiere TriasProvider nach VDV 431 gegen den VRR-Zugang:
LocationInformationRequest, StopEventRequest, TripRequest, TripInfoRequest.
TRIAS ist XML, also sauberer Request-Aufbau und ein eigener Parser.
Schreibe Tests gegen aufgezeichnete Antworten in test/fixtures/.
Zeig mir zuerst die Signaturen, bevor du die Implementierung schreibst.
```

Wenn das steht, einmal live prüfen und dabei die offene Frage klären:

```
Schreibe ein kleines Dart-Skript in tool/, das "Wuppertal Hauptbahnhof"
sucht, die nächsten Abfahrten holt und die Rohantworten nach
test/fixtures/ speichert – einmal über TRIAS, einmal über die EFA
(openservice-test.vrr.de/static02/, outputFormat=rapidJSON,
useRealtime=1). Vergleiche, welche Angaben zu Verspätung, Umleitung
und Haltausfall jede Seite liefert, und schreib das Ergebnis in
docs/konzept.md unter "Offene Entscheidungen".
```

Erst danach entscheidet sich, ob und wofür der `EfaProvider` gebraucht
wird. Er kommt als zweiter Adapter dazu, nicht als Ersatz.

## Schritt 4 – Startbildschirm

```
Baue den Startbildschirm nach docs/konzept.md, Abschnitt
"Startbildschirm, Suche, Verlauf und Favoriten":
oben das Logo klein, darunter das Suchfeld, dann die Karte
"Zuletzt angesehene Fahrt", dann Favoriten und Verlauf.
Halte dich exakt an docs/design.md. Die Karte oben ist noch mit
Beispieldaten gefüllt, aber in der endgültigen Größe.
Achte auf: nichts springt, Platz für "+3" reserviert, Namen
einzeilig gekürzt, gleich breite Ziffern.
```

## Schritt 5 – Die zentrale Funktion

```
Verdrahte "Zuletzt angesehene Fahrt": Beim Öffnen einer Fahrt werden
Linie, stopID, tripCode, Datum und Zeit in Drift gespeichert.
Beim Start der App wird die gespeicherte Fahrt sofort aus dem Cache
angezeigt und parallel per XML_TRIPSTOPTIMES_REQUEST aktualisiert.
Schlägt das fehl, wird eine normale Suche nach Linie und Zeiten als
Rückfall verwendet. Der Zeitstempel der letzten Aktualisierung ist
sichtbar. Liegt keine Echtzeit vor, steht dort "nur Fahrplan".
```

## Danach

In dieser Reihenfolge weiter, jeweils mit Verweis auf den passenden
Abschnitt in `docs/konzept.md`:

6. Suche mit Eingabe, Standortbezug und Sortierung gleichnamiger Haltestellen
7. Suchoptionen und Zeitwahl (Abfahrt/Ankunft)
8. Verbindungsliste, Umschalter Liste / Zeitraster, Auswahl wird gemerkt
9. Fahrtdetail mit Fahrtverlauf nach Öffi-Vorbild
10. Abweichungen, Ausfälle, Alternativen, Anschlussprüfung
11. Abfahrten in der Nähe
12. Meldungen und Linienabos (zunächst lokal)
13. Weg zum Steig und SEV
14. Unterwegs-Modus, Live Activity und Benachrichtigung
15. Fahrtenwecker und Meine Orte
16. Mehr-Bereich, Profil, Datenschutzangaben
17. Serverloser Push-Dienst

## APK bauen

```
flutter build apk --release
```
Die Datei liegt danach unter
`build/app/outputs/flutter-apk/app-release.apk`.
Zum Testen auf dem eigenen Gerät reicht das; für Google Play wird ein
signiertes App Bundle gebraucht:
```
flutter build appbundle --release
```

## Wenn der Kontext voll wird

Claude Code verliert nichts, was in Dateien steht. Deshalb: neue
Erkenntnisse und Entscheidungen immer in `docs/konzept.md` oder
`CLAUDE.md` nachtragen lassen, dann `/clear` und mit dem nächsten
Prompt weitermachen.

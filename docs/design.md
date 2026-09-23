# Gestaltungsvorgaben Gleichda

Diese Datei ist die verbindliche Umsetzung des Abschnitts „Gestaltung“ aus
`konzept.md`. Alle Werte stammen aus dem Klick-Prototypen und sind exakt so zu
übernehmen. Abweichungen nur, wenn ein Wert hier fehlt.

## 1. Farben

Es gibt genau zwei Themes. Jede Farbe hat eine Bedeutung; es gibt keine rein
dekorativen Farbflächen, keine Verläufe, keine Schatten.

### Hell

| Rolle | Wert | Verwendung |
|---|---|---|
| bg | `#F4F5F6` | Seitenhintergrund |
| surface | `#FFFFFF` | Karten, Listengruppen, Leisten |
| ink | `#111418` | Haupttext, Zeiten |
| ink2 | `#3D434B` | Sekundärtext in Listen |
| muted | `#5F6670` | Labels, Hinweise, inaktive Tabs |
| hair | `#E4E6E9` | Trennlinien (1 px) |
| fill | `#E9EBEE` | Eingabefelder, Chips, Platzhalter |
| accent | `#0B6E66` | Aktionen, aktiver Tab, Logo-Grund |
| onAccent | `#FFFFFF` | Text auf accent |
| green | `#1A7F3C` | pünktlich |
| orange | `#B25400` | verspätet, Umleitung |
| red | `#C0272D` | Ausfall |
| bus | `#9B1B43` | Linienfarbe Bus (WSW) |
| schwebe | `#0A5CB0` | Linienfarbe Schwebebahn |
| bar | `#FFFFFF` | Kopf- und Tableiste |
| indicator | `#D3EAE7` | Material-Pille unter aktivem Tab (Android) |

### Dunkel

| Rolle | Wert |
|---|---|
| bg | `#0E1012` |
| surface | `#181B1F` |
| ink | `#ECEEF0` |
| ink2 | `#C3C8CE` |
| muted | `#9AA1A9` |
| hair | `#272B30` |
| fill | `#22262B` |
| accent | `#49B7AA` |
| onAccent | `#06201D` |
| green | `#5CC27F` |
| orange | `#F0A451` |
| red | `#F2766F` |
| bus | `#A8214D` |
| schwebe | `#1767C2` |
| bar | `#131619` |
| indicator | `#1F3B38` |

Weitere feste Werte: Bernstein `#E8A94F` (Scheinwerfer im Logo, Live-Punkt),
Violett für SEV `#6D4AA8` hell / `#A78BDA` dunkel, Benachrichtigungs-Karte im
Dunkeln `#16191C`.

Das Theme folgt automatisch der Systemeinstellung und ist zusätzlich manuell
umschaltbar (Hell / Dunkel / System) unter „Mehr → Erscheinungsbild“.

## 2. Schrift

- Systemschrift, nie eine Webschrift im Fließtext:
  iOS `-apple-system / SF Pro`, Android `Roboto`.
- Größen: 28 px Bildschirmtitel · 17 px Listenzeile (iOS) bzw. 16 px (Android)
  · 15 px Sekundärzeile · 13 px Label · 11 px Tableiste.
- Gewichte: 600 für Zeiten, Titel und Liniennummern, 400 für alles andere.
  Kein Kursiv außer im Wortmarke-Schriftzug.
- Überschriften in normaler Schreibweise, nicht in Versalien.
- **Alle Zeiten und Zahlen mit gleich breiten Ziffern**
  (`fontFeatures: [FontFeature.tabularFigures()]`). Ohne Ausnahme.

## 3. Maße

- Bildschirmbreite im Entwurf 390 px, Höhe 844 px.
- Seitenrand 16 px, alle Screens gleich.
- Abstände in Vielfachen von 4: 4 · 8 · 12 · 16 · 24.
- Eckenradius: 12 px Karten und Gruppen, 10 px Eingabefelder und Chips,
  8 px Linienplaketten, 22 px Logo-Kachel.
- Trennlinie 1 px in `hair`, eingerückt bis zur Textkante, nie unter dem
  letzten Element einer Gruppe.
- Mindest-Tapfläche 44 px.
- Oberer Innenabstand: iOS 58 px, Android 44 px (Status- und Gestenleiste).

## 4. Nichts springt, nichts bricht merkwürdig um

Dies ist die wichtigste Regel des Projekts; sie hat Vorrang vor jeder
Layout-Idee.

- Für Verspätungen wie `+3` ist immer Platz reserviert, auch wenn keine
  Verspätung vorliegt. Beim Eintreffen der Echtzeit darf sich nichts
  verschieben.
- Haltestellen- und Zielnamen einzeilig mit `…` kürzen, nie umbrechen.
- Fließtext ohne Silbentrennung; keine Zeile mit einem einzelnen Wort.
- Ladezustände sind Platzhalterblöcke in exakt der späteren Größe und
  Position, kein Spinner mitten im Inhalt.
- Listen haben feste Zeilenhöhen; nachgeladene Echtzeit ändert nur Text und
  Farbe, nie die Höhe.

## 5. Bewegung

- Screenwechsel: horizontales Schieben, 250 ms, `easeOutCubic`.
- Geänderte Zeiten blenden am selben Platz über (150 ms), sie springen nicht.
- Live-Punkt pulsiert sanft (2 s Zyklus).
- Ist „Bewegung reduzieren“ aktiv, entfallen alle Animationen; Wechsel ohne
  Übergang.

## 6. iPhone und Android

Gleiche Screens, gleiche Anzahl, gleiche Inhalte, gleiches Design.
Unterschiede ausschließlich dort, wo das System sie vorgibt:

| | iOS | Android |
|---|---|---|
| Schrift | San Francisco | Roboto |
| Zurück | `‹` mit Zielbezeichnung | Pfeil links |
| Untere Navigation | Tableiste mit Symbol + Label | Material-NavigationBar mit Pille in `indicator` |
| Ränder oben | 58 px | 44 px |
| Unterwegs-Anzeige | Live Activity / Dynamic Island | dauerhafte Benachrichtigung |

## 7. Logo und Fahrzeugsymbole

- Wortmarke: **Gleichda**. Schrift vorläufig Rubik fett kursiv
  (Alternativen Nunito kursiv, Outfit geneigt) – nur für Wortmarke und
  Startbild, nie im Fließtext.
- Bildmarke: Zug, Straßenbahn und Bus, um 10° nach vorn geneigt, hintereinander
  gestaffelt mit einem Versatz von 12 px horizontal und 17 px vertikal je
  Fahrzeug. **Der Bus steht vorne** und ist voll deckend, Straßenbahn 0,75,
  Zug 0,5. Zentriert mit gleichen Randabständen.
- Farben: weiß auf Petrol `#0B6E66`, Scheinwerfer des Busses in Bernstein
  `#E8A94F`. Im Dunkelmodus `#49B7AA` auf `#1C2024`.
- In kleinen Größen (Favicon, Benachrichtigung) nur der Bus.
- Im App-Inneren erscheint das Logo nur auf Startbild und Startseite.
- Fertige Dateien: `assets/logo.svg`, `assets/logo-dark.svg`,
  `assets/appicon.svg`.

Die Fahrzeugsymbole in `assets/glyphs/` (Bus, Tram, U-Bahn, Zug, Schwebebahn,
Fähre) sind dieselbe Formensprache, gescherte Seitenansicht, `currentColor`.
Sie werden verwendet als Fortschrittsmarke in der Unterwegs-Benachrichtigung –
der Punkt auf dem Balken ist das Fahrzeug der laufenden Fahrt – und dürfen
zusätzlich in Verbindungsliste und Fahrtverlauf eingesetzt werden.

## 8. Inhalt der Unterwegs-Benachrichtigung

Nur vier Angaben, nichts sonst:

1. Linienplakette und Fahrtziel klein in der Kopfzeile,
2. **Wo aussteigen** (fett, eine Zeile),
3. **Wann**: Minuten und Uhrzeit,
4. Fortschrittsbalken, dessen Marke das Fahrzeugsymbol ist.

Auf Android zusätzlich eine einzige Aktion „Beenden“. Stimmt etwas nicht, wird
die Zeitangabe orange bzw. rot eingefärbt und **nur dann** eine fünfte Zeile
mit dem Grund ergänzt.

## 9. Was nicht vorkommt

Verläufe, Schlagschatten, Glas-Effekte, bunte Icon-Kacheln, Emoji als Symbol,
abgerundete Riesenbuttons, Versalien-Überschriften, mehr als eine Akzentfarbe,
Schmuckillustrationen, Text auf Bildern, animierte Ladebalken.

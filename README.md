# Gleich.da

Bus und Bahn in Echtzeit – Verbindungen, Abfahrten, Meldungen und Begleitung unterwegs.
Im VRR mit den Daten der VRR-Auskunft, deutschlandweit über Transitous.

**Installieren:** die APK aus dem [neuesten Release](https://github.com/macpano/gleich.da/releases/latest)
herunterladen und öffnen. Danach aktualisiert sich Gleich.da selbst: Neue Versionen lädt die App
im Hintergrund und bietet sie zum Installieren an.

**Lizenz:** Gleich.da ist freie Software unter der GNU General Public License v3.0, siehe [LICENSE](LICENSE).

## Aufbau

- `lib/` – die App (Flutter): `data/` Datenquellen, `domain/` Fachlogik, `state/` Zustand, `ui/` Oberfläche
- `docs/konzept.md` – Anforderungen, Bildschirm für Bildschirm
- `docs/design.md` – Farben, Maße, Schrift, Layoutregeln
- `docs/abgleich.md` – was umgesetzt ist, je Version
- `assets/` – Logo, App-Symbol und Fahrzeugsymbole als SVG
- `test/`, `test_screens/` – Tests und Bildschirmfotos (`flutter test test_screens --update-goldens`)

## Daten

Fahrplandaten: VRR (TRIAS, EFA), DELFI e. V. · deutschlandweit [Transitous](https://transitous.org/sources/) ·
Karte © OpenStreetMap-Mitwirkende, OpenMapTiles, OpenFreeMap. Alle Angaben ohne Gewähr.

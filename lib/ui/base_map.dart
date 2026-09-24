import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;

import 'screens/walk_screen.dart' show tileUrl;

/// Kartengrund aller Karten: Vektorkarte von OpenFreeMap (OpenStreetMap-Daten,
/// frei, ohne Schlüssel). Anders als Rasterkacheln bleibt die Beschriftung
/// beim Drehen der Karte aufrecht – die Karte kann sich nach der Blickrichtung
/// ausrichten (Nutzerwunsch 24.09.2026).
///
/// Lädt der Stil nicht (offline ohne Zwischenspeicher), bleiben die
/// Rasterkacheln von FOSSGIS als Rückfall.
class BaseMapLayer extends StatefulWidget {
  const BaseMapLayer({super.key});

  static const _styleUri = 'https://tiles.openfreemap.org/styles/liberty';

  /// Nachtkarte aus dem hellen Stil: Helligkeit umkehren und den Farbton
  /// zurückdrehen, leicht angehoben. Fluss bleibt blau, Hauptstraßen gelb,
  /// Grün grün, Beschriftung hell auf dunkel. Der eigene dunkle Stil von
  /// OpenFreeMap war zu dunkel und zeigte kaum mehr als Straßennamen
  /// (Nutzerbefund 24.09.2026).
  static const _night = ColorFilter.matrix(<double>[
    0.4592, -1.1440, -0.1152, 0, 244, //
    -0.3408, -0.3440, -0.1152, 0, 244,
    -0.3408, -1.1440, 0.6848, 0, 244,
    0, 0, 0, 1, 0,
  ]);

  /// Ein Stil für die ganze App – nicht je Karte neu laden.
  static final _styles = <String, Future<vt.Style>>{};

  static Future<vt.Style> _style(String uri) {
    final f = _styles[uri] ??= vt.StyleReader(
      uri: uri,
      headers: const {'User-Agent': 'Gleich.da (+https://github.com/macpano/gleich.da)'},
    ).read();
    // Gescheitert: beim nächsten Öffnen erneut versuchen.
    f.then((_) {}, onError: (Object _) {
      _styles.remove(uri);
    });
    return f;
  }

  @override
  State<BaseMapLayer> createState() => _BaseMapLayerState();
}

class _BaseMapLayerState extends State<BaseMapLayer> {
  vt.Style? _loaded;
  bool _failed = false;
  String? _uri;

  void _load(String uri) {
    if (uri == _uri) return;
    _uri = uri;
    BaseMapLayer._style(uri).then((s) {
      if (mounted && _uri == uri) setState(() => _loaded = s);
    }, onError: (Object _) {
      if (mounted && _uri == uri) setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    _load(BaseMapLayer._styleUri);
    final s = _loaded;
    if (s == null) {
      // Bis der Stil da ist: nichts (Kartenhintergrund); scheitert er, Raster.
      return _failed
          // FOSSGIS liefert bis Stufe 19; darüber werden diese Kacheln vergrößert.
          ? TileLayer(urlTemplate: tileUrl, userAgentPackageName: 'de.gleichda.app', maxNativeZoom: 19, maxZoom: mapMaxZoom)
          : const SizedBox.shrink();
    }
    final layer = vt.VectorTileLayer(
      theme: _withoutTransit(s.theme),
      tileProviders: s.providers,
      rasterSources: s.rasterSources,
      sprites: s.sprites,
    );
    return dark ? ColorFiltered(colorFilter: BaseMapLayer._night, child: layer) : layer;
  }
}

/// Ohne die Haltestellen-Symbole des Kartenstils (Ebene „poi_transit“): Die
/// App zeichnet Haltestellen und Steige selbst – sonst stünden sie doppelt da,
/// und in der Navigation sollen nur die wichtigen zu sehen sein.
final _trimmed = Expando<vt.Theme>();
vt.Theme _withoutTransit(vt.Theme t) => _trimmed[t] ??=
    vt.Theme(id: '${t.id}-ohne-oepnv', layers: t.layers.where((l) => l.id != 'poi_transit').toList());

/// Größte Zoomstufe aller Karten. Die Kartendaten reichen bis Stufe 14, alles
/// darüber wird hochgerechnet; ohne Grenze wurde die Karte beim Hineinzoomen
/// irgendwann weiß (Nutzerbefund 24.09.2026). 19 reicht bis auf Gehwegbreite.
const mapMaxZoom = 19.0;

/// Namensnennung für den Kartengrund (Bedingung von OpenFreeMap und ODbL).
const mapAttribution = '© OpenStreetMap-Mitwirkende · OpenMapTiles · OpenFreeMap';

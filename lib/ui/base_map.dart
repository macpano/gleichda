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

  static const _light = 'https://tiles.openfreemap.org/styles/liberty';
  static const _dark = 'https://tiles.openfreemap.org/styles/dark';

  /// Ein Stil je Hell/Dunkel für die ganze App – nicht je Karte neu laden.
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
    _load(dark ? BaseMapLayer._dark : BaseMapLayer._light);
    final s = _loaded;
    if (s == null) {
      // Bis der Stil da ist: nichts (Kartenhintergrund); scheitert er, Raster.
      return _failed
          ? TileLayer(urlTemplate: tileUrl, userAgentPackageName: 'de.gleichda.app', maxZoom: 19)
          : const SizedBox.shrink();
    }
    return vt.VectorTileLayer(
      theme: _withoutTransit(s.theme),
      tileProviders: s.providers,
      rasterSources: s.rasterSources,
      sprites: s.sprites,
    );
  }
}

/// Ohne die Haltestellen-Symbole des Kartenstils (Ebene „poi_transit“): Die
/// App zeichnet Haltestellen und Steige selbst – sonst stünden sie doppelt da,
/// und in der Navigation sollen nur die wichtigen zu sehen sein.
final _trimmed = Expando<vt.Theme>();
vt.Theme _withoutTransit(vt.Theme t) => _trimmed[t] ??=
    vt.Theme(id: '${t.id}-ohne-oepnv', layers: t.layers.where((l) => l.id != 'poi_transit').toList());

/// Namensnennung für den Kartengrund (Bedingung von OpenFreeMap und ODbL).
const mapAttribution = '© OpenStreetMap-Mitwirkende · OpenMapTiles · OpenFreeMap';

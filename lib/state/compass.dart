import 'package:flutter/services.dart';

/// Blickrichtung des Handys in Grad (0 = Norden, im Uhrzeigersinn), aus dem
/// Drehvektor-Sensor (`MainActivity`). Ohne Sensor ein Strom ohne Werte – die
/// Karte bleibt dann genordet.
Stream<double> compassHeadings() => compassSource();

/// Quelle der Kompasswerte; Tests setzen sie auf einen leeren Strom.
Stream<double> Function() compassSource = () => const EventChannel('de.gleichda/compass')
    .receiveBroadcastStream()
    .map((e) => (e as num).toDouble())
    .handleError((Object _) {});

/// Gleitender Mittelwert über den Kreis (359° und 1° ergeben 0°, nicht 180°).
double smoothHeading(double previous, double next, {double factor = 0.25}) {
  final d = ((next - previous + 540) % 360) - 180;
  return (previous + d * factor + 360) % 360;
}

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/models.dart';
import 'widgets.dart';

/// Zeichnet den Fortschrittsbalken der Unterwegs-Benachrichtigung als Bild:
/// Balken bis zum Ausstieg, die Marke ist das Fahrzeug der laufenden Fahrt,
/// am Ende die Zielmarke.
Future<Uint8List> renderProgressBar({
  required double progress,
  required TransportMode? mode,
  required Color color,
  required Color track,
  double width = 720,
  double height = 120,
}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec, Rect.fromLTWH(0, 0, width, height));
  const pad = 24.0;
  final y = height * 0.62;
  final left = pad + 40, right = width - pad - 14;
  final x = left + (right - left) * progress.clamp(0.0, 1.0);
  final bar = Paint()
    ..strokeWidth = 10
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(left, y), Offset(right, y), bar..color = track);
  canvas.drawLine(Offset(left, y), Offset(x, y), bar..color = color);
  // Zielmarke
  canvas.drawCircle(Offset(right, y), 14, Paint()..color = color);
  canvas.drawCircle(Offset(right, y), 6, Paint()..color = track);
  // Fahrzeug
  final info = await vg.loadPicture(
    SvgAssetLoader(VehicleGlyph.assetFor(mode), theme: SvgTheme(currentColor: color)),
    null,
  );
  const gw = 84.0;
  final scale = gw / info.size.width;
  canvas.save();
  canvas.translate(x - gw * 0.7, y - info.size.height * scale - 4);
  canvas.scale(scale);
  canvas.drawPicture(info.picture);
  canvas.restore();
  info.picture.dispose();
  final img = await rec.endRecording().toImage(width.round(), height.round());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

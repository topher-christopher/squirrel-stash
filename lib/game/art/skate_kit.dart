import 'dart:ui';

import 'asset_manifest.dart';
import 'paint_kit.dart';

/// The colony's skateboard (custom deck PNG drop-in:
/// `assets/images/outfitter/custom_skate_deck.png`). Shared by the
/// Outfitter half-pipe, the terraces and the Metro platform.
abstract final class SkateKit {
  static void board(Canvas c, Offset at, StashAssetManifest art) {
    final deck = art.outfitter('custom_skate_deck');
    if (deck != null) {
      c.drawImageRect(deck, Rect.fromLTWH(0, 0, deck.width.toDouble(), deck.height.toDouble()),
          Rect.fromCenter(center: at, width: 24, height: 6), Paint()..filterQuality = FilterQuality.medium);
    } else {
      c.drawRRect(Kit.rr(Rect.fromCenter(center: at, width: 22, height: 3), 1.5), Kit.fill(const Color(0xFF7C3AED)));
      c.drawLine(at.translate(-9, -1), at.translate(9, -1), Kit.stroke(const Color(0xFFF472B6), 0.8));
      c.drawPath(Path()
        ..moveTo(at.dx + 10, at.dy - 1.5)
        ..quadraticBezierTo(at.dx + 13, at.dy - 2, at.dx + 13, at.dy - 4), Kit.stroke(const Color(0xFF7C3AED), 1.6));
    }
    for (final dx in const [-7.0, 7.0]) {
      c.drawCircle(at.translate(dx, 3), 2, Kit.fill(const Color(0xFF22D3EE)));
    }
  }
}

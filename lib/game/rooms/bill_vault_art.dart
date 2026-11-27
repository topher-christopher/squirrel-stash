import 'dart:ui';

import '../art/paint_kit.dart';
import '../diorama_snapshot.dart';
import 'room_kit.dart';
import 'waterline_scenes.dart';

/// Expanded "Above Water" Hollow Log Bill Vault: a full-width log chamber
/// whose waterline follows unpaid bills ÷ Free Cash — a brook and lawn
/// chairs when bills are small, a walnut skiff in the middle, a scuba diver
/// and a hapless raft angler when the water's high. (The Etch A Sketch
/// due-date countdown lives in the drawer now.) Local units 302 × 150.
class BillVaultArt extends RoomArt {
  const BillVaultArt();

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    RoomKit.shell(c, x, wall: const Color(0xFF2E2416));
    final r = x.r;
    // Log rings on the back wall
    for (final (center, n) in [(Offset(r.left + 40, r.top + 34), 5), (Offset(r.right - 70, r.top + 26), 4)]) {
      for (var k = 1; k <= n; k++) {
        c.drawCircle(center, k * 5.5, Kit.stroke(const Color(0x22FDE68A), 1.1));
      }
    }
    // Waterline gauge on the right wall: brass marks at 25% and 50%
    final gauge = Rect.fromLTWH(r.right - 12, r.top + 18, 5, x.floorY - r.top - 20);
    c.drawRRect(Kit.rr(gauge, 2), Kit.fill(const Color(0xFF3B2410)));
    for (final f in const [0.25, 0.5, 0.75]) {
      final y = gauge.bottom - gauge.height * f;
      c.drawLine(Offset(gauge.left - 2, y), Offset(gauge.right + 1, y), Kit.stroke(const Color(0xFFFBBF24), 1.2));
    }
    // Strongbox in the corner
    RoomKit.crate(c, Rect.fromLTWH(r.right - 52, x.floorY - 22, 30, 22), color: const Color(0xFF57534E));
    c.drawCircle(Offset(r.right - 37, x.floorY - 11), 3.6, Kit.stroke(const Color(0xFFFBBF24), 1.3));
    if (x.level >= 2) {
      // Rope coil and a lifebuoy ring
      c.drawCircle(Offset(r.left + 120, r.top + 26), 8, Kit.stroke(const Color(0xFFF8FAFC), 4));
      for (var k = 0; k < 4; k++) {
        c.drawArc(Rect.fromCircle(center: Offset(r.left + 120, r.top + 26), radius: 8), k * 1.57 + 0.4, 0.6, false,
            Kit.stroke(const Color(0xFFDC2626), 4));
      }
    }
    if (x.level >= 3) {
      // Brass portholes and a lighthouse lamp
      for (final dx in const [170.0, 214.0]) {
        final p = Offset(r.left + dx, r.top + 30);
        c.drawCircle(p, 9, Kit.fill(const Color(0xFF0C4A6E)));
        c.drawCircle(p.translate(-3, -3), 2.4, Kit.fill(const Color(0x66FFFFFF)));
        c.drawCircle(p, 9, Kit.stroke(const Color(0xFFFBBF24), 2.4));
      }
      RoomKit.shelf(c, r.left + 60, r.left + 96, r.top + 40);
    }
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final r = x.r;
    if (x.level >= 3) RoomKit.lamp(c, Offset(r.left + 78, r.top + 20), x.t, color: const Color(0xFFFEF9C3));
    c.save();
    c.clipRRect(Kit.rr(r.deflate(2), 16));
    switch (x.snap.waterScene) {
      case WaterScene.low:
        Waterline.low(c, x);
      case WaterScene.mid:
        Waterline.mid(c, x);
      case WaterScene.high:
        Waterline.high(c, x);
    }
    c.restore();
  }
}

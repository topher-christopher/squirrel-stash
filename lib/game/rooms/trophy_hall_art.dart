import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import 'room_kit.dart';

/// Trophy Hall: a lantern-lit museum where earned trophies fill the shelves,
/// overflow into boxes underneath, and goal statues stand in a glass case.
class TrophyHallArt extends RoomArt {
  const TrophyHallArt();

  static const _perShelf = 6;
  static const _shelves = 3;

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    RoomKit.shell(c, x, wall: const Color(0xFF2E1A10));
    c.save();
    c.translate(x.r.left, x.r.top);
    final floor = x.r.height - 16;
    // Wall shelves on both sides of the display case
    final count = x.snap.trophyCount;
    var placed = 0;
    for (var s = 0; s < _shelves; s++) {
      final y = 40.0 + s * 30;
      for (final side in const [(10.0, 112.0), (188.0, 290.0)]) {
        RoomKit.shelf(c, side.$1, side.$2, y);
        for (var k = 0; k < _perShelf; k++) {
          if (placed >= count) break;
          _trophy(c, Offset(side.$1 + 10 + k * 16.0, y), placed);
          placed++;
        }
      }
    }
    // Overflow boxes stacked under the shelves
    final overflow = math.min(8, math.max(0, count - placed));
    for (var b = 0; b < overflow; b++) {
      final col = b % 4, row = b ~/ 4;
      final left = b.isEven ? 14.0 + col * 12 : 198.0 + col * 12;
      RoomKit.crate(c, Rect.fromLTWH(left, floor - 12 - row * 12, 14, 12),
          color: const Color(0xFF92400E));
    }
    _displayCase(c, Rect.fromLTWH(122, 22, 56, floor - 22), x.snap.statueCount, x.level);
    if (x.level >= 2) RoomKit.rug(c, Offset(150, floor + 7), 60, const Color(0xFF7F1D1D));
    c.restore();
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final r = x.r;
    RoomKit.lamp(c, Offset(r.left + 60, r.top + 12), x.t);
    RoomKit.lamp(c, Offset(r.right - 60, r.top + 12), x.t);
    // Case glint sweeping across the glass
    final s = (x.t * 0.3) % 1.6;
    if (s < 1) {
      final gx = r.left + 122 + s * 56;
      c.drawLine(Offset(gx, r.top + 26), Offset(gx - 8, r.bottom - 22),
          Kit.stroke(const Color(0x55FFFFFF), 2.2));
    }
    // Curator squirrel dusting the shelves, pacing left ↔ right
    final pace = Ease.pingPong(x.t / 6);
    final px = r.left + 30 + pace * 240;
    final dir = (x.t / 6) % 2 < 1 ? 1.0 : -1.0;
    final skipCase = px > r.left + 112 && px < r.left + 190;
    SquirrelPainter.paint(c, Offset(px, x.floorY - 14 - (skipCase ? 0 : 0)),
        dir: dir, scale: 0.95, time: x.t, seed: 3.7,
        look: SquirrelLook(prop: SquirrelProp.duster, scarf: x.frost,
            hat: x.snap.outfits ? SquirrelHat.visor : SquirrelHat.none),
        art: x.art);
    if (x.level >= 3 || x.detail > 0.05) {
      final a = x.level >= 3 ? 1.0 : x.detail;
      c.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, a));
      for (var k = 0; k < 4; k++) {
        final ph = (x.t * 0.5 + k * 0.27) % 1.0;
        Kit.sparkle(c, Offset(r.left + 130 + k * 12, r.top + 40 + math.sin(k * 2.0) * 20),
            2.4 * math.sin(ph * math.pi), const Color(0xFFFFF7AE));
      }
      c.restore();
    }
  }

  static void _trophy(Canvas c, Offset shelfTop, int i) {
    final o = shelfTop;
    switch (i % 3) {
      case 0: // cup
        c.drawPath(Path()..moveTo(o.dx - 4, o.dy - 12)..lineTo(o.dx + 4, o.dy - 12)
          ..quadraticBezierTo(o.dx + 4, o.dy - 5, o.dx, o.dy - 5)
          ..quadraticBezierTo(o.dx - 4, o.dy - 5, o.dx - 4, o.dy - 12)..close(), Kit.fill(const Color(0xFFFACC15)));
        c.drawRect(Rect.fromLTWH(o.dx - 1, o.dy - 5, 2, 3), Kit.fill(const Color(0xFFD97706)));
        c.drawRect(Rect.fromLTWH(o.dx - 3.5, o.dy - 2, 7, 2), Kit.fill(const Color(0xFF78350F)));
      case 1: // shield
        c.drawPath(Path()..moveTo(o.dx - 4.5, o.dy - 13)..lineTo(o.dx + 4.5, o.dy - 13)
          ..lineTo(o.dx + 4.5, o.dy - 7)..quadraticBezierTo(o.dx, o.dy - 1, o.dx - 4.5, o.dy - 7)..close(),
            Kit.fill(const Color(0xFF94A3B8)));
        c.drawLine(Offset(o.dx, o.dy - 12), Offset(o.dx, o.dy - 3), Kit.stroke(const Color(0xFFDC2626), 1.2));
      default: // medal plaque
        c.drawRRect(Kit.rr(Rect.fromLTWH(o.dx - 4.5, o.dy - 12, 9, 12), 1.5), Kit.fill(const Color(0xFF92400E)));
        c.drawCircle(Offset(o.dx, o.dy - 6), 2.8, Kit.fill(const Color(0xFFFB923C)));
    }
  }

  static void _displayCase(Canvas c, Rect b, int statues, int level) {
    Kit.glow(c, b.center, 46, const Color(0xFFFDE68A), level >= 2 ? 0.22 : 0.12);
    c.drawRRect(Kit.rr(Rect.fromLTWH(b.left - 3, b.bottom - 10, b.width + 6, 10), 2), Kit.fill(const Color(0xFF6B3D1E)));
    final glass = Rect.fromLTRB(b.left, b.top, b.right, b.bottom - 10);
    c.drawRRect(Kit.rr(glass, 3), Kit.fill(const Color(0x33BAE6FD)));
    c.drawRRect(Kit.rr(glass, 3), Kit.stroke(const Color(0xFFFBBF24), 1.4));
    for (var tier = 0; tier < 2; tier++) {
      final y = glass.top + 34 + tier * 36;
      c.drawLine(Offset(glass.left + 2, y), Offset(glass.right - 2, y), Kit.stroke(const Color(0x88FDE68A), 1));
    }
    final shown = math.min(4, statues);
    for (var k = 0; k < shown; k++) {
      final y = glass.top + 34 + (k ~/ 2) * 36;
      final x = glass.left + 16 + (k % 2) * 24;
      _statue(c, Offset(x, y));
    }
  }

  static void _statue(Canvas c, Offset base) {
    c.drawRect(Rect.fromLTWH(base.dx - 6, base.dy - 4, 12, 4), Kit.fill(const Color(0xFF78350F)));
    c.drawOval(Kit.oval(base.translate(0, -10), 4.5, 6), Kit.fill(const Color(0xFFFACC15)));
    c.drawCircle(base.translate(0.5, -18), 3.6, Kit.fill(const Color(0xFFFACC15)));
    c.drawPath(Path()..moveTo(base.dx - 4, base.dy - 8)..quadraticBezierTo(base.dx - 10, base.dy - 14, base.dx - 6, base.dy - 20),
        Kit.stroke(const Color(0xFFEAB308), 2.4));
  }
}

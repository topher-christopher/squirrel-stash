import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import 'room_kit.dart';

/// Ratatouille-style Squirrel Kitchen: a cast-iron stove, bubbling pots,
/// hanging herbs, grocery crates and chef squirrels at work.
class KitchenArt extends RoomArt {
  const KitchenArt();

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    RoomKit.shell(c, x, wall: const Color(0xFF3B2412));
    c.save();
    c.translate(x.r.left, x.r.top);
    final floor = x.r.height - 16;
    // Checkered tile backsplash
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 10; col++) {
        if ((row + col).isEven) {
          c.drawRect(Rect.fromLTWH(86 + col * 12.0, 46 + row * 10.0, 12, 10), Kit.fill(const Color(0x22FEF3C7)));
        }
      }
    }
    // Stove
    final stove = Rect.fromLTWH(96, floor - 42, 92, 42);
    c.drawRRect(Kit.rr(stove, 4), Kit.fill(const Color(0xFF292524)));
    c.drawRRect(Kit.rr(Rect.fromLTWH(stove.left + 10, stove.top + 14, 72, 22), 3), Kit.fill(const Color(0xFF1C1917)));
    c.drawRRect(Kit.rr(Rect.fromLTWH(stove.left + 10, stove.top + 14, 72, 22), 3), Kit.stroke(const Color(0xFF78716C), 1));
    for (var k = 0; k < 4; k++) {
      c.drawCircle(Offset(stove.left + 16 + k * 20.0, stove.top + 7), 2.2, Kit.fill(const Color(0xFFB45309)));
    }
    // Hood
    c.drawPath(Path()..moveTo(104, 34)..lineTo(180, 34)..lineTo(170, 18)..lineTo(114, 18)..close(),
        Kit.fill(const Color(0xFF57534E)));
    // Hanging herbs & garlic
    c.drawLine(const Offset(14, 14), const Offset(80, 14), Kit.stroke(const Color(0xFF6B3D1E), 1.6));
    for (var k = 0; k < 4; k++) {
      final hx = 22.0 + k * 16;
      c.drawLine(Offset(hx, 14), Offset(hx, 24), Kit.stroke(const Color(0xFF6B3D1E), 0.8));
      if (k.isEven) {
        for (var l = 0; l < 4; l++) {
          c.drawOval(Kit.oval(Offset(hx - 3 + l * 2.0, 28 + (l % 2) * 3.0), 2, 4), Kit.fill(const Color(0xFF4D7C0F)));
        }
      } else {
        c.drawCircle(Offset(hx, 28), 4, Kit.fill(const Color(0xFFFEF3C7)));
        c.drawLine(Offset(hx, 24), Offset(hx, 32), Kit.stroke(const Color(0x55451A03), 0.6));
      }
    }
    // Grocery crates (veg pops out)
    RoomKit.crate(c, Rect.fromLTWH(12, floor - 16, 26, 16));
    RoomKit.crate(c, Rect.fromLTWH(40, floor - 14, 22, 14), color: const Color(0xFF854D0E));
    for (final (dx, color) in const [(18.0, Color(0xFFF97316)), (26.0, Color(0xFFDC2626)), (32.0, Color(0xFF65A30D)), (48.0, Color(0xFFFACC15))]) {
      c.drawCircle(Offset(dx, floor - 18), 3.2, Kit.fill(color));
    }
    // Prep counter
    c.drawRRect(Kit.rr(Rect.fromLTWH(206, floor - 26, 80, 26), 2), Kit.fill(const Color(0xFF8B5A2B)));
    c.drawRect(Rect.fromLTWH(204, floor - 28, 84, 4), Kit.fill(const Color(0xFFD6D3D1)));
    if (x.level >= 2) {
      RoomKit.shelf(c, 206, 286, 40);
      for (var k = 0; k < 5; k++) {
        final jar = Rect.fromLTWH(212 + k * 14.0, 28, 9, 12);
        c.drawRRect(Kit.rr(jar, 2), Kit.fill(const [Color(0xFFF59E0B), Color(0xFFDC2626), Color(0xFF65A30D), Color(0xFFFDE68A), Color(0xFF7C2D12)][k]));
        c.drawRect(Rect.fromLTWH(jar.left - 0.5, jar.top - 2, 10, 2.4), Kit.fill(const Color(0xFF78350F)));
      }
      // Cutting board with a carrot
      c.drawRRect(Kit.rr(Rect.fromLTWH(222, floor - 33, 30, 5), 1.5), Kit.fill(const Color(0xFFD97706)));
      c.drawPath(Path()..moveTo(228, floor - 34)..lineTo(246, floor - 31)..lineTo(228, floor - 30)..close(),
          Kit.fill(const Color(0xFFF97316)));
    }
    if (x.level >= 3) {
      // Copper pans on the wall
      for (var k = 0; k < 3; k++) {
        c.drawCircle(Offset(230 + k * 18.0, 16), 6, Kit.fill(const Color(0xFFC2410C)));
        c.drawCircle(Offset(230 + k * 18.0, 16), 4, Kit.stroke(const Color(0xFFFB923C), 0.8));
      }
    }
    c.restore();
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final r = x.r;
    final floor = x.floorY;
    final stoveTop = floor - 42;
    // Pots with lids rattling & steam
    for (var k = 0; k < (x.level >= 2 ? 2 : 1); k++) {
      final px = r.left + 120 + k * 40;
      final rattle = math.sin(x.t * 9 + k) * 0.8;
      c.drawRRect(Kit.rr(Rect.fromLTWH(px - 11, stoveTop - 14, 22, 14), 3), Kit.fill(const Color(0xFF475569)));
      c.drawRRect(Kit.rr(Rect.fromLTWH(px - 12, stoveTop - 17 + rattle, 24, 4), 2), Kit.fill(const Color(0xFF64748B)));
      Kit.glow(c, Offset(px, stoveTop), 14, const Color(0xFFF97316), 0.3);
      for (var w = 0; w < 2; w++) {
        RoomKit.wisp(c, Offset(px - 4 + w * 8, stoveTop - 20), x.t * 0.5 + w * 0.5 + k * 0.3, height: 18);
      }
    }
    // Head chef stirring at the stove
    SquirrelPainter.paint(c, Offset(r.left + 106, floor - 14),
        scale: 1.0, time: x.t, seed: 1.3,
        look: SquirrelLook(hat: SquirrelHat.chef, prop: SquirrelProp.ladle, scarf: x.frost),
        art: x.art);
    // Sous-chef chopping at the counter
    SquirrelPainter.paint(c, Offset(r.left + 262, floor - 14 - math.sin(x.t * 8).abs() * 0.8),
        dir: -1, scale: 0.92, time: x.t, seed: 4.4,
        look: SquirrelLook(hat: SquirrelHat.chef, scarf: x.frost), art: x.art);
    if (x.detail > 0.05 || x.level >= 3) {
      // Taste-tester hopping in with a veggie (fades in when zoomed)
      final a = x.level >= 3 ? 1.0 : x.detail;
      c.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, a));
      final hop = Ease.pingPong(x.t / 4);
      SquirrelPainter.paint(c, Offset(r.left + 40 + hop * 30, floor - 14 - math.sin(x.t * 6).abs() * 2),
          dir: (x.t / 4) % 2 < 1 ? 1 : -1, scale: 0.8, time: x.t, seed: 8.1,
          look: const SquirrelLook(acorn: true), art: x.art);
      c.restore();
    }
  }
}

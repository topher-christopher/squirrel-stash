import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import 'holiday_tree.dart';
import 'room_kit.dart';

/// Ratatouille Squirrel Kitchen (cozy dining & holiday hearth): a cast-iron
/// stove with bubbling pots, the Brass Thumbpin Dining Table on the Vintage
/// Button Rug, and the Treehouse Christmas Tree. Room-local units
/// (300 × 150, floor at 134).
class KitchenArt extends RoomArt {
  const KitchenArt();

  static const _floor = 134.0;
  static const _table = 168.0;
  static const _tree = Offset(262, _floor);

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    RoomKit.shell(c, x, wall: const Color(0xFF3B2412));
    c.save();
    c.translate(x.r.left, x.r.top);
    // Checkered backsplash, stove and hood
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 7; col++) {
        if ((row + col).isEven) {
          c.drawRect(Rect.fromLTWH(12 + col * 11.0, 46 + row * 10.0, 11, 10), Kit.fill(const Color(0x22FEF3C7)));
        }
      }
    }
    final stove = Rect.fromLTWH(10, _floor - 42, 82, 42);
    c.drawRRect(Kit.rr(stove, 4), Kit.fill(const Color(0xFF292524)));
    c.drawRRect(Kit.rr(Rect.fromLTWH(stove.left + 8, stove.top + 14, 66, 22), 3), Kit.fill(const Color(0xFF1C1917)));
    c.drawRRect(Kit.rr(Rect.fromLTWH(stove.left + 8, stove.top + 14, 66, 22), 3), Kit.stroke(const Color(0xFF78716C), 1));
    for (var k = 0; k < 4; k++) {
      c.drawCircle(Offset(stove.left + 14 + k * 18.0, stove.top + 7), 2.2, Kit.fill(const Color(0xFFB45309)));
    }
    c.drawPath(Path()..moveTo(18, 34)..lineTo(84, 34)..lineTo(74, 18)..lineTo(28, 18)..close(), Kit.fill(const Color(0xFF57534E)));
    // Hanging herbs & garlic
    c.drawLine(const Offset(98, 14), const Offset(150, 14), Kit.stroke(const Color(0xFF6B3D1E), 1.6));
    for (var k = 0; k < 4; k++) {
      final hx = 104.0 + k * 13;
      c.drawLine(Offset(hx, 14), Offset(hx, 23), Kit.stroke(const Color(0xFF6B3D1E), 0.8));
      if (k.isEven) {
        for (var l = 0; l < 4; l++) {
          c.drawOval(Kit.oval(Offset(hx - 3 + l * 2.0, 27 + (l % 2) * 3.0), 2, 4), Kit.fill(const Color(0xFF4D7C0F)));
        }
      } else {
        c.drawCircle(Offset(hx, 27), 4, Kit.fill(const Color(0xFFFEF3C7)));
      }
    }
    if (x.level >= 2) {
      RoomKit.shelf(c, 98, 150, 44);
      for (var k = 0; k < 4; k++) {
        final jar = Rect.fromLTWH(102 + k * 12.0, 32, 8, 12);
        c.drawRRect(Kit.rr(jar, 2), Kit.fill(const [Color(0xFFF59E0B), Color(0xFFDC2626), Color(0xFF65A30D), Color(0xFFFDE68A)][k]));
        c.drawRect(Rect.fromLTWH(jar.left - 0.5, jar.top - 2, 9, 2.4), Kit.fill(const Color(0xFF78350F)));
      }
      RoomKit.crate(c, const Rect.fromLTWH(96, _floor - 16, 24, 16));
      for (final (dx, color) in const [(101.0, Color(0xFFF97316)), (108.0, Color(0xFFDC2626)), (115.0, Color(0xFF65A30D))]) {
        c.drawCircle(Offset(dx, _floor - 18), 3, Kit.fill(color));
      }
    }
    if (x.level >= 3) {
      for (var k = 0; k < 3; k++) {
        c.drawCircle(Offset(176 + k * 17.0, 18), 6, Kit.fill(const Color(0xFFC2410C)));
        c.drawCircle(Offset(176 + k * 17.0, 18), 4, Kit.stroke(const Color(0xFFFB923C), 0.8));
      }
      // Pine garland swagged across the ceiling
      final g = Path()..moveTo(96, 6)..quadraticBezierTo(190, 26, 292, 6);
      c.drawPath(g, Kit.stroke(const Color(0xFF166534), 4));
      c.drawPath(g, Kit.stroke(const Color(0xFF15803D), 2));
    }
    _rugAndTable(c);
    HolidayTree.body(c, _tree, x.level, snowy: x.snap.winter);
    c.restore();
  }

  /// Vintage Button Rug, Brass Thumbpin Dining Table and thread-spool stools.
  static void _rugAndTable(Canvas c) {
    const center = Offset(_table, _floor + 6);
    c.drawOval(Kit.oval(center, 50, 7.5), Kit.fill(const Color(0xFFB91C1C)));
    c.drawOval(Kit.oval(center, 42, 5.8), Kit.stroke(const Color(0x66000000), 1));
    for (final dx in const [-9.0, 9.0]) {
      for (final dy in const [-1.6, 1.6]) {
        c.drawOval(Kit.oval(center.translate(dx, dy), 3, 1), Kit.fill(const Color(0xFF7F1D1D)));
      }
    }
    for (final sx in const [_table - 32, _table + 32]) {
      final spool = Rect.fromLTWH(sx - 7, _floor - 14, 14, 14);
      c.drawRect(Rect.fromLTWH(spool.left + 2, spool.top + 2, 10, 10), Kit.fill(const Color(0xFF2563EB)));
      for (var k = 0; k < 4; k++) {
        c.drawLine(Offset(spool.left + 2, spool.top + 3.5 + k * 2.4), Offset(spool.right - 2, spool.top + 3.5 + k * 2.4),
            Kit.stroke(const Color(0x5593C5FD), 0.6));
      }
      c.drawRect(Rect.fromLTWH(spool.left, spool.top, 14, 2.4), Kit.fill(const Color(0xFFD6B48A)));
      c.drawRect(Rect.fromLTWH(spool.left, spool.bottom - 2.4, 14, 2.4), Kit.fill(const Color(0xFFD6B48A)));
    }
    // The pin (point side DOWN) and the domed brass head as the tabletop
    c.drawPath(Path()
      ..moveTo(_table - 2, _floor - 20)
      ..lineTo(_table + 2, _floor - 20)
      ..lineTo(_table, _floor)
      ..close(), Kit.fill(const Color(0xFFCBD5E1)));
    const top = Offset(_table, _floor - 22);
    c.drawOval(Kit.oval(top.translate(0, 2), 25, 4.5), Kit.fill(const Color(0xFF92400E)));
    c.drawOval(Kit.oval(top, 25, 4.5), Kit.linear(top.translate(-25, 0), top.translate(25, 0),
        const [Color(0xFFB45309), Color(0xFFFDE68A), Color(0xFFD97706)]));
    c.drawOval(Kit.oval(top.translate(-6, -1), 7, 1.2), Kit.fill(const Color(0x66FFFFFF)));
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final o = x.r.topLeft;
    final stoveTop = o.dy + _floor - 42;
    for (var k = 0; k < (x.level >= 2 ? 2 : 1); k++) {
      final px = o.dx + 34 + k * 34;
      final rattle = math.sin(x.t * 9 + k) * 0.8;
      c.drawRRect(Kit.rr(Rect.fromLTWH(px - 11, stoveTop - 14, 22, 14), 3), Kit.fill(const Color(0xFF475569)));
      c.drawRRect(Kit.rr(Rect.fromLTWH(px - 12, stoveTop - 17 + rattle, 24, 4), 2), Kit.fill(const Color(0xFF64748B)));
      Kit.glow(c, Offset(px, stoveTop), 14, const Color(0xFFF97316), 0.3);
      for (var w = 0; w < 2; w++) {
        RoomKit.wisp(c, Offset(px - 4 + w * 8, stoveTop - 20), x.t * 0.5 + w * 0.5 + k * 0.3, height: 18);
      }
    }
    if (x.level >= 3) {
      // Bulbs on the ceiling garland
      for (var k = 0; k < 9; k++) {
        final u = (k + 0.5) / 9;
        final p = Offset(o.dx + 96 + u * 196, o.dy + 6 + math.sin(u * math.pi) * 10 + 4);
        final on = x.lit && (0.5 + 0.5 * math.sin(x.t * 2.4 + k)) > 0.3;
        if (on) Kit.glow(c, p, 6, const Color(0xFFFDE68A), 0.4);
        c.drawCircle(p, 1.5, Kit.fill(on ? const Color(0xFFFDE68A) : const Color(0xFF57534E)));
      }
    }
    // Head chef stirring at the stove
    SquirrelPainter.paint(c, Offset(o.dx + 52, o.dy + _floor - 14), scale: 1.0, time: x.t, seed: 1.3,
        look: SquirrelLook(hat: SquirrelHat.chef, prop: SquirrelProp.ladle, scarf: x.frost), art: x.art);
    // Diners on the spool stools, sipping acorn tea
    for (var k = 0; k < (x.level >= 2 ? 2 : 1); k++) {
      final sx = o.dx + _table + (k == 0 ? -32 : 32);
      SquirrelPainter.paint(c, Offset(sx, o.dy + _floor - 28), dir: k == 0 ? 1 : -1, scale: 0.78, time: x.t, seed: 4.4 + k,
          pose: SquirrelPose.tea, look: SquirrelLook(scarf: x.frost), art: x.art);
    }
    if (x.level >= 3 || x.detail > 0.05) {
      // A sous-chef ferrying a pie from the stove to the table
      final a = x.level >= 3 ? 1.0 : x.detail;
      c.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, a));
      final u = Ease.easeInOut(Ease.pingPong(x.work / 6));
      final toTable = (x.work / 6) % 2 < 1;
      final px = o.dx + 80 + u * 60;
      SquirrelPainter.paint(c, Offset(px, o.dy + _floor - 14 - math.sin(x.work * 7).abs()), dir: toTable ? 1 : -1,
          scale: 0.82, time: x.t, seed: 8.1, look: SquirrelLook(hat: SquirrelHat.chef, scarf: x.frost), art: x.art);
      if (toTable) {
        final pie = Offset(px + 8, o.dy + _floor - 18);
        c.drawOval(Kit.oval(pie, 5, 2), Kit.fill(const Color(0xFFD97706)));
        c.drawOval(Kit.oval(pie.translate(0, -1), 4, 1.2), Kit.fill(const Color(0xFFFDBA74)));
      }
      c.restore();
    }
    HolidayTree.live(c, o + _tree, x);
  }
}

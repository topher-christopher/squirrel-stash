import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/squirrel_painter.dart';
import 'room_kit.dart';

/// The Treehouse Christmas Tree in the Ratatouille Kitchen: a pine sprig in
/// a walnut-shell pot. While the Hearth burns, squirrels string twinkling
/// lights and hang glass-bead ornaments; in the dark it stands unlit.
abstract final class HolidayTree {
  static double height(int level) => switch (level) { >= 3 => 92.0, 2 => 72.0, _ => 56.0 };

  static double _halfWidth(double h, double u) => h * 0.36 * (1 - u) + 2;

  /// Pot, pine tiers and (at Max) presents. [base] is the pot's floor point.
  static void body(Canvas c, Offset base, int level, {required bool snowy}) {
    final h = height(level);
    final pot = Path()
      ..moveTo(base.dx - 13, base.dy - 12)
      ..quadraticBezierTo(base.dx - 12, base.dy, base.dx, base.dy)
      ..quadraticBezierTo(base.dx + 12, base.dy, base.dx + 13, base.dy - 12)
      ..close();
    c.drawPath(pot, Kit.fill(const Color(0xFF7C4A22)));
    for (final dx in const [-6.0, 0.0, 6.0]) {
      c.drawLine(Offset(base.dx + dx, base.dy - 11), Offset(base.dx + dx * 0.7, base.dy - 1), Kit.stroke(const Color(0x55000000), 0.8));
    }
    c.drawRect(Rect.fromLTWH(base.dx - 2, base.dy - 16, 4, 5), Kit.fill(const Color(0xFF5C3419)));
    final top = base.dy - 14 - h;
    for (var tier = 0; tier < 3; tier++) {
      final y0 = base.dy - 14 - tier * h * 0.28;
      final y1 = tier == 2 ? top : y0 - h * 0.52;
      final w = _halfWidth(h, tier * 0.28);
      final p = Path()
        ..moveTo(base.dx - w, y0)
        ..quadraticBezierTo(base.dx - w * 0.2, y0 + 3, base.dx, y0 + 1)
        ..quadraticBezierTo(base.dx + w * 0.2, y0 + 3, base.dx + w, y0)
        ..lineTo(base.dx, y1)
        ..close();
      c.drawPath(p, Kit.vertical(Rect.fromLTRB(base.dx - w, y1, base.dx + w, y0), const [Color(0xFF15803D), Color(0xFF14532D)]));
      if (snowy) {
        c.drawPath(Path()..moveTo(base.dx - w * 0.9, y0)..lineTo(base.dx, y1 + 4)..lineTo(base.dx + w * 0.9, y0),
            Kit.stroke(const Color(0x99FFFFFF), 1.2));
      }
    }
    if (level >= 3) {
      for (final (dx, w, color) in const [(-20.0, 12.0, Color(0xFFDC2626)), (16.0, 10.0, Color(0xFF2563EB)), (-6.0, 9.0, Color(0xFFFACC15))]) {
        final box = Rect.fromLTWH(base.dx + dx - w / 2, base.dy - w * 0.8, w, w * 0.8);
        c.drawRect(box, Kit.fill(color));
        c.drawLine(box.topCenter, box.bottomCenter, Kit.stroke(const Color(0xFFFFFFFF), 1));
        c.drawLine(box.centerLeft, box.centerRight, Kit.stroke(const Color(0xFFFFFFFF), 1));
      }
    }
  }

  /// Lights, ornaments, the sequin star and the decorating crew.
  static void live(Canvas c, Offset base, RoomCtx x) {
    final h = height(x.level);
    final lit = x.lit;
    final foot = base.dy - 14;
    // Glass-bead ornaments (always hung)
    final rng = math.Random(3);
    const colors = [Color(0xFFF87171), Color(0xFFFDE047), Color(0xFF60A5FA), Color(0xFFF472B6), Color(0xFFC084FC)];
    final count = 5 + x.level * 2;
    for (var i = 0; i < count; i++) {
      final u = 0.08 + rng.nextDouble() * 0.78;
      final w = _halfWidth(h, u) * 0.75;
      final p = Offset(base.dx + (rng.nextDouble() * 2 - 1) * w, foot - u * h);
      c.drawCircle(p, 2.2, Kit.fill(colors[i % colors.length]));
      c.drawCircle(p.translate(-0.7, -0.7), 0.7, Kit.fill(const Color(0xCCFFFFFF)));
    }
    // Spiral string of lights (twinkles only while the Hearth burns)
    for (var i = 0; i < 22; i++) {
      final u = i / 22 * 0.9;
      final turn = u * math.pi * 5;
      if (math.cos(turn) < -0.2) continue;
      final p = Offset(base.dx + _halfWidth(h, u) * 0.92 * math.sin(turn), foot - u * h);
      final color = colors[i % colors.length];
      if (lit) {
        final tw = 0.5 + 0.5 * math.sin(x.t * 3 + i * 1.7);
        Kit.glow(c, p, 5 + tw * 2, color, 0.25 + tw * 0.25);
        c.drawCircle(p, 1.4, Kit.fill(color));
      } else {
        c.drawCircle(p, 1.2, Kit.fill(const Color(0xFF3F3F46)));
      }
    }
    // Sequin star
    final star = Offset(base.dx, foot - h - 2);
    if (lit) Kit.glow(c, star, 14, const Color(0xFFFDE047), 0.5 + 0.2 * math.sin(x.t * 2));
    Kit.sparkle(c, star, 5.5, lit ? const Color(0xFFFDE047) : const Color(0xFFA16207));
    _crew(c, base, h, x);
  }

  /// A decorator on a little ladder hanging a bead, and a helper circling
  /// the pot trailing a spare loop of lights.
  static void _crew(Canvas c, Offset base, double h, RoomCtx x) {
    final ladderX = base.dx - _halfWidth(h, 0.25) - 8;
    final ladderTop = base.dy - 34;
    for (final dx in const [-3.0, 3.0]) {
      c.drawLine(Offset(ladderX + dx, base.dy), Offset(ladderX + dx * 0.6, ladderTop), Kit.stroke(const Color(0xFF8B5A2B), 1.3));
    }
    for (var k = 1; k < 4; k++) {
      final y = base.dy - k * 8.0;
      c.drawLine(Offset(ladderX - 3, y), Offset(ladderX + 3, y), Kit.stroke(const Color(0xFF8B5A2B), 1));
    }
    final reach = x.lit ? (math.sin(x.work * 1.4) * 0.5 + 0.5) : 0.0;
    SquirrelPainter.paint(c, Offset(ladderX + 1, ladderTop - 10), scale: 0.66, time: x.t, seed: 6.6,
        look: SquirrelLook(scarf: x.frost), art: x.art);
    if (x.lit) {
      final bead = Offset(ladderX + 9 + reach * 6, ladderTop - 9 + reach * 2);
      c.drawCircle(bead, 2, Kit.fill(const Color(0xFF34D399)));
    }
    final u = Ease.pingPong(x.work / 7);
    final going = (x.work / 7) % 2 < 1;
    final hx = base.dx - 22 + u * 44;
    SquirrelPainter.paint(c, Offset(hx, base.dy - 10), dir: going ? 1 : -1, scale: 0.62, time: x.t, seed: 7.7,
        hop: -math.sin(x.work * 7).abs(), look: SquirrelLook(scarf: x.frost), art: x.art);
    if (x.lit) {
      final loop = Path()..moveTo(hx + (going ? -6 : 6), base.dy - 8);
      for (var k = 1; k <= 4; k++) {
        loop.lineTo(hx + (going ? -6 - k * 4.0 : 6 + k * 4.0), base.dy - 6 + (k.isEven ? 2 : 0));
      }
      c.drawPath(loop, Kit.stroke(const Color(0xFF166534), 0.8));
      for (var k = 1; k <= 4; k++) {
        final p = Offset(hx + (going ? -6 - k * 4.0 : 6 + k * 4.0), base.dy - 6 + (k.isEven ? 2 : 0));
        c.drawCircle(p, 1.1, Kit.fill(const [Color(0xFFFDE047), Color(0xFFF87171), Color(0xFF60A5FA), Color(0xFFF472B6)][k % 4]));
      }
    }
  }
}

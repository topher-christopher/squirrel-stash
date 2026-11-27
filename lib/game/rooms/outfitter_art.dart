import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import 'room_kit.dart';

/// Acorn Outfitter: a Borrower-scale workshop of repurposed human trinkets
/// plus the colony wardrobe. Drawn in room-local units (298 × 150).
class OutfitterArt extends RoomArt {
  const OutfitterArt();

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    RoomKit.shell(c, x, wall: const Color(0xFF3A2414));
    c.save();
    c.translate(x.r.left, x.r.top);
    final floor = x.r.height - 16;
    _cardWall(c, const Offset(96, 18));
    _filmBarrels(c, Offset(14, floor));
    _buttonRug(c, Offset(150, floor + 6));
    _boosterBench(c, Offset(70, floor));
    _wardrobe(c, const Offset(250, 22));
    if (x.level >= 2) {
      RoomKit.shelf(c, 150, 222, 46);
      _thimblePlanter(c, const Offset(166, 46));
      _thimblePlanter(c, const Offset(204, 46));
      _thumbtackTable(c, Offset(176, floor));
      _wheelOttoman(c, Offset(206, floor));
    }
    if (x.level >= 3) {
      _sneakerDaybed(c, Offset(228, floor));
      _pennyGong(c, const Offset(46, 20));
    }
    c.restore();
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final r = x.r;
    final floor = x.floorY;
    if (x.level >= 2) _bottlecapFire(c, Offset(r.left + 128, floor), x.t);
    if (x.level >= 2) RoomKit.lamp(c, Offset(r.left + 150, r.top + 14), x.t);
    // Tailor squirrel trying on goggles; a knight-helm squirrel admires the card wall.
    final hats = x.snap.outfits;
    SquirrelPainter.paint(c, Offset(r.left + 214 + math.sin(x.t * 0.6) * 10, floor - 14),
        dir: math.cos(x.t * 0.6) > 0 ? 1 : -1, scale: 0.95, time: x.t, seed: 2.2,
        hop: -math.sin(x.t * 3).abs() * 0.8,
        look: SquirrelLook(hat: hats ? SquirrelHat.goggles : SquirrelHat.none, scarf: x.frost),
        art: x.art);
    SquirrelPainter.paint(c, Offset(r.left + 118, floor - 14),
        dir: -1, scale: 0.9, time: x.t, seed: 5.1,
        look: SquirrelLook(hat: hats ? SquirrelHat.knight : SquirrelHat.none, scarf: x.frost),
        art: x.art);
    if (x.level >= 3) {
      SquirrelPainter.paint(c, Offset(r.left + 252, floor - 20), pose: SquirrelPose.sleep,
          scale: 0.8, time: x.t, seed: 7.3,
          look: SquirrelLook(hat: hats ? SquirrelHat.beanie : SquirrelHat.none), art: x.art);
    }
    if (x.detail > 0.05) {
      // Extra colony member browsing the barrels (fades in when zoomed).
      c.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, x.detail));
      SquirrelPainter.paint(c, Offset(r.left + 40 + math.sin(x.t * 0.8) * 6, floor - 14),
          scale: 0.82, time: x.t, seed: 9.9, pose: SquirrelPose.toss,
          look: SquirrelLook(hat: hats ? SquirrelHat.visor : SquirrelHat.none), art: x.art);
      c.restore();
    }
  }

  // ----------------------------------------------------------- trinkets
  static void _filmBarrels(Canvas c, Offset base) {
    for (final (dx, dy) in const [(0.0, 0.0), (16.0, 0.0), (8.0, -22.0)]) {
      final b = Rect.fromLTWH(base.dx + dx, base.dy + dy - 22, 14, 22);
      c.drawRRect(Kit.rr(b, 2), Kit.fill(const Color(0xFF1C1917)));
      c.drawRect(Rect.fromLTWH(b.left, b.top, b.width, 4), Kit.fill(const Color(0xFF94A3B8)));
      c.drawRect(Rect.fromLTWH(b.left + 2, b.top + 9, b.width - 4, 6), Kit.fill(const Color(0xFFFACC15)));
      c.drawOval(Kit.oval(Offset(b.center.dx, b.top + 1), 6, 1.6), Kit.fill(const Color(0xFFFDE68A)));
    }
  }

  static void _cardWall(Canvas c, Offset o) {
    final frame = Rect.fromLTWH(o.dx, o.dy, 40, 54);
    c.drawRRect(Kit.rr(frame.inflate(3), 2), Kit.fill(const Color(0xFF78350F)));
    c.drawRRect(Kit.rr(frame, 3), Kit.fill(const Color(0xFFFACC15)));
    final art = Rect.fromLTWH(o.dx + 4, o.dy + 8, 32, 22);
    c.drawRect(art, Kit.vertical(art, const [Color(0xFFF97316), Color(0xFFDC2626)]));
    c.drawCircle(art.center, 6, Kit.fill(const Color(0xFFFDE68A)));
    c.drawRect(Rect.fromLTWH(o.dx + 4, o.dy + 33, 32, 15), Kit.fill(const Color(0xFFFEF3C7)));
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(o.dx + 7, o.dy + 37 + i * 4.0), Offset(o.dx + 30, o.dy + 37 + i * 4.0),
          Kit.stroke(const Color(0x66451A03), 0.8));
    }
  }

  static void _boosterBench(Canvas c, Offset base) {
    final box = Rect.fromLTWH(base.dx, base.dy - 14, 48, 14);
    c.drawRRect(Kit.rr(box, 2), Kit.linear(box.centerLeft, box.centerRight,
        const [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)]));
    c.drawRRect(Kit.rr(box, 2), Kit.stroke(const Color(0xFF1E1B4B), 1));
    c.drawCircle(box.center, 3.4, Kit.fill(const Color(0xFFFFFFFF)));
    c.drawLine(box.center.translate(-3.4, 0), box.center.translate(3.4, 0), Kit.stroke(const Color(0xFFDC2626), 1));
  }

  static void _buttonRug(Canvas c, Offset center) {
    c.drawOval(Kit.oval(center, 46, 7), Kit.fill(const Color(0xFFB91C1C)));
    c.drawOval(Kit.oval(center, 38, 5.4), Kit.stroke(const Color(0x66000000), 1));
    for (final dx in const [-8.0, 8.0]) {
      c.drawOval(Kit.oval(center.translate(dx, -1.4), 3, 0.9), Kit.fill(const Color(0xFF7F1D1D)));
      c.drawOval(Kit.oval(center.translate(dx, 1.4), 3, 0.9), Kit.fill(const Color(0xFF7F1D1D)));
    }
  }

  static void _thumbtackTable(Canvas c, Offset base) {
    c.drawLine(base, base.translate(0, -14), Kit.stroke(const Color(0xFF94A3B8), 1.6));
    c.drawOval(Kit.oval(base.translate(0, -15), 13, 3.4), Kit.fill(const Color(0xFFD97706)));
    c.drawOval(Kit.oval(base.translate(0, -16), 11, 2.4), Kit.fill(const Color(0xFFFBBF24)));
  }

  static void _wheelOttoman(Canvas c, Offset base) {
    final w = Rect.fromCenter(center: base.translate(0, -5), width: 14, height: 10);
    c.drawRRect(Kit.rr(w, 4), Kit.fill(const Color(0xFF22D3EE)));
    c.drawOval(Kit.oval(w.center, 2.4, 3), Kit.fill(const Color(0xFF0E7490)));
  }

  static void _thimblePlanter(Canvas c, Offset shelf) {
    final t = Path()
      ..moveTo(shelf.dx - 6, shelf.dy)
      ..lineTo(shelf.dx - 4.5, shelf.dy - 10)
      ..quadraticBezierTo(shelf.dx, shelf.dy - 13, shelf.dx + 4.5, shelf.dy - 10)
      ..lineTo(shelf.dx + 6, shelf.dy)
      ..close();
    c.drawPath(t, Kit.fill(const Color(0xFFCBD5E1)));
    for (var k = 0; k < 4; k++) {
      c.drawCircle(Offset(shelf.dx - 4 + k * 2.6, shelf.dy - 7 + (k % 2) * 3.0), 0.7, Kit.fill(const Color(0xFF64748B)));
    }
    for (final dx in const [-3.0, 0.0, 3.0]) {
      c.drawCircle(Offset(shelf.dx + dx, shelf.dy - 13), 3, Kit.fill(const Color(0xFF4D7C0F)));
    }
  }

  static void _sneakerDaybed(Canvas c, Offset base) {
    final sole = Rect.fromLTWH(base.dx, base.dy - 5, 50, 5);
    c.drawRRect(Kit.rr(sole, 2.5), Kit.fill(const Color(0xFFF8FAFC)));
    final upper = Path()
      ..moveTo(base.dx + 2, base.dy - 5)
      ..quadraticBezierTo(base.dx + 4, base.dy - 18, base.dx + 18, base.dy - 18)
      ..lineTo(base.dx + 30, base.dy - 12)
      ..quadraticBezierTo(base.dx + 48, base.dy - 11, base.dx + 49, base.dy - 5)
      ..close();
    c.drawPath(upper, Kit.fill(const Color(0xFFEF4444)));
    c.drawPath(upper, Kit.stroke(const Color(0xFF7F1D1D), 1));
    for (var k = 0; k < 3; k++) {
      c.drawLine(Offset(base.dx + 20 + k * 4.0, base.dy - 15 + k), Offset(base.dx + 24 + k * 4.0, base.dy - 13 + k),
          Kit.stroke(const Color(0xFFFFFFFF), 0.9));
    }
  }

  static void _pennyGong(Canvas c, Offset o) {
    c.drawLine(o.translate(-12, -6), o.translate(-12, 22), Kit.stroke(const Color(0xFF6B3D1E), 2));
    c.drawLine(o.translate(12, -6), o.translate(12, 22), Kit.stroke(const Color(0xFF6B3D1E), 2));
    c.drawLine(o.translate(-14, -6), o.translate(14, -6), Kit.stroke(const Color(0xFF6B3D1E), 2.4));
    c.drawCircle(o.translate(0, 7), 9, Kit.fill(const Color(0xFFC2410C)));
    c.drawCircle(o.translate(0, 7), 6.5, Kit.stroke(const Color(0xFFFB923C), 0.9));
    c.drawCircle(o.translate(-2.4, 4.6), 1.6, Kit.fill(const Color(0x66FFFFFF)));
  }

  static void _wardrobe(Canvas c, Offset o) {
    c.drawLine(o.translate(-6, 0), o.translate(36, 0), Kit.stroke(const Color(0xFF92400E), 2));
    final hats = [SquirrelHat.knight, SquirrelHat.beanie, SquirrelHat.goggles, SquirrelHat.visor];
    for (var i = 0; i < hats.length; i++) {
      c.drawCircle(o.translate(i * 10.0, 0), 1.4, Kit.fill(const Color(0xFFFBBF24)));
      c.save();
      c.translate(o.dx + i * 10.0 - 1.5, o.dy + 14);
      c.scale(0.6);
      SquirrelOutfits.hat(c, hats[i]);
      c.restore();
    }
  }

  static void _bottlecapFire(Canvas c, Offset base, double t) {
    final cap = Rect.fromCenter(center: base.translate(0, -2), width: 18, height: 5);
    final flick = 0.85 + 0.15 * math.sin(t * 11);
    Kit.glow(c, base.translate(0, -10), 22, const Color(0xFFFB923C), 0.35 * flick);
    c.drawPath(
        Path()
          ..moveTo(base.dx, base.dy - 18 * flick)
          ..quadraticBezierTo(base.dx + 6, base.dy - 8, base.dx, base.dy - 4)
          ..quadraticBezierTo(base.dx - 6, base.dy - 8, base.dx, base.dy - 18 * flick)
          ..close(),
        Kit.fill(const Color(0xFFF97316)));
    c.drawPath(
        Path()
          ..moveTo(base.dx, base.dy - 12 * flick)
          ..quadraticBezierTo(base.dx + 3, base.dy - 7, base.dx, base.dy - 5)
          ..quadraticBezierTo(base.dx - 3, base.dy - 7, base.dx, base.dy - 12 * flick)
          ..close(),
        Kit.fill(const Color(0xFFFDE047)));
    c.drawRRect(Kit.rr(cap, 1.5), Kit.fill(const Color(0xFFDC2626)));
    for (var k = 0; k < 6; k++) {
      c.drawLine(Offset(cap.left + 1.5 + k * 3, cap.top), Offset(cap.left + 1.5 + k * 3, cap.bottom),
          Kit.stroke(const Color(0x66000000), 0.7));
    }
  }
}

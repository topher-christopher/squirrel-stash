import 'dart:math' as math;
import 'dart:ui';

import '../../models/room.dart';
import '../art/paint_kit.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import 'room_kit.dart';

/// The seven equal-sized deep-root vault pockets (126 × 92 each).
class PocketArt extends RoomArt {
  const PocketArt();

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    RoomKit.shell(c, x, earthy: true, wall: const Color(0xFF2A170B));
    // Root tendrils hugging the corners
    final r = x.r;
    final tendril = Kit.stroke(const Color(0xFF5A3418), 2.2);
    c.drawPath(Path()..moveTo(r.left + 4, r.top + 24)..quadraticBezierTo(r.left - 4, r.top + 4, r.left + 24, r.top - 2), tendril);
    c.drawPath(Path()..moveTo(r.right - 22, r.bottom + 2)..quadraticBezierTo(r.right + 4, r.bottom - 2, r.right - 2, r.bottom - 24), tendril);
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final o = x.r.topLeft;
    final f = x.floorY;
    final up = x.snap.pocketGains[x.room] ?? true;
    switch (x.room) {
      case RoomKey.brokerage:
        _brokerage(c, x, o, f, up);
      case RoomKey.pokemon:
        _pokemon(c, x, o, f);
      case RoomKey.crypto:
        _crypto(c, x, o, f, up);
      case RoomKey.espp:
        _espp(c, x, o, f);
      case RoomKey.hysa:
        _hysa(c, x, o, f);
      case RoomKey.retirement:
        _retirement(c, x, o, f);
      case RoomKey.silver:
        _silver(c, x, o, f);
      default:
        break;
    }
    if (x.level >= 2) RoomKit.lamp(c, Offset(x.r.right - 16, x.r.top + 10), x.t, size: 0.7);
    if (x.level >= 3) {
      // A little gold-coin stash glinting in the corner
      final base = Offset(x.r.left + 12, f + 2);
      for (var k = 0; k < 4; k++) {
        c.drawOval(Kit.oval(base.translate(0, -k * 2.2), 5, 1.6), Kit.fill(const Color(0xFFFACC15)));
        c.drawOval(Kit.oval(base.translate(0, -k * 2.2), 5, 1.6), Kit.stroke(const Color(0xFFB45309), 0.5));
      }
      final s = (x.t * 0.6 + x.r.left) % 1.0;
      Kit.sparkle(c, base.translate(4, -12), 2.4 * math.sin(s * math.pi), const Color(0xFFFFF7AE));
    }
  }

  static void _brokerage(Canvas c, RoomCtx x, Offset o, double f, bool up) {
    final board = Rect.fromLTWH(o.dx + 10, o.dy + 12, 66, 40);
    c.drawRRect(Kit.rr(board, 3), Kit.fill(const Color(0xFF0F172A)));
    c.drawRRect(Kit.rr(board, 3), Kit.stroke(const Color(0xFF78350F), 2));
    final line = Path()..moveTo(board.left + 4, board.bottom - 8);
    for (var k = 1; k <= 8; k++) {
      final wobble = math.sin(k * 1.7 + x.t * 0.6) * 4;
      final trend = up ? -k * 2.8 : k * 1.6 - 14;
      line.lineTo(board.left + 4 + k * 7, board.bottom - 10 + trend + wobble);
    }
    c.drawPath(line, Kit.stroke(up ? const Color(0xFF4ADE80) : const Color(0xFFF87171), 1.6));
    _resident(c, x, Offset(o.dx + 96, f - 14), SquirrelHat.visor, SquirrelProp.briefcase, 1.1);
  }

  static void _pokemon(Canvas c, RoomCtx x, Offset o, double f) {
    for (var k = 0; k < 3; k++) {
      final slab = Rect.fromLTWH(o.dx + 12 + k * 20.0, o.dy + 18 + (k % 2) * 6.0, 15, 24);
      c.drawRRect(Kit.rr(slab, 2), Kit.fill(const Color(0xCCE2E8F0)));
      c.drawRect(Rect.fromLTWH(slab.left + 2, slab.top + 2, 11, 4), Kit.fill(const Color(0xFFDC2626)));
      c.drawRRect(Kit.rr(Rect.fromLTWH(slab.left + 2, slab.top + 7, 11, 15), 1),
          Kit.fill(const [Color(0xFFF97316), Color(0xFF38BDF8), Color(0xFFFACC15)][k]));
      final s = (x.t * 0.35 + k * 0.3) % 1.4;
      if (s < 1) {
        final gx = slab.left + s * slab.width;
        c.drawLine(Offset(gx, slab.top + 7), Offset(gx - 4, slab.bottom - 2), Kit.stroke(const Color(0x88FFFFFF), 1.4));
      }
    }
    RoomKit.crate(c, Rect.fromLTWH(o.dx + 14, f - 14, 30, 14), color: const Color(0xFF7C3AED));
    _resident(c, x, Offset(o.dx + 98, f - 14), SquirrelHat.goggles, SquirrelProp.none, 2.3);
  }

  static void _crypto(Canvas c, RoomCtx x, Offset o, double f, bool up) {
    final pulse = 0.5 + 0.5 * math.sin(x.t * 1.4);
    final glow = up ? const Color(0xFFA78BFA) : const Color(0xFF60A5FA);
    Kit.glow(c, Offset(o.dx + 44, f - 18), 32, glow, 0.25 + pulse * 0.2);
    for (final (dx, h, color) in const [(24.0, 30.0, Color(0xFF8B5CF6)), (40.0, 42.0, Color(0xFFC4B5FD)), (56.0, 26.0, Color(0xFF6366F1))]) {
      c.drawPath(Path()..addPolygon([Offset(o.dx + dx - 7, f), Offset(o.dx + dx, f - h), Offset(o.dx + dx + 7, f)], true),
          Kit.fill(color));
      c.drawLine(Offset(o.dx + dx - 1, f - h + 6), Offset(o.dx + dx - 3, f - 6), Kit.stroke(const Color(0x88FFFFFF), 1));
    }
    // A floating coin
    final bob = math.sin(x.t * 2) * 3;
    c.drawCircle(Offset(o.dx + 84, o.dy + 26 + bob), 7, Kit.fill(const Color(0xFFF59E0B)));
    c.drawCircle(Offset(o.dx + 84, o.dy + 26 + bob), 5, Kit.stroke(const Color(0xFFFDE68A), 1));
    _resident(c, x, Offset(o.dx + 100, f - 14), SquirrelHat.goggles, SquirrelProp.pickaxe, 3.1, dir: -1);
  }

  static void _espp(Canvas c, RoomCtx x, Offset o, double f) {
    // Company badge on a lanyard + a payroll jar filling toward the quarterly buy
    final badge = Rect.fromLTWH(o.dx + 16, o.dy + 18, 26, 32);
    c.drawLine(Offset(badge.center.dx - 8, o.dy + 6), Offset(badge.center.dx, badge.top), Kit.stroke(const Color(0xFF2563EB), 1.4));
    c.drawLine(Offset(badge.center.dx + 8, o.dy + 6), Offset(badge.center.dx, badge.top), Kit.stroke(const Color(0xFF2563EB), 1.4));
    c.drawRRect(Kit.rr(badge, 3), Kit.fill(const Color(0xFFF8FAFC)));
    c.drawRect(Rect.fromLTWH(badge.left, badge.top, badge.width, 8), Kit.fill(const Color(0xFF1D4ED8)));
    c.drawCircle(badge.center.translate(0, 4), 5, Kit.fill(const Color(0xFFFDE68A)));
    final jar = Rect.fromLTWH(o.dx + 52, f - 26, 20, 26);
    final fill = 0.35 + 0.25 * (0.5 + 0.5 * math.sin(x.t * 0.2));
    c.drawRRect(Kit.rr(jar, 4), Kit.fill(const Color(0x55BAE6FD)));
    c.drawRect(Rect.fromLTRB(jar.left + 2, jar.bottom - jar.height * fill, jar.right - 2, jar.bottom - 2), Kit.fill(const Color(0xFF4ADE80)));
    c.drawRRect(Kit.rr(jar, 4), Kit.stroke(const Color(0xFF64748B), 1));
    _resident(c, x, Offset(o.dx + 98, f - 14), SquirrelHat.none, SquirrelProp.briefcase, 4.4, suit: true, dir: -1);
  }

  static void _hysa(Canvas c, RoomCtx x, Offset o, double f) {
    // Glass honey-jar savings with coins dropping in monthly
    final jar = Rect.fromLTWH(o.dx + 16, f - 40, 34, 40);
    c.drawRRect(Kit.rr(jar, 8), Kit.fill(const Color(0x44FDE68A)));
    c.drawRRect(Kit.rr(Rect.fromLTRB(jar.left + 3, jar.top + 14, jar.right - 3, jar.bottom - 3), 6), Kit.fill(const Color(0xFFF59E0B)));
    c.drawRRect(Kit.rr(jar, 8), Kit.stroke(const Color(0xFF92400E), 1.4));
    c.drawRRect(Kit.rr(Rect.fromLTWH(jar.left - 2, jar.top - 4, jar.width + 4, 6), 2), Kit.fill(const Color(0xFF92400E)));
    final drop = (x.t * 0.4) % 1.0;
    c.drawCircle(Offset(jar.center.dx, o.dy + 8 + drop * 30), 3.2 * (1 - drop * 0.3), Kit.fill(const Color(0xFFFACC15)));
    _resident(c, x, Offset(o.dx + 90, f - 14), SquirrelHat.beanie, SquirrelProp.none, 5.5, acorn: true);
  }

  static void _retirement(Canvas c, RoomCtx x, Offset o, double f) {
    final pile = Offset(o.dx + 62, f - 4);
    c.drawOval(Kit.oval(pile, 34, 9), Kit.fill(const Color(0xFFD97706)));
    final rng = math.Random(5);
    for (var k = 0; k < 11; k++) {
      final p = pile.translate(-26 + rng.nextDouble() * 52, -5 + rng.nextDouble() * 7);
      c.drawCircle(p, 3, Kit.fill(const Color(0xFFFACC15)));
      c.drawCircle(p.translate(-0.8, -0.8), 0.9, Kit.fill(const Color(0xAAFFFFFF)));
    }
    // Sleeping Golden Elder with a tiny crown
    SquirrelPainter.paint(c, pile.translate(0, -12), pose: SquirrelPose.sleep, scale: 0.9, time: x.t, seed: 6,
        look: const SquirrelLook(golden: true), art: x.art);
    final crown = pile.translate(1.5, -32);
    c.drawPath(Path()..moveTo(crown.dx - 5, crown.dy + 4)..lineTo(crown.dx - 4, crown.dy - 1)..lineTo(crown.dx - 1.5, crown.dy + 2)
      ..lineTo(crown.dx, crown.dy - 2)..lineTo(crown.dx + 1.5, crown.dy + 2)..lineTo(crown.dx + 4, crown.dy - 1)
      ..lineTo(crown.dx + 5, crown.dy + 4)..close(), Kit.fill(const Color(0xFFFDE047)));
  }

  static void _silver(Canvas c, RoomCtx x, Offset o, double f) {
    // Mine cart of silver bars and a tiny miner tapping the vein
    for (var k = 0; k < 4; k++) {
      final p = Offset(o.dx + 14 + k * 9.0, o.dy + 14 + (k % 2) * 8.0);
      c.drawPath(Path()..addPolygon([p, p.translate(5, -3), p.translate(9, 2), p.translate(3, 5)], true),
          Kit.fill(const Color(0xFFE2E8F0)));
    }
    final cart = Rect.fromLTWH(o.dx + 14, f - 18, 36, 14);
    c.drawPath(Path()..moveTo(cart.left, cart.top)..lineTo(cart.right, cart.top)..lineTo(cart.right - 4, cart.bottom)
      ..lineTo(cart.left + 4, cart.bottom)..close(), Kit.fill(const Color(0xFF57534E)));
    for (var k = 0; k < 3; k++) {
      final bar = Rect.fromLTWH(cart.left + 4 + k * 9.0, cart.top - 5 + (k % 2) * 1.0, 10, 5);
      c.drawRRect(Kit.rr(bar, 1), Kit.fill(const Color(0xFFCBD5E1)));
      c.drawLine(bar.topLeft.translate(1.5, 1), bar.topRight.translate(-1.5, 1), Kit.stroke(const Color(0xAAFFFFFF), 0.7));
    }
    for (final dx in const [8.0, 28.0]) {
      c.drawCircle(Offset(cart.left + dx, cart.bottom + 1), 3, Kit.fill(const Color(0xFF1C1917)));
    }
    _resident(c, x, Offset(o.dx + 82, f - 14), SquirrelHat.none, SquirrelProp.pickaxe, 8.8, dir: -1, scale: 0.7);
    final spark = (x.t * 3.4 + 8.8) % (math.pi * 2);
    if (math.sin(spark) > 0.92) {
      Kit.sparkle(c, Offset(o.dx + 70, f - 30), 3, const Color(0xFFFFFFFF));
    }
  }

  static void _resident(Canvas c, RoomCtx x, Offset at, SquirrelHat hat, SquirrelProp prop, double seed,
      {double dir = -1, double scale = 0.78, bool suit = false, bool acorn = false}) {
    SquirrelPainter.paint(c, at, dir: dir, scale: scale, time: x.t, seed: seed,
        look: SquirrelLook(hat: x.snap.outfits ? hat : SquirrelHat.none, prop: prop, suit: suit,
            acorn: acorn, scarf: x.frost),
        art: x.art);
  }
}

import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../art/squirrel_painter.dart';
import 'room_kit.dart';

/// The Bill Vault's three waterline scenes (drawn in world space, clipped
/// to the room by the caller).
abstract final class Waterline {
  static void _water(Canvas c, RoomCtx x, double surface, {bool icy = false}) {
    final r = x.r;
    final body = Rect.fromLTRB(r.left, surface, r.right, x.floorY + 4);
    c.drawRect(body, Kit.vertical(body, const [Color(0x7738BDF8), Color(0xAA0C4A6E)]));
    final wave = Path()..moveTo(r.left, surface);
    for (var px = r.left; px <= r.right; px += 5) {
      wave.lineTo(px, surface + math.sin(px * 0.18 + x.t * 2) * 1.3);
    }
    c.drawPath(wave, Kit.stroke(const Color(0xCCBAE6FD), 1.3));
    // Caustic shimmer
    for (var k = 0; k < 6; k++) {
      final px = r.left + 20 + ((x.t * 9 + k * 53) % (r.width - 40));
      final py = surface + 10 + (k * 17) % math.max(1, (x.floorY - surface - 14)).toInt();
      c.drawLine(Offset(px, py), Offset(px + 7, py + 1), Kit.stroke(const Color(0x33E0F2FE), 1));
    }
    if (icy) {
      c.drawRect(Rect.fromLTRB(r.left, surface - 2, r.right, surface + 3), Kit.fill(const Color(0xCCF0F9FF)));
      for (var px = r.left + 10; px < r.right; px += 26) {
        c.drawLine(Offset(px, surface), Offset(px + 9, surface + 2), Kit.stroke(const Color(0x8894A3B8), 0.7));
      }
    }
  }

  /// Bills over half of Free Cash: a brass scuba-diving squirrel hunts
  /// sunken acorns while a raft angler keeps losing a heavy acorn.
  static void high(Canvas c, RoomCtx x) {
    final r = x.r;
    final frozen = x.snap.billPressure >= 1;
    final surface = r.top + r.height * (frozen ? 0.22 : 0.34);
    _water(c, x, surface, icy: frozen);
    final floor = x.floorY;
    // Sunken acorns glinting on the floor
    for (final dx in const [40.0, 92.0, 138.0]) {
      final p = Offset(r.left + dx, floor - 4);
      Kit.acorn(c, p, rx: 3.6, ry: 4.2, strokeWidth: 0.7);
      final s = (x.t * 0.5 + dx) % 1.0;
      Kit.sparkle(c, p.translate(3, -5), 1.8 * math.sin(s * math.pi), const Color(0xFFFEF9C3));
    }
    // Diver walking the floor
    final u = Ease.easeInOut(Ease.pingPong(x.work / 9));
    final dir = (x.work / 9) % 2 < 1 ? 1.0 : -1.0;
    final diver = Offset(r.left + 30 + u * 130, floor - 14);
    SquirrelPainter.paint(c, diver, dir: dir, scale: 0.9, time: x.t, seed: 2.9,
        hop: -math.max(0.0, math.sin(x.work * 2.2)) * 1.5, art: x.art);
    final helmet = diver.translate(dir * 1.4, -6.4);
    c.drawCircle(helmet, 8.6, Kit.fill(const Color(0xFFD97706)));
    c.drawCircle(helmet.translate(dir * 2.4, 0), 4.6, Kit.fill(const Color(0xAABAE6FD)));
    c.drawCircle(helmet.translate(dir * 2.4, 0), 4.6, Kit.stroke(const Color(0xFF92400E), 1.2));
    c.drawCircle(helmet, 8.6, Kit.stroke(const Color(0xFF78350F), 1));
    // Air hose up to the raft and bubbles
    final raftX = r.left + 214 + math.sin(x.t * 0.8) * 4;
    final hose = Path()
      ..moveTo(helmet.dx, helmet.dy - 8)
      ..quadraticBezierTo((helmet.dx + raftX) / 2, surface + 20, raftX - 16, surface);
    c.drawPath(hose, Kit.stroke(const Color(0xFF292524), 1.2));
    for (var k = 0; k < 3; k++) {
      final s = (x.t * 0.7 + k * 0.33) % 1.0;
      final b = Offset(helmet.dx + math.sin(s * 9 + k) * 3, helmet.dy - 10 - s * (helmet.dy - 10 - surface));
      if (b.dy > surface) c.drawCircle(b, 1.4 + s, Kit.stroke(const Color(0xAAE0F2FE), 0.8));
    }
    _raftAngler(c, x, Offset(raftX, surface), floor);
  }

  static void _raftAngler(Canvas c, RoomCtx x, Offset raft, double floor) {
    final bob = math.sin(x.t * 1.6) * 1.2;
    final deck = Rect.fromCenter(center: raft.translate(0, bob), width: 50, height: 6);
    for (var k = 0; k < 5; k++) {
      c.drawRRect(Kit.rr(Rect.fromLTWH(deck.left + k * 10, deck.top, 9.5, 6), 2), Kit.fill(const Color(0xFF8B5A2B)));
    }
    c.drawLine(deck.topLeft.translate(2, 3), deck.topRight.translate(-2, 3), Kit.stroke(const Color(0xFFD6B48A), 0.8));
    final angler = Offset(deck.center.dx + 8, deck.top - 14);
    SquirrelPainter.paint(c, angler, dir: -1, scale: 0.82, time: x.t, seed: 5.2, art: x.art);
    final tip = angler.translate(-26, -18);
    c.drawLine(angler.translate(-6, 0), tip, Kit.stroke(const Color(0xFF78350F), 1.3));
    // The heavy acorn: reeled up... and (usually) it slips off the hook
    const cycle = 6.0;
    final n = (x.work / cycle).floor();
    final u = (x.work % cycle) / cycle;
    final lucky = (n * 7 + 3) % 4 == 0;
    final surfaceY = deck.center.dy;
    Offset acorn;
    if (u < 0.7) {
      acorn = Offset(tip.dx, floor - 6 - (floor - 6 - surfaceY - 4) * Ease.easeInOut(u / 0.7));
    } else if (lucky) {
      final v = ((u - 0.7) / 0.2).clamp(0.0, 1.0);
      acorn = Offset.lerp(Offset(tip.dx, surfaceY - 4), Offset(deck.left + 10, deck.top - 4), v)!
          .translate(0, -math.sin(v * math.pi) * 12);
      if (u > 0.9) Kit.sparkle(c, Offset(deck.left + 10, deck.top - 10), 3, const Color(0xFFFEF9C3));
    } else {
      final v = ((u - 0.74) / 0.26).clamp(0.0, 1.0);
      acorn = Offset(tip.dx, surfaceY - 4 + (floor - 6 - surfaceY + 4) * v * v);
      if (u > 0.72 && u < 0.86) {
        final s = (u - 0.72) / 0.14;
        c.drawOval(Kit.oval(Offset(tip.dx, surfaceY), 4 + s * 10, 1 + s * 2.4),
            Kit.stroke(Color.fromRGBO(224, 242, 254, 1 - s), 1));
        for (final dx in const [-5.0, 0.0, 5.0]) {
          c.drawCircle(Offset(tip.dx + dx * (1 + s), surfaceY - 6 * math.sin(s * math.pi)), 1, Kit.fill(Color.fromRGBO(224, 242, 254, 1 - s)));
        }
      }
    }
    final hooked = u < 0.74;
    c.drawLine(tip, hooked ? acorn.translate(0, -5) : Offset(tip.dx, surfaceY + 6), Kit.stroke(const Color(0xAAF8FAFC), 0.6));
    Kit.acorn(c, acorn, rx: 5, ry: 6, body: Pal.gold, strokeWidth: 0.8);
  }

  /// Bills between a quarter and half of Free Cash: a walnut-shell skiff
  /// paddles about while a squirrel patches the bark seams.
  static void mid(Canvas c, RoomCtx x) {
    final r = x.r;
    final surface = r.top + r.height * 0.58;
    _water(c, x, surface);
    final u = Ease.easeInOut(Ease.pingPong(x.work / 12));
    final skiff = Offset(r.left + 50 + u * 150, surface + math.sin(x.t * 1.5) * 1.2);
    final shell = Path()
      ..moveTo(skiff.dx - 24, skiff.dy - 3)
      ..quadraticBezierTo(skiff.dx, skiff.dy + 16, skiff.dx + 24, skiff.dy - 3)
      ..close();
    for (var k = 0; k < 2; k++) {
      final px = skiff.dx - 9 + k * 18;
      SquirrelPainter.paint(c, Offset(px, skiff.dy - 13), dir: 1, scale: 0.66, time: x.t, seed: 3.1 + k, art: x.art);
      final a = x.lit ? x.work * 3 + k * math.pi : 0.6;
      final grip = Offset(px + 5, skiff.dy - 7);
      c.drawLine(grip, grip + Offset(math.cos(a) * 4 - 6, 10 + math.sin(a) * 3), Kit.stroke(const Color(0xFF92400E), 1.4));
    }
    c.drawPath(shell, Kit.fill(const Color(0xFF7C4A22)));
    for (final dx in const [-12.0, 0.0, 12.0]) {
      c.drawLine(Offset(skiff.dx + dx, skiff.dy - 2), Offset(skiff.dx + dx * 0.6, skiff.dy + 8), Kit.stroke(const Color(0x66000000), 1));
    }
    c.drawPath(shell, Kit.stroke(const Color(0xFF451A03), 1));
    // Seam patcher on a ledge above the water
    final ledgeY = surface - 18;
    final lx = r.right - 64;
    c.drawRect(Rect.fromLTWH(lx - 14, ledgeY, 40, 4), Kit.fill(const Color(0xFF8B5A2B)));
    SquirrelPainter.paint(c, Offset(lx, ledgeY - 14), dir: 1, scale: 0.78, time: x.t, seed: 6.4, art: x.art);
    final swing = x.lit ? math.max(0.0, math.sin(x.work * 6)) : 0.0;
    final hand = Offset(lx + 7, ledgeY - 12);
    c.drawLine(hand, hand + Offset(6 + swing * 3, -6 + swing * 6), Kit.stroke(const Color(0xFF78350F), 1.4));
    final patch = Rect.fromLTWH(lx + 16, ledgeY - 24, 9, 12);
    c.drawRect(patch, Kit.fill(const Color(0xFFA16207)));
    for (final p in [patch.topLeft.translate(2, 2), patch.bottomRight.translate(-2, -2)]) {
      c.drawCircle(p, 0.8, Kit.fill(const Color(0xFF94A3B8)));
    }
    final d = (x.t * 0.8) % 1.0;
    c.drawCircle(Offset(patch.right + 2, patch.bottom + d * (surface - patch.bottom)), 1.2, Kit.fill(const Color(0xCCBAE6FD)));
  }

  /// Bills under a quarter of Free Cash: a shallow, clear brook and two
  /// squirrels kicked back in lawn chairs with acorn cups on dry boards.
  static void low(Canvas c, RoomCtx x) {
    final r = x.r;
    final floor = x.floorY;
    final brook = Rect.fromLTRB(r.left + 4, floor - 7, r.left + 150, floor + 1);
    c.drawRRect(Kit.rr(brook, 4), Kit.vertical(brook, const [Color(0xAA7DD3FC), Color(0xCC38BDF8)]));
    for (var k = 0; k < 6; k++) {
      c.drawOval(Kit.oval(Offset(brook.left + 10 + k * 24.0, brook.bottom - 2), 3, 1.4), Kit.fill(const Color(0xFF78716C)));
      final s = (x.t * 0.6 + k * 0.17) % 1.0;
      c.drawLine(Offset(brook.left + 6 + ((x.t * 18 + k * 30) % 140), brook.top + 2),
          Offset(brook.left + 12 + ((x.t * 18 + k * 30) % 140), brook.top + 2), Kit.stroke(Color.fromRGBO(255, 255, 255, 0.4 * s), 0.8));
    }
    for (var k = 0; k < 2; k++) {
      final base = Offset(r.left + 180 + k * 46, floor);
      _lawnChair(c, base, k);
      final at = base.translate(0, -20);
      final dir = k == 0 ? 1.0 : -1.0;
      SquirrelPainter.paint(c, at, dir: dir, scale: 0.76, time: x.t, seed: 4.8 + k, art: x.art);
      // Acorn-cup drink with a straw
      final cup = at.translate(dir * 7, 2 + math.sin(x.work * 0.8 + k) * 0.6);
      c.drawPath(Path()
        ..moveTo(cup.dx - 3, cup.dy - 2)
        ..quadraticBezierTo(cup.dx, cup.dy + 4, cup.dx + 3, cup.dy - 2)
        ..close(), Kit.fill(Pal.acornCap));
      c.drawLine(cup.translate(1, -2), cup.translate(2.4, -7), Kit.stroke(const Color(0xFFF472B6), 0.8));
    }
    // Cocktail umbrella stuck between the chairs
    final pole = Offset(r.left + 203, floor);
    c.drawLine(pole, pole.translate(0, -26), Kit.stroke(const Color(0xFFD6B48A), 1));
    c.drawPath(Path()
      ..moveTo(pole.dx - 13, pole.dy - 22)
      ..quadraticBezierTo(pole.dx, pole.dy - 34, pole.dx + 13, pole.dy - 22)
      ..close(), Kit.fill(const Color(0xFFF97316)));
  }

  static void _lawnChair(Canvas c, Offset base, int k) {
    final frame = Kit.stroke(const Color(0xFFCBD5E1), 1.1);
    c.drawLine(base.translate(-8, 0), base.translate(6, -12), frame);
    c.drawLine(base.translate(8, 0), base.translate(-6, -12), frame);
    final seat = Rect.fromLTWH(base.dx - 9, base.dy - 14, 18, 4);
    c.drawRect(seat, Kit.fill(k == 0 ? const Color(0xFF22C55E) : const Color(0xFF38BDF8)));
    final back = Rect.fromLTWH(base.dx + (k == 0 ? -10 : 6), base.dy - 26, 4, 13);
    c.drawRect(back, Kit.fill(k == 0 ? const Color(0xFF22C55E) : const Color(0xFF38BDF8)));
    c.drawLine(Offset(seat.left, seat.center.dy), Offset(seat.right, seat.center.dy), Kit.stroke(const Color(0xAAFFFFFF), 0.8));
  }
}

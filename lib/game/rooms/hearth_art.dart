import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show HSVColor;

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../art/squirrel_painter.dart';
import 'room_kit.dart';

/// Deep-Root Hearth & Tree-Light Generator: fueled with Acorns, it sends
/// light up the root veins to the whole tree. Starter is a stone fire ring,
/// Cozy a brick hearth with a flue, Max a riveted brass furnace with
/// gauges. Out of fuel it falls to embers and the stoker dozes.
class HearthArt extends RoomArt {
  const HearthArt();

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    RoomKit.shell(c, x, earthy: true, wall: const Color(0xFF2A1408));
    final r = x.r;
    final f = x.floorY;
    final cx = r.center.dx + 8;
    switch (x.level) {
      case >= 3:
        final body = Rect.fromCenter(center: Offset(cx, f - 22), width: 54, height: 44);
        c.drawRRect(Kit.rr(body, 10), Kit.linear(body.centerLeft, body.centerRight,
            const [Color(0xFF92400E), Color(0xFFFBBF24), Color(0xFF92400E)]));
        for (var k = 0; k < 6; k++) {
          c.drawCircle(Offset(body.left + 5 + k * 8.8, body.top + 4), 1, Kit.fill(const Color(0xFF78350F)));
        }
        c.drawLine(Offset(cx - 18, body.top), Offset(cx - 18, r.top + 4), Kit.stroke(const Color(0xFFB45309), 4));
        c.drawLine(Offset(cx + 18, body.top), Offset(cx + 18, r.top + 4), Kit.stroke(const Color(0xFFB45309), 4));
        Kit.acorn(c, Offset(cx, body.top + 10), rx: 4, ry: 4.8, body: Pal.brass, strokeWidth: 0.6);
      case 2:
        final arch = Rect.fromCenter(center: Offset(cx, f - 18), width: 52, height: 36);
        c.drawRRect(RRect.fromRectAndCorners(arch, topLeft: const Radius.circular(20), topRight: const Radius.circular(20)),
            Kit.fill(const Color(0xFF9A3412)));
        for (var row = 0; row < 4; row++) {
          c.drawLine(Offset(arch.left, arch.top + 8 + row * 7.0), Offset(arch.right, arch.top + 8 + row * 7.0),
              Kit.stroke(const Color(0x55000000), 0.8));
        }
        c.drawRect(Rect.fromLTWH(cx - 7, r.top + 2, 14, arch.top - r.top - 2), Kit.fill(const Color(0xFF7C2D12)));
      default:
        break;
    }
    // Acorn fuel pile
    final pile = Offset(r.left + 22, f);
    for (var k = 0; k < 3 + x.level * 2; k++) {
      final row = k < 4 ? 0 : (k < 7 ? 1 : 2);
      final col = k < 4 ? k : (k < 7 ? k - 4 : k - 7);
      Kit.acorn(c, pile.translate(-9 + col * 6.0 + row * 3, -4 - row * 5.5), rx: 3, ry: 3.6, strokeWidth: 0.6);
    }
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final r = x.r;
    final f = x.floorY;
    final cx = r.center.dx + 8;
    final fire = Offset(cx, f - (x.level >= 3 ? 10 : 6));
    final lit = x.lit;
    final fuel = x.snap.hearthFuel;
    final flare = math.max(0.0, 1 - x.since('hearth') / 2);
    _veins(c, x, lit);
    if (x.level >= 3) {
      final door = Rect.fromCenter(center: fire.translate(0, -6), width: 30, height: 20);
      c.drawRRect(Kit.rr(door, 8), Kit.fill(const Color(0xFF1C1917)));
    }
    // Stone ring (always) and the fire itself
    for (var k = 0; k < 7; k++) {
      c.drawOval(Kit.oval(Offset(cx - 18 + k * 6.0, f - 1), 3.6, 2.6), Kit.fill(const Color(0xFF78716C)));
    }
    if (lit) {
      final size = 0.55 + 0.45 * math.max(fuel, x.snap.overdrive ? 1.0 : 0.0) + flare * 0.4;
      Kit.glow(c, fire.translate(0, -8), 40 * size, const Color(0xFFFB923C), 0.45);
      for (var k = 0; k < 3; k++) {
        final flick = 0.8 + 0.2 * math.sin(x.t * (9 + k) + k);
        final h = (16 + k * 4) * size * flick;
        final dx = (k - 1) * 6.0;
        final outer = x.snap.overdrive ? const Color(0xFF93C5FD) : const Color(0xFFF97316);
        c.drawPath(Path()
          ..moveTo(fire.dx + dx, fire.dy - h)
          ..quadraticBezierTo(fire.dx + dx + 7, fire.dy - h * 0.4, fire.dx + dx, fire.dy)
          ..quadraticBezierTo(fire.dx + dx - 7, fire.dy - h * 0.4, fire.dx + dx, fire.dy - h)
          ..close(), Kit.fill(outer));
        c.drawOval(Kit.oval(fire.translate(dx, -h * 0.3), 2.4, h * 0.28),
            Kit.fill(x.snap.overdrive ? const Color(0xFFF0F9FF) : const Color(0xFFFDE047)));
      }
      if (x.snap.festival) {
        for (var k = 0; k < 5; k++) {
          final s = (x.t * 0.8 + k * 0.2) % 1.0;
          final color = HSVColor.fromAHSV(1, (k * 72 + x.t * 60) % 360, 0.7, 1).toColor();
          Kit.sparkle(c, fire.translate(math.sin(k * 2.0 + x.t) * 10, -14 - s * 34), 2 * (1 - s), color);
        }
      }
    } else {
      // Embers and a lazy curl of smoke
      Kit.glow(c, fire, 12, const Color(0xFFDC2626), 0.35 + 0.1 * math.sin(x.t * 1.5));
      for (var k = 0; k < 4; k++) {
        c.drawCircle(fire.translate(-6 + k * 4.0, -1), 1.2, Kit.fill(const Color(0xFFEF4444)));
      }
      RoomKit.wisp(c, fire.translate(0, -6), x.t * 0.25, height: 26, color: const Color(0xFF9CA3AF));
    }
    if (x.level >= 2) _gauge(c, Offset(r.right - 16, r.top + 22), fuel);
    // Stoker tossing acorns into the flames (dozes when it's dark)
    SquirrelPainter.paint(c, Offset(r.left + 40, f - 14), scale: 0.78, time: x.t, seed: 9.3,
        pose: SquirrelPose.toss, look: SquirrelLook(scarf: x.frost), art: x.art);
  }

  static void _gauge(Canvas c, Offset at, double fuel) {
    c.drawCircle(at, 7, Kit.fill(const Color(0xFFFEF3C7)));
    c.drawCircle(at, 7, Kit.stroke(Pal.brass, 1.4));
    c.drawArc(Rect.fromCircle(center: at, radius: 5), math.pi * 0.8, math.pi * 0.35, false, Kit.stroke(const Color(0xFFDC2626), 1));
    final a = math.pi * 0.8 + fuel * math.pi * 1.4;
    c.drawLine(at, at + Offset(math.cos(a), math.sin(a)) * 5.4, Kit.stroke(const Color(0xFF1C1917), 1));
  }

  /// Glowing root veins carrying the Hearth's light up to the tree.
  static void _veins(Canvas c, RoomCtx x, bool lit) {
    final path = Path()
      ..moveTo(x.r.right - 6, x.r.top + 40)
      ..quadraticBezierTo(590, 1010, 589, 950)
      ..quadraticBezierTo(596, 880, 588, 790);
    c.drawPath(path, Kit.stroke(lit ? const Color(0x55FBBF24) : const Color(0x22FBBF24), lit ? 2.4 : 1.4));
    if (!lit) return;
    for (final metric in path.computeMetrics()) {
      for (var k = 0; k < 3; k++) {
        final d = ((x.t * 40 + k * metric.length / 3) % metric.length);
        final tan = metric.getTangentForOffset(metric.length - d);
        if (tan == null) continue;
        Kit.glow(c, tan.position, 7, const Color(0xFFFDE68A), 0.7);
      }
    }
  }
}

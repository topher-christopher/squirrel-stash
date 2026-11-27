import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/skate_kit.dart';
import '../art/squirrel_gear.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import 'metro_lines.dart';
import 'room_kit.dart';

/// DC Metro Station in the root tunnels: coffered vault ceiling, a train
/// that arrives, swaps commuters and departs while the LED board cycles real
/// Red and Orange/Silver Line stops, suited commuters (a flood of them at
/// rush hour), a skater and a cyclist, and Capitals fans in red jerseys
/// stepping off at Gallery Place and Metro Center.
class MetroArt extends RoomArt {
  const MetroArt();

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    final r = x.r;
    final rr = Kit.rr(r, 22);
    c.drawRRect(rr, Kit.vertical(r, const [Color(0xFF3F3A36), Color(0xFF1C1917)]));
    c.save();
    c.clipRRect(rr);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 18; col++) {
        final cell = Rect.fromLTWH(r.left + 6 + col * 30.0, r.top + 6 + row * 16.0, 24, 11);
        c.drawRRect(Kit.rr(cell, 2), Kit.fill(Color.fromRGBO(0, 0, 0, 0.22 + row * 0.05)));
        c.drawRRect(Kit.rr(cell, 2), Kit.stroke(const Color(0x22FFFFFF), 0.8));
      }
    }
    final platformTop = r.bottom - 34;
    c.drawRect(Rect.fromLTRB(r.left, platformTop, r.right, r.bottom), Kit.fill(const Color(0xFF57534E)));
    c.drawRect(Rect.fromLTRB(r.left, platformTop, r.right, platformTop + 4), Kit.fill(const Color(0xFFD6D3D1)));
    final track = Rect.fromLTRB(r.left, platformTop - 34, r.right, platformTop);
    c.drawRect(track, Kit.fill(const Color(0xFF292524)));
    c.drawLine(Offset(r.left, platformTop - 4), Offset(r.right, platformTop - 4), Kit.stroke(const Color(0xFF78716C), 2));
    // Bronze pylon with the "M" and the line stripes
    final pylon = Rect.fromLTWH(r.left + 30, platformTop - 64, 12, 64);
    c.drawRRect(Kit.rr(pylon, 2), Kit.vertical(pylon, const [Color(0xFF57412B), Color(0xFF3B2A1A)]));
    c.drawRRect(Kit.rr(Rect.fromLTWH(pylon.left - 4, pylon.top - 12, 20, 14), 3), Kit.fill(const Color(0xFF292524)));
    _metroM(c, Offset(pylon.center.dx, pylon.top - 5));
    for (var i = 0; i < 2; i++) {
      c.drawRect(Rect.fromLTWH(pylon.left + 2, pylon.top + 8 + i * 6.0, 8, 4),
          Kit.fill(i == 0 ? MetroLine.red.color : MetroLine.orangeSilver.color));
    }
    if (x.level >= 2) {
      for (var k = 0; k < 3; k++) {
        final g = Rect.fromLTWH(r.left + 200 + k * 26.0, platformTop + 6, 8, 16);
        c.drawRRect(Kit.rr(g, 2), Kit.fill(const Color(0xFF78716C)));
        c.drawRect(Rect.fromLTWH(g.left + 2, g.top + 3, 4, 3), Kit.fill(const Color(0xFF4ADE80)));
      }
    }
    if (x.level >= 3) {
      c.drawRRect(Kit.rr(Rect.fromLTWH(r.right - 150, platformTop + 14, 40, 5), 2), Kit.fill(const Color(0xFF8B5A2B)));
      // Backlit ad panels along the vault
      for (var k = 0; k < 3; k++) {
        final ad = Rect.fromLTWH(r.left + 80 + k * 150.0, platformTop - 64, 34, 22);
        c.drawRRect(Kit.rr(ad, 2), Kit.vertical(ad, [const Color(0xFFFDE68A), [const Color(0xFFF472B6), const Color(0xFF38BDF8), const Color(0xFF4ADE80)][k]]));
        c.drawRRect(Kit.rr(ad, 2), Kit.stroke(const Color(0xFF78716C), 1));
      }
    }
    c.restore();
    c.drawRRect(rr, Kit.stroke(x.level == 3 ? const Color(0xFFFBBF24) : const Color(0xFF451A03), 2.4));
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final r = x.r;
    final platformTop = r.bottom - 34;
    final rush = x.snap.rushHour;
    final cycleLen = rush ? 9.0 : 14.0;
    final n = (x.work / cycleLen).floor();
    final phase = (x.work % cycleLen) / cycleLen;
    final (line, stop) = MetroStops.at(n);
    c.save();
    c.clipRRect(Kit.rr(r, 22));
    MetroSign.paint(c, Rect.fromLTWH(r.left + 180, r.top + 30, 176, 15), line, stop,
        arriving: phase > 0.15 && phase < 0.45, t: x.t);
    final approaching = phase > 0.15 && phase < 0.55;
    for (var k = 0; k < 14; k++) {
      final on = approaching && ((x.t * 4 + k) % 2 < 1);
      c.drawCircle(Offset(r.left + 20 + k * 38.0, platformTop + 2), 1.6,
          Kit.fill(on ? const Color(0xFFFDE68A) : const Color(0x55FDE68A)));
    }
    _train(c, r, platformTop, phase, line);
    final floor = r.bottom - 12;
    // Commuters pacing the platform (a flood of them at rush hour)
    final walkers = rush ? 7 : 2;
    for (var k = 0; k < walkers; k++) {
      final period = 7 + (k % 4) * 1.6;
      final u = Ease.pingPong(x.work / period + k * 0.37);
      final dir = ((x.work / period + k * 0.37) % 2) < 1 ? 1.0 : -1.0;
      SquirrelPainter.paint(c, Offset(r.left + 70 + u * 400, floor - 14),
          dir: dir, scale: 0.88, time: x.t, seed: 2.0 + k,
          hop: -math.sin(x.work * 7 + k).abs() * 0.7,
          look: SquirrelLook(suit: true, prop: SquirrelProp.briefcase, scarf: x.frost), art: x.art);
    }
    _swap(c, x, r, platformTop, phase);
    _fans(c, x, r, floor, n, phase);
    final roll = (x.work / 9) % 1.0;
    final sx = r.left - 20 + roll * (r.width + 40);
    SkateKit.board(c, Offset(sx, floor + 1), x.art);
    SquirrelPainter.paint(c, Offset(sx, floor - 16), scale: 0.85, time: x.t, seed: 6.2,
        look: SquirrelLook(hat: x.snap.outfits ? SquirrelHat.beanie : SquirrelHat.none), art: x.art);
    if (x.level >= 2 || x.detail > 0.05) {
      final bx = r.right + 20 - ((x.work / 11 + 0.5) % 1.0) * (r.width + 40);
      _bike(c, Offset(bx, floor), x.work);
      SquirrelPainter.paint(c, Offset(bx, floor - 22), dir: -1, scale: 0.82, time: x.t, seed: 7.7,
          look: SquirrelLook(hat: x.snap.outfits ? SquirrelHat.goggles : SquirrelHat.none), art: x.art);
    }
    c.restore();
  }

  /// Doors open: one rider steps off, another steps on.
  static void _swap(Canvas c, RoomCtx x, Rect r, double platformTop, double phase) {
    if (phase < 0.46 || phase > 0.72) return;
    final stopX = r.left + (r.width - 300) / 2;
    final off = ((phase - 0.46) / 0.14).clamp(0.0, 1.0);
    final on = ((phase - 0.56) / 0.14).clamp(0.0, 1.0);
    final doorA = Offset(stopX + 60, platformTop - 8), doorB = Offset(stopX + 214, platformTop - 8);
    c.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, math.min(1, off * 3)));
    SquirrelPainter.paint(c, Offset.lerp(doorA, doorA.translate(30, 24), off)!, scale: 0.84, time: x.t, seed: 12,
        look: SquirrelLook(suit: true, prop: SquirrelProp.briefcase, scarf: x.frost), art: x.art);
    c.restore();
    c.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, 1 - on));
    SquirrelPainter.paint(c, Offset.lerp(doorB.translate(-30, 24), doorB, on)!, dir: 1, scale: 0.84, time: x.t, seed: 13,
        look: SquirrelLook(backpack: true, scarf: x.frost), art: x.art);
    c.restore();
  }

  /// Caps fans: they pour off trains departing Gallery Place and Metro
  /// Center, cheer on the platform, and board the next train.
  static void _fans(Canvas c, RoomCtx x, Rect r, double floor, int n, double phase) {
    final justLeft = MetroStops.fanStop(n) && phase >= 0.6;
    final waiting = MetroStops.fanStop(n - 1) && phase < 0.55;
    if (!justLeft && !waiting) return;
    final fade = justLeft ? ((phase - 0.6) / 0.08).clamp(0.0, 1.0) : (1 - ((phase - 0.45) / 0.1).clamp(0.0, 1.0));
    c.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, fade));
    for (var k = 0; k < 3; k++) {
      final at = Offset(r.left + 300 + k * 26.0 + math.sin(x.work * 0.8 + k) * 6, floor - 14);
      SquirrelPainter.paint(c, at, dir: k.isEven ? 1 : -1, scale: 0.86, time: x.t, seed: 30.0 + k,
          hop: -math.max(0.0, math.sin(x.work * 5 + k * 1.3)) * 4,
          look: const SquirrelLook(jersey: true, scarf: true, hat: SquirrelHat.capsBeanie), art: x.art);
      if (k == 1) _flag(c, x, at.translate(9, -20));
    }
    c.restore();
  }

  static void _flag(Canvas c, RoomCtx x, Offset at) {
    c.drawLine(at, at.translate(0, 20), Kit.stroke(const Color(0xFFD6D3D1), 1));
    final wave = math.sin(x.t * 6) * 1.5;
    final custom = x.art.metro('custom_caps_flag');
    final box = Rect.fromLTWH(at.dx, at.dy, 18, 12);
    if (custom != null) {
      c.drawImageRect(custom, Rect.fromLTWH(0, 0, custom.width.toDouble(), custom.height.toDouble()), box,
          Paint()..filterQuality = FilterQuality.medium);
      return;
    }
    final flag = Path()
      ..moveTo(box.left, box.top)
      ..quadraticBezierTo(box.center.dx, box.top + wave, box.right, box.top + 1)
      ..lineTo(box.right, box.bottom - 1)
      ..quadraticBezierTo(box.center.dx, box.bottom + wave, box.left, box.bottom)
      ..close();
    c.drawPath(flag, Kit.fill(SquirrelGear.capsRed));
    c.drawLine(Offset(box.left, box.center.dy), Offset(box.right, box.center.dy + 1), Kit.stroke(const Color(0xFFFFFFFF), 1.6));
    c.drawLine(Offset(box.left, box.center.dy + 2.4), Offset(box.right, box.center.dy + 3.4), Kit.stroke(SquirrelGear.capsNavy, 1.2));
    Kit.sparkle(c, Offset(box.left + 5, box.top + 3.4), 2, const Color(0xFFFFFFFF));
  }

  static void _train(Canvas c, Rect r, double platformTop, double phase, MetroLine line) {
    const len = 300.0;
    final stopX = r.left + (r.width - len) / 2;
    double x;
    if (phase < 0.2) {
      x = r.right + 40;
    } else if (phase < 0.45) {
      final u = Ease.easeInOut((phase - 0.2) / 0.25);
      x = r.right + 40 + (stopX - r.right - 40) * u;
    } else if (phase < 0.72) {
      x = stopX;
    } else {
      final u = (phase - 0.72) / 0.28;
      x = stopX - u * u * (stopX - r.left + len + 40);
    }
    final top = platformTop - 32;
    final doorsOpen = phase > 0.47 && phase < 0.7;
    for (var car = 0; car < 3; car++) {
      final b = Rect.fromLTWH(x + car * 102, top, 98, 28);
      c.drawRRect(Kit.rr(b, 6), Kit.vertical(b, const [Color(0xFFE7E5E4), Color(0xFFA8A29E)]));
      c.drawRect(Rect.fromLTWH(b.left, b.top + 17, b.width, 4), Kit.fill(line.color));
      for (var w = 0; w < 4; w++) {
        c.drawRRect(Kit.rr(Rect.fromLTWH(b.left + 8 + w * 22.0, b.top + 5, 14, 9), 2), Kit.fill(const Color(0xFF1E293B)));
        c.drawRect(Rect.fromLTWH(b.left + 9 + w * 22.0, b.top + 6, 4, 3), Kit.fill(const Color(0x55BAE6FD)));
      }
      if (doorsOpen) {
        c.drawRect(Rect.fromLTWH(b.left + 44, b.top + 4, 10, 22), Kit.fill(const Color(0xFFFEF3C7)));
      }
    }
    Kit.glow(c, Offset(x - 2, top + 18), 18, const Color(0xFFFEF9C3), 0.5);
  }

  static void _metroM(Canvas c, Offset at) {
    final ink = Kit.stroke(const Color(0xFFFFFFFF), 1.5);
    c.drawLine(at.translate(-5, 4), at.translate(-5, -4), ink);
    c.drawLine(at.translate(-5, -4), at.translate(0, 1), ink);
    c.drawLine(at.translate(0, 1), at.translate(5, -4), ink);
    c.drawLine(at.translate(5, -4), at.translate(5, 4), ink);
  }

  static void _bike(Canvas c, Offset at, double t) {
    final ink = Kit.stroke(const Color(0xFF0F766E), 1.6);
    for (final dx in const [-10.0, 10.0]) {
      c.drawCircle(at.translate(dx, -6), 6, Kit.stroke(const Color(0xFF1C1917), 1.6));
      final a = t * 8;
      c.drawLine(at.translate(dx, -6), at.translate(dx + math.cos(a) * 5, -6 + math.sin(a) * 5),
          Kit.stroke(const Color(0x88FFFFFF), 0.6));
    }
    c.drawLine(at.translate(-10, -6), at.translate(-1, -14), ink);
    c.drawLine(at.translate(-1, -14), at.translate(10, -6), ink);
    c.drawLine(at.translate(-1, -14), at.translate(-3, -6), ink);
  }
}

import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import 'room_kit.dart';

/// DC Metro Station in the root tunnels: coffered vault ceiling, a looping
/// train, suited commuters with briefcases and riders with bikes and boards.
class MetroArt extends RoomArt {
  const MetroArt();

  static const _cycle = 14.0;

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    final r = x.r;
    final rr = Kit.rr(r, 22);
    c.drawRRect(rr, Kit.vertical(r, const [Color(0xFF3F3A36), Color(0xFF1C1917)]));
    c.save();
    c.clipRRect(rr);
    // Coffered (waffle) barrel vault — the classic WMATA ceiling
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 18; col++) {
        final cell = Rect.fromLTWH(r.left + 6 + col * 30.0, r.top + 6 + row * 16.0, 24, 11);
        c.drawRRect(Kit.rr(cell, 2), Kit.fill(Color.fromRGBO(0, 0, 0, 0.22 + row * 0.05)));
        c.drawRRect(Kit.rr(cell, 2), Kit.stroke(const Color(0x22FFFFFF), 0.8));
      }
    }
    // Platform & warm floor lights (granite edge with flashing lights)
    final platformTop = r.bottom - 34;
    c.drawRect(Rect.fromLTRB(r.left, platformTop, r.right, r.bottom), Kit.fill(const Color(0xFF57534E)));
    c.drawRect(Rect.fromLTRB(r.left, platformTop, r.right, platformTop + 4), Kit.fill(const Color(0xFFD6D3D1)));
    // Track bed behind the platform
    final track = Rect.fromLTRB(r.left, platformTop - 34, r.right, platformTop);
    c.drawRect(track, Kit.fill(const Color(0xFF292524)));
    c.drawLine(Offset(r.left, platformTop - 4), Offset(r.right, platformTop - 4), Kit.stroke(const Color(0xFF78716C), 2));
    // Pylon sign (brown with the "M")
    final pylon = Rect.fromLTWH(r.left + 30, platformTop - 64, 12, 30);
    c.drawRRect(Kit.rr(pylon, 2), Kit.fill(const Color(0xFF44403C)));
    c.drawRRect(Kit.rr(Rect.fromLTWH(pylon.left - 4, pylon.top - 12, 20, 14), 3), Kit.fill(const Color(0xFF292524)));
    _metroM(c, Offset(pylon.center.dx, pylon.top - 5));
    // Colored line stripes on the wall
    const lines = [Color(0xFFDC2626), Color(0xFFF97316), Color(0xFF2563EB), Color(0xFF16A34A)];
    for (var i = 0; i < lines.length; i++) {
      c.drawRRect(Kit.rr(Rect.fromLTWH(r.right - 120 + i * 24.0, platformTop - 70, 18, 5), 2), Kit.fill(lines[i]));
    }
    if (x.level >= 2) {
      // Fare gates on the platform
      for (var k = 0; k < 3; k++) {
        final g = Rect.fromLTWH(r.left + 200 + k * 26.0, platformTop + 6, 8, 16);
        c.drawRRect(Kit.rr(g, 2), Kit.fill(const Color(0xFF78716C)));
        c.drawRect(Rect.fromLTWH(g.left + 2, g.top + 3, 4, 3), Kit.fill(const Color(0xFF4ADE80)));
      }
    }
    if (x.level >= 3) {
      // Bench and a rack of bikes
      c.drawRRect(Kit.rr(Rect.fromLTWH(r.right - 150, platformTop + 14, 40, 5), 2), Kit.fill(const Color(0xFF8B5A2B)));
    }
    c.restore();
    c.drawRRect(rr, Kit.stroke(x.level == 3 ? const Color(0xFFFBBF24) : const Color(0xFF451A03), 2.4));
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final r = x.r;
    final platformTop = r.bottom - 34;
    c.save();
    c.clipRRect(Kit.rr(r, 22));
    // Platform edge lights pulse as the train approaches
    final phase = (x.t % _cycle) / _cycle;
    final approaching = phase > 0.15 && phase < 0.55;
    for (var k = 0; k < 14; k++) {
      final on = approaching && ((x.t * 4 + k) % 2 < 1);
      c.drawCircle(Offset(r.left + 20 + k * 38.0, platformTop + 2), 1.6,
          Kit.fill(on ? const Color(0xFFFDE68A) : const Color(0x55FDE68A)));
    }
    _train(c, r, platformTop, phase);
    // Commuters: suited squirrels with briefcases walking the platform,
    // a skateboarder and a bike rider rolling through.
    final floor = r.bottom - 12;
    for (var k = 0; k < 2; k++) {
      final u = Ease.pingPong(x.t / (7 + k * 2) + k * 0.4);
      final dir = ((x.t / (7 + k * 2) + k * 0.4) % 2) < 1 ? 1.0 : -1.0;
      SquirrelPainter.paint(c, Offset(r.left + 70 + u * 360, floor - 14),
          dir: dir, scale: 0.9, time: x.t, seed: 2.0 + k,
          hop: -math.sin(x.t * 7 + k).abs() * 0.7,
          look: SquirrelLook(suit: true, prop: SquirrelProp.briefcase, scarf: x.frost), art: x.art);
    }
    final roll = (x.t / 9) % 1.0;
    final sx = r.left - 20 + roll * (r.width + 40);
    _skateboard(c, Offset(sx, floor + 1));
    SquirrelPainter.paint(c, Offset(sx, floor - 16), scale: 0.85, time: x.t, seed: 6.2,
        look: SquirrelLook(hat: x.snap.outfits ? SquirrelHat.beanie : SquirrelHat.none), art: x.art);
    if (x.level >= 2 || x.detail > 0.05) {
      final bx = r.right + 20 - ((x.t / 11 + 0.5) % 1.0) * (r.width + 40);
      _bike(c, Offset(bx, floor), x.t);
      SquirrelPainter.paint(c, Offset(bx, floor - 22), dir: -1, scale: 0.82, time: x.t, seed: 7.7,
          look: SquirrelLook(hat: x.snap.outfits ? SquirrelHat.goggles : SquirrelHat.none), art: x.art);
    }
    c.restore();
  }

  /// Train glides in, dwells at the platform, then departs (looping).
  static void _train(Canvas c, Rect r, double platformTop, double phase) {
    final len = 300.0;
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
    for (var car = 0; car < 3; car++) {
      final b = Rect.fromLTWH(x + car * 102, top, 98, 28);
      c.drawRRect(Kit.rr(b, 6), Kit.vertical(b, const [Color(0xFFE7E5E4), Color(0xFFA8A29E)]));
      c.drawRect(Rect.fromLTWH(b.left, b.top + 17, b.width, 4), Kit.fill(const Color(0xFF78350F)));
      for (var w = 0; w < 4; w++) {
        c.drawRRect(Kit.rr(Rect.fromLTWH(b.left + 8 + w * 22.0, b.top + 5, 14, 9), 2), Kit.fill(const Color(0xFF1E293B)));
        c.drawRect(Rect.fromLTWH(b.left + 9 + w * 22.0, b.top + 6, 4, 3), Kit.fill(const Color(0x55BAE6FD)));
      }
    }
    // Headlight glow on the lead car
    Kit.glow(c, Offset(x - 2, top + 18), 18, const Color(0xFFFEF9C3), 0.5);
  }

  static void _metroM(Canvas c, Offset at) {
    final ink = Kit.stroke(const Color(0xFFFFFFFF), 1.5);
    c.drawLine(at.translate(-5, 4), at.translate(-5, -4), ink);
    c.drawLine(at.translate(-5, -4), at.translate(0, 1), ink);
    c.drawLine(at.translate(0, 1), at.translate(5, -4), ink);
    c.drawLine(at.translate(5, -4), at.translate(5, 4), ink);
  }

  static void _skateboard(Canvas c, Offset at) {
    c.drawRRect(Kit.rr(Rect.fromCenter(center: at, width: 22, height: 3), 1.5), Kit.fill(const Color(0xFF7C3AED)));
    for (final dx in const [-7.0, 7.0]) {
      c.drawCircle(at.translate(dx, 3), 2, Kit.fill(const Color(0xFF22D3EE)));
    }
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

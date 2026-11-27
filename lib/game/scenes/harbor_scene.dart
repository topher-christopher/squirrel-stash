import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/squirrel_painter.dart';
import 'scene_art.dart';

/// Sea-Lion Lighthouse Jetty: sweeping beam, sunbathing sea lions, gulls,
/// a fishing squirrel and a slowly rising tide.
class HarborScene extends SceneArt {
  final PictureCache _lighthouse = PictureCache();
  final PictureCache _jetty = PictureCache();

  @override
  void render(Canvas canvas, SceneContext ctx) {
    final key = (ctx.frost, ctx.twilight);
    final tide = math.sin(ctx.time * 2 * math.pi / 18) * 5;
    _paintWater(canvas, ctx, 255 - tide);
    _paintBoat(canvas, ctx, 255 - tide);
    _paintGulls(canvas, ctx);
    _lighthouse.draw(canvas, key, (c) => _paintLighthouse(c, ctx));
    _paintBeam(canvas, ctx);
    _jetty.draw(canvas, key, (c) => _paintJetty(c, ctx));
    _paintSeaLions(canvas, ctx);
    _paintFisher(canvas, ctx, 255 - tide);
  }

  void _paintWater(Canvas canvas, SceneContext ctx, double top) {
    final rect = Rect.fromLTRB(30, top, 410, 385);
    final deep = ctx.land(const Color(0xFF0284C7), const Color(0xFF64748B), 0.5);
    canvas.drawRect(rect, Kit.vertical(rect, [Color.lerp(deep, const Color(0xFFFFFFFF), 0.15)!, deep]));
    // Distant island
    canvas.drawPath(
        Path()
          ..moveTo(250, top + 1)
          ..quadraticBezierTo(300, top - 14, 360, top + 1)
          ..close(),
        Kit.fill(ctx.dusk(ctx.frost ? const Color(0xFF94A3B8) : const Color(0xFF0F766E), 0.5)));
    final wave = Kit.stroke(Kit.a(const Color(0xFF7DD3FC), 0.7), 2);
    for (var row = 0; row < 3; row++) {
      final y = top + 25 + row * 22.0;
      final shift = (ctx.time * (12 + row * 6)) % 100;
      final path = Path()..moveTo(30 - shift, y);
      for (var x = 30 - shift; x < 420; x += 50) {
        path.quadraticBezierTo(x + 25, y - 6 + row, x + 50, y);
      }
      canvas.drawPath(path, Kit.stroke(Kit.a(const Color(0xFF7DD3FC), 0.5 - row * 0.12), 1.6));
    }
    canvas.drawLine(Offset(30, top), Offset(410, top), wave);
  }

  void _paintBoat(Canvas canvas, SceneContext ctx, double top) {
    final x = 180 + ((ctx.time * 6) % 260) - 60;
    final bob = math.sin(ctx.time * 1.8) * 1.2;
    canvas.save();
    canvas.translate(x, top + 4 + bob);
    canvas.drawPath(Path()..moveTo(-9, 0)..lineTo(9, 0)..lineTo(6, 4)..lineTo(-6, 4)..close(),
        Kit.fill(ctx.dusk(const Color(0xFF9A3412), 0.4)));
    canvas.drawLine(const Offset(0, 0), const Offset(0, -14), Kit.stroke(const Color(0xFF451A03), 1));
    canvas.drawPath(Path()..moveTo(1, -13)..lineTo(9, -2)..lineTo(1, -2)..close(),
        Kit.fill(ctx.dusk(const Color(0xFFFFF7ED), 0.3)));
    canvas.restore();
  }

  void _paintGulls(Canvas canvas, SceneContext ctx) {
    for (var i = 0; i < 2; i++) {
      final x = 30 + ((ctx.time * (16 + i * 5) + i * 190) % 400);
      final y = 120 + i * 36 + math.sin(ctx.time * 0.8 + i) * 8;
      final flap = math.sin(ctx.time * 6 + i * 2) * 3;
      canvas.drawPath(
          Path()
            ..moveTo(x - 7, y - flap)
            ..quadraticBezierTo(x - 3, y - 3, x, y)
            ..quadraticBezierTo(x + 3, y - 3, x + 7, y - flap),
          Kit.stroke(ctx.twilight ? const Color(0xFFE2E8F0) : const Color(0xFF334155), 1.4));
    }
  }

  void _paintLighthouse(Canvas c, SceneContext ctx) {
    c.drawOval(Kit.oval(const Offset(105, 278), 42, 8), Kit.fill(ctx.dusk(const Color(0xFF57534E), 0.4)));
    final tower = Path()..addPolygon(const [Offset(75, 275), Offset(95, 155), Offset(115, 155), Offset(135, 275)], true);
    c.drawPath(tower, Kit.fill(ctx.dusk(const Color(0xFFF8FAFC), 0.35)));
    c.save();
    c.clipPath(tower);
    final red = Kit.fill(ctx.dusk(const Color(0xFFEF4444), 0.35));
    c.drawRect(const Rect.fromLTWH(70, 185, 70, 18), red);
    c.drawRect(const Rect.fromLTWH(70, 225, 70, 20), red);
    c.drawRect(const Rect.fromLTWH(105, 150, 40, 130), Kit.fill(const Color(0x1A000000)));
    c.restore();
    c.drawRect(const Rect.fromLTWH(88, 153, 34, 3), Kit.fill(const Color(0xFF1E293B)));
    c.drawRRect(Kit.rr(const Rect.fromLTWH(92, 138, 26, 17), 3), Kit.fill(const Color(0xFF1E293B)));
    c.drawPath(Path()..addPolygon(const [Offset(89, 139), Offset(105, 126), Offset(121, 139)], true),
        Kit.fill(ctx.dusk(const Color(0xFFB91C1C), 0.3)));
    c.drawRRect(Kit.rr(const Rect.fromLTWH(98, 202, 8, 12), 3), Kit.fill(const Color(0xFF1E293B)));
    if (ctx.frost) {
      c.drawPath(Path()..addPolygon(const [Offset(89, 139), Offset(105, 126), Offset(121, 139), Offset(105, 133)], true),
          Kit.fill(const Color(0xFFFFFFFF)));
    }
  }

  void _paintBeam(Canvas canvas, SceneContext ctx) {
    const lamp = Offset(105, 146);
    final angle = math.sin(ctx.time * 0.9) * 0.35;
    canvas.save();
    canvas.translate(lamp.dx, lamp.dy);
    canvas.rotate(angle);
    final strength = ctx.twilight ? 0.42 : 0.24;
    canvas.drawPath(
        Path()..addPolygon(const [Offset(0, 0), Offset(185, -30), Offset(185, 28)], true),
        Kit.linear(Offset.zero, const Offset(185, 0), [
          Color.fromRGBO(254, 240, 138, strength),
          const Color(0x00FEF08A),
        ]));
    canvas.restore();
    Kit.glow(canvas, lamp, 16, const Color(0xFFFEF08A), ctx.twilight ? 0.9 : 0.6);
    canvas.drawCircle(lamp, 6, Kit.fill(const Color(0xFFFEF08A)));
  }

  void _paintJetty(Canvas c, SceneContext ctx) {
    final rock = Path()
      ..moveTo(110, 385)
      ..quadraticBezierTo(235, 312, 410, 326)
      ..lineTo(410, 385)
      ..close();
    c.drawPath(rock, Kit.fill(ctx.dusk(const Color(0xFF57534E), 0.4)));
    final rng = math.Random(4);
    for (var i = 0; i < 14; i++) {
      final p = Offset(180 + rng.nextDouble() * 225, 340 + rng.nextDouble() * 40);
      c.drawOval(Kit.oval(p, 6 + rng.nextDouble() * 6, 3 + rng.nextDouble() * 2),
          Kit.fill(ctx.dusk(i.isEven ? const Color(0xFF78716C) : const Color(0xFF44403C), 0.4)));
    }
    c.drawPath(
        Path()
          ..moveTo(110, 385)
          ..quadraticBezierTo(235, 312, 410, 326),
        Kit.stroke(ctx.frost ? const Color(0xFFFFFFFF) : const Color(0x33FFFFFF), ctx.frost ? 4 : 1.5));
  }

  void _paintSeaLions(Canvas canvas, SceneContext ctx) {
    void seaLion(Offset at, double dir, double seed, Color body) {
      final lift = math.max(0.0, math.sin(ctx.time * 0.9 + seed)) * 3;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(dir, 1);
      final fill = Kit.fill(ctx.dusk(body, 0.4));
      canvas.drawOval(Kit.oval(const Offset(0, 4), 18, 8), fill);
      canvas.drawPath(
          Path()
            ..moveTo(-14, 2)
            ..quadraticBezierTo(-22, -12 - lift, -15, -16 - lift)
            ..quadraticBezierTo(-9, -14 - lift, -8, 2)
            ..close(),
          fill);
      canvas.drawCircle(Offset(-16, -13 - lift), 1.4, Kit.fill(const Color(0xFF1C1917)));
      canvas.drawCircle(Offset(-19.5, -11 - lift), 0.9, Kit.fill(const Color(0xFF1C1917)));
      canvas.drawPath(Path()..moveTo(14, 6)..lineTo(22, 2)..lineTo(20, 9)..close(), fill);
      canvas.restore();
    }

    seaLion(const Offset(245, 332), 1, 0, const Color(0xFF78716C));
    seaLion(const Offset(310, 326), -1, 2.2, const Color(0xFFA8A29E));
  }

  void _paintFisher(Canvas canvas, SceneContext ctx, double waterTop) {
    const seat = Offset(378, 318);
    SquirrelPainter.paint(canvas, seat,
        pose: SquirrelPose.idle, dir: -1, scale: 0.6, time: ctx.time, seed: 7,
        look: SquirrelLook(scarf: ctx.frost), art: ctx.art);
    final bob = math.sin(ctx.time * 2.4) * 1.5;
    final tip = seat.translate(-26, -16);
    canvas.drawLine(seat.translate(-4, 0), tip, Kit.stroke(const Color(0xFF78350F), 1.1));
    final bobber = Offset(tip.dx - 10, waterTop + 34 + bob);
    canvas.drawLine(tip, bobber, Kit.stroke(const Color(0x99FFFFFF), 0.5));
    canvas.drawCircle(bobber, 1.8, Kit.fill(const Color(0xFFEF4444)));
  }

  @override
  void dispose() {
    _lighthouse.dispose();
    _jetty.dispose();
  }
}

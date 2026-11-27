import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/squirrel_painter.dart';
import 'scene_art.dart';

/// Alpine Ski-Lift & River Tubing: looping gondola, a carving skier
/// squirrel and tubers drifting down the valley river.
class AlpineScene extends SceneArt {
  final PictureCache _static = PictureCache();

  @override
  void render(Canvas canvas, SceneContext ctx) {
    _static.draw(canvas, (ctx.frost, ctx.twilight), (c) => _paintStatic(c, ctx));
    _paintLift(canvas, ctx);
    _paintSkier(canvas, ctx);
    _paintRiver(canvas, ctx);
  }

  void _paintStatic(Canvas c, SceneContext ctx) {
    // Mountains (lit left faces, shaded right faces)
    void peak(List<Offset> base, Offset apex, Color rock, List<Offset> cap) {
      c.drawPath(Path()..addPolygon([base[0], apex, base[1]], true), Kit.fill(ctx.dusk(rock, 0.45)));
      c.drawPath(Path()..addPolygon([apex, base[1], Offset((apex.dx + base[1].dx) / 2 - 10, base[1].dy)], true),
          Kit.fill(const Color(0x22000000)));
      c.drawPath(Path()..addPolygon(cap, true), Kit.fill(ctx.dusk(const Color(0xFFF8FAFC), 0.35)));
    }

    peak(const [Offset(40, 310), Offset(250, 310)], const Offset(145, 125), const Color(0xFF64748B), const [
      Offset(145, 125), Offset(112, 184), Offset(134, 178), Offset(145, 192), Offset(162, 176), Offset(178, 184),
    ]);
    peak(const [Offset(165, 310), Offset(405, 310)], const Offset(285, 105), const Color(0xFF475569), const [
      Offset(285, 105), Offset(246, 172), Offset(270, 164), Offset(285, 180), Offset(304, 162), Offset(324, 172),
    ]);

    // Pine forest along the foothills
    final pine = Kit.fill(ctx.dusk(ctx.frost ? const Color(0xFF64748B) : const Color(0xFF166534), 0.5));
    final rng = math.Random(21);
    for (var x = 36.0; x < 410; x += 13 + rng.nextDouble() * 8) {
      final h = 16 + rng.nextDouble() * 12;
      final base = 300 + rng.nextDouble() * 6;
      c.drawPath(Path()..addPolygon([Offset(x - 6, base), Offset(x, base - h), Offset(x + 6, base)], true), pine);
      if (ctx.frost) {
        c.drawPath(Path()..addPolygon([Offset(x - 2.5, base - h + 6), Offset(x, base - h), Offset(x + 2.5, base - h + 6)], true),
            Kit.fill(const Color(0xFFFFFFFF)));
      }
    }

    // Valley meadow and river
    c.drawPath(
        Path()
          ..moveTo(30, 295)
          ..quadraticBezierTo(220, 275, 410, 295)
          ..lineTo(410, 385)
          ..lineTo(30, 385)
          ..close(),
        Kit.fill(ctx.land(const Color(0xFF4ADE80), const Color(0xFFF1F5F9), 0.6)));
    final river = Path()
      ..moveTo(30, 318)
      ..quadraticBezierTo(220, 302, 410, 322)
      ..lineTo(410, 356)
      ..quadraticBezierTo(220, 338, 30, 356)
      ..close();
    c.drawPath(river, Kit.fill(ctx.land(const Color(0xFF0EA5E9), const Color(0xFFBAE6FD), 0.5)));
    c.drawPath(
        Path()
          ..moveTo(30, 318)
          ..quadraticBezierTo(220, 302, 410, 322),
        Kit.stroke(ctx.frost ? const Color(0xFFFFFFFF) : const Color(0xFF15803D), 2));

    // Lift towers
    final tower = Kit.stroke(const Color(0xFF1E293B), 2);
    c.drawLine(const Offset(150, 265), const Offset(150, 300), tower);
    c.drawLine(const Offset(285, 132), const Offset(285, 150), tower);
    c.drawLine(const Offset(144, 266), const Offset(156, 264), tower);
  }

  void _paintLift(Canvas canvas, SceneContext ctx) {
    canvas.drawLine(const Offset(150, 265), const Offset(285, 132), Kit.stroke(const Color(0xFF1E293B), 1.5));
    for (var k = 0; k < 2; k++) {
      final u = ((ctx.time / 7) + k * 0.5) % 1.0;
      final p = Offset(150 + u * 135, 265 - u * 133);
      final sway = math.sin(ctx.time * 2.2 + k) * 0.06;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(sway);
      canvas.drawLine(Offset.zero, const Offset(0, 7), Kit.stroke(const Color(0xFF1E293B), 1.2));
      canvas.drawRRect(Kit.rr(const Rect.fromLTWH(-6, 7, 12, 8), 2), Kit.fill(const Color(0xFFEF4444)));
      canvas.drawRect(const Rect.fromLTWH(-4, 8.5, 8, 3), Kit.fill(const Color(0xCCE0F2FE)));
      canvas.drawCircle(const Offset(0, 10), 1.6, Kit.fill(const Color(0xFFC26D38)));
      canvas.restore();
    }
  }

  void _paintSkier(Canvas canvas, SceneContext ctx) {
    final u = ((ctx.time + 2.25) % 5) / 5;
    final carve = math.sin(u * 12);
    final p = Offset(290 - u * 130 + carve * 8, 148 + u * 125);
    // Powder spray trail
    for (var i = 1; i <= 5; i++) {
      final tu = u - i * 0.012;
      if (tu < 0) break;
      final tp = Offset(290 - tu * 130 + math.sin(tu * 12) * 8, 152 + tu * 125);
      canvas.drawCircle(tp, 1.6 - i * 0.2, Kit.fill(Color.fromRGBO(255, 255, 255, 0.7 - i * 0.12)));
    }
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(carve * 0.25);
    canvas.drawLine(const Offset(-6, 4), const Offset(6, 6), Kit.stroke(const Color(0xFFFACC15), 2));
    canvas.restore();
    SquirrelPainter.paint(canvas, p.translate(0, -4),
        pose: SquirrelPose.idle, dir: -1, scale: 0.42, time: ctx.time, seed: 3,
        look: const SquirrelLook(scarf: true), art: ctx.art);
  }

  void _paintRiver(Canvas canvas, SceneContext ctx) {
    final shimmer = Kit.stroke(Color.fromRGBO(255, 255, 255, ctx.frost ? 0.5 : 0.35), 1);
    for (var i = 0; i < 5; i++) {
      final x = 40 + ((ctx.time * 18 + i * 76) % 360);
      final y = 326 + (i % 3) * 8.0;
      canvas.drawLine(Offset(x, y), Offset(x + 12, y), shimmer);
    }
    final phase = ctx.time * 1.6;
    for (var i = 0; i < 2; i++) {
      final x = 55 + ((ctx.time * 28 + i * 170) % 330);
      final y = 334 + math.sin(phase + i) * 3;
      SquirrelPainter.paint(canvas, Offset(x, y - 7),
          pose: SquirrelPose.idle, scale: 0.5, time: ctx.time, seed: i + 5.0,
          look: SquirrelLook(scarf: ctx.frost), art: ctx.art);
      final tube = Kit.oval(Offset(x, y + 2), 11, 5);
      canvas.drawOval(tube, Kit.fill(i == 0 ? const Color(0xFFFB7185) : const Color(0xFFFBBF24)));
      canvas.drawOval(Kit.oval(Offset(x, y + 1), 6, 2.2), Kit.fill(const Color(0x33000000)));
      canvas.drawArc(tube.deflate(1.5), math.pi * 1.1, math.pi * 0.5, false,
          Kit.stroke(const Color(0x88FFFFFF), 1));
    }
  }

  @override
  void dispose() => _static.dispose();
}

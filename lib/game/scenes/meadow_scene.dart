import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../art/squirrel_painter.dart';
import 'professor_hoot.dart';
import 'scene_art.dart';

/// Default scene: the Great Oak meadow with upgrade lanterns, Professor
/// Hoot, the hammock napper and the acorn-tossing stump squirrel.
class MeadowScene extends SceneArt {
  final PictureCache _ground = PictureCache();
  final PictureCache _canopy = PictureCache();

  static const _tufts = [Offset(60, 362), Offset(150, 368), Offset(268, 366), Offset(392, 360)];

  @override
  void render(Canvas canvas, SceneContext ctx) {
    final key = (ctx.frost, ctx.twilight);
    _ground.draw(canvas, key, (c) => _paintGround(c, ctx));
    if (!ctx.frost) _paintTufts(canvas, ctx);
    canvas.save();
    canvas.translate(math.sin(ctx.time * 0.7) * 0.9, math.sin(ctx.time * 0.5) * 0.4);
    _canopy.draw(canvas, key, (c) => _paintCanopy(c, ctx));
    canvas.restore();
    _paintLanterns(canvas, ctx);
    ProfessorHoot.paint(canvas, ctx);
    _paintHammock(canvas, ctx);
    _paintStump(canvas, ctx);
  }

  Color _hill(SceneContext ctx, Color normal, Color frost, Color dusk) =>
      ctx.frost ? frost : (ctx.twilight ? dusk : normal);

  void _paintGround(Canvas c, SceneContext ctx) {
    // Distant tree line
    final treeLine = Kit.fill(_hill(ctx, const Color(0xFF34A35A), const Color(0xFFB8C4D4), const Color(0xFF172033)));
    for (var x = 30.0; x < 420; x += 21) {
      c.drawCircle(Offset(x, 316 + math.sin(x * 0.13) * 5), 12 + (x % 3) * 2, treeLine);
    }
    final back = Path()
      ..moveTo(30, 330)
      ..quadraticBezierTo(145, 280, 250, 320)
      ..quadraticBezierTo(355, 360, 410, 310)
      ..lineTo(410, 385)
      ..lineTo(30, 385)
      ..close();
    c.drawPath(back, Kit.fill(_hill(ctx, Pal.hillBack, const Color(0xFFCBD5E1), const Color(0xFF1E293B))));
    final front = Path()
      ..moveTo(30, 348)
      ..quadraticBezierTo(180, 315, 320, 342)
      ..quadraticBezierTo(460, 369, 410, 335)
      ..lineTo(410, 385)
      ..lineTo(30, 385)
      ..close();
    c.drawPath(front, Kit.fill(_hill(ctx, Pal.hillFront, Pal.frostGround, const Color(0xFF14532D))));
    c.drawPath(
        Path()
          ..moveTo(30, 348)
          ..quadraticBezierTo(180, 315, 320, 342),
        Kit.stroke(ctx.frost ? const Color(0xFFFFFFFF) : const Color(0x55FFFFFF), 2));

    // Meadow flowers (snow mounds in frost)
    final rng = math.Random(5);
    for (var i = 0; i < 16; i++) {
      final p = Offset(44 + rng.nextDouble() * 352, 352 + rng.nextDouble() * 26);
      if (ctx.frost) {
        c.drawOval(Kit.oval(p, 5, 2), Kit.fill(const Color(0xFFFFFFFF)));
      } else {
        final petal = [const Color(0xFFFDA4AF), const Color(0xFFFFFFFF), const Color(0xFFFDE047)][i % 3];
        for (var k = 0; k < 4; k++) {
          final a = k * math.pi / 2;
          c.drawCircle(p + Offset(math.cos(a), math.sin(a)) * 1.4, 1.2, Kit.fill(ctx.dusk(petal, 0.4)));
        }
        c.drawCircle(p, 0.9, Kit.fill(const Color(0xFFF59E0B)));
      }
    }

    // Great Oak limbs
    final limb = Kit.fill(ctx.dusk(Pal.limb, 0.35));
    final left = Path()
      ..moveTo(30, 165)
      ..quadraticBezierTo(115, 175, 162, 205)
      ..lineTo(154, 216)
      ..quadraticBezierTo(105, 188, 30, 182)
      ..close();
    final right = Path()
      ..moveTo(410, 175)
      ..quadraticBezierTo(335, 185, 288, 210)
      ..lineTo(295, 220)
      ..quadraticBezierTo(345, 196, 410, 192)
      ..close();
    for (final l in [left, right]) {
      c.drawPath(l, limb);
      c.drawPath(l, Kit.stroke(Kit.a(Pal.limbDark, 0.8), 1.2));
    }
    final bark = Kit.stroke(Kit.a(Pal.limbDark, 0.7), 0.8);
    c.drawPath(Path()..moveTo(44, 172)..quadraticBezierTo(100, 180, 140, 200), bark);
    c.drawPath(Path()..moveTo(396, 182)..quadraticBezierTo(345, 190, 305, 210), bark);
    if (ctx.frost) {
      c.drawPath(Path()..moveTo(30, 165)..quadraticBezierTo(115, 175, 162, 205),
          Kit.stroke(const Color(0xFFFFFFFF), 3));
      c.drawPath(Path()..moveTo(410, 175)..quadraticBezierTo(335, 185, 288, 210),
          Kit.stroke(const Color(0xFFFFFFFF), 3));
    }
  }

  void _paintCanopy(Canvas c, SceneContext ctx) {
    final blobs = [
      (const Offset(95, 115), 56.0, ctx.frost ? Pal.frostCanopyDark : Pal.canopyDark),
      (const Offset(165, 95), 52.0, ctx.frost ? Pal.frostCanopyLight : Pal.canopyMid),
      (const Offset(345, 118), 54.0, ctx.frost ? Pal.frostCanopyDark : Pal.canopyDark),
      (const Offset(285, 98), 46.0, ctx.frost ? Pal.frostCanopyLight : Pal.canopyLight),
    ];
    final rng = math.Random(9);
    for (final (center, r, color) in blobs) {
      final base = ctx.dusk(color, 0.5);
      final shade = Color.lerp(base, const Color(0xFF052E16), ctx.frost ? 0.18 : 0.35)!;
      final light = Color.lerp(base, const Color(0xFFFFFFFF), ctx.frost ? 0.35 : 0.16)!;
      // Bumpy cloud-like crown: a core plus scalloped perimeter puffs.
      final puffs = <(Offset, double)>[(center, r * 0.74)];
      for (var k = 0; k < 9; k++) {
        final a = k / 9 * math.pi * 2 + rng.nextDouble() * 0.3;
        puffs.add((center + Offset(math.cos(a), math.sin(a) * 0.9) * (r * 0.56), r * (0.38 + rng.nextDouble() * 0.1)));
      }
      for (final (p, pr) in puffs) {
        c.drawCircle(p.translate(2.5, 4), pr, Kit.fill(shade));
      }
      for (final (p, pr) in puffs) {
        c.drawCircle(p, pr, Kit.fill(base));
      }
      // Sunlit upper-left puffs
      for (final (p, pr) in puffs.skip(1)) {
        if (p.dx < center.dx + r * 0.1 && p.dy < center.dy + r * 0.05) {
          c.drawCircle(p.translate(-pr * 0.18, -pr * 0.2), pr * 0.62, Kit.fill(light));
        }
      }
      // Scalloped leaf-clump strokes for texture (not dots)
      final scallop = Kit.stroke(Kit.a(shade, 0.55), 1.5);
      for (var i = 0; i < 9; i++) {
        final a = rng.nextDouble() * math.pi * 2;
        final d = rng.nextDouble() * r * 0.7;
        final p = center + Offset(math.cos(a), math.sin(a)) * d;
        final s = 5 + rng.nextDouble() * 4;
        c.drawArc(Kit.oval(p, s, s * 0.8), 0.2, math.pi - 0.4, false, scallop);
      }
      if (ctx.frost) {
        final snow = Kit.fill(const Color(0xF2FFFFFF));
        for (final (p, pr) in puffs) {
          if (p.dy <= center.dy - r * 0.1 || identical(p, center)) {
            c.drawOval(Kit.oval(p.translate(0, -pr * 0.55), pr * 0.78, pr * 0.36), snow);
          }
        }
      }
    }
  }

  void _paintTufts(Canvas canvas, SceneContext ctx) {
    final blade = Kit.stroke(ctx.dusk(const Color(0xFF16A34A), 0.5), 1.3);
    for (var i = 0; i < _tufts.length; i++) {
      final base = _tufts[i];
      final sway = math.sin(ctx.time * 1.6 + i * 1.7) * 2.2;
      for (final dx in const [-3.0, 0.0, 3.0]) {
        canvas.drawPath(
            Path()
              ..moveTo(base.dx + dx, base.dy)
              ..quadraticBezierTo(base.dx + dx * 1.5, base.dy - 6, base.dx + dx * 2 + sway, base.dy - 10 - dx.abs()),
            blade);
      }
    }
  }

  void _paintLanterns(Canvas canvas, SceneContext ctx) {
    final level = ctx.snap.oakLevel;
    final golden = level >= 4;
    final body = golden ? const Color(0xFFFDE047) : const Color(0xFFFACC15);
    void lantern(Offset top, double seed) {
      final swing = math.sin(ctx.time * 1.4 + seed) * 0.06;
      canvas.save();
      canvas.translate(top.dx, top.dy);
      canvas.rotate(swing);
      canvas.drawLine(Offset.zero, const Offset(0, 16), Kit.stroke(Pal.outline, 1.5));
      final flicker = 0.32 + 0.06 * math.sin(ctx.time * 8 + seed * 3);
      Kit.glow(canvas, const Offset(0, 21), golden ? 20 : 13, const Color(0xFFFEF08A),
          (ctx.twilight ? 0.75 : 0.45) + flicker * 0.3);
      canvas.drawRRect(Kit.rr(const Rect.fromLTWH(-4, 16, 8, 9), 2), Kit.fill(body));
      canvas.drawRRect(Kit.rr(const Rect.fromLTWH(-4, 16, 8, 9), 2), Kit.stroke(Pal.acornCap, 1.1));
      canvas.drawLine(const Offset(-4.5, 16), const Offset(4.5, 16), Kit.stroke(Pal.acornCap, 1.6));
      canvas.restore();
    }

    lantern(const Offset(128, 194), 0);
    if (level >= 2) lantern(const Offset(70, 176), 1.7);
    if (level >= 3) {
      final bunting = Path()
        ..moveTo(40, 170)
        ..quadraticBezierTo(95, 196, 150, 202);
      canvas.drawPath(bunting, Kit.stroke(const Color(0xFF78350F), 0.8));
      const flags = [Color(0xFFF87171), Color(0xFFFDE047), Color(0xFF38BDF8), Color(0xFF4ADE80)];
      for (var i = 0; i < 7; i++) {
        final u = (i + 0.5) / 7;
        final x = 40 + 110 * u;
        final y = (1 - u) * (1 - u) * 170 + 2 * (1 - u) * u * 196 + u * u * 202;
        final flutter = math.sin(ctx.time * 3 + i) * 0.8;
        canvas.drawPath(
            Path()
              ..moveTo(x - 3.5, y)
              ..lineTo(x + 3.5, y)
              ..lineTo(x + flutter, y + 7)
              ..close(),
            Kit.fill(ctx.dusk(flags[i % flags.length], 0.3)));
      }
    }
    if (golden) {
      lantern(const Offset(388, 186), 3.1);
      Kit.sparkle(canvas, const Offset(392, 172), 2.5 + math.sin(ctx.time * 3) * 1.2, const Color(0xFFFFF7AE));
    }
  }

  void _paintHammock(Canvas canvas, SceneContext ctx) {
    canvas.save();
    canvas.translate(332, 212);
    canvas.rotate(math.sin(ctx.time * 2 * math.pi / 3.6) * 0.035);
    canvas.translate(-332, -212);
    canvas.drawPath(
        Path()
          ..moveTo(300, 202)
          ..quadraticBezierTo(332, 232, 365, 194),
        Kit.stroke(const Color(0xFF78350F), 1.4));
    final leaf = Path()
      ..moveTo(304, 205)
      ..quadraticBezierTo(332, 230, 361, 198)
      ..quadraticBezierTo(332, 214, 304, 205)
      ..close();
    SquirrelPainter.paint(canvas, const Offset(332, 205),
        pose: SquirrelPose.sleep, scale: 0.74, time: ctx.time, seed: 2.2,
        look: SquirrelLook(scarf: ctx.frost), art: ctx.art);
    canvas.drawPath(leaf, Kit.fill(ctx.land(const Color(0xFF65A30D), const Color(0xFF9CAF88), 0.4)));
    canvas.drawPath(
        Path()
          ..moveTo(308, 207)
          ..quadraticBezierTo(332, 222, 357, 201),
        Kit.stroke(const Color(0x553F6212), 0.8));
    canvas.restore();
  }

  void _paintStump(Canvas canvas, SceneContext ctx) {
    canvas.save();
    canvas.translate(112, 356);
    canvas.drawRRect(Kit.rr(const Rect.fromLTWH(-10, -4, 20, 13), 3), Kit.fill(ctx.dusk(const Color(0xFF78350F), 0.3)));
    canvas.drawOval(Kit.oval(const Offset(0, -4), 10, 3.2), Kit.fill(ctx.dusk(const Color(0xFFD97706), 0.3)));
    canvas.drawOval(Kit.oval(const Offset(0, -4), 5.5, 1.7), Kit.stroke(const Color(0x88783510), 0.7));
    if (ctx.frost) {
      canvas.drawOval(Kit.oval(const Offset(-2, -5), 8, 2.2), Kit.fill(const Color(0xF2FFFFFF)));
    }
    SquirrelPainter.paint(canvas, const Offset(0, -17),
        pose: SquirrelPose.toss, scale: 0.86, time: ctx.time, seed: 0.4,
        look: SquirrelLook(scarf: ctx.frost), art: ctx.art);
    canvas.restore();
  }

  @override
  void dispose() {
    _ground.dispose();
    _canopy.dispose();
  }
}

import 'dart:math' as math;
import 'dart:ui';

import '../../models/window_scene.dart';
import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../art/squirrel_painter.dart';
import '../diorama_event.dart';
import '../layout.dart';
import 'scene_art.dart';

/// The Free Cash Acorn Pile — grows one acorn at a time toward its target.
class AcornPile {
  double _shown = 0;
  double _dropT = 1;

  void update(double dt, int target) {
    if (_shown.round() != target) {
      _shown += (target > _shown ? 1 : -1) * dt * 14;
      if ((target - _shown).abs() < 0.05) _shown = target.toDouble();
      _dropT = 0;
    }
    _dropT = math.min(1, _dropT + dt * 3);
  }

  void render(Canvas canvas, SceneContext ctx) {
    final o = StudyLayout.cashPile;
    final squash = ctx.poke(DioramaTarget.cashPile);
    canvas.save();
    canvas.translate(o.dx, o.dy + 5);
    canvas.scale(1 + squash * 0.08, 1 - squash * 0.12);
    canvas.translate(0, -5);
    canvas.drawOval(Kit.oval(const Offset(0, 5), 40, 8), Kit.fill(const Color(0x591C110A)));
    final count = _shown.floor();
    final custom = ctx.art.prop('acorn');
    for (var i = 0; i < count; i++) {
      final row = i ~/ 5;
      final col = i % 5 - 2;
      var p = Offset(col * 12.0 + (row % 2) * 4, -row * 7.5);
      if (i == count - 1 && _dropT < 1) {
        p = p.translate(0, -18 * (1 - Ease.easeOutBounce(_dropT)));
      }
      if (custom != null) {
        canvas.drawImageRect(custom,
            Rect.fromLTWH(0, 0, custom.width.toDouble(), custom.height.toDouble()),
            Kit.oval(p, 5.5, 6.5), Paint()..filterQuality = FilterQuality.medium);
      } else {
        Kit.acorn(canvas, p, rx: 5, ry: 6);
      }
    }
    if (count > 0 && !ctx.frost) {
      final glint = (ctx.time * 0.5) % 3.0;
      if (glint < 0.5) {
        Kit.sparkle(canvas, Offset(-8 + glint * 30, -12), 3 * math.sin(glint / 0.5 * math.pi),
            const Color(0xEEFFFFFF));
      }
    }
    canvas.restore();
  }
}

/// Tiny easing helpers (avoids a Flutter dependency inside painters).
abstract final class Ease {
  static double easeOutBounce(double t) {
    if (t < 1 / 2.75) return 7.5625 * t * t;
    if (t < 2 / 2.75) {
      final u = t - 1.5 / 2.75;
      return 7.5625 * u * u + 0.75;
    }
    if (t < 2.5 / 2.75) {
      final u = t - 2.25 / 2.75;
      return 7.5625 * u * u + 0.9375;
    }
    final u = t - 2.625 / 2.75;
    return 7.5625 * u * u + 0.984375;
  }

  static double easeInOut(double t) => t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;
}

/// The Bills Campfire with its tea-sipping squirrel (meadow).
abstract final class Campfire {
  static void render(Canvas canvas, SceneContext ctx) {
    final o = StudyLayout.campfire;
    final phase = ctx.time * 1.6;
    final squash = ctx.poke(DioramaTarget.campfire);
    canvas.save();
    canvas.translate(o.dx, o.dy);
    final flicker = 0.85 + 0.15 * math.sin(ctx.time * 7.3) * math.sin(ctx.time * 3.1);
    Kit.glow(canvas, const Offset(0, -4), 30 + flicker * 6, Pal.fireGlow, 0.7 * flicker);
    // Stone ring
    for (var i = 0; i < 7; i++) {
      final a = math.pi * (i / 6);
      canvas.drawOval(Kit.oval(Offset(math.cos(a) * 15, 6 - math.sin(a) * 2.5 + 2), 3.4, 2.4),
          Kit.fill(i.isEven ? const Color(0xFF78716C) : const Color(0xFF57534E)));
    }
    // Crossed logs
    for (final angle in const [0.244, -0.244]) {
      canvas.save();
      canvas.rotate(angle);
      canvas.drawRRect(Kit.rr(const Rect.fromLTWH(-12, 2, 24, 4.5), 2),
          Kit.fill(angle > 0 ? const Color(0xFF5C3419) : Pal.outline));
      canvas.restore();
    }
    canvas.save();
    canvas.translate(0, 2);
    canvas.scale(1 - squash * 0.15, 1 + squash * 0.25);
    canvas.translate(0, -2);
    final h1 = -18 - math.sin(phase * 2) * 2.5;
    canvas.drawPath(
        Path()
          ..moveTo(0, h1)
          ..cubicTo(8, -9, 9, 1, 0, 2)
          ..cubicTo(-9, 1, -8, -9, 0, h1)
          ..close(),
        Kit.fill(Pal.fireOuter));
    final h2 = -12 - math.cos(phase * 2) * 2;
    canvas.drawPath(
        Path()
          ..moveTo(0, h2)
          ..cubicTo(4.5, -6, 4.5, 0, 0, 1)
          ..cubicTo(-4.5, 0, -4.5, -6, 0, h2)
          ..close(),
        Kit.fill(Pal.fireInner));
    canvas.restore();
    // Rising embers
    for (var i = 0; i < 6; i++) {
      final p = (ctx.time * 0.55 + i / 6) % 1.0;
      final x = math.sin(i * 7.0 + ctx.time * 2) * 6;
      canvas.drawCircle(Offset(x, -12 - p * 28), 1.1 * (1 - p) + 0.3,
          Kit.fill(Color.fromRGBO(253, 186, 116, 1 - p)));
    }
    if (ctx.snap.scene == WindowScene.meadow) {
      SquirrelPainter.paint(canvas, const Offset(-25, -9),
          pose: SquirrelPose.tea, scale: 0.88, time: ctx.time, seed: 1.3,
          look: SquirrelLook(scarf: ctx.frost), art: ctx.art);
    }
    canvas.restore();
  }
}

/// Multi-squirrel acorn delivery sprint on payday.
class PaydayRush {
  double _elapsed = 0;
  bool _active = false;

  void update(double dt, bool active) {
    if (active && !_active) _elapsed = 0;
    _active = active;
    if (active) _elapsed += dt;
  }

  void render(Canvas canvas, SceneContext ctx) {
    if (!_active) return;
    final fadeIn = math.min(1.0, _elapsed * 3);
    for (var i = 0; i < 3; i++) {
      final x = 48 + ((_elapsed * 110 + i * 38) % 140);
      final hopPhase = ctx.time * 9 + i * 1.7;
      final hop = -math.sin(hopPhase).abs() * 3.2 * fadeIn;
      SquirrelPainter.paint(canvas, Offset(x, 352 - (i % 2) * 5.0),
          pose: SquirrelPose.hauler, scale: 0.82, hop: hop,
          squash: math.sin(hopPhase).abs() < 0.2 ? 0.35 : 0,
          time: ctx.time, seed: i * 0.9,
          look: SquirrelLook(acorn: true, golden: i == 0, scarf: ctx.frost),
          art: ctx.art);
    }
  }
}

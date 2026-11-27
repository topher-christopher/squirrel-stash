import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import 'scene_art.dart';

class _Cloud {
  _Cloud(this.x, this.y, this.scale, this.speed);
  double x;
  final double y;
  final double scale;
  final double speed;
}

/// Day / Frost / Twilight sky with sun or moon, drifting clouds and stars.
class SkyPainter {
  final List<_Cloud> _clouds = [
    _Cloud(70, 64, 1.0, 4.2),
    _Cloud(250, 46, 0.8, 3.1),
    _Cloud(330, 104, 1.15, 5.4),
    _Cloud(160, 128, 0.7, 2.6),
  ];

  static const _stars = [
    Offset(88, 76), Offset(348, 72), Offset(285, 98), Offset(150, 48),
    Offset(210, 88), Offset(372, 132), Offset(60, 120), Offset(250, 36),
    Offset(118, 140), Offset(318, 40),
  ];

  static const Rect _skyRect = Rect.fromLTWH(35, 20, 370, 365);

  void update(double dt) {
    for (final c in _clouds) {
      c.x += c.speed * dt;
      if (c.x > 440) c.x = -60;
    }
  }

  void render(Canvas canvas, SceneContext ctx) {
    final colors = ctx.twilight
        ? Pal.skyTwilight
        : (ctx.frost ? Pal.skyFrost : Pal.skyDay);
    canvas.drawRect(
        _skyRect,
        Kit.vertical(_skyRect, colors, ctx.twilight ? const [0, 0.55, 1] : const [0, 0.65, 1]));

    const sun = Offset(232, 62);
    if (ctx.twilight) {
      for (var i = 0; i < _stars.length; i++) {
        final tw = 0.45 + 0.55 * math.sin(ctx.time * 1.8 + i * 2.1).abs();
        canvas.drawCircle(_stars[i], i.isEven ? 1.6 : 1.2,
            Kit.fill(Color.fromRGBO(254, 240, 138, tw)));
      }
      Kit.glow(canvas, sun, 34, const Color(0xFFFDE68A), 0.25);
      canvas.drawCircle(sun, 12, Kit.fill(const Color(0xFFFEF9C3)));
      canvas.drawCircle(sun.translate(5, -3), 10.5, Kit.fill(colors.first));
    } else {
      final pale = ctx.frost;
      Kit.glow(canvas, sun, 46, pale ? const Color(0xFFFFFFFF) : const Color(0xFFFDE68A),
          pale ? 0.5 : 0.55);
      canvas.drawCircle(sun, 13, Kit.fill(pale ? const Color(0xFFF8FAFC) : const Color(0xFFFDE047)));
      canvas.drawCircle(sun.translate(-3, -3), 5, Kit.fill(const Color(0x66FFFFFF)));
    }

    final cloudColor = ctx.twilight
        ? const Color(0x553730A3)
        : (ctx.frost ? const Color(0xEEFFFFFF) : const Color(0xE6FFFFFF));
    final cloudShade = ctx.twilight ? const Color(0x00000000) : const Color(0x22B6D4FE);
    for (final c in _clouds) {
      _cloud(canvas, Offset(c.x, c.y), c.scale, cloudColor, cloudShade);
    }
  }

  static void _cloud(Canvas canvas, Offset o, double s, Color color, Color shade) {
    final p = Kit.fill(color);
    canvas.drawOval(Kit.oval(o.translate(0, 4 * s), 26 * s, 7 * s), Kit.fill(shade));
    canvas.drawCircle(o.translate(-14 * s, 0), 9 * s, p);
    canvas.drawCircle(o.translate(-2 * s, -6 * s), 12 * s, p);
    canvas.drawCircle(o.translate(12 * s, -1 * s), 9.5 * s, p);
    canvas.drawOval(Kit.oval(o.translate(0, 3 * s), 25 * s, 6.5 * s), p);
  }
}

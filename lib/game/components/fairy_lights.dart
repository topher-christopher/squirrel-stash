import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import 'diorama_layer.dart';

/// Golden Leaf decor: a garland of twinkling fairy lights draped in two
/// swags across the top of the arched window (drawn over the frame).
class FairyLights extends DioramaLayer {
  FairyLights() : super(priority: 25);

  static const _colors = [Color(0xFFFDE047), Color(0xFF38BDF8), Color(0xFF4ADE80), Color(0xFFF9A8D4)];

  // Two quadratic swags hanging from the keystone (start, control, end).
  static const _swags = [
    (Offset(12, 40), Offset(116, 96), Offset(220, 26)),
    (Offset(220, 26), Offset(324, 96), Offset(428, 40)),
  ];

  static Offset _q(Offset a, Offset c, Offset b, double u) =>
      a * ((1 - u) * (1 - u)) + c * (2 * (1 - u) * u) + b * (u * u);

  @override
  void render(Canvas canvas) {
    if (!snap.fairyLights) return;
    final wire = Kit.stroke(const Color(0xFF5C2E10), 1.4);
    var bulb = 0;
    for (final (a, c, b) in _swags) {
      canvas.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy),
          wire);
      for (var i = 1; i < 8; i++) {
        final p = _q(a, c, b, i / 8);
        final drop = p.translate(0, 4.5);
        final twinkle = 0.5 + 0.5 * math.sin(t * 2.2 + bulb * 1.3);
        final color = _colors[bulb % _colors.length];
        canvas.drawLine(p, drop.translate(0, -2), Kit.stroke(const Color(0xFF5C2E10), 0.9));
        Kit.glow(canvas, drop, 9 + twinkle * 3, color, 0.18 + twinkle * 0.22);
        canvas.drawOval(Kit.oval(drop, 2.4, 3), Kit.fill(color));
        canvas.drawCircle(drop.translate(-0.8, -1), 0.8, Kit.fill(const Color(0xCCFFFFFF)));
        bulb++;
      }
    }
  }
}

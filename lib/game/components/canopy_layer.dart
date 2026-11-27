import 'dart:math' as math;
import 'dart:ui';

import '../../core/dates.dart';
import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../layout.dart';
import 'diorama_layer.dart';

/// The Great Oak's sunlit crown: swaying foliage clusters (seasonal when
/// that Grand Tree upgrade is active, frosted during the Frostline) and the
/// great limbs reaching out from the top of the trunk.
class CanopyLayer extends DioramaLayer {
  CanopyLayer() : super(priority: 8);

  /// (center, radius, sway phase) — back row first.
  static const _clusters = [
    (Offset(60, 120), 78.0, 0.0), (Offset(170, 70), 84.0, 1.1), (Offset(300, 44), 92.0, 2.3),
    (Offset(430, 70), 84.0, 0.7), (Offset(545, 120), 78.0, 1.9), (Offset(30, 210), 54.0, 2.8),
    (Offset(570, 205), 56.0, 0.4), (Offset(120, 178), 66.0, 1.5), (Offset(480, 176), 66.0, 2.1),
    (Offset(240, 150), 60.0, 0.9), (Offset(360, 150), 60.0, 2.6),
  ];

  List<Color> _palette() {
    if (snap.frost) return const [Pal.frostCanopyDark, Color(0xFFB6C2D1), Pal.frostCanopyLight];
    if (!snap.seasonal) return const [Pal.canopyDark, Pal.canopyMid, Pal.canopyLight];
    return switch (snap.season) {
      Season.spring => const [Color(0xFF15803D), Color(0xFF22C55E), Color(0xFFF9A8D4)],
      Season.summer => const [Pal.canopyDark, Pal.canopyMid, Pal.canopyLight],
      Season.fall => const [Color(0xFF9A3412), Color(0xFFEA580C), Color(0xFFFBBF24)],
      Season.winter => const [Color(0xFF64748B), Color(0xFF94A3B8), Color(0xFFF1F5F9)],
    };
  }

  @override
  void render(Canvas canvas) {
    _limbs(canvas);
    final colors = _palette();
    final dusk = snap.twilight ? 0.45 : 0.0;
    Color tone(Color c) => dusk == 0 ? c : Color.lerp(c, Pal.twilightInk, dusk)!;
    const scale = [1.0, 0.8, 0.46];
    const lift = [0.0, -8.0, -22.0];
    for (var pass = 0; pass < 3; pass++) {
      for (final (center, radius, phase) in _clusters) {
        final sway = math.sin(t * 0.6 + phase) * 3.2;
        final c = center.translate(sway - pass * 8, lift[pass] * radius / 80);
        final color = tone(colors[pass]);
        canvas.drawCircle(c, radius * scale[pass], Kit.fill(pass == 2 ? Kit.a(color, 0.7) : color));
      }
    }
    // Leaf speckles & blossoms catching light
    final rng = math.Random(9);
    for (var k = 0; k < 70; k++) {
      final p = Offset(rng.nextDouble() * 600, 10 + rng.nextDouble() * 210);
      final sway = math.sin(t * 0.6 + k) * 2;
      final accent = snap.seasonal && snap.season == Season.spring && k % 3 == 0
          ? const Color(0xFFFBCFE8)
          : Kit.a(tone(colors[2]), 0.85);
      canvas.drawOval(Kit.oval(p.translate(sway, 0), 3.2, 1.8), Kit.fill(accent));
    }
    if (snap.frost) {
      // Snow resting on the crown tops
      for (final (center, radius, phase) in _clusters.take(5)) {
        final sway = math.sin(t * 0.6 + phase) * 3.2;
        canvas.drawArc(Rect.fromCircle(center: center.translate(sway, 0), radius: radius * 0.92),
            math.pi * 1.15, math.pi * 0.7, false, Kit.stroke(const Color(0xF2FFFFFF), 8));
      }
    }
  }

  void _limbs(Canvas c) {
    final bark = Kit.stroke(Pal.limbDark, 22);
    final barkLight = Kit.stroke(Pal.limb, 16);
    // The two great branches (owl lantern left, bird feeder right) plus the
    // two uprights holding up the Canopy Treasury.
    final limbs = [
      TreeLayout.leftLimb,
      TreeLayout.rightLimb,
      (const Offset(260, 246), const Offset(240, 170), const Offset(250, 90)),
      (const Offset(340, 246), const Offset(370, 170), const Offset(360, 90)),
    ];
    for (final (a, ctrl, b) in limbs) {
      final p = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      c.drawPath(p, bark);
      c.drawPath(p, barkLight);
    }
    // Trunk top flaring into the limbs
    c.drawPath(
        Path()
          ..moveTo(52, 260)
          ..quadraticBezierTo(150, 214, 230, 230)
          ..lineTo(370, 230)
          ..quadraticBezierTo(450, 214, 548, 260)
          ..close(),
        Kit.fill(Pal.bark));
  }
}

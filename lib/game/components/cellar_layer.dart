import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../layout.dart';
import 'diorama_layer.dart';

/// Cutaway root cellar below the floorboards (static, cached): layered
/// earth, pebbles, winding oak roots, the floor beam and the brass acorn
/// chute with its wooden ladder.
class CellarLayer extends DioramaLayer {
  CellarLayer() : super(priority: 50);

  final PictureCache _cache = PictureCache();

  @override
  void render(Canvas canvas) => _cache.draw(canvas, 'cellar', _paint);

  void _paint(Canvas c) {
    const earth = Rect.fromLTWH(0, 512, 440, 308);
    c.drawRect(earth, Kit.vertical(earth, const [Pal.earthTop, Pal.earthBottom]));
    // Strata bands
    for (final (y, alpha) in const [(600.0, 0.12), (668.0, 0.18), (760.0, 0.14)]) {
      c.drawPath(
          Path()
            ..moveTo(0, y)
            ..quadraticBezierTo(110, y - 6, 220, y + 2)
            ..quadraticBezierTo(330, y + 8, 440, y - 2),
          Kit.stroke(Color.fromRGBO(0, 0, 0, alpha), 7));
    }
    final rng = math.Random(31);
    for (var i = 0; i < 110; i++) {
      final p = Offset(rng.nextDouble() * 440, 520 + rng.nextDouble() * 296);
      c.drawCircle(p, 0.6 + rng.nextDouble() * 1.1,
          Kit.fill(Color.fromRGBO(120, 72, 40, 0.25 + rng.nextDouble() * 0.3)));
    }
    for (var i = 0; i < 16; i++) {
      final p = Offset(rng.nextDouble() * 440, 530 + rng.nextDouble() * 280);
      c.drawOval(Kit.oval(p, 3 + rng.nextDouble() * 4, 2 + rng.nextDouble() * 2),
          Kit.fill(Color.fromRGBO(87, 83, 78, 0.35 + rng.nextDouble() * 0.25)));
    }

    // Winding oak roots descending from the floorboards
    final roots = [
      (const Offset(40, 512), const Offset(10, 600), const Offset(30, 690), 7.0),
      (const Offset(130, 512), const Offset(150, 580), const Offset(120, 660), 5.0),
      (const Offset(300, 512), const Offset(270, 590), const Offset(300, 670), 5.5),
      (const Offset(410, 512), const Offset(436, 610), const Offset(405, 700), 7.0),
      (const Offset(220, 668), const Offset(200, 720), const Offset(150, 812), 4.0),
      (const Offset(220, 668), const Offset(250, 730), const Offset(300, 812), 4.0),
    ];
    for (final (a, ctrl, b, w) in roots) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      c.drawPath(path, Kit.stroke(Pal.rootDark, w + 2));
      c.drawPath(path, Kit.stroke(Pal.root, w));
      c.drawPath(path, Kit.stroke(const Color(0x22FDE68A), w * 0.25));
    }

    // Floor beam (planks with nail heads)
    const beam = Rect.fromLTWH(0, 506, 440, 10);
    c.drawRect(beam, Kit.vertical(beam, const [Color(0xFF3B1E0B), Pal.beam]));
    for (var x = 0.0; x < 440; x += 55) {
      c.drawLine(Offset(x, 506), Offset(x, 516), Kit.stroke(const Color(0x66000000), 1));
      c.drawCircle(Offset(x + 6, 511), 1, Kit.fill(const Color(0xFF78716C)));
      c.drawCircle(Offset(x + 49, 511), 1, Kit.fill(const Color(0xFF78716C)));
    }
    c.drawLine(const Offset(0, 516), const Offset(440, 516), Kit.stroke(Pal.beam, 2));

    // Brass acorn chute & ladder
    const chute = StudyLayout.chute;
    c.drawRect(chute, Kit.fill(Pal.chuteShaft));
    c.drawRect(chute, Kit.vertical(chute, const [Color(0x44000000), Color(0x00000000)]));
    final rail = Kit.stroke(Pal.rail, 3);
    c.drawLine(const Offset(210, 512), const Offset(210, 668), rail);
    c.drawLine(const Offset(230, 512), const Offset(230, 668), rail);
    for (var y = 526.0; y <= 658; y += 22) {
      c.drawLine(Offset(210, y), Offset(230, y), Kit.stroke(Pal.rung, 2.2));
    }
    // Brass funnel mouth at the floor
    c.drawPath(
        Path()
          ..moveTo(200, 506)
          ..lineTo(240, 506)
          ..lineTo(233, 518)
          ..lineTo(207, 518)
          ..close(),
        Kit.vertical(const Rect.fromLTWH(200, 506, 40, 12), const [Color(0xFFFBBF24), Color(0xFFB45309)]));
    c.drawOval(Kit.oval(const Offset(220, 668), 16, 4), Kit.fill(const Color(0x55000000)));
  }

  @override
  void onRemove() {
    _cache.dispose();
    super.onRemove();
  }
}

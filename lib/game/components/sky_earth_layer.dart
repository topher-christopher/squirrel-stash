import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../layout.dart';
import 'diorama_layer.dart';

class _Cloud {
  _Cloud(this.x, this.y, this.scale, this.speed);
  double x;
  final double y;
  final double scale;
  final double speed;
}

/// Day / Frost / Twilight sky with sun or moon, drifting clouds, distant
/// meadow hills at the horizon, and the cutaway earth below the grass line.
class SkyEarthLayer extends DioramaLayer {
  SkyEarthLayer() : super(priority: 0);

  final PictureCache _earth = PictureCache();
  final List<_Cloud> _clouds = [
    _Cloud(40, 40, 1.0, 4.2),
    _Cloud(420, 26, 0.8, 3.1),
    _Cloud(520, 230, 1.1, 5.4),
    _Cloud(60, 300, 0.7, 2.6),
  ];

  static const _stars = [
    Offset(28, 30), Offset(580, 44), Offset(560, 280), Offset(16, 260),
    Offset(590, 160), Offset(10, 120), Offset(300, 12), Offset(470, 12),
  ];

  @override
  void update(double dt) {
    for (final c in _clouds) {
      c.x += c.speed * dt;
      if (c.x > TreeLayout.width + 60) c.x = -60;
    }
  }

  @override
  void render(Canvas canvas) {
    const sky = Rect.fromLTWH(0, 0, TreeLayout.width, TreeLayout.groundY);
    final colors = snap.twilight ? Pal.skyTwilight : (snap.frost ? Pal.skyFrost : Pal.skyDay);
    canvas.drawRect(sky, Kit.vertical(sky, colors, const [0, 0.55, 1]));
    const sun = Offset(560, 70);
    if (snap.twilight) {
      for (var i = 0; i < _stars.length; i++) {
        final tw = 0.45 + 0.55 * math.sin(t * 1.8 + i * 2.1).abs();
        canvas.drawCircle(_stars[i], i.isEven ? 1.6 : 1.2, Kit.fill(Color.fromRGBO(254, 240, 138, tw)));
      }
      Kit.glow(canvas, sun, 34, const Color(0xFFFDE68A), 0.25);
      canvas.drawCircle(sun, 12, Kit.fill(const Color(0xFFFEF9C3)));
      canvas.drawCircle(sun.translate(5, -3), 10.5, Kit.fill(colors.first));
    } else {
      Kit.glow(canvas, sun, 46, snap.frost ? const Color(0xFFFFFFFF) : const Color(0xFFFDE68A), 0.55);
      canvas.drawCircle(sun, 13, Kit.fill(snap.frost ? const Color(0xFFF8FAFC) : const Color(0xFFFDE047)));
    }
    final cloud = snap.twilight ? const Color(0x553730A3) : const Color(0xE6FFFFFF);
    for (final c in _clouds) {
      final p = Kit.fill(cloud);
      final o = Offset(c.x, c.y);
      final s = c.scale;
      canvas.drawCircle(o.translate(-14 * s, 0), 9 * s, p);
      canvas.drawCircle(o.translate(-2 * s, -6 * s), 12 * s, p);
      canvas.drawCircle(o.translate(12 * s, -1 * s), 9.5 * s, p);
      canvas.drawOval(Kit.oval(o.translate(0, 3 * s), 25 * s, 6.5 * s), p);
    }
    // Distant hills peeking beside the trunk
    final hill = snap.frost ? Pal.frostGround : (snap.twilight ? const Color(0xFF365314) : Pal.hillBack);
    canvas.drawPath(
        Path()
          ..moveTo(0, TreeLayout.groundY - 40)
          ..quadraticBezierTo(150, TreeLayout.groundY - 90, 300, TreeLayout.groundY - 50)
          ..quadraticBezierTo(450, TreeLayout.groundY - 10, 600, TreeLayout.groundY - 70)
          ..lineTo(600, TreeLayout.groundY)
          ..lineTo(0, TreeLayout.groundY)
          ..close(),
        Kit.fill(hill));
    _earth.draw(canvas, 'earth', _paintEarth);
  }

  void _paintEarth(Canvas c) {
    const earth = Rect.fromLTWH(0, TreeLayout.groundY, TreeLayout.width, TreeLayout.height - TreeLayout.groundY);
    c.drawRect(earth, Kit.vertical(earth, const [Pal.earthTop, Pal.earthBottom]));
    for (final (y, alpha) in const [(860.0, 0.12), (944.0, 0.18), (1046.0, 0.14)]) {
      c.drawPath(
          Path()
            ..moveTo(0, y)
            ..quadraticBezierTo(150, y - 8, 300, y + 2)
            ..quadraticBezierTo(450, y + 10, 600, y - 3),
          Kit.stroke(Color.fromRGBO(0, 0, 0, alpha), 7));
    }
    final rng = math.Random(31);
    for (var i = 0; i < 160; i++) {
      final p = Offset(rng.nextDouble() * 600, TreeLayout.groundY + 10 + rng.nextDouble() * 380);
      c.drawCircle(p, 0.6 + rng.nextDouble() * 1.1,
          Kit.fill(Color.fromRGBO(120, 72, 40, 0.25 + rng.nextDouble() * 0.3)));
    }
    for (var i = 0; i < 22; i++) {
      final p = Offset(rng.nextDouble() * 600, TreeLayout.groundY + 20 + rng.nextDouble() * 360);
      c.drawOval(Kit.oval(p, 3 + rng.nextDouble() * 4, 2 + rng.nextDouble() * 2),
          Kit.fill(Color.fromRGBO(87, 83, 78, 0.35 + rng.nextDouble() * 0.25)));
    }
    // Great Oak roots spreading through the soil between the pockets
    final roots = [
      (const Offset(80, 780), const Offset(20, 900), const Offset(40, 1140), 9.0),
      (const Offset(200, 780), const Offset(240, 930), const Offset(160, 1146), 6.0),
      (const Offset(300, 780), const Offset(300, 960), const Offset(300, 1148), 7.0),
      (const Offset(420, 780), const Offset(380, 930), const Offset(450, 1146), 6.0),
      (const Offset(520, 780), const Offset(590, 900), const Offset(560, 1140), 9.0),
      (const Offset(150, 940), const Offset(90, 1010), const Offset(20, 1060), 4.0),
      (const Offset(450, 940), const Offset(520, 1010), const Offset(590, 1060), 4.0),
    ];
    for (final (a, ctrl, b, w) in roots) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      c.drawPath(path, Kit.stroke(Pal.rootDark, w + 2));
      c.drawPath(path, Kit.stroke(Pal.root, w));
      c.drawPath(path, Kit.stroke(const Color(0x22FDE68A), w * 0.25));
    }
  }

  @override
  void onRemove() {
    _earth.dispose();
    super.onRemove();
  }
}

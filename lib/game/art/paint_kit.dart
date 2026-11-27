import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'palette.dart';

/// Small drawing vocabulary shared by every diorama painter.
abstract final class Kit {
  static Paint fill(Color c) => Paint()..color = c;

  static Paint stroke(Color c, double width) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static Paint vertical(Rect r, List<Color> colors, [List<double>? stops]) =>
      Paint()
        ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, colors,
            stops ?? _evenStops(colors.length));

  static Paint linear(Offset a, Offset b, List<Color> colors,
          [List<double>? stops]) =>
      Paint()
        ..shader =
            ui.Gradient.linear(a, b, colors, stops ?? _evenStops(colors.length));

  static Paint radial(Offset c, double r, List<Color> colors,
          [List<double>? stops]) =>
      Paint()
        ..shader =
            ui.Gradient.radial(c, r, colors, stops ?? _evenStops(colors.length));

  static List<double> _evenStops(int n) =>
      [for (var i = 0; i < n; i++) n == 1 ? 0.0 : i / (n - 1)];

  static Color a(Color c, double alpha) =>
      c.withValues(alpha: (c.a * alpha).clamp(0.0, 1.0));

  static Rect oval(Offset c, double rx, double ry) =>
      Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);

  /// Soft radial glow.
  static void glow(Canvas canvas, Offset c, double r, Color color,
      [double alpha = 0.6]) {
    canvas.drawCircle(
        c, r, radial(c, r, [a(color, alpha), a(color, alpha * 0.35), a(color, 0)], [0, 0.55, 1]));
  }

  /// Chibi acorn with cap, stem and shine.
  static void acorn(
    Canvas canvas,
    Offset c, {
    double rx = 5,
    double ry = 6,
    Color body = Pal.acorn,
    Color cap = Pal.acornCap,
    Color line = Pal.acornLine,
    double strokeWidth = 0.9,
  }) {
    final bodyRect = oval(c.translate(0, ry * 0.08), rx, ry * 0.92);
    canvas.drawOval(bodyRect, fill(body));
    canvas.drawOval(bodyRect, stroke(line, strokeWidth));
    final capPath = Path()
      ..moveTo(c.dx - rx * 1.08, c.dy - ry * 0.28)
      ..quadraticBezierTo(c.dx, c.dy - ry * 1.02, c.dx + rx * 1.08, c.dy - ry * 0.28)
      ..quadraticBezierTo(c.dx, c.dy - ry * 0.05, c.dx - rx * 1.08, c.dy - ry * 0.28)
      ..close();
    canvas.drawPath(capPath, fill(cap));
    canvas.drawLine(c.translate(0, -ry * 0.78), c.translate(rx * 0.25, -ry * 1.12),
        stroke(cap, math.max(0.8, rx * 0.22)));
    canvas.drawOval(oval(c.translate(-rx * 0.38, ry * 0.12), rx * 0.2, ry * 0.3),
        fill(const Color(0x66FFFFFF)));
  }

  /// Four-point twinkle star.
  static void sparkle(Canvas canvas, Offset c, double size, Color color) {
    final s = size;
    final w = s * 0.28;
    final p = Path()
      ..moveTo(c.dx, c.dy - s)
      ..quadraticBezierTo(c.dx + w * 0.4, c.dy - w * 0.4, c.dx + s, c.dy)
      ..quadraticBezierTo(c.dx + w * 0.4, c.dy + w * 0.4, c.dx, c.dy + s)
      ..quadraticBezierTo(c.dx - w * 0.4, c.dy + w * 0.4, c.dx - s, c.dy)
      ..quadraticBezierTo(c.dx - w * 0.4, c.dy - w * 0.4, c.dx, c.dy - s)
      ..close();
    canvas.drawPath(p, fill(color));
  }

  static void dashedRRect(Canvas canvas, RRect rr, Paint paint,
      {double dash = 5, double gap = 4}) {
    final path = Path()..addRRect(rr);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + dash, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  /// Wavy horizontal grain lines, deterministic per [seed].
  static void woodGrain(Canvas canvas, Rect r, Color color,
      {int seed = 1, int lines = 9, double width = 0.8}) {
    final rng = math.Random(seed);
    final paint = stroke(color, width);
    for (var i = 0; i < lines; i++) {
      final y = r.top + (i + 0.5) * r.height / lines + rng.nextDouble() * 2 - 1;
      final path = Path()..moveTo(r.left, y);
      var x = r.left;
      while (x < r.right) {
        final step = 30 + rng.nextDouble() * 40;
        final amp = rng.nextDouble() * 2.2 - 1.1;
        path.quadraticBezierTo(x + step / 2, y + amp * 2, math.min(x + step, r.right), y);
        x += step;
      }
      canvas.drawPath(path, paint);
    }
    // a couple of knots
    for (var k = 0; k < (r.width / 160).ceil(); k++) {
      final c = Offset(r.left + rng.nextDouble() * r.width,
          r.top + rng.nextDouble() * r.height);
      canvas.drawOval(oval(c, 4 + rng.nextDouble() * 3, 1.6 + rng.nextDouble()),
          stroke(color, width));
    }
  }

  /// Rounded rect helper.
  static RRect rr(Rect r, double radius) =>
      RRect.fromRectAndRadius(r, Radius.circular(radius));
}

/// Records a static layer once and replays it until [key] changes.
class PictureCache {
  ui.Picture? _picture;
  Object? _key;

  void draw(Canvas canvas, Object key, void Function(Canvas c) painter) {
    if (_picture == null || _key != key) {
      _picture?.dispose();
      final recorder = ui.PictureRecorder();
      painter(Canvas(recorder));
      _picture = recorder.endRecording();
      _key = key;
    }
    canvas.drawPicture(_picture!);
  }

  void dispose() {
    _picture?.dispose();
    _picture = null;
  }
}

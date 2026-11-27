import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../diorama_snapshot.dart';

/// Brass twin-bell Focus Shift clock. Idle it keeps real local time; during
/// a Focus Shift an amber sector fills with progress and the second hand
/// ticks.
abstract final class DeskClock {
  static const Offset center = Offset(286, 388);

  static void paint(Canvas c, DioramaSnapshot snap, double time, double squash) {
    c.save();
    c.translate(center.dx, center.dy + 26);
    c.scale(1 + squash * 0.08, 1 - squash * 0.1);
    c.translate(-center.dx, -(center.dy + 26));

    // Legs & bells
    final brassStroke = Kit.stroke(Pal.brass, 2.4);
    c.drawLine(center.translate(-16, 20), center.translate(-21, 28), brassStroke);
    c.drawLine(center.translate(16, 20), center.translate(21, 28), brassStroke);
    final ring = squash.abs() * 3; // bells jingle when the clock is tapped
    for (final side in const [-1.0, 1.0]) {
      final bell = center.translate(side * 17, -24);
      c.save();
      c.translate(bell.dx, bell.dy);
      c.rotate(side * 0.5 + ring * math.sin(time * 40) * 0.1);
      c.drawArc(Kit.oval(Offset.zero, 9, 7), math.pi, math.pi, true, Kit.fill(Pal.brassDark));
      c.drawArc(Kit.oval(Offset.zero, 9, 7), math.pi, math.pi, false, Kit.stroke(Pal.brass, 1.2));
      c.restore();
    }
    c.drawLine(center.translate(0, -27), center.translate(0, -31), Kit.stroke(Pal.brass, 2));
    c.drawCircle(center.translate(0, -32), 2.2, Kit.fill(Pal.brass));

    c.drawCircle(center, 27, Kit.fill(const Color(0xFF78350F)));
    c.drawCircle(center, 27, Kit.stroke(Pal.brass, 2.5));
    c.drawCircle(center, 21, Kit.fill(const Color(0xFFFEF3C7)));
    c.drawCircle(center, 21, Kit.stroke(const Color(0x33451A03), 1));

    if (snap.focusRunning) {
      c.drawArc(Rect.fromCircle(center: center, radius: 18), -math.pi / 2,
          snap.focusProgress * math.pi * 2, true, Kit.fill(const Color(0x66F59E0B)));
    }
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      final dir = Offset(math.cos(a), math.sin(a));
      c.drawLine(center + dir * (i % 3 == 0 ? 15.5 : 17.5), center + dir * 19.5,
          Kit.stroke(Pal.outline, i % 3 == 0 ? 1.6 : 0.9));
    }

    final now = DateTime.now();
    double handAngle(double fraction) => fraction * math.pi * 2 - math.pi / 2;
    final double hourA;
    final double minuteA;
    final double secondA;
    if (snap.focusRunning) {
      hourA = handAngle((now.hour % 12 + now.minute / 60) / 12);
      minuteA = handAngle(snap.focusProgress);
      secondA = handAngle((time.floor() % 60) / 60);
    } else {
      hourA = handAngle((now.hour % 12 + now.minute / 60) / 12);
      minuteA = handAngle((now.minute + now.second / 60) / 60);
      secondA = handAngle((now.second + now.millisecond / 1000) / 60);
    }
    Offset hand(double a, double len) => center + Offset(math.cos(a), math.sin(a)) * len;
    c.drawLine(center, hand(hourA, 10), Kit.stroke(Pal.outline, 2.4));
    c.drawLine(center, hand(minuteA, 15), Kit.stroke(const Color(0xFFD97706), 1.8));
    c.drawLine(center, hand(secondA, 16.5), Kit.stroke(const Color(0xFFB91C1C), 0.8));
    c.drawCircle(center, 2.2, Kit.fill(Pal.outline));
    c.drawArc(Rect.fromCircle(center: center, radius: 24), math.pi * 1.1, math.pi * 0.45, false,
        Kit.stroke(const Color(0x44FFFFFF), 1.4));
    c.restore();
  }
}

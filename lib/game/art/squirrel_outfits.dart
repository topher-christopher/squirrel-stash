import 'dart:math' as math;
import 'dart:ui';

import 'paint_kit.dart';
import 'palette.dart';

/// Headwear for the colony (Acorn Outfitter wardrobe).
enum SquirrelHat { none, chef, scholar, knight, beanie, goggles, visor }

/// Things a squirrel carries.
enum SquirrelProp { none, briefcase, duster, ladle, pickaxe }

/// Outfit & prop art drawn in the squirrel's local space (head near (1.5, -7),
/// feet at y = +14, facing right).
abstract final class SquirrelOutfits {
  static void hat(Canvas c, SquirrelHat hat) {
    switch (hat) {
      case SquirrelHat.none:
        return;
      case SquirrelHat.chef:
        c.save();
        c.translate(1, -16);
        final white = Kit.fill(const Color(0xFFFFFFFF));
        c.drawRRect(Kit.rr(const Rect.fromLTWH(-5, -3, 10, 4), 1.5), white);
        c.drawRRect(Kit.rr(const Rect.fromLTWH(-5, -3, 10, 4), 1.5), Kit.stroke(Pal.acornCap, 0.8));
        c.drawCircle(const Offset(-3, -5), 3.2, white);
        c.drawCircle(const Offset(3, -5), 3.2, white);
        c.drawCircle(const Offset(0, -6.5), 3.8, white);
        c.restore();
      case SquirrelHat.scholar:
        c.save();
        c.translate(1, -15);
        final board = Path()
          ..moveTo(-8, -2)
          ..lineTo(0, -6)
          ..lineTo(8, -2)
          ..lineTo(0, 2)
          ..close();
        c.drawPath(board, Kit.fill(const Color(0xFF1E293B)));
        c.drawPath(board, Kit.stroke(Pal.brass, 0.8));
        c.drawLine(const Offset(6, -2), const Offset(7.5, 3), Kit.stroke(Pal.brass, 1.1));
        c.drawCircle(const Offset(7.5, 3.4), 0.9, Kit.fill(Pal.brass));
        c.restore();
      case SquirrelHat.knight:
        // Acorn-cap knight helm with a little plume.
        c.save();
        c.translate(1.5, -12);
        final cap = Path()
          ..moveTo(-9, 1)
          ..quadraticBezierTo(-8, -9, 0, -9.5)
          ..quadraticBezierTo(8, -9, 9, 1)
          ..close();
        c.drawPath(cap, Kit.fill(Pal.acornCap));
        for (var y = -6.0; y < 1; y += 2.6) {
          c.drawLine(Offset(-7, y), Offset(7, y), Kit.stroke(const Color(0x55000000), 0.7));
        }
        c.drawPath(cap, Kit.stroke(Pal.outline, 0.9));
        c.drawRect(const Rect.fromLTWH(2.5, -1, 7, 1.6), Kit.fill(const Color(0xFF94A3B8)));
        c.drawPath(Path()..moveTo(0, -9)..quadraticBezierTo(-4, -16, -9, -13)..quadraticBezierTo(-4, -12, 0, -9),
            Kit.fill(const Color(0xFFDC2626)));
        c.restore();
      case SquirrelHat.beanie:
        c.save();
        c.translate(1.5, -12);
        final dome = Path()
          ..moveTo(-8.5, 0)
          ..quadraticBezierTo(-8, -9, 0, -9)
          ..quadraticBezierTo(8, -9, 8.5, 0)
          ..close();
        c.drawPath(dome, Kit.fill(const Color(0xFF0E7490)));
        c.drawRRect(Kit.rr(const Rect.fromLTWH(-9, -1.5, 18, 3.4), 1.6), Kit.fill(const Color(0xFF155E75)));
        for (var x = -6.0; x <= 6; x += 3) {
          c.drawLine(Offset(x, -7), Offset(x, -1.6), Kit.stroke(const Color(0x33FFFFFF), 0.7));
        }
        c.drawCircle(const Offset(0, -10), 2.4, Kit.fill(const Color(0xFFFDE68A)));
        c.restore();
      case SquirrelHat.goggles:
        c.save();
        c.translate(1.5, -11);
        c.drawLine(const Offset(-8, 0), const Offset(9, 0), Kit.stroke(const Color(0xFF7C2D12), 1.8));
        for (final x in const [1.0, 6.5]) {
          c.drawCircle(Offset(x, -0.5), 2.7, Kit.fill(const Color(0xFFB45309)));
          c.drawCircle(Offset(x, -0.5), 1.8, Kit.fill(const Color(0xFF7DD3FC)));
          c.drawCircle(Offset(x - 0.6, -1.1), 0.6, Kit.fill(const Color(0xCCFFFFFF)));
        }
        c.restore();
      case SquirrelHat.visor:
        // Banker's green eyeshade.
        c.save();
        c.translate(1.5, -12);
        c.drawLine(const Offset(-8, 0.5), const Offset(8, 0.5), Kit.stroke(const Color(0xFF1C1917), 1.1));
        final shade = Path()
          ..moveTo(-1, 0)
          ..lineTo(12, -1)
          ..lineTo(10, 3.5)
          ..lineTo(0, 3)
          ..close();
        c.drawPath(shade, Kit.fill(const Color(0xCC16A34A)));
        c.drawPath(shade, Kit.stroke(const Color(0xFF14532D), 0.6));
        c.restore();
    }
  }

  /// Navy jacket & red tie over the belly (commuters, bankers).
  static void suit(Canvas c) {
    final jacket = Path()
      ..moveTo(-7.5, 0)
      ..quadraticBezierTo(-8, 12, -2, 13)
      ..lineTo(1, 4)
      ..lineTo(4, 13)
      ..quadraticBezierTo(8.5, 11, 8, 1)
      ..quadraticBezierTo(1, -2, -7.5, 0)
      ..close();
    c.drawPath(jacket, Kit.fill(const Color(0xFF1E3A8A)));
    c.drawPath(Path()..moveTo(1, 0)..lineTo(2.6, 2)..lineTo(1.6, 9)..lineTo(0, 10.5)..lineTo(-0.4, 2)..close(),
        Kit.fill(const Color(0xFFDC2626)));
  }

  static void prop(Canvas c, SquirrelProp prop, double t, double seed, Paint paw) {
    switch (prop) {
      case SquirrelProp.none:
        return;
      case SquirrelProp.briefcase:
        final swing = math.sin(t * 6 + seed) * 0.12;
        c.save();
        c.translate(7, 6);
        c.rotate(swing);
        c.drawRRect(Kit.rr(const Rect.fromLTWH(-1, 2, 11, 8), 1.5), Kit.fill(const Color(0xFF78350F)));
        c.drawRRect(Kit.rr(const Rect.fromLTWH(-1, 2, 11, 8), 1.5), Kit.stroke(Pal.outline, 0.8));
        c.drawRRect(Kit.rr(const Rect.fromLTWH(2.5, 0, 4, 2.6), 1), Kit.stroke(const Color(0xFF451A03), 0.9));
        c.drawRect(const Rect.fromLTWH(3.8, 5, 1.6, 1.4), Kit.fill(Pal.brass));
        c.restore();
        c.drawOval(Kit.oval(const Offset(7, 7), 2, 1.6), paw);
      case SquirrelProp.duster:
        final wipe = math.sin(t * 7 + seed) * 0.5;
        c.save();
        c.translate(7, 0);
        c.rotate(-0.6 + wipe);
        c.drawLine(Offset.zero, const Offset(0, -9), Kit.stroke(const Color(0xFF92400E), 1.3));
        for (var k = 0; k < 5; k++) {
          c.drawOval(Kit.oval(Offset(-2.0 + k, -11 - (k % 2) * 1.5), 1.8, 2.8),
              Kit.fill([const Color(0xFFF472B6), const Color(0xFFFDE68A), const Color(0xFF93C5FD)][k % 3]));
        }
        c.restore();
        c.drawOval(Kit.oval(const Offset(7, 0), 2, 1.6), paw);
      case SquirrelProp.ladle:
        final stir = math.sin(t * 4 + seed);
        c.save();
        c.translate(8 + stir * 1.5, 2);
        c.drawLine(const Offset(0, -6), const Offset(2, 8), Kit.stroke(const Color(0xFF94A3B8), 1.2));
        c.drawOval(Kit.oval(const Offset(2.2, 8.5), 2.2, 1.4), Kit.fill(const Color(0xFF94A3B8)));
        c.restore();
        c.drawOval(Kit.oval(Offset(8 + stir * 1.5, -3), 2, 1.6), paw);
      case SquirrelProp.pickaxe:
        final swing = -0.4 + math.max(0, math.sin(t * 3.4 + seed)) * 1.4;
        c.save();
        c.translate(6, 2);
        c.rotate(-swing);
        c.drawLine(Offset.zero, const Offset(0, -13), Kit.stroke(const Color(0xFF92400E), 1.4));
        c.drawPath(Path()..moveTo(-6, -12)..quadraticBezierTo(0, -16, 6, -12)..quadraticBezierTo(0, -14, -6, -12),
            Kit.stroke(const Color(0xFF94A3B8), 1.6));
        c.restore();
        c.drawOval(Kit.oval(const Offset(6, 1), 2, 1.6), paw);
    }
  }
}

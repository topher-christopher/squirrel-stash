import 'dart:ui';

import 'paint_kit.dart';
import 'palette.dart';

/// v1.2 wardrobe: winter jackets, Caps fan gear, scavenger backpacks, DJ
/// headphones and seed bags. Drawn in the squirrel's local space (head near
/// (1.5, -7), feet at y = +14, facing right).
abstract final class SquirrelGear {
  static const capsRed = Color(0xFFC8102E);
  static const capsNavy = Color(0xFF041E42);

  /// Puffy quilted winter jacket over the body.
  static void jacket(Canvas c) {
    final coat = Path()
      ..moveTo(-8.2, -1)
      ..quadraticBezierTo(-9.4, 11, -3, 13)
      ..lineTo(5, 13)
      ..quadraticBezierTo(9.6, 11, 8.6, 0)
      ..quadraticBezierTo(0.5, -3.2, -8.2, -1)
      ..close();
    c.drawPath(coat, Kit.fill(const Color(0xFF2563EB)));
    for (final y in const [3.5, 8.0]) {
      c.drawLine(Offset(-8, y), Offset(8.4, y), Kit.stroke(const Color(0x551E3A8A), 1));
    }
    c.drawLine(const Offset(1.2, -1.6), const Offset(1.2, 13), Kit.stroke(const Color(0xFFBFDBFE), 0.9));
    c.drawPath(coat, Kit.stroke(const Color(0xFF1E3A8A), 0.8));
  }

  /// Washington-style red hockey jersey with a white & navy stripe.
  static void jersey(Canvas c) {
    final shirt = Path()
      ..moveTo(-8, -1)
      ..quadraticBezierTo(-9, 11, -3, 13)
      ..lineTo(5, 13)
      ..quadraticBezierTo(9.2, 11, 8.4, 0)
      ..quadraticBezierTo(0.5, -3, -8, -1)
      ..close();
    c.drawPath(shirt, Kit.fill(capsRed));
    c.drawRect(const Rect.fromLTWH(-8.6, 8, 17.4, 1.6), Kit.fill(const Color(0xFFFFFFFF)));
    c.drawRect(const Rect.fromLTWH(-8.6, 9.6, 17.4, 1.2), Kit.fill(capsNavy));
    c.drawCircle(const Offset(2, 4), 2.2, Kit.fill(const Color(0xFFFFFFFF)));
    c.drawCircle(const Offset(2, 4), 1.2, Kit.fill(capsRed));
    c.drawPath(shirt, Kit.stroke(const Color(0xFF7F1D1D), 0.7));
  }

  /// Canvas scavenger backpack, drawn behind the body.
  static void backpack(Canvas c) {
    final pack = Rect.fromLTWH(-12.5, -2, 9, 12);
    c.drawRRect(Kit.rr(pack, 3), Kit.fill(const Color(0xFF4D7C0F)));
    c.drawRRect(Kit.rr(Rect.fromLTWH(pack.left + 1, pack.top + 6, 7, 5), 2), Kit.fill(const Color(0xFF65A30D)));
    c.drawRRect(Kit.rr(pack, 3), Kit.stroke(const Color(0xFF1A2E05), 0.8));
    c.drawLine(const Offset(-5, -1), const Offset(-1, 5), Kit.stroke(const Color(0xFF3F2A12), 1.2));
    // Bedroll on top
    c.drawRRect(Kit.rr(Rect.fromLTWH(pack.left - 0.5, pack.top - 3.4, 10, 3.6), 1.8), Kit.fill(const Color(0xFFB45309)));
  }

  /// Burlap seed bag hugged in front.
  static void seedBag(Canvas c, Color tie) {
    final bag = Path()
      ..moveTo(4, 9)
      ..quadraticBezierTo(3, 1, 7, -1)
      ..lineTo(11, -1)
      ..quadraticBezierTo(15, 1, 14, 9)
      ..close();
    c.drawPath(bag, Kit.fill(const Color(0xFFD9B26F)));
    c.drawPath(bag, Kit.stroke(const Color(0xFF7C5A22), 0.8));
    c.drawLine(const Offset(7.4, 0.4), const Offset(10.6, 0.4), Kit.stroke(tie, 1.4));
    c.drawLine(const Offset(6.5, 5), const Offset(11.5, 5), Kit.stroke(const Color(0x557C5A22), 0.6));
    c.drawOval(Kit.oval(const Offset(4.8, 4.2), 2, 1.6), Kit.fill(Pal.fur));
  }

  /// Chunky DJ headphones.
  static void headphones(Canvas c) {
    c.save();
    c.translate(1.5, -8);
    c.drawArc(const Rect.fromLTWH(-8.5, -9, 17, 14), 3.4, 2.6, false, Kit.stroke(const Color(0xFF111827), 1.8));
    for (final x in const [-8.0, 8.4]) {
      c.drawRRect(Kit.rr(Rect.fromCenter(center: Offset(x, 0.5), width: 4.2, height: 6), 1.6),
          Kit.fill(const Color(0xFF1F2937)));
      c.drawCircle(Offset(x, 0.5), 1.2, Kit.fill(const Color(0xFFF472B6)));
    }
    c.restore();
  }

  /// Red knit fan beanie with a white stripe and pom.
  static void capsBeanie(Canvas c) {
    c.save();
    c.translate(1.5, -12);
    final dome = Path()
      ..moveTo(-8.5, 0)
      ..quadraticBezierTo(-8, -9, 0, -9)
      ..quadraticBezierTo(8, -9, 8.5, 0)
      ..close();
    c.drawPath(dome, Kit.fill(capsRed));
    c.drawRect(const Rect.fromLTWH(-8.2, -5, 16.4, 1.6), Kit.fill(const Color(0xFFFFFFFF)));
    c.drawRRect(Kit.rr(const Rect.fromLTWH(-9, -1.5, 18, 3.4), 1.6), Kit.fill(capsNavy));
    c.drawCircle(const Offset(0, -10), 2.4, Kit.fill(const Color(0xFFFFFFFF)));
    c.restore();
  }
}

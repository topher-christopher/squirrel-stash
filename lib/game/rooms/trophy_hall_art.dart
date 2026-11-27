import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import 'custodian.dart';
import 'room_kit.dart';

/// Trophy Hall & Stats (compact): two trophy shelves along the back wall,
/// overflow crates, a statue case, a center pedestal, a standing mirror, a
/// mouse hole and a side doorway — the stage for the custodian's routine.
/// Room-local units (172 × 144, floor at 128).
class TrophyHallArt extends RoomArt {
  const TrophyHallArt();

  static const floor = 128.0;
  static const _perShelf = 8;

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    RoomKit.shell(c, x, wall: const Color(0xFF2E1A10));
    c.save();
    c.translate(x.r.left, x.r.top);
    final count = x.snap.trophyCount;
    var placed = 0;
    for (var s = 0; s < 2; s++) {
      final y = 30.0 + s * 24;
      RoomKit.shelf(c, 10, 162, y);
      for (var k = 0; k < _perShelf && placed < count; k++) {
        _trophy(c, Offset(20 + k * 18.0, y), placed);
        placed++;
      }
    }
    final overflow = math.min(6, math.max(0, count - placed));
    for (var b = 0; b < overflow; b++) {
      RoomKit.crate(c, Rect.fromLTWH(50 + (b % 3) * 13.0, floor - 11 - (b ~/ 3) * 11.0, 12, 11), color: const Color(0xFF92400E));
    }
    _case(c, Rect.fromLTWH(6, 64, 38, floor - 64), x.snap.statueCount, x.level);
    // Center pedestal with the featured cup
    c.drawRect(const Rect.fromLTWH(84, floor - 18, 18, 18), Kit.linear(const Offset(84, 0), const Offset(102, 0),
        const [Color(0xFF78716C), Color(0xFFD6D3D1), Color(0xFF78716C)]));
    c.drawRect(const Rect.fromLTWH(81, floor - 21, 24, 4), Kit.fill(const Color(0xFFA8A29E)));
    _trophy(c, const Offset(93, floor - 21), 0, scale: 1.4);
    // Standing mirror
    const mirror = Rect.fromLTWH(118, 70, 24, floor - 72);
    c.drawRRect(Kit.rr(mirror.inflate(2.5), 10), Kit.fill(const Color(0xFF78350F)));
    c.drawRRect(Kit.rr(mirror, 9), Kit.vertical(mirror, const [Color(0xFFBAE6FD), Color(0xFF64748B)]));
    c.drawLine(mirror.topLeft.translate(5, 10), mirror.topLeft.translate(10, 4), Kit.stroke(const Color(0x88FFFFFF), 1.4));
    // Mouse hole (left wall) and arched side doorway (right wall)
    c.drawPath(Path()
      ..moveTo(2, floor)
      ..lineTo(2, floor - 9)
      ..quadraticBezierTo(8, floor - 17, 14, floor - 9)
      ..lineTo(14, floor)
      ..close(), Kit.fill(const Color(0xFF0C0603)));
    final door = RRect.fromRectAndCorners(const Rect.fromLTWH(150, floor - 34, 18, 34),
        topLeft: const Radius.circular(9), topRight: const Radius.circular(9));
    c.drawRRect(door, Kit.fill(const Color(0xFF0C0603)));
    c.drawRRect(door, Kit.stroke(const Color(0xFF8B5A2B), 1.4));
    if (x.level >= 2) RoomKit.rug(c, const Offset(93, floor + 6), 44, const Color(0xFF7F1D1D));
    if (x.level >= 3) {
      // Velvet rope stanchions around the pedestal
      for (final dx in const [70.0, 116.0]) {
        c.drawLine(Offset(dx, floor), Offset(dx, floor - 14), Kit.stroke(const Color(0xFFFBBF24), 1.6));
        c.drawCircle(Offset(dx, floor - 15), 1.8, Kit.fill(const Color(0xFFFBBF24)));
      }
      c.drawPath(Path()..moveTo(70, floor - 12)..quadraticBezierTo(93, floor - 4, 116, floor - 12),
          Kit.stroke(const Color(0xFFB91C1C), 1.6));
    }
    c.restore();
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final r = x.r;
    RoomKit.lamp(c, Offset(r.left + 40, r.top + 12), x.t);
    RoomKit.lamp(c, Offset(r.right - 40, r.top + 12), x.t);
    if (x.level >= 3) {
      // Spotlight on the featured cup
      c.drawPath(Path()
        ..moveTo(r.left + 88, r.top + 6)
        ..lineTo(r.left + 98, r.top + 6)
        ..lineTo(r.left + 112, r.top + floor)
        ..lineTo(r.left + 74, r.top + floor)
        ..close(), Kit.fill(const Color(0x14FEF9C3)));
    }
    final s = (x.t * 0.3) % 1.6;
    if (s < 1) {
      final gx = r.left + 6 + s * 38;
      c.drawLine(Offset(gx, r.top + 68), Offset(gx - 6, r.top + floor - 4), Kit.stroke(const Color(0x55FFFFFF), 1.8));
    }
    Custodian.paint(c, x);
    if (x.level >= 3 || x.detail > 0.05) {
      final a = x.level >= 3 ? 1.0 : x.detail;
      c.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, a));
      for (var k = 0; k < 3; k++) {
        final ph = (x.t * 0.5 + k * 0.27) % 1.0;
        Kit.sparkle(c, Offset(r.left + 12 + k * 12, r.top + 80 + math.sin(k * 2.0) * 16),
            2.2 * math.sin(ph * math.pi), const Color(0xFFFFF7AE));
      }
      c.restore();
    }
  }

  static void _trophy(Canvas c, Offset o, int i, {double scale = 1}) {
    c.save();
    c.translate(o.dx, o.dy);
    c.scale(scale);
    switch (i % 3) {
      case 0:
        c.drawPath(Path()..moveTo(-4, -12)..lineTo(4, -12)..quadraticBezierTo(4, -5, 0, -5)
          ..quadraticBezierTo(-4, -5, -4, -12)..close(), Kit.fill(const Color(0xFFFACC15)));
        c.drawRect(const Rect.fromLTWH(-1, -5, 2, 3), Kit.fill(const Color(0xFFD97706)));
        c.drawRect(const Rect.fromLTWH(-3.5, -2, 7, 2), Kit.fill(const Color(0xFF78350F)));
      case 1:
        c.drawPath(Path()..moveTo(-4.5, -13)..lineTo(4.5, -13)..lineTo(4.5, -7)
          ..quadraticBezierTo(0, -1, -4.5, -7)..close(), Kit.fill(const Color(0xFF94A3B8)));
        c.drawLine(const Offset(0, -12), const Offset(0, -3), Kit.stroke(const Color(0xFFDC2626), 1.2));
      default:
        c.drawRRect(Kit.rr(const Rect.fromLTWH(-4.5, -12, 9, 12), 1.5), Kit.fill(const Color(0xFF92400E)));
        c.drawCircle(const Offset(0, -6), 2.8, Kit.fill(const Color(0xFFFB923C)));
    }
    c.restore();
  }

  static void _case(Canvas c, Rect b, int statues, int level) {
    Kit.glow(c, b.center, 30, const Color(0xFFFDE68A), level >= 2 ? 0.2 : 0.1);
    c.drawRRect(Kit.rr(Rect.fromLTWH(b.left - 2, b.bottom - 8, b.width + 4, 8), 2), Kit.fill(const Color(0xFF6B3D1E)));
    final glass = Rect.fromLTRB(b.left, b.top, b.right, b.bottom - 8);
    c.drawRRect(Kit.rr(glass, 3), Kit.fill(const Color(0x33BAE6FD)));
    c.drawRRect(Kit.rr(glass, 3), Kit.stroke(const Color(0xFFFBBF24), 1.2));
    final tier = glass.top + glass.height / 2;
    c.drawLine(Offset(glass.left + 2, tier), Offset(glass.right - 2, tier), Kit.stroke(const Color(0x88FDE68A), 1));
    for (var k = 0; k < math.min(4, statues); k++) {
      final base = Offset(glass.left + 10 + (k % 2) * 18, k < 2 ? tier : glass.bottom - 1);
      c.drawRect(Rect.fromLTWH(base.dx - 5, base.dy - 3, 10, 3), Kit.fill(const Color(0xFF78350F)));
      c.drawOval(Kit.oval(base.translate(0, -8), 3.6, 5), Kit.fill(const Color(0xFFFACC15)));
      c.drawCircle(base.translate(0.5, -15), 3, Kit.fill(const Color(0xFFFACC15)));
    }
  }
}

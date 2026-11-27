import 'dart:math' as math;
import 'dart:ui';

import '../../models/bird.dart';
import 'paint_kit.dart';
import 'squirrel_painter.dart';

/// Procedural feeder visitors, drawn facing right with feet at (0, 0) in a
/// ~16-unit space. Shared by the Great Oak and the logbook portraits.
abstract final class BirdPainter {
  static double scaleOf(BirdSpecies s) => switch (s) {
        BirdSpecies.baldEagle => 1.9,
        BirdSpecies.greatHornedOwl => 1.7,
        BirdSpecies.peregrine => 1.45,
        BirdSpecies.chickadee => 0.85,
        _ => 1.0,
      };

  static void paint(Canvas c, Offset at, BirdSpecies s,
      {double dir = 1, double scale = 1, double time = 0, double seed = 0, bool flying = false, bool peck = false}) {
    if (s == BirdSpecies.albinoSquirrel) {
      SquirrelPainter.paint(c, at.translate(0, -14 * 0.62 * scale), dir: dir, scale: 0.62 * scale, time: time, seed: seed,
          look: const SquirrelLook(albino: true));
      return;
    }
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(dir * scale * scaleOf(s), scale * scaleOf(s));
    if (s == BirdSpecies.chipmunk) {
      _chipmunk(c, time, seed);
    } else if (s == BirdSpecies.greatHornedOwl) {
      _owl(c, time, seed);
    } else {
      _songbird(c, s, time, seed, flying, peck);
    }
    c.restore();
  }

  static (Color back, Color belly, Color head, Color beak) _palette(BirdSpecies s) => switch (s) {
        BirdSpecies.cardinal => (const Color(0xFFDC2626), const Color(0xFFEF4444), const Color(0xFFDC2626), const Color(0xFFF97316)),
        BirdSpecies.blueJay => (const Color(0xFF3B82F6), const Color(0xFFF1F5F9), const Color(0xFF60A5FA), const Color(0xFF1C1917)),
        BirdSpecies.chickadee => (const Color(0xFF9CA3AF), const Color(0xFFF5F5F4), const Color(0xFF111827), const Color(0xFF1C1917)),
        BirdSpecies.robin => (const Color(0xFF57534E), const Color(0xFFEA580C), const Color(0xFF292524), const Color(0xFFFACC15)),
        BirdSpecies.woodpecker => (const Color(0xFF1C1917), const Color(0xFFF5E6C8), const Color(0xFFDC2626), const Color(0xFF64748B)),
        BirdSpecies.waxwing => (const Color(0xFFC2A27A), const Color(0xFFE7D3A8), const Color(0xFFB08B5B), const Color(0xFF1C1917)),
        BirdSpecies.oriole => (const Color(0xFF111827), const Color(0xFFF97316), const Color(0xFF111827), const Color(0xFF64748B)),
        BirdSpecies.baldEagle => (const Color(0xFF3F2A1A), const Color(0xFF4A3320), const Color(0xFFF8FAFC), const Color(0xFFFACC15)),
        BirdSpecies.peregrine => (const Color(0xFF475569), const Color(0xFFE2E8F0), const Color(0xFF1E293B), const Color(0xFFFACC15)),
        _ => (const Color(0xFF78350F), const Color(0xFFFDE68A), const Color(0xFF78350F), const Color(0xFFF59E0B)),
      };

  static void _songbird(Canvas c, BirdSpecies s, double t, double seed, bool flying, bool peck) {
    final (back, belly, head, beak) = _palette(s);
    final ink = Kit.stroke(const Color(0x99000000), 0.6);
    // Tail
    final tail = Path()..moveTo(-5, -5)..lineTo(-13, -2.5)..lineTo(-12, 0)..lineTo(-4, -3)..close();
    c.drawPath(tail, Kit.fill(back));
    if (s == BirdSpecies.waxwing) c.drawLine(const Offset(-12.5, -2.4), const Offset(-12, -0.2), Kit.stroke(const Color(0xFFFACC15), 1.4));
    // Feet
    if (!flying) {
      c.drawLine(const Offset(-1, -2), const Offset(-1.5, 0), Kit.stroke(const Color(0xFF78716C), 0.8));
      c.drawLine(const Offset(1.5, -2), const Offset(1.5, 0), Kit.stroke(const Color(0xFF78716C), 0.8));
    }
    // Body & belly
    c.drawOval(Kit.oval(const Offset(0, -6), 7, 5.2), Kit.fill(back));
    c.drawOval(Kit.oval(const Offset(1.8, -4.6), 4.6, 3.4), Kit.fill(belly));
    if (s == BirdSpecies.peregrine) {
      for (var k = 0; k < 3; k++) {
        c.drawLine(Offset(0.2 + k * 1.4, -6 + k * 0.6), Offset(1.6 + k * 1.4, -6 + k * 0.6), Kit.stroke(const Color(0xFF64748B), 0.6));
      }
    }
    // Wing (flaps in flight)
    final flap = flying ? math.sin(t * 22 + seed) : 0.0;
    c.save();
    c.translate(-1, -7);
    c.rotate(flying ? -0.6 - flap * 0.9 : 0.15);
    final wingColor = s == BirdSpecies.woodpecker ? const Color(0xFF1C1917) : Color.lerp(back, const Color(0xFF000000), 0.18)!;
    c.drawOval(Kit.oval(const Offset(-2, 0), 5, 2.8), Kit.fill(wingColor));
    if (s == BirdSpecies.woodpecker) {
      for (var k = 0; k < 3; k++) {
        c.drawLine(Offset(-5 + k * 2.4, -1.4), Offset(-5 + k * 2.4, 1.4), Kit.stroke(const Color(0xFFF8FAFC), 0.7));
      }
    }
    if (s == BirdSpecies.oriole || s == BirdSpecies.blueJay) {
      c.drawLine(const Offset(-5, 0.4), const Offset(0.6, 0.4), Kit.stroke(const Color(0xFFF8FAFC), 0.7));
    }
    c.restore();
    // Head (dips while pecking)
    final dip = peck ? math.max(0.0, math.sin(t * 7 + seed)) * 2.2 : 0.0;
    c.save();
    c.translate(dip * 0.6, dip);
    final hc = const Offset(5, -11);
    c.drawCircle(hc, 4, Kit.fill(head));
    if (s == BirdSpecies.cardinal || s == BirdSpecies.blueJay || s == BirdSpecies.waxwing) {
      c.drawPath(Path()..moveTo(2.4, -13)..lineTo(1, -18)..lineTo(5.4, -14.2)..close(), Kit.fill(head));
    }
    switch (s) {
      case BirdSpecies.chickadee:
        c.drawCircle(const Offset(5.6, -10), 2.2, Kit.fill(const Color(0xFFF8FAFC)));
        c.drawOval(Kit.oval(const Offset(6, -7.5), 1.8, 1.2), Kit.fill(const Color(0xFF111827)));
      case BirdSpecies.cardinal || BirdSpecies.waxwing:
        c.drawOval(Kit.oval(const Offset(7.6, -11), 2, 1.5), Kit.fill(const Color(0xFF111827)));
      case BirdSpecies.blueJay:
        c.drawArc(const Rect.fromLTWH(2, -10, 7, 5), 0.2, 2.6, false, Kit.stroke(const Color(0xFF111827), 0.8));
      case BirdSpecies.woodpecker:
        c.drawCircle(const Offset(5.4, -9.6), 2.6, Kit.fill(const Color(0xFFF5E6C8)));
      case BirdSpecies.baldEagle:
        c.drawPath(Path()..moveTo(8.2, -11.6)..quadraticBezierTo(12.6, -11.4, 11.4, -8.4)..lineTo(8.4, -9.6)..close(),
            Kit.fill(beak));
      case BirdSpecies.peregrine:
        c.drawLine(const Offset(5.6, -10), const Offset(5.2, -7.6), Kit.stroke(const Color(0xFF0F172A), 1.4));
        c.drawCircle(const Offset(6.2, -11.6), 1.4, Kit.stroke(const Color(0xFFFACC15), 0.6));
      default:
        break;
    }
    if (s != BirdSpecies.baldEagle) {
      c.drawPath(Path()..moveTo(8.4, -11.6)..lineTo(s == BirdSpecies.woodpecker ? 12.6 : 11.2, -10.6)..lineTo(8.4, -9.8)..close(),
          Kit.fill(beak));
    }
    c.drawCircle(const Offset(6.2, -11.6), 0.9, Kit.fill(const Color(0xFF0C0A09)));
    c.drawCircle(hc, 4, ink);
    c.restore();
  }

  static void _owl(Canvas c, double t, double seed) {
    final body = Kit.fill(const Color(0xFF78350F));
    c.drawOval(Kit.oval(const Offset(0, -8), 6.5, 8), body);
    c.drawOval(Kit.oval(const Offset(0.8, -6.5), 4.2, 5.2), Kit.fill(const Color(0xFFD6B48A)));
    for (var k = 0; k < 3; k++) {
      c.drawLine(Offset(-1.6 + k * 1.6, -8.0 + k), Offset(-0.6 + k * 1.6, -8.0 + k), Kit.stroke(const Color(0xFF78350F), 0.6));
    }
    c.drawOval(Kit.oval(const Offset(0.6, -15), 5.4, 4.6), body);
    c.drawPath(Path()..moveTo(-3.6, -18)..lineTo(-4.6, -22)..lineTo(-1.6, -19)..close(), body);
    c.drawPath(Path()..moveTo(4.6, -18)..lineTo(5.8, -22)..lineTo(2.8, -19)..close(), body);
    c.drawOval(Kit.oval(const Offset(0.6, -14.8), 4.2, 3.4), Kit.fill(const Color(0xFFB08B5B)));
    final blink = (t + seed) % 4.6 < 0.15;
    for (final ex in const [-1.4, 2.6]) {
      if (blink) {
        c.drawLine(Offset(ex - 1.2, -15.5), Offset(ex + 1.2, -15.5), Kit.stroke(const Color(0xFF1C1917), 0.7));
      } else {
        c.drawCircle(Offset(ex, -15.5), 1.5, Kit.fill(const Color(0xFFFACC15)));
        c.drawCircle(Offset(ex, -15.5), 0.7, Kit.fill(const Color(0xFF0C0A09)));
      }
    }
    c.drawPath(Path()..moveTo(0, -14.2)..lineTo(1.2, -14.2)..lineTo(0.6, -12.6)..close(), Kit.fill(const Color(0xFF292524)));
  }

  static void _chipmunk(Canvas c, double t, double seed) {
    final fur = Kit.fill(const Color(0xFFB45309));
    final tail = Path()..moveTo(-5, -3)..quadraticBezierTo(-12, -6, -10, -12)..quadraticBezierTo(-8, -7, -4, -5)..close();
    c.drawPath(tail, fur);
    c.drawOval(Kit.oval(const Offset(0, -4.5), 6.5, 4.4), fur);
    for (final (dy, color) in const [(-7.0, Color(0xFF1C1917)), (-6.0, Color(0xFFF5F5F4)), (-5.0, Color(0xFF1C1917))]) {
      c.drawLine(Offset(-4, dy + 1), Offset(3.6, dy), Kit.stroke(color, 0.7));
    }
    c.drawCircle(const Offset(5, -8), 3.4, fur);
    c.drawOval(Kit.oval(const Offset(6.4, -7), 1.8, 1.4), Kit.fill(const Color(0xFFFDE68A)));
    c.drawCircle(const Offset(5.8, -9.2), 0.8, Kit.fill(const Color(0xFF0C0A09)));
    c.drawCircle(const Offset(3.6, -11), 1.2, fur);
    final chew = math.sin(t * 12 + seed) > 0.4 ? 0.3 : 0.0;
    c.drawCircle(Offset(8.2, -7.4 + chew), 0.6, Kit.fill(const Color(0xFF1C1917)));
  }
}

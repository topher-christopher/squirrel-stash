import 'dart:math' as math;
import 'dart:ui';

import '../../models/treat_status.dart';
import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import 'room_kit.dart';

/// Lantern colors shared by the Treasury lantern and the canopy beacon.
const treatColors = {
  TreatLevel.green: Color(0xFF4ADE80),
  TreatLevel.yellow: Color(0xFFFACC15),
  TreatLevel.red: Color(0xFFF87171),
};

/// Canopy Treasury: a treehouse cabin in the crown holding the Free Cash
/// acorn pile, the Treat Yourself lantern and the payday delivery sprint.
class TreasuryArt extends RoomArt {
  const TreasuryArt();

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    final r = x.r;
    // Little peaked roof above the cabin
    c.drawPath(
        Path()
          ..moveTo(r.left - 10, r.top + 6)
          ..lineTo(r.center.dx, r.top - 26)
          ..lineTo(r.right + 10, r.top + 6)
          ..close(),
        Kit.fill(const Color(0xFF7C2D12)));
    for (var k = 0; k < 5; k++) {
      final y = r.top - 18 + k * 5.0;
      final half = (y - (r.top - 26)) / 32 * (r.width / 2 + 10);
      c.drawLine(Offset(r.center.dx - half, y), Offset(r.center.dx + half, y), Kit.stroke(const Color(0x33000000), 1));
    }
    RoomKit.shell(c, x, wall: const Color(0xFF4A2A14));
    c.save();
    c.translate(r.left, r.top);
    // Round window with sky
    c.drawCircle(const Offset(40, 40), 15, Kit.fill(const Color(0xFF7DD3FC)));
    c.drawCircle(const Offset(40, 40), 15, Kit.stroke(const Color(0xFF6B3D1E), 3));
    c.drawLine(const Offset(25, 40), const Offset(55, 40), Kit.stroke(const Color(0xFF6B3D1E), 1.6));
    c.drawLine(const Offset(40, 25), const Offset(40, 55), Kit.stroke(const Color(0xFF6B3D1E), 1.6));
    // Counting desk
    final floor = r.height - 16;
    c.drawRRect(Kit.rr(Rect.fromLTWH(118, floor - 22, 56, 22), 2), Kit.fill(const Color(0xFF8B5A2B)));
    c.drawRect(Rect.fromLTWH(116, floor - 24, 60, 4), Kit.fill(const Color(0xFFB45309)));
    if (x.level >= 2) {
      // Ledger book and an abacus on the desk
      c.drawRect(Rect.fromLTWH(124, floor - 29, 14, 5), Kit.fill(const Color(0xFF14532D)));
      for (var k = 0; k < 3; k++) {
        c.drawLine(Offset(146, floor - 32 + k * 3.0), Offset(168, floor - 32 + k * 3.0), Kit.stroke(const Color(0xFF78350F), 0.7));
        for (var b = 0; b < 4; b++) {
          c.drawCircle(Offset(148 + b * 4.0 + k * 2, floor - 32 + k * 3.0), 1.1, Kit.fill(Pal.gold));
        }
      }
    }
    c.restore();
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final r = x.r;
    final floor = x.floorY;
    _acornPile(c, Offset(r.left + 70, floor), x.snap.acornPile, x.t);
    _lantern(c, Offset(r.left + 98, r.top + 14), x.snap.treat, x.t);
    // Banker squirrel at the desk
    SquirrelPainter.paint(c, Offset(r.left + 150, floor - 30),
        dir: -1, scale: 0.85, time: x.t, seed: 0.6, pose: SquirrelPose.researcher,
        look: SquirrelLook(hat: x.snap.outfits ? SquirrelHat.visor : SquirrelHat.none, scarf: x.frost),
        art: x.art);
    if (x.snap.paydayBurst) {
      // Payday sprint: three runners haul acorns (one golden) to the pile.
      for (var k = 0; k < 3; k++) {
        final u = ((x.t * 0.7 + k * 0.33) % 1.0);
        final px = r.left + 8 + u * 62;
        SquirrelPainter.paint(c, Offset(px, floor - 14 - math.sin(u * math.pi * 6).abs() * 3),
            scale: 0.7, time: x.t, seed: k * 1.7,
            look: SquirrelLook(acorn: true, golden: k == 1), art: x.art);
      }
    }
  }

  static void _acornPile(Canvas c, Offset base, int count, double t) {
    if (count <= 0) return;
    c.drawOval(Kit.oval(base.translate(0, 1), 8 + count * 1.6, 3), Kit.fill(const Color(0x55000000)));
    var placed = 0;
    for (var row = 0; placed < count; row++) {
      final inRow = math.max(1, 5 - row);
      for (var k = 0; k < inRow && placed < count; k++) {
        final p = base.translate((k - (inRow - 1) / 2) * 8.5, -5 - row * 7.0);
        Kit.acorn(c, p, rx: 4.2, ry: 5, strokeWidth: 0.8);
        placed++;
      }
    }
    final s = (t * 0.5) % 1.0;
    Kit.sparkle(c, base.translate(10, -14 - s * 6), 2.2 * (1 - s), const Color(0xFFFFFFFF));
  }

  /// Green / Yellow / Red Treat Yourself lantern hanging from the rafters.
  static void _lantern(Canvas c, Offset hook, TreatLevel level, double t) {
    final color = treatColors[level]!;
    final pulse = level == TreatLevel.yellow ? 0.5 + 0.5 * math.sin(t * 1.6) : 0.75 + 0.25 * math.sin(t * 3.1);
    final body = Rect.fromLTWH(hook.dx - 8, hook.dy + 10, 16, 24);
    c.drawLine(hook, Offset(hook.dx, body.top - 4), Kit.stroke(const Color(0xFF451A03), 1.2));
    Kit.glow(c, body.center, 30 + pulse * 6, color, 0.4 + pulse * 0.2);
    c.drawPath(Path()..moveTo(body.left - 3, body.top)..lineTo(hook.dx, body.top - 7)..lineTo(body.right + 3, body.top)..close(),
        Kit.fill(const Color(0xFF92400E)));
    c.drawRRect(Kit.rr(body, 4), Kit.vertical(body, [Color.lerp(color, const Color(0xFFFFFFFF), 0.45)!, color]));
    c.drawRRect(Kit.rr(body, 4), Kit.stroke(Pal.outline, 1.4));
    final flame = 0.9 + 0.1 * math.sin(t * 11);
    c.drawOval(Kit.oval(body.center.translate(0, 2), 2.6, 5 * flame), Kit.fill(const Color(0xCCFFFBEB)));
  }
}

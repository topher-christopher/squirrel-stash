import 'dart:math' as math;
import 'dart:ui';

import '../../models/bird.dart';
import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import '../layout.dart';
import 'diorama_layer.dart';

/// Interconnected colony paths: wooden catwalks bridging the lift shaft
/// between the hero rooms and the compact rooms (double-duty squirrels
/// commute across), and the seed-bag rope lift running down the outer bark
/// from the bird feeder branch to the Scavenger Burrow.
class CatwalksLayer extends DioramaLayer {
  CatwalksLayer() : super(priority: 35);

  /// (left door x, left floor y, right door x, right floor y)
  static const _bridges = [(346.0, 390.0, 382.0, 384.0), (346.0, 554.0, 382.0, 540.0)];

  @override
  void render(Canvas canvas) {
    for (var i = 0; i < _bridges.length; i++) {
      _bridge(canvas, _bridges[i], i);
    }
    _ropeLift(canvas);
  }

  void _bridge(Canvas c, (double, double, double, double) b, int i) {
    final (lx, ly, rx, ry) = b;
    // Doorways cut into each room's wall
    for (final (x, y) in [(lx - 5, ly), (rx + 5, ry)]) {
      final door = Rect.fromLTRB(x - 6, y - 22, x + 6, y);
      c.drawRRect(RRect.fromRectAndCorners(door, topLeft: const Radius.circular(6), topRight: const Radius.circular(6)),
          Kit.fill(const Color(0xFF140A04)));
      c.drawRRect(RRect.fromRectAndCorners(door, topLeft: const Radius.circular(6), topRight: const Radius.circular(6)),
          Kit.stroke(const Color(0xFF8B5A2B), 1.2));
    }
    // Plank walkway and rope rails
    final a = Offset(lx - 2, ly), z = Offset(rx + 2, ry);
    c.drawLine(a, z, Kit.stroke(const Color(0xFF5C3419), 5));
    c.drawLine(a.translate(0, -1.5), z.translate(0, -1.5), Kit.stroke(const Color(0xFF9A5B2C), 2));
    for (var k = 1; k < 6; k++) {
      final p = Offset.lerp(a, z, k / 6)!;
      c.drawLine(p.translate(0, -2), p.translate(0, 2), Kit.stroke(const Color(0x66000000), 0.8));
    }
    final rail = Path()
      ..moveTo(a.dx, a.dy - 12)
      ..quadraticBezierTo((a.dx + z.dx) / 2, (a.dy + z.dy) / 2 - 6, z.dx, z.dy - 12);
    c.drawPath(rail, Kit.stroke(const Color(0xFFD6B48A), 1));
    // A double-duty squirrel commuting between the two rooms
    final period = 8.0 + i * 3;
    final u = Ease.easeInOut(Ease.pingPong(work / period + i * 0.4));
    final toRight = ((work / period + i * 0.4) % 2) < 1;
    final x = lx - 16 + u * (rx - lx + 32);
    final y = ly + (ry - ly) * ((x - lx) / (rx - lx)).clamp(0.0, 1.0);
    SquirrelPainter.paint(c, Offset(x, y - 10), dir: toRight ? 1 : -1, scale: 0.68, time: t, seed: 21.0 + i,
        hop: -math.sin(work * 9 + i).abs() * 1.2,
        look: SquirrelLook(
          acorn: i == 0 && toRight,
          book: i == 1,
          hat: snap.outfits ? (i == 0 ? SquirrelHat.goggles : SquirrelHat.visor) : SquirrelHat.none,
          scarf: snap.frost,
        ),
        pose: i == 1 ? SquirrelPose.researcher : SquirrelPose.idle,
        art: game.art);
  }

  /// Seed bags ride a rope bucket from the burrow up to the feeder branch.
  void _ropeLift(Canvas c) {
    const x = TreeLayout.ropeX;
    const top = 150.0, bottom = 742.0;
    c.drawLine(const Offset(x, top), const Offset(x, bottom), Kit.stroke(const Color(0xFFD6B48A), 1.1));
    c.drawCircle(const Offset(x, top - 3), 4, Kit.fill(const Color(0xFF92400E)));
    c.drawCircle(const Offset(x, top - 3), 4, Kit.stroke(Pal.brass, 1));
    final haul = game.since('ropeHaul');
    double u; // 0 = at the burrow, 1 = at the branch
    if (haul < 7) {
      u = haul < 5 ? Ease.easeInOut(haul / 5) : 1 - (haul - 5) / 2;
    } else {
      u = snap.feederSeed == null && snap.seedBags == 0 ? 0 : Ease.easeInOut(Ease.pingPong(work / 18));
    }
    final y = bottom - (bottom - top - 14) * u.clamp(0.0, 1.0);
    final bucket = Rect.fromCenter(center: Offset(x, y), width: 10, height: 9);
    c.drawLine(Offset(x - 4, y - 4.5), Offset(x, y - 9), Kit.stroke(const Color(0xFF78350F), 0.8));
    c.drawLine(Offset(x + 4, y - 4.5), Offset(x, y - 9), Kit.stroke(const Color(0xFF78350F), 0.8));
    c.drawRRect(Kit.rr(bucket, 2), Kit.fill(const Color(0xFF8B5A2B)));
    if (haul < 5 || snap.seedBags > 0) {
      final tie = switch (snap.feederSeed) {
        SeedKind.berryHickory => const Color(0xFFBE123C),
        SeedKind.goldenHusk => Pal.gold,
        _ => const Color(0xFF65A30D),
      };
      c.drawOval(Kit.oval(Offset(x, y - 5), 4, 3.4), Kit.fill(const Color(0xFFD9B26F)));
      c.drawLine(Offset(x - 2, y - 8), Offset(x + 2, y - 8), Kit.stroke(tie, 1.2));
    }
  }
}

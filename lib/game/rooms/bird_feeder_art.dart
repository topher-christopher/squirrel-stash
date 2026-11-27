import 'dart:math' as math;
import 'dart:ui';

import '../../models/bird.dart';
import '../art/bird_painter.dart';
import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../layout.dart';
import 'room_kit.dart';

/// Canopy Bird Feeder (right branch): the upgradeable birdhouse, a wooden
/// landing perch where visitors touch down before hopping onto the
/// branches, and the hanging feeder showing its seed level and lures.
/// Drawn in world space.
class BirdFeederArt extends RoomArt {
  BirdFeederArt();

  static const _roof = Offset(562, 156);
  static const _tray = Rect.fromLTWH(540, 192, 44, 4);

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    _birdhouse(c, TreeLayout.birdhouse, x.level);
    // Wooden landing perch: a post with a crossbar standing on the limb
    const p = TreeLayout.landingPerch;
    c.drawLine(p.translate(0, 26), p, Kit.stroke(const Color(0xFF6B3D1E), 2.6));
    c.drawLine(p.translate(-13, 0), p.translate(13, 0), Kit.stroke(const Color(0xFF8B5A2B), 3));
    if (x.level >= 3) c.drawLine(p.translate(-9, 10), p.translate(9, 10), Kit.stroke(const Color(0xFF8B5A2B), 2.4));
    // Hanging feeder: rope, roof, glass hopper and seed tray
    const hook = TreeLayout.feederHook;
    c.drawLine(hook, _roof, Kit.stroke(const Color(0xFFD6B48A), 1.1));
    c.drawPath(Path()
      ..moveTo(_roof.dx - 17, _roof.dy + 11)
      ..lineTo(_roof.dx, _roof.dy)
      ..lineTo(_roof.dx + 17, _roof.dy + 11)
      ..close(), Kit.fill(x.level >= 2 ? const Color(0xFF15803D) : const Color(0xFF7C2D12)));
    c.drawRRect(Kit.rr(const Rect.fromLTWH(550, 167, 24, 25), 3), Kit.fill(const Color(0x55E0F2FE)));
    c.drawRRect(Kit.rr(const Rect.fromLTWH(550, 167, 24, 25), 3), Kit.stroke(const Color(0xFF8B5A2B), 1.4));
    c.drawRRect(Kit.rr(_tray, 1.5), Kit.fill(const Color(0xFF8B5A2B)));
    for (final dx in const [-3.0, 47.0]) {
      c.drawLine(Offset(_tray.left + dx, _tray.top + 2), Offset(_tray.left + dx + (dx < 0 ? -5 : 5), _tray.top + 2),
          Kit.stroke(const Color(0xFF6B3D1E), 1.4));
    }
    // A tiny carved sign on the limb
    final sign = RoomKit.text('FEEDER', 4.4, const Color(0xCC3B1E0B), spacing: 0.8);
    c.drawRRect(Kit.rr(Rect.fromLTWH(522, 176, sign.width + 6, 7), 1.5), Kit.fill(const Color(0xFFD6B48A)));
    sign.paint(c, Offset(525, 176.5));
  }

  static void _birdhouse(Canvas c, Offset base, int level) {
    final stories = level.clamp(1, 3);
    var floor = base.dy;
    for (var s = 0; s < stories; s++) {
      final w = 24.0 - s * 4, h = 18.0 - s * 2;
      final box = Rect.fromLTWH(base.dx - w / 2, floor - h, w, h);
      final wall = switch (level) { >= 3 => const Color(0xFFFDE68A), 2 => const Color(0xFF60A5FA), _ => const Color(0xFFD6B48A) };
      c.drawRect(box, Kit.fill(wall));
      c.drawRect(box, Kit.stroke(const Color(0xFF7C4A22), 1));
      c.drawCircle(box.center.translate(0, -1), 3, Kit.fill(const Color(0xFF1C1917)));
      if (level >= 2) {
        c.drawLine(Offset(box.center.dx, box.center.dy + 3), Offset(box.center.dx, box.center.dy + 6),
            Kit.stroke(const Color(0xFF7C4A22), 1.2));
      }
      floor -= h;
    }
    final topW = 30.0 - (stories - 1) * 4;
    c.drawPath(Path()
      ..moveTo(base.dx - topW / 2, floor + 1)
      ..lineTo(base.dx, floor - 12)
      ..lineTo(base.dx + topW / 2, floor + 1)
      ..close(), Kit.fill(level >= 3 ? const Color(0xFFB91C1C) : const Color(0xFF7C2D12)));
    if (level >= 2) {
      // Flower box
      c.drawRect(Rect.fromLTWH(base.dx - 10, base.dy - 3, 20, 4), Kit.fill(const Color(0xFF8B5A2B)));
      for (var k = 0; k < 4; k++) {
        c.drawCircle(Offset(base.dx - 7 + k * 4.6, base.dy - 4.4), 1.6, Kit.fill(k.isEven ? const Color(0xFFF472B6) : const Color(0xFFFDE047)));
      }
    }
    if (level >= 3) {
      // Acorn weathervane
      c.drawLine(Offset(base.dx, floor - 12), Offset(base.dx, floor - 24), Kit.stroke(Pal.brass, 1));
      c.drawLine(Offset(base.dx - 6, floor - 21), Offset(base.dx + 6, floor - 21), Kit.stroke(Pal.brass, 1));
      Kit.acorn(c, Offset(base.dx + 7, floor - 21), rx: 2, ry: 2.4, body: Pal.brass, strokeWidth: 0.5);
    }
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final s = x.snap;
    // Seed level in the glass hopper and spilled seed on the tray
    if (s.feederSeed != null && s.feederFill > 0) {
      final color = switch (s.feederSeed!) {
        SeedKind.sunflowerMillet => const Color(0xFF9CA3AF),
        SeedKind.berryHickory => const Color(0xFFBE123C),
        SeedKind.goldenHusk => Pal.gold,
      };
      final h = 23 * s.feederFill;
      final fill = Rect.fromLTWH(551, 191 - h, 22, h);
      c.drawRect(fill, Kit.fill(color));
      final rng = math.Random(4);
      for (var k = 0; k < (h * 1.4).round(); k++) {
        c.drawCircle(Offset(fill.left + rng.nextDouble() * 22, fill.top + rng.nextDouble() * h), 0.6,
            Kit.fill(const Color(0x88000000)));
      }
      for (var k = 0; k < 6; k++) {
        c.drawCircle(Offset(_tray.left + 6 + k * 6.0, _tray.top - 0.6), 1, Kit.fill(color));
      }
    }
    if (s.lure == LureKind.berrySuet) {
      final cake = Rect.fromCenter(center: const Offset(562, 206), width: 10, height: 8);
      c.drawLine(const Offset(562, 196), cake.topCenter, Kit.stroke(const Color(0xFF94A3B8), 0.7));
      c.drawRect(cake, Kit.fill(const Color(0xFFFDE68A)));
      for (var k = 0; k < 4; k++) {
        c.drawCircle(Offset(cake.left + 2 + k * 2.2, cake.top + 2 + (k % 2) * 3.0), 1, Kit.fill(const Color(0xFFBE123C)));
      }
      c.drawRect(cake, Kit.stroke(const Color(0xFF64748B), 0.6));
    }
    if (s.lure == LureKind.deluxeFeast) {
      for (final p in _deluxePerches) {
        c.drawLine(Offset(p.dx, _tray.bottom), p.translate(0, -4), Kit.stroke(const Color(0xFF94A3B8), 0.6));
        c.drawCircle(p.translate(0, 1), 4, Kit.stroke(const Color(0xFFFBBF24), 1));
      }
      c.drawCircle(const Offset(556, 191), 2.6, Kit.fill(const Color(0xFFFB923C)));
      c.drawCircle(const Offset(570, 191), 2.6, Kit.fill(const Color(0xFFFB923C)));
    }
    if (x.level >= 3 && x.lit) {
      Kit.glow(c, TreeLayout.birdhouse.translate(0, -20), 16, const Color(0xFFFDE68A), 0.3 + 0.1 * math.sin(x.t * 2));
    }
    _visitors(c, x);
  }

  static const _deluxePerches = [Offset(550, 205), Offset(574, 205)];

  /// Tray left, tray right, the open songbird perch under the Owl Lantern,
  /// then the two Deluxe Feast perch rings.
  static const _spots = [Offset(545, 192), Offset(580, 192), Offset(36, 196), Offset(550, 205), Offset(574, 205)];

  /// Visitors fly in, land on the wooden perch, hop to a feeding spot,
  /// peck a while and fly off. Critters scamper along the branch instead.
  void _visitors(Canvas c, RoomCtx x) {
    final s = x.snap;
    if (s.feederSeed == null) return;
    final max = s.lure == LureKind.deluxeFeast ? 5 : 3;
    final birds = s.perched.take(max).toList();
    for (var i = 0; i < birds.length; i++) {
      final b = birds[i];
      final dest = switch (b) {
        BirdSpecies.baldEagle => const Offset(578, 134),
        BirdSpecies.greatHornedOwl => const Offset(66, 146),
        BirdSpecies.peregrine => TreeLayout.birdhouse.translate(0, -30 - (x.level - 1) * 16.0),
        _ => _spots[i],
      };
      if (b.critter) {
        _critter(c, x, b, dest, i);
      } else {
        _flyer(c, x, b, dest, i);
      }
    }
  }

  void _flyer(Canvas c, RoomCtx x, BirdSpecies b, Offset dest, int i) {
    const period = 16.0;
    final t = (x.t + i * 5.3) % period;
    final seed = i * 1.7;
    final from = b == BirdSpecies.greatHornedOwl ? const Offset(-30, 90) : Offset(640, 70.0 + i * 18);
    final perch = b.large ? dest : TreeLayout.landingPerch;
    if (t < 1.5) {
      final u = Ease.easeInOut(t / 1.5);
      final p = Offset.lerp(from, perch, u)!.translate(0, -math.sin(u * math.pi) * 18);
      BirdPainter.paint(c, p, b, dir: perch.dx < from.dx ? -1 : 1, time: x.t, seed: seed, flying: true);
    } else if (t < 3.3 && !b.large) {
      BirdPainter.paint(c, perch, b, dir: math.sin(x.t * 1.3 + i) > 0 ? 1 : -1, time: x.t, seed: seed);
    } else if (t < 3.9 && !b.large) {
      final u = (t - 3.3) / 0.6;
      final p = Offset.lerp(perch, dest, u)!.translate(0, -math.sin(u * math.pi) * 10);
      BirdPainter.paint(c, p, b, dir: dest.dx >= perch.dx ? 1 : -1, time: x.t, seed: seed, flying: true);
    } else if (t < 14.5) {
      BirdPainter.paint(c, dest, b, dir: dest.dx > 562 ? -1 : 1, time: x.t, seed: seed, peck: !b.large);
    } else {
      final u = (t - 14.5) / 1.5;
      final p = Offset.lerp(dest, Offset(640, 30.0 + i * 12), u * u)!;
      BirdPainter.paint(c, p, b, dir: 1, time: x.t, seed: seed, flying: true);
    }
  }

  void _critter(Canvas c, RoomCtx x, BirdSpecies b, Offset dest, int i) {
    const period = 16.0;
    final t = (x.t + i * 5.3) % period;
    Offset p;
    var dir = 1.0;
    if (t < 2.4) {
      p = TreeLayout.limbAt(TreeLayout.rightLimb, 0.05 + 0.75 * (t / 2.4)).translate(0, -2);
    } else if (t < 3.0) {
      final u = (t - 2.4) / 0.6;
      final start = TreeLayout.limbAt(TreeLayout.rightLimb, 0.8).translate(0, -2);
      p = Offset.lerp(start, dest, u)!.translate(0, -math.sin(u * math.pi) * 12);
    } else if (t < 13.6) {
      p = dest;
      dir = dest.dx > 562 ? -1 : 1;
    } else {
      final u = (t - 13.6) / 2.4;
      p = TreeLayout.limbAt(TreeLayout.rightLimb, 0.8 - 0.75 * u).translate(0, -2);
      dir = -1;
    }
    BirdPainter.paint(c, p, b, dir: dir, time: x.t, seed: i * 1.7);
  }
}

import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../art/squirrel_painter.dart';
import '../layout.dart';
import 'room_kit.dart';

/// Grass-level Scavenger Burrow Outpost: a dug-out prep alcove in the
/// trunk's foot (backpacks on hooks), a grassy mound with the burrow hole
/// right on the ground line, ready-to-pour seed bags stacked by the door,
/// and squads that pop out with backpacks and sprint home with seed bags.
/// Drawn in world space.
class BurrowArt extends RoomArt {
  const BurrowArt();

  static const _alcove = Rect.fromLTWH(404, 680, 150, 62);
  static const _hooks = [Offset(420, 696), Offset(442, 696), Offset(464, 696)];

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    // Prep alcove dug into the trunk's foot
    c.drawRRect(Kit.rr(_alcove, 12), Kit.vertical(_alcove, const [Color(0xFF3A2010), Color(0xFF24130A)]));
    final rng = math.Random(23);
    for (var k = 0; k < 18; k++) {
      c.drawCircle(Offset(_alcove.left + rng.nextDouble() * _alcove.width, _alcove.top + rng.nextDouble() * _alcove.height),
          0.8 + rng.nextDouble() * 1.4, Kit.fill(const Color(0x22000000)));
    }
    c.drawLine(Offset(_alcove.left + 8, _hooks.first.dy - 4), Offset(_alcove.left + 76, _hooks.first.dy - 4),
        Kit.stroke(const Color(0xFF6B3D1E), 2));
    for (final h in _hooks) {
      c.drawLine(h.translate(0, -4), h, Kit.stroke(const Color(0xFF94A3B8), 1.2));
    }
    // Quartermaster's table with a seed scale, and a sack pile
    final table = Rect.fromLTWH(_alcove.left + 92, _alcove.bottom - 22, 40, 4);
    c.drawRect(table, Kit.fill(const Color(0xFF8B5A2B)));
    for (final dx in const [3.0, 36.0]) {
      c.drawLine(Offset(table.left + dx, table.bottom), Offset(table.left + dx, _alcove.bottom - 4),
          Kit.stroke(const Color(0xFF6B3D1E), 1.6));
    }
    final scale = Offset(table.left + 28, table.top);
    c.drawLine(scale, scale.translate(0, -9), Kit.stroke(Pal.brass, 1));
    c.drawLine(scale.translate(-6, -9), scale.translate(6, -9), Kit.stroke(Pal.brass, 1));
    for (final dx in const [-6.0, 6.0]) {
      c.drawArc(Rect.fromCenter(center: scale.translate(dx, -6), width: 6, height: 4), 0, math.pi, false, Kit.stroke(Pal.brass, 0.9));
    }
    for (var k = 0; k < 3; k++) {
      c.drawOval(Kit.oval(Offset(_alcove.right - 16 - (k % 2) * 9.0, _alcove.bottom - 8 - (k ~/ 2) * 7.0), 5, 4.4),
          Kit.fill(const Color(0xFFC9A061)));
    }
    if (x.level >= 2) {
      RoomKit.shelf(c, _alcove.left + 90, _alcove.right - 8, _alcove.top + 18);
      for (var k = 0; k < 3; k++) {
        c.drawOval(Kit.oval(Offset(_alcove.left + 100 + k * 14.0, _alcove.top + 15), 4, 3), Kit.fill(const Color(0xFFD9B26F)));
      }
    }
    if (x.level >= 3) {
      // Expedition map pinned to the wall
      final map = Rect.fromLTWH(_alcove.left + 96, _alcove.top + 26, 30, 20);
      c.drawRect(map, Kit.fill(const Color(0xFFFEF3C7)));
      c.drawPath(Path()..moveTo(map.left + 3, map.bottom - 4)..quadraticBezierTo(map.center.dx, map.top, map.right - 4, map.top + 6),
          Kit.stroke(const Color(0xFFDC2626), 0.8));
      c.drawCircle(Offset(map.right - 4, map.top + 6), 1.4, Kit.fill(const Color(0xFFDC2626)));
    }
    c.drawRRect(Kit.rr(_alcove, 12), Kit.stroke(const Color(0x88000000), 3));
    _mound(c, x);
  }

  void _mound(Canvas c, RoomCtx x) {
    final snowy = x.snap.frost || x.snap.winter;
    final mound = Path()
      ..moveTo(410, 782)
      ..quadraticBezierTo(500, 690, 598, 782)
      ..close();
    c.drawPath(mound, Kit.vertical(const Rect.fromLTRB(410, 735, 598, 782),
        snowy ? const [Color(0xFFF8FAFC), Color(0xFFCBD5E1)] : const [Color(0xFF84CC16), Pal.grassDark]));
    for (var k = 0; k < 12; k++) {
      final px = 432 + k * 13.0;
      final py = 760 - math.sin((px - 410) / 188 * math.pi) * 22;
      c.drawLine(Offset(px, py + 3), Offset(px - 2, py - 2), Kit.stroke(snowy ? const Color(0xFF94A3B8) : Pal.grassDark, 1.1));
    }
    const hole = TreeLayout.burrowHole;
    if (x.level >= 3) {
      // Stone arch
      for (var k = 0; k < 7; k++) {
        final a = math.pi + k * math.pi / 6;
        c.drawCircle(hole + Offset(math.cos(a) * 18, math.sin(a) * 15 + 1), 3.6, Kit.fill(const Color(0xFFA8A29E)));
      }
    } else if (x.level == 2) {
      // Little wooden door frame
      c.drawLine(hole.translate(-15, 2), hole.translate(-15, -13), Kit.stroke(const Color(0xFF8B5A2B), 2.4));
      c.drawLine(hole.translate(15, 2), hole.translate(15, -13), Kit.stroke(const Color(0xFF8B5A2B), 2.4));
      c.drawLine(hole.translate(-17, -13), hole.translate(17, -13), Kit.stroke(const Color(0xFF8B5A2B), 2.6));
    }
    c.drawOval(Kit.oval(hole, 14, 10), Kit.fill(const Color(0xFF1A0D05)));
    c.drawOval(Kit.oval(hole.translate(0, 2), 10, 6), Kit.fill(const Color(0xFF0C0603)));
    c.drawOval(Kit.oval(hole.translate(-20, 9), 9, 3), Kit.fill(const Color(0xFF5C3419)));
    // Signpost
    c.drawLine(const Offset(566, 768), const Offset(566, 738), Kit.stroke(const Color(0xFF6B3D1E), 2));
    final sign = RoomKit.text('SCAVENGER', 4.2, const Color(0xFF3B1E0B), spacing: 0.4);
    final sign2 = RoomKit.text('BURROW', 4.2, const Color(0xFF3B1E0B), spacing: 0.8);
    final board = Rect.fromLTWH(566 - sign.width / 2 - 3, 730, sign.width + 6, 13);
    c.drawRRect(Kit.rr(board, 1.5), Kit.fill(const Color(0xFFD6B48A)));
    sign.paint(c, Offset(566 - sign.width / 2, 730.5));
    sign2.paint(c, Offset(566 - sign2.width / 2, 736.5));
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final s = x.snap;
    final home = math.max(0, s.squads - s.expeditionsOut);
    for (var i = 0; i < _hooks.length; i++) {
      if (i < home) _hangingPack(c, _hooks[i]);
    }
    RoomKit.lamp(c, Offset(_alcove.left + 84, _alcove.top + 8), x.t, size: 0.7);
    // The quartermaster packs seed scoops (or waits by the map when everyone's out)
    SquirrelPainter.paint(c, Offset(_alcove.left + 104, _alcove.bottom - 18), dir: 1, scale: 0.7, time: x.t, seed: 53,
        pose: s.expeditionsOut > 0 ? SquirrelPose.researcher : SquirrelPose.toss,
        look: SquirrelLook(book: s.expeditionsOut > 0, scarf: x.frost), art: x.art);
    // Ready-to-pour seed bags by the door
    for (var k = 0; k < math.min(4, s.seedBags); k++) {
      final p = Offset(492 + (k % 2) * 10.0 + (k ~/ 2) * 5, 770 - (k ~/ 2) * 8.0);
      c.drawOval(Kit.oval(p, 5, 4.4), Kit.fill(const Color(0xFFD9B26F)));
      c.drawLine(p.translate(-2, -4), p.translate(2, -4), Kit.stroke(const Color(0xFF65A30D), 1.2));
      c.drawOval(Kit.oval(p, 5, 4.4), Kit.stroke(const Color(0xFF7C5A22), 0.6));
    }
    const hole = TreeLayout.burrowHole;
    if (s.expeditionsOut > 0) {
      // "Out foraging" pennant and footprints heading off the map
      final pole = hole.translate(-26, 0);
      c.drawLine(pole, pole.translate(0, -22), Kit.stroke(const Color(0xFF8B5A2B), 1.2));
      final wave = math.sin(x.t * 4) * 2;
      c.drawPath(Path()
        ..moveTo(pole.dx, pole.dy - 22)
        ..quadraticBezierTo(pole.dx + 6, pole.dy - 20 + wave, pole.dx + 12, pole.dy - 18)
        ..lineTo(pole.dx, pole.dy - 14)
        ..close(), Kit.fill(const Color(0xFF65A30D)));
      for (var k = 0; k < 6; k++) {
        c.drawOval(Kit.oval(Offset(hole.dx + 24 + k * 13.0, 772 + (k.isEven ? 1 : -1)), 1.6, 0.9), Kit.fill(const Color(0x88451A03)));
      }
    }
    final out = x.since('burrowOut');
    final back = x.since('burrowBack');
    if (out < 3) {
      _depart(c, x, out);
    } else if (back < 3) {
      _return(c, x, back);
    } else if (home > 0) {
      _peek(c, x);
    }
  }

  static void _hangingPack(Canvas c, Offset hook) {
    final pack = Rect.fromLTWH(hook.dx - 5, hook.dy, 10, 13);
    c.drawRRect(Kit.rr(pack, 3), Kit.fill(const Color(0xFF4D7C0F)));
    c.drawRRect(Kit.rr(Rect.fromLTWH(pack.left + 1.5, pack.top + 6, 7, 5), 2), Kit.fill(const Color(0xFF65A30D)));
    c.drawRRect(Kit.rr(Rect.fromLTWH(pack.left - 0.5, pack.top - 2.6, 11, 3), 1.4), Kit.fill(const Color(0xFFB45309)));
  }

  /// Pops out of the hole with a backpack, then sprints off the map.
  static void _depart(Canvas c, RoomCtx x, double s) {
    const hole = TreeLayout.burrowHole;
    if (s < 0.5) {
      c.save();
      c.clipRect(const Rect.fromLTRB(440, 700, 500, 768));
      SquirrelPainter.paint(c, hole.translate(0, 18 - s / 0.5 * 26), scale: 0.72, time: x.t, seed: 50,
          look: const SquirrelLook(backpack: true), art: x.art);
      c.restore();
      return;
    }
    final u = ((s - 0.5) / 2.3).clamp(0.0, 1.0);
    SquirrelPainter.paint(c, Offset(hole.dx + u * u * 180, hole.dy - 8), scale: 0.72, time: x.t, seed: 50,
        hop: -math.sin(s * 18).abs() * 2, look: const SquirrelLook(backpack: true), art: x.art);
  }

  /// Sprints home carrying a seed bag and dives into the hole.
  static void _return(Canvas c, RoomCtx x, double s) {
    const hole = TreeLayout.burrowHole;
    if (s < 2.3) {
      final u = Ease.easeInOut(s / 2.3);
      SquirrelPainter.paint(c, Offset(640 - (640 - hole.dx) * u, hole.dy - 8), dir: -1, scale: 0.72, time: x.t, seed: 51,
          hop: -math.sin(s * 18).abs() * 2, look: const SquirrelLook(backpack: true, seedBag: Color(0xFF65A30D)), art: x.art);
      return;
    }
    final d = ((s - 2.3) / 0.5).clamp(0.0, 1.0);
    c.save();
    c.clipRect(const Rect.fromLTRB(440, 700, 500, 768));
    SquirrelPainter.paint(c, hole.translate(0, -8 + d * 26), dir: -1, scale: 0.72, time: x.t, seed: 51,
        look: const SquirrelLook(backpack: true, seedBag: Color(0xFF65A30D)), art: x.art);
    c.restore();
  }

  /// A scout peeks out of the hole now and then.
  static void _peek(Canvas c, RoomCtx x) {
    final cycle = x.work % 8;
    if (cycle > 2.2) return;
    final rise = math.sin(cycle / 2.2 * math.pi);
    const hole = TreeLayout.burrowHole;
    c.save();
    c.clipRect(const Rect.fromLTRB(440, 700, 500, 768));
    SquirrelPainter.paint(c, hole.translate(0, 18 - rise * 16), dir: -1, scale: 0.7, time: x.t, seed: 52, art: x.art);
    c.restore();
  }
}

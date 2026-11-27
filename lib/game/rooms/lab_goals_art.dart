import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import '../diorama_snapshot.dart';
import 'room_kit.dart';

/// Foraging & Willpower Lab: the sand-art silo filling with this month's
/// wins, bubbling beakers and the researcher squirrel.
class LabArt extends RoomArt {
  LabArt();

  double _fill = 0.12, _skip = 0, _down = 0, _diy = 1;

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    RoomKit.shell(c, x, wall: const Color(0xFF213029));
    final r = x.r;
    final floor = x.floorY;
    c.drawRRect(Kit.rr(Rect.fromLTWH(r.left + 78, floor - 24, 84, 24), 2), Kit.fill(const Color(0xFF6B3D1E)));
    c.drawRect(Rect.fromLTWH(r.left + 76, floor - 26, 88, 4), Kit.fill(const Color(0xFF94A3B8)));
    if (x.level >= 2) {
      RoomKit.shelf(c, r.left + 84, r.right - 10, r.top + 40);
      for (var k = 0; k < 4; k++) {
        c.drawCircle(Offset(r.left + 96 + k * 16.0, r.top + 34), 4.4,
            Kit.fill(const [Color(0x9938BDF8), Color(0x9910B981), Color(0x99F59E0B), Color(0x99C084FC)][k]));
      }
    }
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final k = 0.05;
    _fill += (x.snap.siloFill - _fill) * k;
    _skip += (x.snap.skipFraction - _skip) * k;
    _down += (x.snap.downsizeFraction - _down) * k;
    _diy += (x.snap.diyFraction - _diy) * k;
    final r = x.r;
    final floor = x.floorY;
    _silo(c, Rect.fromLTWH(r.left + 18, r.top + 22, 40, floor - r.top - 26), x.t);
    // Bubbling flasks on the bench
    for (var f = 0; f < 2; f++) {
      final base = Offset(r.left + 96 + f * 26.0, floor - 26);
      final color = f == 0 ? Pal.sandDownsize : Pal.sandSkip;
      c.drawPath(Path()..moveTo(base.dx - 7, base.dy)..lineTo(base.dx - 2, base.dy - 10)..lineTo(base.dx - 2, base.dy - 16)
        ..lineTo(base.dx + 2, base.dy - 16)..lineTo(base.dx + 2, base.dy - 10)..lineTo(base.dx + 7, base.dy)..close(),
          Kit.fill(Kit.a(color, 0.75)));
      for (var b = 0; b < 2; b++) {
        final ph = (x.t * 0.8 + b * 0.5 + f * 0.3) % 1.0;
        c.drawCircle(base.translate(b * 2.0 - 1, -16 - ph * 10), 1.4 * (1 - ph), Kit.fill(Kit.a(color, 0.8)));
      }
    }
    SquirrelPainter.paint(c, Offset(r.left + 146, floor - 14 + math.sin(x.t * 2.4) * 0.8),
        dir: -1, scale: 0.92, time: x.t, seed: 0.7, pose: SquirrelPose.researcher,
        look: SquirrelLook(hat: x.snap.outfits ? SquirrelHat.goggles : SquirrelHat.none, scarf: x.frost),
        art: x.art);
  }

  void _silo(Canvas c, Rect tube, double t) {
    c.drawRRect(Kit.rr(tube, 16), Kit.fill(const Color(0xD91A0E06)));
    final inner = tube.deflate(3);
    c.save();
    c.clipRRect(Kit.rr(inner, 13));
    final total = inner.height * _fill;
    var y = inner.bottom;
    for (final (frac, color) in [(_diy, Pal.sandDiy), (_down, Pal.sandDownsize), (_skip, Pal.sandSkip)]) {
      final h = total * frac;
      if (h < 0.5) continue;
      final layer = Rect.fromLTRB(inner.left, y - h, inner.right, y + 0.5);
      c.drawRect(layer, Kit.vertical(layer, [Color.lerp(color, const Color(0xFFFFFFFF), 0.18)!, color]));
      y -= h;
    }
    c.drawPath(Path()..moveTo(inner.left, y + 1)..quadraticBezierTo(inner.center.dx, y - 3 + math.sin(t * 1.2), inner.right, y)
      ..lineTo(inner.right, y + 2)..lineTo(inner.left, y + 2)..close(), Kit.fill(const Color(0x55FFFFFF)));
    c.restore();
    c.drawRRect(Kit.rr(tube, 16), Kit.stroke(Pal.brass, 2));
    c.drawRRect(Kit.rr(Rect.fromLTWH(tube.left + 5, tube.top + 8, 4, tube.height - 16), 2), Kit.fill(const Color(0x2EFFFFFF)));
  }
}

/// Goal Chambers: up to three chests that evolve Dirt Alcove → Timber
/// Chamber → Gold Treasury, a dig slot, and the hauler squirrel.
class GoalsArt extends RoomArt {
  const GoalsArt();

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    RoomKit.shell(c, x, earthy: true);
    final r = x.r;
    if (x.level >= 2) {
      c.drawRRect(Kit.rr(Rect.fromLTWH(r.left + 8, r.top + 8, r.width - 16, 6), 3), Kit.fill(const Color(0xFF6B3D1E)));
    }
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final r = x.r;
    final floor = x.floorY;
    final goals = x.snap.goals;
    for (var i = 0; i < 3; i++) {
      final center = Offset(r.left + 32 + i * 54.0, floor - 2);
      if (i < goals.length) {
        _chest(c, center, goals[i], x);
      } else if (i == goals.length) {
        Kit.dashedRRect(c, Kit.rr(Rect.fromCenter(center: center.translate(0, -12), width: 34, height: 26), 6),
            Kit.stroke(Color.fromRGBO(217, 119, 6, 0.5 + 0.3 * math.sin(x.t * 2)), 1.4));
        c.drawLine(center.translate(-5, -12), center.translate(5, -12), Kit.stroke(const Color(0xFFD97706), 1.6));
        c.drawLine(center.translate(0, -17), center.translate(0, -7), Kit.stroke(const Color(0xFFD97706), 1.6));
      }
    }
    // Hauler carrying a golden acorn back and forth from the lift
    final u = Ease.pingPong(x.t / 5);
    final dir = (x.t / 5) % 2 < 1 ? -1.0 : 1.0;
    SquirrelPainter.paint(c, Offset(r.left + 20 + (1 - u) * (r.width - 40), r.top + 50),
        dir: dir, scale: 0.75, time: x.t, seed: 1.9, hop: -math.sin(x.t * 8).abs() * 1.2,
        look: SquirrelLook(acorn: dir < 0, golden: true, scarf: x.frost,
            hat: x.snap.outfits ? SquirrelHat.knight : SquirrelHat.none),
        art: x.art);
  }

  static void _chest(Canvas c, Offset o, GoalArt g, RoomCtx x) {
    final t = x.t;
    final custom = x.art.prop('chest_lv${g.level}');
    if (custom != null) {
      c.drawImageRect(custom, Rect.fromLTWH(0, 0, custom.width.toDouble(), custom.height.toDouble()),
          Rect.fromCenter(center: o.translate(0, -12), width: 34, height: 28), Paint()..filterQuality = FilterQuality.medium);
      return;
    }
    final trim = g.level == 3 ? const Color(0xFFFDE047) : const Color(0xFFF59E0B);
    if (g.level == 3) Kit.glow(c, o.translate(0, -14), 24, const Color(0xFFFDE047), 0.45);
    if (g.priority) Kit.glow(c, o.translate(0, -12), 20, const Color(0xFFFDE68A), 0.18 + 0.1 * math.sin(t * 2));
    c.drawOval(Kit.oval(o.translate(0, 1), 17, 3), Kit.fill(const Color(0x55000000)));
    final box = Rect.fromLTWH(o.dx - 15, o.dy - 20, 30, 20);
    c.drawRRect(Kit.rr(box, 4), Kit.fill(g.level == 1 ? const Color(0xFF5C3419) : const Color(0xFF78350F)));
    c.drawRRect(Kit.rr(box, 4), Kit.stroke(trim, 1.3));
    if (g.percent >= 40) {
      final bob = math.sin(t * 2.2) * 0.6;
      for (final dx in const [-6.0, 0.0, 6.0]) {
        c.drawCircle(o.translate(dx, -20 + bob - (dx == 0 ? 2 : 0)), 4.2, Kit.fill(Pal.gold));
      }
    }
    final lid = g.level == 3 ? -3.0 : 0.0;
    c.drawRRect(Kit.rr(Rect.fromLTWH(o.dx - 16, o.dy - 23 + lid, 32, 6.5), 2), Kit.fill(const Color(0xFF92400E)));
    c.drawRect(Rect.fromLTWH(o.dx - 2, o.dy - 18, 4, 5), Kit.fill(trim));
    // Progress meter under the chest
    final bar = Rect.fromLTWH(o.dx - 16, o.dy + 4, 32, 3.4);
    c.drawRRect(Kit.rr(bar, 1.7), Kit.fill(const Color(0x66000000)));
    final fill = Rect.fromLTWH(bar.left, bar.top, bar.width * (g.percent / 100).clamp(0, 1), bar.height);
    if (fill.width > 0) {
      c.drawRRect(Kit.rr(fill, 1.7), Kit.linear(fill.centerLeft, fill.centerRight, const [Color(0xFFD97706), Color(0xFFFDE047)]));
    }
  }
}

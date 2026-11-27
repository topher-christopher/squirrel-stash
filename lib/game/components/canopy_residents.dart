import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import '../diorama_event.dart';
import '../layout.dart';
import '../rooms/treasury_art.dart';
import 'diorama_layer.dart';

/// Life in the crown: front limbs, the birdhouse Treat beacon, Professor
/// Hoot, the hammock napper, fairy-light garlands and branch runners.
class CanopyResidents extends DioramaLayer {
  CanopyResidents() : super(priority: 50);

  static const _lightColors = [Color(0xFFFDE047), Color(0xFF38BDF8), Color(0xFF4ADE80), Color(0xFFF9A8D4)];
  static const _swags = [
    (Offset(18, 196), Offset(110, 236), Offset(198, 206)),
    (Offset(402, 206), Offset(490, 236), Offset(584, 192)),
  ];

  static Offset _q(Offset a, Offset c, Offset b, double u) =>
      a * ((1 - u) * (1 - u)) + c * (2 * (1 - u) * u) + b * (u * u);

  @override
  void render(Canvas canvas) {
    _frontLimbs(canvas);
    _hammock(canvas);
    _beacon(canvas);
    _hoot(canvas);
    if (snap.fairyLights) _fairyLights(canvas);
    _branchRunners(canvas);
  }

  void _frontLimbs(Canvas c) {
    for (final (a, ctrl, b) in const [
      (Offset(150, 214), Offset(110, 188), Offset(40, 178)),
      (Offset(430, 206), Offset(490, 174), Offset(590, 166)),
    ]) {
      final p = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      c.drawPath(p, Kit.stroke(Pal.limbDark, 12));
      c.drawPath(p, Kit.stroke(Pal.limb, 8));
      if (snap.frost) c.drawPath(p.shift(const Offset(0, -4)), Kit.stroke(const Color(0xEEFFFFFF), 3));
    }
  }

  void _hammock(Canvas c) {
    const a = Offset(440, 194), b = Offset(540, 178);
    final sway = math.sin(t * 0.9) * 3;
    final mid = Offset((a.dx + b.dx) / 2 + sway, 214);
    final leaf = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(mid.dx, mid.dy + 10, b.dx, b.dy)
      ..quadraticBezierTo(mid.dx, mid.dy - 2, a.dx, a.dy)
      ..close();
    c.drawPath(leaf, Kit.fill(snap.frost ? const Color(0xFFCBD5E1) : const Color(0xFF65A30D)));
    c.drawPath(leaf, Kit.stroke(const Color(0x66000000), 1));
    SquirrelPainter.paint(c, mid.translate(-2, -9), pose: SquirrelPose.sleep, scale: 0.8, time: t, seed: 4.2,
        look: SquirrelLook(scarf: snap.frost, hat: snap.outfits ? SquirrelHat.beanie : SquirrelHat.none),
        art: game.art);
  }

  void _beacon(Canvas c) {
    const o = TreeLayout.beacon;
    c.drawLine(o.translate(0, -14), o.translate(0, -4), Kit.stroke(const Color(0xFF451A03), 1.2));
    final lit = snap.beacon;
    final color = treatColors[snap.treat]!;
    if (lit) {
      final pulse = 0.7 + 0.3 * math.sin(t * 2.4);
      // Projected glow washing over the canopy
      Kit.glow(c, o.translate(0, 8), 120, color, 0.18 * pulse);
      Kit.glow(c, o.translate(0, 8), 34, color, 0.5 * pulse);
    }
    final house = Rect.fromLTWH(o.dx - 12, o.dy - 2, 24, 22);
    c.drawRRect(Kit.rr(house, 2), Kit.fill(const Color(0xFFB45309)));
    c.drawPath(Path()..moveTo(house.left - 4, house.top + 1)..lineTo(o.dx, house.top - 12)..lineTo(house.right + 4, house.top + 1)..close(),
        Kit.fill(const Color(0xFF7C2D12)));
    c.drawCircle(house.center, 5.5, Kit.fill(lit ? Color.lerp(color, const Color(0xFFFFFFFF), 0.4)! : const Color(0xFF1C1917)));
    c.drawLine(Offset(o.dx, house.bottom - 3), Offset(o.dx, house.bottom + 3), Kit.stroke(const Color(0xFF78350F), 1.4));
  }

  void _hoot(Canvas c) {
    final squash = game.pokeAmount(DioramaEvent.hoot);
    c.save();
    c.translate(TreeLayout.hoot.dx, TreeLayout.hoot.dy);
    c.rotate(math.sin(t * 0.9) * 0.05);
    c.scale(1 + squash * 0.12, 1 - squash * 0.16);
    final brown = Kit.fill(const Color(0xFF78350F));
    c.drawPath(Path()..moveTo(-7, -8)..lineTo(-5, -14)..lineTo(-2, -9)..close(), brown);
    c.drawPath(Path()..moveTo(7, -8)..lineTo(5, -14)..lineTo(2, -9)..close(), brown);
    c.drawOval(Kit.oval(Offset.zero, 8.5, 10.5), brown);
    c.drawOval(Kit.oval(const Offset(0, 2), 5.5, 6.5), Kit.fill(const Color(0xFFFDE68A)));
    final blink = (t % 5.1) < 0.14;
    for (final ex in const [-3.0, 3.0]) {
      if (blink) {
        c.drawLine(Offset(ex - 2, -3), Offset(ex + 2, -3), Kit.stroke(Pal.eye, 1.1));
      } else {
        c.drawCircle(Offset(ex, -3), 2.4, Kit.fill(const Color(0xFFFFFFFF)));
        c.drawCircle(Offset(ex, -3), 1.1, Kit.fill(Pal.eye));
      }
    }
    c.drawPath(Path()..moveTo(-1.4, -1)..lineTo(1.4, -1)..lineTo(0, 2)..close(), Kit.fill(const Color(0xFFF59E0B)));
    c.drawLine(const Offset(-0.6, -3), const Offset(0.6, -3), Kit.stroke(Pal.brass, 0.7));
    c.restore();
    if (snap.hootHasGift) {
      final p = TreeLayout.hoot.translate(10, -10 + math.sin(t * 2.2) * 2);
      Kit.glow(c, p, 8, const Color(0xFFFACC15), 0.5);
      Kit.acorn(c, p, rx: 3.4, ry: 4, body: Pal.gold, strokeWidth: 0.7);
    }
  }

  void _fairyLights(Canvas c) {
    final wire = Kit.stroke(const Color(0xFF5C2E10), 1.2);
    var bulb = 0;
    for (final (a, ctl, b) in _swags) {
      c.drawPath(Path()..moveTo(a.dx, a.dy)..quadraticBezierTo(ctl.dx, ctl.dy, b.dx, b.dy), wire);
      for (var i = 1; i < 9; i++) {
        final p = _q(a, ctl, b, i / 9).translate(0, 4);
        final twinkle = 0.5 + 0.5 * math.sin(t * 2.2 + bulb * 1.3);
        final color = _lightColors[bulb % _lightColors.length];
        Kit.glow(c, p, 8 + twinkle * 3, color, 0.18 + twinkle * 0.22);
        c.drawOval(Kit.oval(p, 2.2, 2.8), Kit.fill(color));
        bulb++;
      }
    }
  }

  /// Squirrels scampering out along the limbs and back.
  void _branchRunners(Canvas c) {
    for (var k = 0; k < 2; k++) {
      final period = 7.0 + k * 2;
      final u = Ease.easeInOut(Ease.pingPong(t / period + k * 0.5));
      final outbound = ((t / period + k * 0.5) % 2) < 1;
      final (a, ctl, b) = k == 0
          ? (const Offset(200, 222), const Offset(120, 190), const Offset(60, 182))
          : (const Offset(400, 214), const Offset(470, 182), const Offset(560, 168));
      final p = _q(a, ctl, b, u);
      final heading = (k == 0) == outbound ? -1.0 : 1.0;
      SquirrelPainter.paint(c, p.translate(0, -12), dir: heading, scale: 0.7, time: t, seed: 10 + k * 3.0,
          hop: -math.sin(t * 10 + k).abs() * 1.6,
          look: SquirrelLook(acorn: !outbound, scarf: snap.frost,
              hat: snap.outfits ? (k == 0 ? SquirrelHat.knight : SquirrelHat.goggles) : SquirrelHat.none),
          art: game.art);
    }
  }
}

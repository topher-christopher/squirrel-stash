import 'dart:math' as math;
import 'dart:ui';

import '../../models/bird.dart';
import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import '../diorama_event.dart';
import '../layout.dart';
import '../rooms/treasury_art.dart';
import 'diorama_layer.dart';

/// Life in the crown: the front limbs, the Owl Moonlight Lantern with its
/// open songbird perch (left branch), Professor Hoot, fairy-light garlands,
/// branch runners and the wild acorn bubbles floating above the canopy.
/// (The bird feeder, landing perch and birdhouse are the Bird Feeder room.)
class CanopyResidents extends DioramaLayer {
  CanopyResidents() : super(priority: 50);

  static const _lightColors = [Color(0xFFFDE047), Color(0xFF38BDF8), Color(0xFF4ADE80), Color(0xFFF9A8D4)];

  @override
  void render(Canvas canvas) {
    _frontLimbs(canvas);
    _owlLantern(canvas);
    _hoot(canvas);
    if (snap.fairyLights) _fairyLights(canvas);
    _branchRunners(canvas);
    _bubbles(canvas);
  }

  static Path _limbPath((Offset, Offset, Offset) l, {double dy = 0}) {
    final (a, c, b) = l;
    return Path()
      ..moveTo(a.dx, a.dy + dy)
      ..quadraticBezierTo(c.dx, c.dy + dy, b.dx, b.dy + dy);
  }

  void _frontLimbs(Canvas c) {
    for (final limb in const [TreeLayout.leftLimb, TreeLayout.rightLimb]) {
      final p = _limbPath(limb, dy: 4);
      c.drawPath(p, Kit.stroke(Pal.limbDark, 12));
      c.drawPath(p, Kit.stroke(Pal.limb, 8));
      if (snap.frost || snap.winter) {
        c.drawPath(p.shift(const Offset(0, -4)), Kit.stroke(const Color(0xEEFFFFFF), 3));
      }
    }
  }

  /// Moon-glass lantern with an owl-shaped brass cap. Glows at dusk, burns
  /// bright with Moonlight Lantern Oil, and takes the Treat color when the
  /// Treat Lantern Beacon look is on.
  void _owlLantern(Canvas c) {
    const hook = TreeLayout.owlLantern;
    final moonOil = snap.lure == LureKind.moonOil;
    final glass = hook.translate(0, 24);
    final color = snap.beacon ? treatColors[snap.treat]! : const Color(0xFFE0F2FE);
    final glow = moonOil ? 1.0 : (snap.twilight ? 0.7 : (snap.beacon ? 0.55 : 0.25));
    final pulse = 0.85 + 0.15 * math.sin(t * 2.2);
    Kit.glow(c, glass, 70, color, 0.16 * glow * pulse);
    Kit.glow(c, glass, 22, color, 0.55 * glow * pulse);
    c.drawLine(hook, hook.translate(0, 10), Kit.stroke(const Color(0xFF451A03), 1.2));
    // Glass globe
    c.drawCircle(glass, 9.5, Kit.fill(Color.lerp(const Color(0xFF64748B), color, 0.35 + 0.6 * glow)!));
    c.drawCircle(glass.translate(-3, -3), 3, Kit.fill(const Color(0x88FFFFFF)));
    c.drawCircle(glass, 9.5, Kit.stroke(Pal.brass, 1.4));
    // Owl cap with ear tufts and two tiny eyes
    final cap = Path()
      ..moveTo(hook.dx - 9, hook.dy + 17)
      ..quadraticBezierTo(hook.dx, hook.dy + 5, hook.dx + 9, hook.dy + 17)
      ..close();
    c.drawPath(cap, Kit.fill(Pal.brassDark));
    for (final s in const [-1.0, 1.0]) {
      c.drawPath(Path()
        ..moveTo(hook.dx + s * 4, hook.dy + 11)
        ..lineTo(hook.dx + s * 8, hook.dy + 6)
        ..lineTo(hook.dx + s * 7.5, hook.dy + 13)
        ..close(), Kit.fill(Pal.brassDark));
      c.drawCircle(Offset(hook.dx + s * 2.6, hook.dy + 13.4), 1.2, Kit.fill(const Color(0xFFFDE68A)));
    }
    // Brass base and the threads holding the open songbird perch
    c.drawRect(Rect.fromCenter(center: glass.translate(0, 10), width: 10, height: 3), Kit.fill(Pal.brassDark));
    const perch = TreeLayout.songPerch;
    c.drawLine(glass.translate(-3, 11), perch.translate(-16, 0), Kit.stroke(const Color(0xAA451A03), 0.8));
    c.drawLine(glass.translate(3, 11), perch.translate(16, 0), Kit.stroke(const Color(0xAA451A03), 0.8));
    c.drawLine(perch.translate(-20, 0), perch.translate(20, 0), Kit.stroke(const Color(0xFF6B3D1E), 2.4));
    if (moonOil) {
      // Moths circling the lantern
      for (var k = 0; k < 3; k++) {
        final a = t * (1.6 + k * 0.3) + k * 2.1;
        final p = glass + Offset(math.cos(a) * (14 + k * 3), math.sin(a * 1.3) * 10);
        c.drawOval(Kit.oval(p, 1.8, 1.0 + 0.6 * math.sin(t * 20 + k).abs()), Kit.fill(const Color(0xFFF5F5F4)));
      }
    }
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
    final asleep = game.wake < 0.5;
    final blink = asleep || (t % 5.1) < 0.14;
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
    for (final limb in const [TreeLayout.leftLimb, TreeLayout.rightLimb]) {
      final pts = [for (var i = 0; i <= 12; i++) TreeLayout.limbAt(limb, 0.06 + i / 12 * 0.86)];
      final path = Path()..moveTo(pts.first.dx, pts.first.dy + 9);
      for (var i = 1; i < pts.length; i++) {
        final mid = Offset((pts[i - 1].dx + pts[i].dx) / 2, (pts[i - 1].dy + pts[i].dy) / 2 + 14);
        path.quadraticBezierTo(mid.dx, mid.dy, pts[i].dx, pts[i].dy + 9);
      }
      c.drawPath(path, wire);
      for (var i = 0; i < pts.length - 1; i++) {
        final p = Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2 + 16);
        final twinkle = 0.5 + 0.5 * math.sin(t * 2.2 + bulb * 1.3);
        final color = _lightColors[bulb % _lightColors.length];
        Kit.glow(c, p, 8 + twinkle * 3, color, 0.18 + twinkle * 0.22);
        c.drawOval(Kit.oval(p, 2.2, 2.8), Kit.fill(color));
        bulb++;
      }
    }
  }

  /// Squirrels scampering out along the great limbs and back.
  void _branchRunners(Canvas c) {
    for (var k = 0; k < 2; k++) {
      final period = 7.0 + k * 2;
      final u = 0.06 + 0.7 * Ease.easeInOut(Ease.pingPong(work / period + k * 0.5));
      final outbound = ((work / period + k * 0.5) % 2) < 1;
      final p = TreeLayout.limbAt(k == 0 ? TreeLayout.leftLimb : TreeLayout.rightLimb, u);
      final heading = (k == 0) == outbound ? -1.0 : 1.0;
      SquirrelPainter.paint(c, p.translate(0, -10), dir: heading, scale: 0.7, time: t, seed: 10 + k * 3.0,
          hop: -math.sin(work * 10 + k).abs() * 1.6,
          look: SquirrelLook(acorn: !outbound, scarf: snap.frost,
              hat: snap.outfits ? (k == 0 ? SquirrelHat.knight : SquirrelHat.goggles) : SquirrelHat.none),
          art: game.art);
    }
  }

  /// Wild acorn bubbles (Clash-of-Clans-style collector), tap to harvest.
  void _bubbles(Canvas c) {
    for (var i = 0; i < snap.acornBubbles && i < TreeLayout.bubbleSpots.length; i++) {
      final p = TreeLayout.bubbleSpots[i].translate(math.sin(t * 1.3 + i) * 2, math.sin(t * 1.7 + i * 1.9) * 3);
      Kit.glow(c, p, 20, const Color(0xFFFDE68A), 0.25);
      c.drawCircle(p, 12, Kit.radial(p.translate(-3, -3), 14,
          const [Color(0x55FFFFFF), Color(0x33BAE6FD), Color(0x66E0F2FE)], const [0, 0.7, 1]));
      c.drawCircle(p, 12, Kit.stroke(const Color(0xCCF0F9FF), 1.1));
      Kit.acorn(c, p.translate(0, 1), rx: 4.6, ry: 5.4, strokeWidth: 0.8);
      c.drawArc(Rect.fromCircle(center: p, radius: 9), 3.6, 1.0, false, Kit.stroke(const Color(0xDDFFFFFF), 1.6));
      final s = (t * 0.6 + i * 0.37) % 1.0;
      Kit.sparkle(c, p.translate(9, -9), 2.4 * math.sin(s * math.pi), const Color(0xFFFFFFFF));
    }
  }
}

import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/skate_kit.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import 'outfitter_props.dart';
import 'room_kit.dart';

/// Acorn Outfitter: an indoor mini half-pipe skatepark and DJ club lounge
/// under a spinning mirror disco ball, with the Giant Framed Pokémon Card,
/// 35mm film canister barrels and the colony wardrobe. Starter is a plywood
/// mini ramp; Max adds coping, graffiti, a neon sign, a light truss and a
/// three-rider session. Room-local units (298 × 150, floor at 134).
class OutfitterArt extends RoomArt {
  const OutfitterArt();

  static const _floor = 134.0;

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    RoomKit.shell(c, x, wall: x.max ? const Color(0xFF2A1636) : const Color(0xFF33202A));
    c.save();
    c.translate(x.r.left, x.r.top);
    if (x.level >= 3) {
      // Light truss across the ceiling and a neon SKATE sign
      c.drawLine(const Offset(120, 9), const Offset(292, 9), Kit.stroke(const Color(0xFF94A3B8), 2));
      for (var k = 0; k < 6; k++) {
        c.drawLine(Offset(124 + k * 30.0, 9), Offset(138 + k * 30.0, 9), Kit.stroke(const Color(0xFF475569), 0.6));
      }
      final neon = RoomKit.text('SKATE', 9, const Color(0xFFF472B6), spacing: 1.6);
      Kit.glow(c, const Offset(150, 30), 26, const Color(0xFFF472B6), 0.35);
      neon.paint(c, Offset(150 - neon.width / 2, 24));
    }
    OutfitterProps.pokemonCard(c, const Rect.fromLTWH(72, 14, 34, 48), x.art);
    OutfitterProps.halfPipe(c, _floor, x.level);
    OutfitterProps.filmCanisters(c, const Offset(66, _floor), x.art);
    if (x.level >= 2) {
      OutfitterProps.boosterBench(c, const Rect.fromLTWH(100, _floor - 12, 40, 12));
      _wardrobe(c, const Offset(256, 18));
    }
    if (x.level >= 3) {
      // Speaker stacks flanking the DJ booth
      for (final sx in const [0.0, 60.0]) {
        final box = Rect.fromLTWH(sx, _floor - 50, 8, 22);
        c.drawRRect(Kit.rr(box, 1.5), Kit.fill(const Color(0xFF1C1917)));
        c.drawCircle(box.center.translate(0, -4), 2.6, Kit.stroke(const Color(0xFF57534E), 1));
        c.drawCircle(box.center.translate(0, 5), 3, Kit.stroke(const Color(0xFF57534E), 1));
      }
    }
    c.restore();
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final r = x.r;
    final o = r.topLeft;
    final ballSize = x.level >= 3 ? 9.0 : (x.level == 2 ? 7.0 : 5.5);
    c.save();
    c.clipRRect(Kit.rr(r.deflate(2), 16));
    c.translate(o.dx, o.dy);
    OutfitterProps.discoBall(c, Offset(OutfitterProps.pipeCenter, 18 + ballSize), ballSize, x.t,
        lit: x.lit, festival: x.snap.festival);
    c.restore();
    _djBooth(c, x, o);
    final riders = x.level;
    for (var k = 0; k < riders; k++) {
      _skater(c, x, o, k);
    }
    if (x.detail > 0.05) {
      // A shopper browsing the film-canister barrels (fades in when zoomed)
      c.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, x.detail));
      SquirrelPainter.paint(c, Offset(o.dx + 92 + math.sin(x.work * 0.8) * 4, o.dy + _floor - 14),
          dir: -1, scale: 0.8, time: x.t, seed: 9.9, pose: SquirrelPose.toss,
          look: SquirrelLook(hat: x.snap.outfits ? SquirrelHat.visor : SquirrelHat.none), art: x.art);
      c.restore();
    }
  }

  /// DJ Hazelnut behind two spinning bottle-cap turntables.
  void _djBooth(Canvas c, RoomCtx x, Offset o) {
    final beat = x.lit ? math.sin(x.work * 6.2).abs() : 0.0;
    SquirrelPainter.paint(c, o.translate(34, _floor - 24), scale: 0.86, time: x.t, seed: 3.3, hop: -beat * 1.4,
        look: SquirrelLook(hat: SquirrelHat.headphones, scarf: x.frost), art: x.art);
    final desk = Rect.fromLTWH(o.dx + 4, o.dy + _floor - 22, 58, 22);
    c.drawRRect(Kit.rr(desk, 2), Kit.vertical(desk, const [Color(0xFF292524), Color(0xFF0C0A09)]));
    c.drawRect(Rect.fromLTWH(desk.left, desk.top - 3, desk.width, 3), Kit.fill(const Color(0xFF57534E)));
    for (final dx in const [15.0, 47.0]) {
      final p = Offset(desk.left + dx - 4, desk.top - 4);
      c.drawOval(Kit.oval(p, 9, 2.6), Kit.fill(const Color(0xFFB91C1C)));
      c.drawOval(Kit.oval(p, 6, 1.7), Kit.fill(const Color(0xFF111827)));
      final a = x.lit ? x.work * 5 : 0.0;
      c.drawLine(p, p + Offset(math.cos(a) * 5.5, math.sin(a) * 1.4), Kit.stroke(const Color(0xFFF8FAFC), 0.6));
    }
    // Mixer LEDs bouncing to the beat
    for (var k = 0; k < 5; k++) {
      final on = x.lit && ((x.work * 4 + k * 0.7) % 2 < 1.2 - k * 0.15);
      c.drawRect(Rect.fromLTWH(desk.left + 21 + k * 3.2, desk.top + 4, 2, 5),
          Kit.fill(on ? const [Color(0xFF4ADE80), Color(0xFF4ADE80), Color(0xFFFDE047), Color(0xFFFB923C), Color(0xFFF87171)][k] : const Color(0xFF292524)));
    }
    if (x.lit && x.detail > 0.1) {
      // Little music notes drifting up from the booth
      for (var k = 0; k < 2; k++) {
        final s = (x.work * 0.4 + k * 0.5) % 1.0;
        final p = Offset(desk.left + 30 + k * 10 + math.sin(s * 6) * 4, desk.top - 10 - s * 26);
        c.drawCircle(p, 1.6, Kit.fill(Color.fromRGBO(244, 114, 182, (1 - s) * x.detail)));
        c.drawLine(p.translate(1.4, 0), p.translate(1.4, -5), Kit.stroke(Color.fromRGBO(244, 114, 182, (1 - s) * x.detail), 0.7));
      }
    }
  }

  /// A rider pumping the half-pipe; parks (asleep) on the flat when dark.
  void _skater(Canvas c, RoomCtx x, Offset o, int k) {
    final omega = 1.15 + k * 0.17;
    final phase = k * 2.1;
    final s = x.lit ? math.sin(x.work * omega + phase) * 0.97 : -0.3 + k * 0.3;
    final moving = math.cos(x.work * omega + phase) >= 0;
    final (p, tilt) = OutfitterProps.rampAt(s, _floor);
    c.save();
    c.translate(o.dx + p.dx, o.dy + p.dy);
    c.rotate(tilt);
    SkateKit.board(c, const Offset(0, -3), x.art);
    SquirrelPainter.paint(c, const Offset(0, -14.6), dir: moving ? 1 : -1, scale: 0.72, time: x.t, seed: 2.2 + k * 1.7,
        look: SquirrelLook(
          hat: x.snap.outfits ? (k == 1 ? SquirrelHat.goggles : SquirrelHat.beanie) : SquirrelHat.none,
          scarf: x.frost,
        ),
        art: x.art);
    c.restore();
  }

  static void _wardrobe(Canvas c, Offset o) {
    c.drawLine(o.translate(-6, 0), o.translate(36, 0), Kit.stroke(const Color(0xFF92400E), 2));
    const hats = [SquirrelHat.knight, SquirrelHat.beanie, SquirrelHat.goggles, SquirrelHat.visor];
    for (var i = 0; i < hats.length; i++) {
      c.drawCircle(o.translate(i * 10.0, 0), 1.4, Kit.fill(const Color(0xFFFBBF24)));
      c.save();
      c.translate(o.dx + i * 10.0 - 1.5, o.dy + 14);
      c.scale(0.6);
      SquirrelOutfits.hat(c, hats[i]);
      c.restore();
    }
  }
}

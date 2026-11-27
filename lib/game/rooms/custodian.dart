import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import 'room_kit.dart';
import 'trophy_hall_art.dart';

/// The Trophy Hall custodian's 24-second routine: polish the pedestal,
/// duck behind the statue case, rappel upside-down to buff the high
/// shelves, scrub the standing mirror, get startled by his reflection,
/// bolt out the mouse hole, peek back in from the side doorway, and stroll
/// back to start.
abstract final class Custodian {
  static const cycle = 24.0;
  static const _floor = TrophyHallArt.floor;

  static void paint(Canvas c, RoomCtx x) {
    final o = x.r.topLeft;
    final t = x.work % cycle;
    final look = SquirrelLook(prop: SquirrelProp.duster, scarf: x.frost,
        hat: x.snap.outfits ? SquirrelHat.visor : SquirrelHat.none);
    const y = _floor - 14;
    void squirrel(Offset at, {double dir = 1, double hop = 0, SquirrelLook? as}) =>
        SquirrelPainter.paint(c, o + at, dir: dir, scale: 0.8, time: x.t, seed: 3.7, hop: hop, look: as ?? look, art: x.art);

    if (t < 4) {
      // 1. Polishing the pedestal
      squirrel(const Offset(74, y), hop: -math.sin(x.work * 8).abs() * 0.6);
      final s = (x.t * 1.2) % 1.0;
      Kit.sparkle(c, o + Offset(96, _floor - 36 - s * 4), 2.4 * math.sin(s * math.pi), const Color(0xFFFFF7AE));
    } else if (t < 7) {
      // 2. Ducking behind the case
      final u = Ease.easeInOut((t - 4) / 3);
      squirrel(Offset(74 - u * 48, y), dir: -1, hop: u > 0.6 ? 3 : 0);
      if (u > 0.55) _casePane(c, o);
    } else if (t < 12) {
      // 3. Rappelling upside-down to buff the top shelf
      final drop = t < 8 ? Ease.easeInOut(t - 7) : (t > 11 ? 1 - Ease.easeInOut(t - 11) : 1.0);
      const ropeX = 112.0;
      final hang = 6 + drop * 30;
      c.drawLine(o + const Offset(ropeX, 0), o + Offset(ropeX, hang), Kit.stroke(const Color(0xFFD6B48A), 1));
      c.save();
      c.translate(o.dx + ropeX, o.dy + hang + 12);
      c.rotate(math.pi);
      SquirrelPainter.paint(c, Offset.zero, dir: -1, scale: 0.8, time: x.t, seed: 3.7, look: look, art: x.art);
      c.restore();
      if (drop >= 1) {
        final s = (x.t * 1.4) % 1.0;
        Kit.sparkle(c, o + Offset(ropeX - 8, 24), 2.2 * math.sin(s * math.pi), const Color(0xFFFFF7AE));
      }
    } else if (t < 15) {
      // 4. Scrubbing the standing mirror (with his reflection doing the same)
      squirrel(const Offset(110, y), hop: -math.sin(x.work * 9).abs() * 0.5);
      _reflection(c, x, o, look, 0);
    } else if (t < 16.5) {
      // 5. Startled by his reflection!
      final jump = -math.sin(((t - 15) / 1.5) * math.pi) * 9;
      squirrel(const Offset(108, y), hop: jump);
      _reflection(c, x, o, look, jump);
      final bang = RoomKit.text('!', 10, const Color(0xFFFDE047));
      bang.paint(c, o + Offset(104, y - 30 + jump));
    } else if (t < 18) {
      // 6. Bolting out of the mouse hole
      final u = (t - 16.5) / 1.5;
      final px = 108 - u * u * 112;
      c.save();
      c.clipRect(Rect.fromLTRB(o.dx + 8, o.dy, x.r.right, x.r.bottom));
      squirrel(Offset(px, y), dir: -1, hop: -math.sin(x.work * 16).abs() * 1.4);
      c.restore();
    } else if (t < 21) {
      // 7. Peeking back in from the side doorway
      final peek = math.sin(((t - 18) / 3) * math.pi).clamp(0.0, 1.0);
      c.save();
      c.clipRect(Rect.fromLTWH(o.dx + 120, o.dy, 32, x.r.height));
      squirrel(Offset(162 - peek * 10, y), dir: -1);
      c.restore();
    } else {
      // 8. Strolling back to the pedestal
      final u = Ease.easeInOut((t - 21) / 3);
      squirrel(Offset(154 - u * 80, y), dir: -1, hop: -math.sin(x.work * 8).abs());
    }
  }

  static void _casePane(Canvas c, Offset o) {
    final glass = Rect.fromLTWH(o.dx + 6, o.dy + 64, 38, _floor - 72);
    c.drawRRect(Kit.rr(glass, 3), Kit.fill(const Color(0x8C2E1A10)));
    c.drawRRect(Kit.rr(glass, 3), Kit.stroke(const Color(0xFFFBBF24), 1.2));
  }

  static void _reflection(Canvas c, RoomCtx x, Offset o, SquirrelLook look, double hop) {
    final mirror = Rect.fromLTWH(o.dx + 118, o.dy + 70, 24, _floor - 72);
    c.save();
    c.clipRRect(Kit.rr(mirror, 9));
    SquirrelPainter.paint(c, o + const Offset(134, _floor - 14), dir: -1, scale: 0.8, time: x.t, seed: 3.7, hop: hop,
        look: look, art: x.art);
    c.drawRect(mirror, Kit.fill(const Color(0x3364748B)));
    c.restore();
  }
}

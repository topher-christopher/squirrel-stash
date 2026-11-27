import 'dart:math' as math;
import 'dart:ui';

import '../../models/treat_status.dart';
import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../art/squirrel_painter.dart';
import '../diorama_event.dart';
import 'desk_clock.dart';
import 'diorama_layer.dart';

/// Thumb-reach desk instruments: the Sand-Art Impulse Silo & researcher,
/// the Treat-Yourself lantern, the brass Focus clock & study squirrel, the
/// espresso press and the trophy shelf.
class DeskInstruments extends DioramaLayer {
  DeskInstruments() : super(priority: 40);

  double _fill = 14;
  double _skip = 0, _down = 0, _diy = 1;

  static const _lanternColors = {
    TreatLevel.green: Color(0xFF4ADE80),
    TreatLevel.yellow: Color(0xFFFACC15),
    TreatLevel.red: Color(0xFFF87171),
  };

  @override
  void update(double dt) {
    final k = math.min(1.0, dt * 3);
    _fill += (snap.siloFill - _fill) * k;
    _skip += (snap.skipFraction - _skip) * k;
    _down += (snap.downsizeFraction - _down) * k;
    _diy += (snap.diyFraction - _diy) * k;
  }

  @override
  void render(Canvas canvas) {
    _paintSilo(canvas);
    _paintLantern(canvas);
    DeskClock.paint(canvas, snap, t, game.pokeAmount(DioramaTarget.clock));
    if (snap.espresso) _paintEspresso(canvas);
    _paintTrophyShelf(canvas);
    SquirrelPainter.paint(canvas, const Offset(320, 402),
        pose: SquirrelPose.focus, dir: -1, scale: 0.78, time: t, seed: 4.1,
        hop: snap.focusRunning ? math.sin(t * 5).abs() * -0.8 : 0,
        squash: game.pokeAmount(DioramaTarget.clock) * 0.6,
        look: SquirrelLook(scholarHat: snap.hats, book: snap.focusRunning),
        art: game.art);
  }

  void _paintSilo(Canvas c) {
    final squash = game.pokeAmount(DioramaTarget.silo);
    c.save();
    c.translate(49, 418);
    c.scale(1 + squash * 0.06, 1 - squash * 0.05);
    c.translate(-49, -418);

    c.drawRRect(Kit.rr(const Rect.fromLTWH(30, 410, 38, 8), 3), Kit.fill(const Color(0xFFB45309)));
    c.drawLine(const Offset(32, 411), const Offset(66, 411), Kit.stroke(const Color(0x66FDE68A), 0.8));
    const tube = Rect.fromLTWH(33, 332, 32, 80);
    c.drawRRect(Kit.rr(tube, 13), Kit.fill(const Color(0xD91A0E06)));

    final inner = Kit.rr(tube.deflate(2), 11);
    c.save();
    c.clipRRect(inner);
    const baseY = 408.0;
    final diyH = _fill * _diy;
    final downH = _fill * _down;
    final skipH = _fill * _skip;
    var y = baseY;
    for (final (h, color) in [(diyH, Pal.sandDiy), (downH, Pal.sandDownsize), (skipH, Pal.sandSkip)]) {
      if (h <= 0.3) continue;
      final layer = Rect.fromLTRB(35, y - h, 63, y + 0.5);
      c.drawRect(layer, Kit.vertical(layer, [Color.lerp(color, const Color(0xFFFFFFFF), 0.18)!, color]));
      final rng = math.Random(color.toARGB32());
      for (var i = 0; i < (h * 1.4).round(); i++) {
        c.drawCircle(Offset(36 + rng.nextDouble() * 26, y - rng.nextDouble() * h), 0.55,
            Kit.fill(Color.lerp(color, const Color(0xFF000000), 0.2 + rng.nextDouble() * 0.2)!));
      }
      y -= h;
    }
    // Soft dune surface
    final top = y;
    c.drawPath(
        Path()
          ..moveTo(35, top + 1)
          ..quadraticBezierTo(42, top - 2 + math.sin(t * 1.2), 49, top)
          ..quadraticBezierTo(56, top + 2, 63, top - 1)
          ..lineTo(63, top + 2)
          ..lineTo(35, top + 2)
          ..close(),
        Kit.fill(const Color(0x55FFFFFF)));
    c.restore();

    c.drawRRect(Kit.rr(tube, 13), Kit.stroke(Pal.brass, 1.8));
    c.drawRRect(Kit.rr(const Rect.fromLTWH(37, 338, 4, 64), 2), Kit.fill(const Color(0x2EFFFFFF)));
    c.drawRRect(Kit.rr(const Rect.fromLTWH(30, 328, 38, 6), 3), Kit.fill(const Color(0xFFB45309)));
    c.restore();

    // Forged acorns beside the silo: every $25 forges a Silver acorn and
    // every four Silvers fuse into a Royal Gold ($100). Shows up to three
    // gold plus the loose silvers still waiting to fuse.
    final gold = math.min(3, snap.forgedGold);
    final silver = (snap.forgedSilver - snap.forgedGold * 4).clamp(0, 3);
    for (var i = 0; i < gold; i++) {
      Kit.acorn(c, Offset(21, 411 - i * 7.5), rx: 3.2, ry: 3.8, body: Pal.gold, line: Pal.brassDark, strokeWidth: 0.7);
    }
    for (var i = 0; i < silver; i++) {
      Kit.acorn(c, Offset(11, 411 - i * 7.5), rx: 3, ry: 3.6, body: Pal.silver, cap: Pal.silverLine, line: Pal.silverLine, strokeWidth: 0.7);
    }

    SquirrelPainter.paint(c, Offset(90, 400 + math.sin(t * 2.4) * 1.2),
        pose: SquirrelPose.researcher, dir: -1, scale: 0.86, time: t, seed: 0.7,
        squash: squash * 0.6, look: SquirrelLook(chefHat: snap.hats), art: game.art);
  }

  void _paintLantern(Canvas c) {
    final color = _lanternColors[snap.treat]!;
    final squash = game.pokeAmount(DioramaTarget.lantern);
    final pulse = snap.treat == TreatLevel.yellow
        ? 0.5 + 0.5 * math.sin(t * 1.6)
        : 0.75 + 0.25 * math.sin(t * 3.1);
    Kit.glow(c, const Offset(182, 384), 34 + pulse * 6, color, 0.42 + pulse * 0.18);
    c.save();
    c.translate(182, 418);
    c.scale(1 - squash * 0.1, 1 + squash * 0.12);
    c.translate(-182, -418);
    c.drawRRect(Kit.rr(const Rect.fromLTWH(169, 412, 26, 6), 2.5), Kit.fill(const Color(0xFF78350F)));
    const body = Rect.fromLTWH(171, 372, 22, 40);
    c.drawRRect(Kit.rr(body, 6),
        Kit.vertical(body, [Color.lerp(color, const Color(0xFFFFFFFF), 0.45)!, color]));
    final flame = 0.9 + 0.1 * math.sin(t * 11);
    c.drawPath(
        Path()
          ..moveTo(182, 386 - 8 * flame)
          ..quadraticBezierTo(187, 394, 182, 398)
          ..quadraticBezierTo(177, 394, 182, 386 - 8 * flame)
          ..close(),
        Kit.fill(const Color(0xCCFFFBEB)));
    for (final x in const [177.0, 187.0]) {
      c.drawLine(Offset(x, 374), Offset(x, 410), Kit.stroke(const Color(0x66451A03), 1));
    }
    c.drawRRect(Kit.rr(body, 6), Kit.stroke(Pal.outline, 2));
    c.drawPath(Path()..moveTo(168, 372)..lineTo(182, 360)..lineTo(196, 372)..close(),
        Kit.fill(const Color(0xFF92400E)));
    c.drawCircle(const Offset(182, 357), 3, Kit.stroke(Pal.brass, 1.5));
    if (snap.treat == TreatLevel.green) {
      final s = (t * 0.6) % 1.0;
      Kit.sparkle(c, Offset(176 + s * 4, 368 - s * 20), 2.4 * (1 - s), const Color(0xFFFFFFFF));
    } else if (snap.treat == TreatLevel.red) {
      c.drawLine(const Offset(172, 380), const Offset(178, 386), Kit.stroke(const Color(0xCCFFFFFF), 0.9));
      c.drawLine(const Offset(178, 380), const Offset(172, 386), Kit.stroke(const Color(0xCCFFFFFF), 0.9));
    }
    c.restore();
  }

  void _paintEspresso(Canvas c) {
    c.drawRRect(Kit.rr(const Rect.fromLTWH(237, 356, 15, 20), 2.5), Kit.fill(const Color(0x99E0F2FE)));
    c.drawRect(const Rect.fromLTWH(238.5, 364, 12, 11), Kit.fill(const Color(0xFF451A03)));
    c.drawRRect(Kit.rr(const Rect.fromLTWH(237, 356, 15, 20), 2.5), Kit.stroke(const Color(0xFF78350F), 1));
    c.drawRect(const Rect.fromLTWH(236, 353, 17, 3), Kit.fill(const Color(0xFF78350F)));
    c.drawLine(const Offset(244.5, 353), const Offset(244.5, 347), Kit.stroke(const Color(0xFFB45309), 1.4));
    c.drawCircle(const Offset(244.5, 346.5), 1.6, Kit.fill(Pal.brass));
    c.drawArc(const Rect.fromLTWH(250, 360, 6, 9), -math.pi / 2, math.pi, false, Kit.stroke(const Color(0xFF78350F), 1.2));
    final s = (t * 0.5) % 1.0;
    c.drawPath(
        Path()
          ..moveTo(240, 352 - s * 4)
          ..quadraticBezierTo(237, 346 - s * 6, 240, 340 - s * 8),
        Kit.stroke(Color.fromRGBO(255, 255, 255, 0.6 * math.sin(s * math.pi)), 1));
  }

  void _paintTrophyShelf(Canvas c) {
    final squash = game.pokeAmount(DioramaTarget.trophies);
    c.save();
    c.translate(381, 413);
    c.scale(1 + squash * 0.05, 1 - squash * 0.08);
    c.translate(-381, -413);
    for (final x in const [356.0, 406.0]) {
      c.drawPath(Path()..moveTo(x - 3, 418)..lineTo(x + 3, 418)..lineTo(x, 412)..close(),
          Kit.fill(const Color(0xFF5C2E10)));
    }
    c.drawRRect(Kit.rr(const Rect.fromLTWH(350, 408, 62, 10), 3), Kit.fill(const Color(0xFF78350F)));
    c.drawRRect(Kit.rr(const Rect.fromLTWH(350, 408, 62, 10), 3), Kit.stroke(Pal.brass, 1));
    for (final x in const [370.0, 394.0]) {
      c.drawOval(Kit.oval(Offset(x, 408), 9, 2.4), Kit.fill(const Color(0xFF5C2E10)));
    }
    c.restore();
  }
}

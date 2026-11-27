import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/skate_kit.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import '../layout.dart';
import 'diorama_layer.dart';

/// Outdoor colony life on the grass and the Canopy Terrace: year-round
/// skateboarders, and in winter wooden sleds and a snowball fight. During a
/// Colony Festival confetti keeps raining over the tree.
class ColonyLifeLayer extends DioramaLayer {
  ColonyLifeLayer() : super(priority: 42);

  final math.Random _rng = math.Random(5);
  double _confetti = 0;

  @override
  void update(double dt) {
    if (!snap.festival) return;
    _confetti += dt;
    if (_confetti > 2.6) {
      _confetti = 0;
      game.fx.confetti(Offset(80 + _rng.nextDouble() * 440, 60 + _rng.nextDouble() * 640));
    }
  }

  @override
  void render(Canvas canvas) {
    _deckSkater(canvas);
    if (snap.winter) {
      _snowballFight(canvas);
      _sleds(canvas);
    } else {
      _groundSkater(canvas);
    }
  }

  SquirrelHat get _beanie => snap.outfits ? SquirrelHat.beanie : SquirrelHat.none;

  /// A skateboarder cruising the Canopy Terrace behind the pedestals.
  void _deckSkater(Canvas c) {
    const period = 11.0;
    final u = Ease.easeInOut(Ease.pingPong(work / period + 0.3));
    final right = ((work / period + 0.3) % 2) < 1;
    final x = 80 + u * 440;
    const y = TreeLayout.deckY - 1;
    SkateKit.board(c, Offset(x, y), game.art);
    SquirrelPainter.paint(c, Offset(x, y - 16), dir: right ? 1 : -1, scale: 0.66, time: t, seed: 31,
        look: SquirrelLook(hat: _beanie, scarf: snap.frost), art: game.art);
  }

  /// Ground-line skater kick-pushing past the trunk (not in winter).
  void _groundSkater(Canvas c) {
    const period = 9.0;
    final u = Ease.easeInOut(Ease.pingPong(work / period));
    final right = (work / period) % 2 < 1;
    final x = 40 + u * 360;
    const y = TreeLayout.groundY - 4;
    final ollie = math.max(0.0, math.sin(work * 1.7)) > 0.97 ? -5.0 : 0.0;
    SkateKit.board(c, Offset(x, y + ollie), game.art);
    SquirrelPainter.paint(c, Offset(x, y - 16 + ollie), dir: right ? 1 : -1, scale: 0.74, time: t, seed: 14.2,
        pose: snap.focusRunning ? SquirrelPose.focus : SquirrelPose.idle,
        look: SquirrelLook(book: snap.focusRunning, hat: snap.outfits ? SquirrelHat.goggles : SquirrelHat.none),
        art: game.art);
  }

  /// Two jacketed squirrels lobbing snowballs across the grass.
  void _snowballFight(Canvas c) {
    const a = Offset(110, TreeLayout.groundY - 18), b = Offset(250, TreeLayout.groundY - 18);
    for (final (p, dir, seed) in [(a, 1.0, 41.0), (b, -1.0, 42.0)]) {
      SquirrelPainter.paint(c, p, dir: dir, scale: 0.72, time: t, seed: seed,
          hop: -math.max(0.0, math.sin(work * 2 + seed)) * 2, look: const SquirrelLook(jacket: true),
          pose: SquirrelPose.toss, art: game.art);
    }
    // Snow forts
    for (final x in [a.dx - 16, b.dx + 16]) {
      c.drawOval(Kit.oval(Offset(x, TreeLayout.groundY - 6), 10, 7), Kit.fill(const Color(0xFFF8FAFC)));
    }
    final u = (work / 1.6) % 1.0;
    final toB = ((work / 1.6) % 2) < 1;
    final from = toB ? a : b, to = toB ? b : a;
    final p = Offset.lerp(from, to, u)!.translate(0, -14 - math.sin(u * math.pi) * 26);
    c.drawCircle(p, 2.6, Kit.fill(const Color(0xFFFFFFFF)));
    c.drawCircle(p, 2.6, Kit.stroke(const Color(0xFFCBD5E1), 0.6));
  }

  /// A wooden sled whooshing down the burrow mound, and two parked on the
  /// Canopy Terrace.
  void _sleds(Canvas c) {
    final u = (work / 4.5) % 1.0;
    final p = Offset.lerp(const Offset(560, 730), const Offset(420, 766), Ease.easeInOut(u))!;
    _sled(c, p);
    SquirrelPainter.paint(c, p.translate(0, -14), dir: -1, scale: 0.66, time: t, seed: 44,
        look: const SquirrelLook(jacket: true), art: game.art);
    _sled(c, const Offset(222, TreeLayout.deckY - 1));
    _sled(c, const Offset(380, TreeLayout.deckY - 1));
  }

  static void _sled(Canvas c, Offset at) {
    c.drawRRect(Kit.rr(Rect.fromCenter(center: at.translate(0, -3), width: 22, height: 4), 1.5),
        Kit.fill(const Color(0xFFB45309)));
    c.drawPath(Path()
      ..moveTo(at.dx - 12, at.dy)
      ..lineTo(at.dx + 9, at.dy)
      ..quadraticBezierTo(at.dx + 14, at.dy, at.dx + 13, at.dy - 5), Kit.stroke(const Color(0xFF7F1D1D), 1.3));
  }
}

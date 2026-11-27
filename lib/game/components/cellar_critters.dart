import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../art/squirrel_painter.dart';
import '../layout.dart';
import '../scenes/window_props.dart';
import 'diorama_layer.dart';

class _Drop {
  _Drop(this.slot);
  final int? slot;
  double age = 0;
  bool burst = false;
}

/// Autonomous cellar squirrels: the chute hauler ferrying golden acorns
/// down the ladder and the lantern-carrying root caretaker on patrol.
/// Also animates acorns dropped into chambers when cash is allocated.
class CellarCritters extends DioramaLayer {
  CellarCritters() : super(priority: 60);

  final List<_Drop> _drops = [];

  static const _down = 5.5;
  static const _up = 3.5;
  static const _patrol = 5.5;

  void dropAcorn(int? slot) {
    if (_drops.length < 8) _drops.add(_Drop(slot));
  }

  @override
  void update(double dt) {
    for (final d in _drops) {
      d.age += dt;
      if (!d.burst && d.age >= 1.1) {
        d.burst = true;
        final slot = d.slot;
        final at = slot == null
            ? const Offset(220, 664)
            : StudyLayout.chestIn(StudyLayout.chambers[slot]).translate(0, -10);
        game.fx.burst(at, count: 10, colors: const [Pal.gold, Pal.acorn, Color(0xFFFFFFFF)], speed: 55);
      }
    }
    _drops.removeWhere((d) => d.age > 1.15);
  }

  @override
  void render(Canvas canvas) {
    _paintHauler(canvas);
    _paintPatrol(canvas);
    for (final d in _drops) {
      _paintDrop(canvas, d);
    }
  }

  void _paintHauler(Canvas canvas) {
    final cycle = t % (_down + _up);
    final goingDown = cycle < _down;
    final u = goingDown ? cycle / _down : 1 - (cycle - _down) / _up;
    final y = 522 + Ease.easeInOut(u) * 122;
    final climb = math.sin(t * (goingDown ? 9 : 13)) * 0.9;
    SquirrelPainter.paint(canvas, Offset(220 + climb * 0.6, y),
        pose: snap.focusRunning ? SquirrelPose.focus : SquirrelPose.hauler,
        scale: 0.76, time: t, seed: 1.9, hop: climb,
        look: SquirrelLook(acorn: goingDown, golden: snap.oakLevel >= 4),
        art: game.art);
  }

  void _paintPatrol(Canvas canvas) {
    final cycle = t % (_patrol * 2);
    final forward = cycle < _patrol;
    final u = forward ? cycle / _patrol : 2 - cycle / _patrol;
    final x = 95 + Ease.easeInOut(u) * 250;
    final hop = -math.sin(t * 8).abs() * 1.6;
    Kit.glow(canvas, Offset(x + (forward ? 8 : -8), StudyLayout.patrolY + 6), 26,
        const Color(0xFFFEF08A), 0.16);
    SquirrelPainter.paint(canvas, Offset(x, StudyLayout.patrolY),
        pose: snap.focusRunning ? SquirrelPose.focus : SquirrelPose.lantern,
        dir: forward ? 1 : -1, scale: 0.72, time: t, seed: 3.3, hop: hop,
        look: SquirrelLook(scholarHat: snap.hats),
        art: game.art);
  }

  void _paintDrop(Canvas canvas, _Drop d) {
    final Offset p;
    if (d.age < 0.6) {
      final u = d.age / 0.6;
      p = Offset(220, 506 + u * u * 150);
    } else {
      final slot = d.slot;
      if (slot == null) return;
      final u = ((d.age - 0.6) / 0.5).clamp(0.0, 1.0);
      final from = const Offset(220, 656);
      final to = StudyLayout.chestIn(StudyLayout.chambers[slot]).translate(0, -12);
      final mid = Offset((from.dx + to.dx) / 2, math.min(from.dy, to.dy) - 40);
      final a = Offset.lerp(from, mid, u)!;
      final b = Offset.lerp(mid, to, u)!;
      p = Offset.lerp(a, b, u)!;
    }
    Kit.acorn(canvas, p, rx: 4.2, ry: 5, body: Pal.gold);
  }
}

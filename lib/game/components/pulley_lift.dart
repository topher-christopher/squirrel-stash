import 'dart:math' as math;
import 'dart:ui';

import '../../models/room.dart';
import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import '../layout.dart';
import 'diorama_layer.dart';

class _Drop {
  _Drop(this.target);
  final Offset target;
  double age = 0;
  bool burst = false;
}

/// The central acorn-pulley lift ferrying squirrels between trunk floors
/// and the Metro platform, terrace strollers, and golden acorns dropped
/// down the shaft when cash is allocated to a goal.
class PulleyLift extends DioramaLayer {
  PulleyLift() : super(priority: 40);

  static const _travel = 2.6;
  static const _dwell = 1.6;
  final List<_Drop> _drops = [];

  void dropAcorn(RoomKey room) {
    if (_drops.length < 8) _drops.add(_Drop(TreeLayout.room(room).center.translate(0, 30)));
  }

  /// Basket floor y for the current moment of the looping route.
  double _basketY() {
    final stops = [TreeLayout.liftStops.first - 160, ...TreeLayout.liftStops];
    final route = [...stops, ...stops.reversed.skip(1).take(stops.length - 2)];
    final leg = _travel + _dwell;
    final total = route.length * leg;
    final tt = t % total;
    final i = (tt / leg).floor();
    final local = tt - i * leg;
    final from = route[i];
    final to = route[(i + 1) % route.length];
    if (local < _dwell) return from;
    return from + (to - from) * Ease.easeInOut((local - _dwell) / _travel);
  }

  @override
  void update(double dt) {
    for (final d in _drops) {
      d.age += dt;
      if (!d.burst && d.age >= 1.3) {
        d.burst = true;
        game.fx.burst(d.target, count: 10, colors: const [Pal.gold, Pal.acorn, Color(0xFFFFFFFF)], speed: 55);
      }
    }
    _drops.removeWhere((d) => d.age > 1.35);
  }

  @override
  void render(Canvas canvas) {
    final y = _basketY();
    const x = TreeLayout.shaftX;
    // Pulley wheel
    const p = TreeLayout.pulley;
    canvas.drawCircle(p, 11, Kit.fill(const Color(0xFF92400E)));
    canvas.drawCircle(p, 11, Kit.stroke(Pal.brass, 2));
    for (var k = 0; k < 4; k++) {
      final a = t * 1.6 + k * math.pi / 2;
      canvas.drawLine(p, p + Offset(math.cos(a), math.sin(a)) * 9, Kit.stroke(Pal.brass, 1.4));
    }
    canvas.drawCircle(p, 2.4, Kit.fill(Pal.brass));
    // Rope & counterweight rope
    canvas.drawLine(p.translate(-6, 0), Offset(x - 6, y - 26), Kit.stroke(const Color(0xFFD6B48A), 1.3));
    canvas.drawLine(p.translate(6, 0), Offset(x + 6, y - 26), Kit.stroke(const Color(0xFFD6B48A), 1.3));
    // Acorn-shaped basket
    final basket = Rect.fromLTWH(x - 11, y - 26, 22, 26);
    canvas.drawPath(
        Path()
          ..moveTo(basket.left, basket.top + 8)
          ..lineTo(basket.right, basket.top + 8)
          ..quadraticBezierTo(basket.right, basket.bottom, x, basket.bottom + 2)
          ..quadraticBezierTo(basket.left, basket.bottom, basket.left, basket.top + 8)
          ..close(),
        Kit.fill(Pal.acorn));
    canvas.drawPath(
        Path()
          ..moveTo(basket.left - 2, basket.top + 9)
          ..quadraticBezierTo(x, basket.top - 2, basket.right + 2, basket.top + 9)
          ..close(),
        Kit.fill(Pal.acornCap));
    SquirrelPainter.paint(canvas, Offset(x, y - 20), scale: 0.62, time: t, seed: 12.5,
        look: SquirrelLook(acorn: true, golden: snap.oakLevel >= 4, scarf: snap.frost,
            hat: snap.outfits ? SquirrelHat.goggles : SquirrelHat.none),
        art: game.art);
    _terraceStroller(canvas);
    for (final d in _drops) {
      _paintDrop(canvas, d);
    }
  }

  void _terraceStroller(Canvas canvas) {
    const period = 9.0;
    final u = Ease.easeInOut(Ease.pingPong(t / period));
    final forward = (t / period) % 2 < 1;
    final px = 60 + u * 480;
    SquirrelPainter.paint(canvas, Offset(px, TreeLayout.groundY - 6),
        dir: forward ? 1 : -1, scale: 0.75, time: t, seed: 14.2,
        hop: -math.sin(t * 8).abs() * 1.4,
        pose: snap.focusRunning ? SquirrelPose.focus : SquirrelPose.lantern,
        look: SquirrelLook(scarf: snap.frost, book: snap.focusRunning,
            hat: snap.outfits ? SquirrelHat.scholar : SquirrelHat.none),
        art: game.art);
  }

  void _paintDrop(Canvas canvas, _Drop d) {
    Offset pos;
    if (d.age < 0.8) {
      final u = d.age / 0.8;
      pos = Offset(TreeLayout.shaftX, 240 + u * u * (d.target.dy - 270));
    } else {
      final u = ((d.age - 0.8) / 0.5).clamp(0.0, 1.0);
      final from = Offset(TreeLayout.shaftX, d.target.dy - 30);
      final mid = Offset((from.dx + d.target.dx) / 2, from.dy - 30);
      pos = Offset.lerp(Offset.lerp(from, mid, u)!, Offset.lerp(mid, d.target, u)!, u)!;
    }
    Kit.acorn(canvas, pos, rx: 4.2, ry: 5, body: Pal.gold);
  }
}

import 'dart:math' as math;
import 'dart:ui';

import '../../core/dates.dart';
import '../art/paint_kit.dart';
import '../layout.dart';
import 'diorama_layer.dart';

class _Mote {
  _Mote(this.p, this.v, this.size, this.color, this.leaf, this.spin);
  Offset p;
  final Offset v;
  final double size;
  final Color color;
  final bool leaf;
  final double spin;
  double rot = 0;
  double age = 0;
}

/// Falling leaves drifting from the crown (the Cozy Zen centerpiece),
/// Frostline snowfall over the whole tree, and twilight fireflies.
class WeatherLayer extends DioramaLayer {
  WeatherLayer() : super(priority: 60);

  final math.Random _rng = math.Random(7);
  final List<_Mote> _motes = [];
  double _snowAcc = 0;
  double _leafAcc = 0;

  static const _fireflies = [
    Offset(40, 300), Offset(570, 330), Offset(30, 520), Offset(580, 560),
    Offset(120, 740), Offset(480, 742), Offset(300, 750), Offset(200, 230),
  ];

  List<Color> get _leafColors {
    if (snap.seasonal) {
      return switch (snap.season) {
        Season.spring => const [Color(0xFFFBCFE8), Color(0xFFF9A8D4), Color(0xFF86EFAC)],
        Season.summer => const [Color(0xFF84CC16), Color(0xFF22C55E), Color(0xFF65A30D)],
        Season.fall => const [Color(0xFFF59E0B), Color(0xFFEA580C), Color(0xFFDC2626), Color(0xFFCA8A04)],
        Season.winter => const [Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
      };
    }
    return const [Color(0xFFF59E0B), Color(0xFFEA580C), Color(0xFF84CC16), Color(0xFFCA8A04)];
  }

  @override
  void update(double dt) {
    if (snap.frost) {
      _snowAcc += dt * 26;
      while (_snowAcc >= 1) {
        _snowAcc -= 1;
        _motes.add(_Mote(Offset(_rng.nextDouble() * TreeLayout.width, -4),
            Offset(4 + _rng.nextDouble() * 10, 30 + _rng.nextDouble() * 30),
            1.1 + _rng.nextDouble() * 1.8, const Color(0xFFFFFFFF), false, 0));
      }
    }
    _leafAcc += dt * (snap.frost ? 0.3 : 1.1);
    final colors = _leafColors;
    while (_leafAcc >= 1) {
      _leafAcc -= 1;
      _motes.add(_Mote(Offset(20 + _rng.nextDouble() * 560, 120 + _rng.nextDouble() * 110),
          Offset(-8 + _rng.nextDouble() * 18, 14 + _rng.nextDouble() * 12),
          2.4 + _rng.nextDouble() * 1.4, colors[_rng.nextInt(colors.length)], true,
          (_rng.nextDouble() - 0.5) * 4));
    }
    for (final m in _motes) {
      m.age += dt;
      final sway = math.sin(m.age * (m.leaf ? 2.2 : 1.4) + m.size * 3) * (m.leaf ? 18 : 8);
      m.p = m.p.translate((m.v.dx + sway) * dt, m.v.dy * dt);
      m.rot += m.spin * dt;
    }
    _motes.removeWhere((m) => m.p.dy > TreeLayout.groundY + 4 || m.age > 40);
  }

  @override
  void render(Canvas canvas) {
    for (final m in _motes) {
      if (m.leaf) {
        canvas.save();
        canvas.translate(m.p.dx, m.p.dy);
        canvas.rotate(m.rot);
        canvas.drawOval(Kit.oval(Offset.zero, m.size * 1.6, m.size * 0.8), Kit.fill(m.color));
        canvas.drawLine(Offset(-m.size * 1.4, 0), Offset(m.size * 1.4, 0), Kit.stroke(const Color(0x55451A03), 0.5));
        canvas.restore();
      } else {
        final fade = math.min(1.0, m.age * 3);
        canvas.drawCircle(m.p, m.size * 1.8, Kit.fill(Color.fromRGBO(255, 255, 255, 0.18 * fade)));
        canvas.drawCircle(m.p, m.size, Kit.fill(Color.fromRGBO(255, 255, 255, 0.92 * fade)));
      }
    }
    if (snap.twilight) {
      for (var i = 0; i < _fireflies.length; i++) {
        final home = _fireflies[i];
        final p = Offset(home.dx + math.sin(t * 0.7 + i) * 14, home.dy + math.cos(t * 0.9 + i * 1.3) * 9);
        final blink = math.max(0.0, math.sin(t * 2.3 + i * 1.9));
        final color = i.isEven ? const Color(0xFFBEF264) : const Color(0xFFFEF08A);
        Kit.glow(canvas, p, 8, color, 0.5 * blink);
        canvas.drawCircle(p, 2.2, Kit.fill(Kit.a(color, 0.35 + 0.65 * blink)));
      }
    }
  }
}

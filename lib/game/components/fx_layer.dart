import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import 'diorama_layer.dart';

enum _Kind { dot, sparkle, confetti, leaf }

class _Particle {
  _Particle({
    required this.p,
    required this.v,
    required this.life,
    required this.size,
    required this.color,
    required this.kind,
    required this.gravity,
    required this.spin,
  });

  Offset p;
  Offset v;
  final double life;
  final double size;
  final Color color;
  final _Kind kind;
  final double gravity;
  final double spin;
  double age = 0;
  double rot = 0;
}

/// Lightweight one-shot particles: sparkle bursts, golden leaves, confetti.
class FxLayer extends DioramaLayer {
  FxLayer() : super(priority: 100);

  final math.Random _rng = math.Random();
  final List<_Particle> _particles = [];
  static const _max = 360;

  void burst(Offset at,
      {int count = 12, List<Color> colors = const [Color(0xFFFFFFFF)], double speed = 80}) {
    for (var i = 0; i < count && _particles.length < _max; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final s = speed * (0.4 + _rng.nextDouble() * 0.8);
      _particles.add(_Particle(
        p: at,
        v: Offset(math.cos(a) * s, math.sin(a) * s - speed * 0.5),
        life: 0.6 + _rng.nextDouble() * 0.6,
        size: 1.6 + _rng.nextDouble() * 2.4,
        color: colors[_rng.nextInt(colors.length)],
        kind: _rng.nextBool() ? _Kind.sparkle : _Kind.dot,
        gravity: 140,
        spin: 0,
      ));
    }
  }

  void leaves(Offset at, {int count = 14}) {
    const golden = [Color(0xFFFDE047), Color(0xFFFBBF24), Color(0xFFBEF264), Color(0xFFF59E0B)];
    for (var i = 0; i < count && _particles.length < _max; i++) {
      final a = -math.pi / 2 + (_rng.nextDouble() - 0.5) * 2.2;
      final s = 50 + _rng.nextDouble() * 60;
      _particles.add(_Particle(
        p: at,
        v: Offset(math.cos(a) * s, math.sin(a) * s),
        life: 1.2 + _rng.nextDouble() * 0.8,
        size: 2.6 + _rng.nextDouble() * 1.6,
        color: golden[_rng.nextInt(golden.length)],
        kind: _Kind.leaf,
        gravity: 55,
        spin: (_rng.nextDouble() - 0.5) * 8,
      ));
    }
  }

  void confetti(Offset at) {
    const colors = [
      Color(0xFFF87171), Color(0xFFFDE047), Color(0xFF4ADE80),
      Color(0xFF38BDF8), Color(0xFFFBBF24), Color(0xFFC084FC),
    ];
    for (var i = 0; i < 90 && _particles.length < _max; i++) {
      _particles.add(_Particle(
        p: Offset(at.dx - 220 + _rng.nextDouble() * 440, at.dy - 10 - _rng.nextDouble() * 120),
        v: Offset((_rng.nextDouble() - 0.5) * 40, 60 + _rng.nextDouble() * 80),
        life: 3.2 + _rng.nextDouble(),
        size: 2.4 + _rng.nextDouble() * 2,
        color: colors[_rng.nextInt(colors.length)],
        kind: _Kind.confetti,
        gravity: 30,
        spin: (_rng.nextDouble() - 0.5) * 12,
      ));
    }
  }

  @override
  void update(double dt) {
    for (final p in _particles) {
      p.age += dt;
      p.v = Offset(p.v.dx * (1 - dt * 0.8), p.v.dy + p.gravity * dt);
      if (p.kind == _Kind.leaf || p.kind == _Kind.confetti) {
        p.v = Offset(p.v.dx + math.sin(p.age * 4 + p.size) * 30 * dt, p.v.dy);
      }
      p.p = p.p + p.v * dt;
      p.rot += p.spin * dt;
    }
    _particles.removeWhere((p) => p.age >= p.life);
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      final fade = (1 - p.age / p.life).clamp(0.0, 1.0);
      final color = Kit.a(p.color, fade);
      switch (p.kind) {
        case _Kind.dot:
          canvas.drawCircle(p.p, p.size * 0.7, Kit.fill(color));
        case _Kind.sparkle:
          Kit.sparkle(canvas, p.p, p.size * 1.3, color);
        case _Kind.confetti:
          canvas.save();
          canvas.translate(p.p.dx, p.p.dy);
          canvas.rotate(p.rot);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size * 1.6, height: p.size * math.cos(p.rot * 1.3).abs() + 0.6),
              Kit.fill(color));
          canvas.restore();
        case _Kind.leaf:
          canvas.save();
          canvas.translate(p.p.dx, p.p.dy);
          canvas.rotate(p.rot);
          canvas.drawOval(Kit.oval(Offset.zero, p.size * 1.5, p.size * 0.75), Kit.fill(color));
          canvas.restore();
      }
    }
  }
}

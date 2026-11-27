import 'dart:math' as math;
import 'dart:ui';

import '../../models/window_scene.dart';
import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../diorama_snapshot.dart';
import '../layout.dart';
import 'scene_art.dart';
import 'window_props.dart';

class _Mote {
  _Mote(this.p, this.v, this.size, this.color, this.leaf, this.spin);
  Offset p;
  Offset v;
  final double size;
  final Color color;
  final bool leaf;
  final double spin;
  double rot = 0;
  double age = 0;
}

/// Snowfall during the Frostline, drifting meadow leaves, twilight fireflies.
class WindowWeather {
  final math.Random _rng = math.Random(7);
  final List<_Mote> _motes = [];
  double _snowAcc = 0;
  double _leafAcc = 0;

  static const _leafColors = [
    Color(0xFFF59E0B), Color(0xFFEA580C), Color(0xFF84CC16), Color(0xFFCA8A04),
  ];
  static const _fireflies = [
    Offset(118, 245), Offset(325, 225), Offset(80, 300), Offset(270, 290),
    Offset(370, 270), Offset(170, 210), Offset(230, 320), Offset(140, 330),
  ];

  void update(double dt, DioramaSnapshot snap) {
    if (snap.frost) {
      _snowAcc += dt * 18;
      while (_snowAcc >= 1) {
        _snowAcc -= 1;
        _motes.add(_Mote(
          Offset(30 + _rng.nextDouble() * 380, 18),
          Offset(4 + _rng.nextDouble() * 10, 28 + _rng.nextDouble() * 30),
          1.1 + _rng.nextDouble() * 1.8,
          const Color(0xFFFFFFFF),
          false,
          0,
        ));
      }
    }
    if (snap.scene == WindowScene.meadow && !snap.frost) {
      _leafAcc += dt * 0.8;
      while (_leafAcc >= 1) {
        _leafAcc -= 1;
        _motes.add(_Mote(
          Offset(60 + _rng.nextDouble() * 320, 120 + _rng.nextDouble() * 40),
          Offset(-8 + _rng.nextDouble() * 18, 12 + _rng.nextDouble() * 10),
          2.2 + _rng.nextDouble() * 1.2,
          _leafColors[_rng.nextInt(_leafColors.length)],
          true,
          (_rng.nextDouble() - 0.5) * 4,
        ));
      }
    }
    for (final m in _motes) {
      m.age += dt;
      final sway = math.sin(m.age * (m.leaf ? 2.2 : 1.4) + m.size * 3) * (m.leaf ? 18 : 8);
      m.p = m.p.translate((m.v.dx + sway) * dt, m.v.dy * dt);
      m.rot += m.spin * dt;
    }
    _motes.removeWhere((m) => m.p.dy > StudyLayout.windowRect.bottom + 6 || m.age > 14);
  }

  void render(Canvas canvas, SceneContext ctx) {
    for (final m in _motes) {
      if (m.leaf) {
        canvas.save();
        canvas.translate(m.p.dx, m.p.dy);
        canvas.rotate(m.rot);
        canvas.drawOval(Kit.oval(Offset.zero, m.size * 1.6, m.size * 0.8), Kit.fill(m.color));
        canvas.drawLine(Offset(-m.size * 1.4, 0), Offset(m.size * 1.4, 0),
            Kit.stroke(const Color(0x55451A03), 0.5));
        canvas.restore();
      } else {
        final fade = math.min(1.0, m.age * 3);
        canvas.drawCircle(m.p, m.size * 1.8, Kit.fill(Color.fromRGBO(255, 255, 255, 0.18 * fade)));
        canvas.drawCircle(m.p, m.size, Kit.fill(Color.fromRGBO(255, 255, 255, 0.92 * fade)));
      }
    }
    if (ctx.twilight) {
      for (var i = 0; i < _fireflies.length; i++) {
        final home = _fireflies[i];
        final p = Offset(home.dx + math.sin(ctx.time * 0.7 + i) * 14,
            home.dy + math.cos(ctx.time * 0.9 + i * 1.3) * 9);
        final blink = math.max(0.0, math.sin(ctx.time * 2.3 + i * 1.9));
        final color = i.isEven ? const Color(0xFFBEF264) : const Color(0xFFFEF08A);
        Kit.glow(canvas, p, 8, color, 0.5 * blink);
        canvas.drawCircle(p, 2.2, Kit.fill(Kit.a(color, 0.35 + 0.65 * blink)));
      }
    }
  }
}

/// Ice crystals creeping across the panes while bills exceed free cash.
class FrostPanes {
  double _amount = 0;
  late final List<(Offset, Offset)> _segments = _buildCrystals();

  bool get visible => _amount > 0;

  void update(double dt, bool frost) {
    _amount = (_amount + (frost ? dt / 2.4 : -dt / 1.4)).clamp(0.0, 1.0);
  }

  void render(Canvas canvas, SceneContext ctx) {
    if (_amount <= 0) return;
    final a = Ease.easeInOut(_amount);
    const win = StudyLayout.windowRect;
    final custom = ctx.art.prop('frost_overlay');
    if (custom != null) {
      canvas.drawImageRect(
          custom,
          Rect.fromLTWH(0, 0, custom.width.toDouble(), custom.height.toDouble()),
          win,
          Paint()..color = Color.fromRGBO(255, 255, 255, a));
      return;
    }
    canvas.drawRect(win, Kit.fill(Color.fromRGBO(224, 242, 254, 0.14 * a)));
    final drift = Kit.fill(Kit.a(Pal.frostPane, 0.72));
    for (final left in const [true, false]) {
      final corner = left ? const Offset(38, 380) : const Offset(402, 380);
      canvas.save();
      canvas.translate(corner.dx, corner.dy);
      canvas.scale(a);
      canvas.translate(-corner.dx, -corner.dy);
      canvas.drawPath(
          left
              ? (Path()
                ..moveTo(38, 380)
                ..lineTo(38, 290)
                ..quadraticBezierTo(75, 345, 135, 380)
                ..close())
              : (Path()
                ..moveTo(402, 380)
                ..lineTo(402, 285)
                ..quadraticBezierTo(360, 345, 300, 380)
                ..close()),
          drift);
      canvas.restore();
    }
    canvas.drawPath(StudyLayout.archPath(), Kit.stroke(Kit.a(Pal.frostEdge, 0.55 * a), 14));
    canvas.drawPath(StudyLayout.archPath(), Kit.stroke(Color.fromRGBO(255, 255, 255, 0.5 * a), 5));
    final visibleCount = (_segments.length * a).floor();
    final line = Kit.stroke(Color.fromRGBO(255, 255, 255, 0.75 * a), 0.9);
    for (var i = 0; i < visibleCount; i++) {
      final (from, to) = _segments[i];
      canvas.drawLine(from, to, line);
    }
  }

  static List<(Offset, Offset)> _buildCrystals() {
    final rng = math.Random(42);
    final seeds = <(Offset, double)>[
      for (var i = 0; i < 6; i++) (Offset(40, 300 + i * 13.0), 0.0),
      for (var i = 0; i < 6; i++) (Offset(400, 300 + i * 13.0), math.pi),
      for (var i = 0; i < 8; i++) (Offset(50 + i * 13.0, 378), -math.pi / 2),
      for (var i = 0; i < 8; i++) (Offset(390 - i * 13.0, 378), -math.pi / 2),
      for (var i = 0; i < 5; i++) (Offset(42, 175 + i * 22.0), 0.25),
      for (var i = 0; i < 5; i++) (Offset(398, 175 + i * 22.0), math.pi - 0.25),
    ]..shuffle(rng);
    final segments = <(Offset, Offset)>[];
    for (final (origin, baseAngle) in seeds) {
      final angle = baseAngle + (rng.nextDouble() - 0.5) * 0.9;
      final length = 9 + rng.nextDouble() * 18;
      final tip = origin + Offset(math.cos(angle), math.sin(angle)) * length;
      segments.add((origin, tip));
      for (var b = 1; b <= 3; b++) {
        final at = origin + (tip - origin) * (b / 4);
        final branch = length * (0.38 - b * 0.07);
        for (final side in const [-1.0, 1.0]) {
          final ba = angle + side * math.pi / 3;
          segments.add((at, at + Offset(math.cos(ba), math.sin(ba)) * branch));
        }
      }
    }
    return segments;
  }
}

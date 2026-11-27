import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/squirrel_painter.dart';
import '../diorama_event.dart';
import '../layout.dart';
import 'diorama_layer.dart';

/// The three Deep Oak-Root Reserves: Amber Reserve (glowing amber
/// crystals), Curio Vault (graded slab & silver bars) and Deep Treasury
/// (gold hoard guarded by the sleeping Golden Elder Squirrel).
class RootReserves extends DioramaLayer {
  RootReserves() : super(priority: 55);

  final PictureCache _cache = PictureCache();

  static const _targets = [DioramaTarget.amber, DioramaTarget.curio, DioramaTarget.treasury];
  static const _fills = [Color(0xFF2A170B), Color(0xFF26150A), Color(0xFF1F1108)];
  static const _borders = [Color(0xFFD97706), Color(0xFF92400E), Color(0xFFB45309)];

  @override
  void render(Canvas canvas) {
    _cache.draw(canvas, 'alcoves', _paintAlcoves);
    final rects = StudyLayout.reserves;
    _withSquash(canvas, rects[0], _targets[0], () => _amber(canvas, rects[0].topLeft));
    _withSquash(canvas, rects[1], _targets[1], () => _curio(canvas, rects[1].topLeft));
    _withSquash(canvas, rects[2], _targets[2], () => _treasury(canvas, rects[2].topLeft));
  }

  void _withSquash(Canvas canvas, Rect r, DioramaTarget target, void Function() paint) {
    final s = game.pokeAmount(target);
    canvas.save();
    canvas.translate(r.right - 30, r.bottom);
    canvas.scale(1 + s * 0.1, 1 - s * 0.14);
    canvas.translate(-(r.right - 30), -r.bottom);
    paint();
    canvas.restore();
  }

  void _paintAlcoves(Canvas c) {
    for (var i = 0; i < 3; i++) {
      final r = StudyLayout.reserves[i];
      final rr = Kit.rr(r, 15);
      c.drawRRect(rr, Kit.fill(_fills[i]));
      c.drawRRect(rr, Kit.vertical(r, const [Color(0x00000000), Color(0x33000000)]));
      c.drawRRect(rr, Kit.stroke(_borders[i], i == 2 ? 1.8 : 1.6));
      // Root tendrils hugging the corners
      final tendril = Kit.stroke(const Color(0xFF5A3418), 2.2);
      c.drawPath(Path()..moveTo(r.left + 4, r.top + 26)..quadraticBezierTo(r.left - 4, r.top + 4, r.left + 26, r.top - 2), tendril);
      c.drawPath(Path()..moveTo(r.right - 24, r.bottom + 2)..quadraticBezierTo(r.right + 4, r.bottom - 2, r.right - 2, r.bottom - 26), tendril);
    }
  }

  void _amber(Canvas c, Offset o) {
    final pulse = 0.5 + 0.5 * math.sin(t * 1.4);
    Kit.glow(c, o.translate(116, 98), 26, const Color(0xFFFBBF24), 0.25 + pulse * 0.2);
    c.drawPath(Path()..addPolygon([o.translate(104, 108), o.translate(112, 84), o.translate(120, 108)], true),
        Kit.fill(const Color(0xFFF59E0B)));
    c.drawPath(Path()..addPolygon([o.translate(114, 108), o.translate(121, 90), o.translate(127, 108)], true),
        Kit.fill(const Color(0xFFFDE047)));
    c.drawPath(Path()..addPolygon([o.translate(96, 108), o.translate(100, 98), o.translate(105, 108)], true),
        Kit.fill(const Color(0xFFD97706)));
    c.drawLine(o.translate(110, 92), o.translate(112, 86), Kit.stroke(const Color(0xAAFFFFFF), 0.9));
    // Honey jar
    final jar = Rect.fromLTWH(o.dx + 76, o.dy + 92, 16, 16);
    c.drawRRect(Kit.rr(jar, 5), Kit.fill(const Color(0xFFF59E0B)));
    c.drawRRect(Kit.rr(Rect.fromLTWH(jar.left - 1, jar.top - 3, 18, 4), 1.5), Kit.fill(const Color(0xFF92400E)));
    c.drawRRect(Kit.rr(Rect.fromLTWH(jar.left + 3, jar.top + 3, 3, 8), 1.5), Kit.fill(const Color(0x66FFFFFF)));
  }

  void _curio(Canvas c, Offset o) {
    for (var k = 0; k < 3; k++) {
      final bar = Rect.fromLTWH(o.dx + 84 + k * 4, o.dy + 100 - k * 5, 18, 7);
      c.drawRRect(Kit.rr(bar, 1.5), Kit.fill(const Color(0xFFCBD5E1)));
      c.drawLine(bar.topLeft.translate(2, 1.5), bar.topRight.translate(-2, 1.5), Kit.stroke(const Color(0xAAFFFFFF), 0.8));
    }
    final slab = Rect.fromLTWH(o.dx + 110, o.dy + 82, 13, 21);
    c.drawRRect(Kit.rr(slab, 2), Kit.fill(const Color(0xFF38BDF8)));
    c.drawRRect(Kit.rr(slab, 2), Kit.stroke(const Color(0xFFFDE047), 1));
    c.drawRect(Rect.fromLTWH(slab.left + 2, slab.top + 2, 9, 4), Kit.fill(const Color(0xFFF8FAFC)));
    c.drawCircle(slab.center.translate(0, 3), 3, Kit.fill(const Color(0xFFFDE047)));
    // Holographic shimmer sweep
    final s = (t * 0.35) % 1.4;
    if (s < 1) {
      c.save();
      c.clipRRect(Kit.rr(slab, 2));
      final x = slab.left - 6 + s * (slab.width + 12);
      c.drawPath(Path()..addPolygon([Offset(x, slab.top), Offset(x + 4, slab.top), Offset(x - 4, slab.bottom), Offset(x - 8, slab.bottom)], true),
          Kit.fill(const Color(0x88FFFFFF)));
      c.restore();
    }
  }

  void _treasury(Canvas c, Offset o) {
    final pile = o.translate(96, 104);
    c.drawOval(Kit.oval(pile, 26, 10), Kit.fill(const Color(0xFFD97706)));
    final rng = math.Random(5);
    for (var k = 0; k < 9; k++) {
      final p = pile.translate(-20 + rng.nextDouble() * 40, -4 + rng.nextDouble() * 7);
      c.drawCircle(p, 3, Kit.fill(const Color(0xFFFACC15)));
      c.drawCircle(p.translate(-0.8, -0.8), 0.9, Kit.fill(const Color(0xAAFFFFFF)));
    }
    SquirrelPainter.paint(c, o.translate(96, 94),
        pose: SquirrelPose.sleep, scale: 0.68, time: t, seed: 6,
        look: const SquirrelLook(golden: true), art: game.art);
    // Tiny crown on the elder
    c.drawPath(
        Path()
          ..moveTo(o.dx + 93, o.dy + 83)
          ..lineTo(o.dx + 94, o.dy + 79)
          ..lineTo(o.dx + 96, o.dy + 81.5)
          ..lineTo(o.dx + 98, o.dy + 78.5)
          ..lineTo(o.dx + 99.5, o.dy + 81.5)
          ..lineTo(o.dx + 101.5, o.dy + 79)
          ..lineTo(o.dx + 102, o.dy + 83)
          ..close(),
        Kit.fill(const Color(0xFFFDE047)));
  }

  @override
  void onRemove() {
    _cache.dispose();
    super.onRemove();
  }
}

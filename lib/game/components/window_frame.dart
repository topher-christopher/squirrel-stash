import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../layout.dart';
import 'diorama_layer.dart';

/// Carved oak arch, mullions, keystone and brass latches.
class WindowFrame extends DioramaLayer {
  WindowFrame() : super(priority: 20);

  final PictureCache _cache = PictureCache();

  @override
  void render(Canvas canvas) => _cache.draw(canvas, 'frame', _paint);

  void _paint(Canvas c) {
    final arch = StudyLayout.archPath();
    // Outer shadow so the frame sits proud of the wall.
    c.save();
    c.translate(0, 3);
    c.drawPath(arch, Kit.stroke(const Color(0x66000000), 16));
    c.restore();
    c.drawPath(arch, Kit.stroke(Pal.frameDark, 12));
    c.drawPath(arch, Kit.stroke(Pal.frameLight, 3));
    // Inner bevel highlight
    c.save();
    c.translate(0, -1.2);
    c.drawPath(arch, Kit.stroke(const Color(0x33FDE68A), 1));
    c.restore();

    // Mullions with a soft lit edge
    final mullion = Kit.stroke(Kit.a(Pal.frameDark, 0.9), 5);
    c.drawLine(const Offset(220, 20), const Offset(220, 380), mullion);
    c.drawLine(const Offset(38, 238), const Offset(402, 238), Kit.stroke(Kit.a(Pal.frameDark, 0.85), 4));
    c.drawLine(const Offset(218.5, 20), const Offset(218.5, 380), Kit.stroke(const Color(0x22FDE68A), 0.8));
    c.drawLine(const Offset(38, 236.6), const Offset(402, 236.6), Kit.stroke(const Color(0x22FDE68A), 0.8));
    // Mullion hub
    c.drawCircle(const Offset(220, 238), 5, Kit.fill(Pal.frameDark));
    c.drawCircle(const Offset(220, 238), 3, Kit.fill(Pal.brassDark));
    c.drawCircle(const Offset(219, 237), 1.1, Kit.fill(const Color(0xAAFDE68A)));

    // Keystone at the apex
    final key = Path()
      ..moveTo(208, 10)
      ..lineTo(232, 10)
      ..lineTo(228, 30)
      ..lineTo(212, 30)
      ..close();
    c.drawPath(key, Kit.vertical(const Rect.fromLTWH(208, 10, 24, 20),
        const [Pal.frameLight, Pal.frameDark]));
    c.drawPath(key, Kit.stroke(Pal.outline, 1));
    Kit.acorn(c, const Offset(220, 21), rx: 3.4, ry: 4, strokeWidth: 0.7);

    // Brass latches
    for (final y in const [170.0, 300.0]) {
      for (final x in const [33.0, 407.0]) {
        c.drawRRect(Kit.rr(Rect.fromCenter(center: Offset(x, y), width: 6, height: 14), 2),
            Kit.fill(Pal.brassDark));
        c.drawCircle(Offset(x, y - 3.5), 1.1, Kit.fill(Pal.brass));
        c.drawCircle(Offset(x, y + 3.5), 1.1, Kit.fill(Pal.brass));
      }
    }
  }

  @override
  void onRemove() {
    _cache.dispose();
    super.onRemove();
  }
}

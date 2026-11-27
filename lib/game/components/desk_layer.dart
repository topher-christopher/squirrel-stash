import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import 'diorama_layer.dart';

/// The carved oak desk (static, cached): top, front panel, recessed plaque
/// insets behind each instrument card, and brass trim.
class DeskLayer extends DioramaLayer {
  DeskLayer() : super(priority: 30);

  final PictureCache _cache = PictureCache();

  static const insets = [
    Rect.fromLTWH(18, 424, 110, 70),
    Rect.fromLTWH(132, 424, 102, 70),
    Rect.fromLTWH(238, 424, 98, 70),
    Rect.fromLTWH(338, 424, 88, 70),
  ];

  @override
  void render(Canvas canvas) => _cache.draw(canvas, 'desk', _paint);

  void _paint(Canvas c) {
    const top = Rect.fromLTRB(0, 376, 440, 418);
    c.drawRect(top, Kit.vertical(top, const [Pal.deskTopLight, Pal.deskTopDark]));
    Kit.woodGrain(c, top, const Color(0x335C2E10), seed: 17, lines: 6, width: 0.9);
    c.drawLine(const Offset(0, 376), const Offset(440, 376), Kit.stroke(Pal.deskEdge, 2.2));
    c.drawLine(const Offset(0, 378.4), const Offset(440, 378.4), Kit.stroke(const Color(0x33FFF7ED), 0.8));

    const front = Rect.fromLTWH(0, 418, 440, 94);
    c.drawRect(front, Kit.vertical(front, const [Pal.deskFrontTop, Pal.deskFrontBottom]));
    Kit.woodGrain(c, front, const Color(0x2A1C0A03), seed: 23, lines: 10, width: 0.9);
    c.drawLine(const Offset(0, 418), const Offset(440, 418), Kit.stroke(const Color(0xFF291408), 2));
    // Shadow cast by the desk lip
    c.drawRect(const Rect.fromLTWH(0, 419, 440, 6),
        Kit.vertical(const Rect.fromLTWH(0, 419, 440, 6), const [Color(0x55000000), Color(0x00000000)]));

    for (final r in insets) {
      final rr = Kit.rr(r, 13);
      c.drawRRect(rr, Kit.fill(const Color(0x33000000)));
      c.drawRRect(rr.shift(const Offset(0, -0.8)), Kit.stroke(const Color(0x55000000), 1.2));
      c.drawRRect(rr.shift(const Offset(0, 0.8)), Kit.stroke(const Color(0x22FDE68A), 0.8));
    }

    // Carved bead & brass trim along the bottom edge
    c.drawLine(const Offset(0, 502), const Offset(440, 502), Kit.stroke(const Color(0x44000000), 1.2));
    c.drawLine(const Offset(0, 503.5), const Offset(440, 503.5), Kit.stroke(const Color(0x22FDE68A), 0.8));
    for (var x = 20.0; x < 440; x += 50) {
      c.drawCircle(Offset(x, 507), 1.6, Kit.fill(const Color(0xFFB45309)));
      c.drawCircle(Offset(x - 0.4, 506.6), 0.6, Kit.fill(const Color(0xAAFDE68A)));
    }
  }

  @override
  void onRemove() {
    _cache.dispose();
    super.onRemove();
  }
}

import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../layout.dart';
import 'diorama_layer.dart';

/// Hollow oak interior walls and hanging ivy (fairy lights: fairy_lights.dart).
class StudyWall extends DioramaLayer {
  StudyWall() : super(priority: 0);

  final PictureCache _cache = PictureCache();

  @override
  void render(Canvas canvas) {
    _cache.draw(canvas, 'wall', _paintStatic);
  }

  void _paintStatic(Canvas c) {
    const wall = Rect.fromLTWH(0, 0, StudyLayout.width, StudyLayout.wallBottom);
    c.drawRect(wall, Kit.vertical(wall, const [Pal.wallTop, Pal.wallBottom]));
    // Carved hollow grooves and bark rings
    final groove = Kit.stroke(Kit.a(Pal.groove, 0.55), 3);
    c.drawPath(Path()..moveTo(16, 0)..quadraticBezierTo(22, 190, 12, 390), groove);
    c.drawPath(Path()..moveTo(424, 0)..quadraticBezierTo(418, 190, 428, 390), groove);
    Kit.woodGrain(c, const Rect.fromLTWH(0, 0, 36, 390), Kit.a(Pal.groove, 0.5), seed: 3, lines: 22);
    Kit.woodGrain(c, const Rect.fromLTWH(404, 0, 36, 390), Kit.a(Pal.groove, 0.5), seed: 7, lines: 22);
    // Inner hollow shading toward the corners
    c.drawRect(wall, Kit.radial(const Offset(220, 200), 320,
        [const Color(0x00000000), const Color(0x00000000), const Color(0x55000000)], [0, 0.6, 1]));
    _paintIvy(c, const Offset(4, 0), 1);
    _paintIvy(c, const Offset(436, 0), -1);
  }

  void _paintIvy(Canvas c, Offset origin, double dir) {
    final vine = Kit.stroke(const Color(0xFF3F6212), 1.4);
    final path = Path()..moveTo(origin.dx, origin.dy);
    final rng = math.Random(dir > 0 ? 11 : 13);
    var y = origin.dy;
    var x = origin.dx;
    final leaves = <Offset>[];
    for (var i = 0; i < 9; i++) {
      final ny = y + 14 + rng.nextDouble() * 8;
      final nx = origin.dx + dir * (6 + rng.nextDouble() * 18);
      path.quadraticBezierTo(x + dir * 10, (y + ny) / 2, nx, ny);
      leaves.add(Offset(nx, ny));
      x = nx;
      y = ny;
    }
    c.drawPath(path, vine);
    for (var i = 0; i < leaves.length; i++) {
      final p = leaves[i];
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(dir * (0.6 + (i % 3) * 0.4));
      c.drawOval(Kit.oval(Offset(dir * 4, 0), 4.2, 2.4),
          Kit.fill(i.isEven ? const Color(0xFF4D7C0F) : const Color(0xFF65A30D)));
      c.restore();
    }
  }

  @override
  void onRemove() {
    _cache.dispose();
    super.onRemove();
  }
}

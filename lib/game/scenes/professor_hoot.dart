import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../diorama_event.dart';
import 'scene_art.dart';

/// Professor Hoot, the rare woodland visitor perched on the Great Oak's left
/// limb. A golden sparkle hovers beside him while his daily gift is waiting.
abstract final class ProfessorHoot {
  static void paint(Canvas canvas, SceneContext ctx) {
    final squash = ctx.poke(DioramaTarget.hoot);
    canvas.save();
    canvas.translate(105, 174);
    canvas.rotate(math.sin(ctx.time * 0.9) * 0.05);
    canvas.scale(1 + squash * 0.12, 1 - squash * 0.16);
    final brown = Kit.fill(const Color(0xFF78350F));
    canvas.drawPath(Path()..moveTo(-7, -8)..lineTo(-5, -14)..lineTo(-2, -9)..close(), brown);
    canvas.drawPath(Path()..moveTo(7, -8)..lineTo(5, -14)..lineTo(2, -9)..close(), brown);
    canvas.drawOval(Kit.oval(Offset.zero, 8.5, 10.5), brown);
    canvas.drawOval(Kit.oval(const Offset(0, 2), 5.5, 6.5), Kit.fill(const Color(0xFFFDE68A)));
    final blink = (ctx.time % 5.1) < 0.14;
    for (final ex in const [-3.0, 3.0]) {
      if (blink) {
        canvas.drawLine(Offset(ex - 2, -3), Offset(ex + 2, -3), Kit.stroke(Pal.eye, 1.1));
      } else {
        canvas.drawCircle(Offset(ex, -3), 2.4, Kit.fill(const Color(0xFFFFFFFF)));
        canvas.drawCircle(Offset(ex, -3), 1.1, Kit.fill(Pal.eye));
      }
    }
    canvas.drawPath(Path()..moveTo(-1.4, -1)..lineTo(1.4, -1)..lineTo(0, 2)..close(),
        Kit.fill(const Color(0xFFF59E0B)));
    // Spectacles: he is a Professor, after all.
    canvas.drawLine(const Offset(-0.6, -3), const Offset(0.6, -3), Kit.stroke(Pal.brass, 0.7));
    canvas.restore();
    if (ctx.snap.hootHasGift) {
      final bob = math.sin(ctx.time * 2.2) * 2;
      final p = Offset(113, 164 + bob);
      Kit.glow(canvas, p, 8, const Color(0xFFFACC15), 0.5);
      canvas.drawCircle(p, 3.8, Kit.fill(const Color(0xFFFACC15)));
      Kit.sparkle(canvas, p.translate(4, -4), 2.2, const Color(0xFFFFFFFF));
    }
  }
}

import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../diorama_event.dart';
import '../diorama_snapshot.dart';
import '../layout.dart';
import 'diorama_layer.dart';

/// Fallout-Shelter Goal Chambers evolving Lv.1 Dirt Alcove → Lv.2 Timber
/// Chamber → Lv.3 Gold Treasury, plus the dashed "dig new room" slot.
class GoalChambers extends DioramaLayer {
  GoalChambers() : super(priority: 55);

  static const _targets = [DioramaTarget.chamberLeft, DioramaTarget.chamberRight];

  @override
  void render(Canvas canvas) {
    for (var i = 0; i < 2; i++) {
      final slot = snap.chambers.length > i ? snap.chambers[i] : null;
      if (slot == null) continue;
      final rect = StudyLayout.chambers[i];
      final squash = game.pokeAmount(_targets[i]);
      canvas.save();
      canvas.translate(rect.center.dx, rect.bottom);
      canvas.scale(1 + squash * 0.03, 1 - squash * 0.04);
      canvas.translate(-rect.center.dx, -rect.bottom);
      if (slot.isDigSlot) {
        _paintDigSlot(canvas, rect);
      } else {
        _paintChamber(canvas, rect, slot, i);
      }
      canvas.restore();
    }
  }

  void _paintDigSlot(Canvas c, Rect r) {
    final rr = Kit.rr(r, 16);
    c.drawRRect(rr, Kit.fill(const Color(0x99241308)));
    Kit.dashedRRect(c, rr, Kit.stroke(const Color(0xFFD97706), 1.6));
    final rng = math.Random(r.left.toInt());
    for (var k = 0; k < 7; k++) {
      c.drawOval(Kit.oval(Offset(r.left + 30 + k * 20 + rng.nextDouble() * 8, r.bottom - 10 - rng.nextDouble() * 4), 5, 3),
          Kit.fill(const Color(0xFF4A2A14)));
    }
    final pulse = 0.5 + 0.5 * math.sin(t * 2);
    c.drawRRect(rr, Kit.stroke(Color.fromRGBO(251, 191, 36, 0.08 + pulse * 0.1), 4));
  }

  void _paintChamber(Canvas c, Rect r, ChamberArt art, int index) {
    final rr = Kit.rr(r, 16);
    switch (art.level) {
      case 3:
        c.drawRRect(rr, Kit.vertical(r, const [Color(0xFF4A2C10), Color(0xFF3B230E)]));
        Kit.glow(c, r.center.translate(-50, 10), 60, const Color(0xFFFBBF24), 0.18);
      case 2:
        c.drawRRect(rr, Kit.fill(const Color(0xFF2D190C)));
      default:
        c.drawRRect(rr, Kit.fill(const Color(0xFF241308)));
    }
    c.save();
    c.clipRRect(rr);
    if (art.level == 1) {
      // Rough dirt walls & pebbles
      final rng = math.Random(index * 7 + 3);
      for (var k = 0; k < 14; k++) {
        c.drawCircle(Offset(r.left + rng.nextDouble() * r.width, r.top + rng.nextDouble() * r.height),
            1 + rng.nextDouble() * 2.2, Kit.fill(const Color(0x334A2A14)));
      }
      c.drawPath(
          Path()
            ..moveTo(r.left, r.bottom - 14)
            ..quadraticBezierTo(r.center.dx, r.bottom - 22, r.right, r.bottom - 12)
            ..lineTo(r.right, r.bottom)
            ..lineTo(r.left, r.bottom)
            ..close(),
          Kit.fill(const Color(0xFF3A2010)));
    } else {
      // Plank floor
      c.drawRect(Rect.fromLTRB(r.left, r.bottom - 16, r.right, r.bottom), Kit.fill(const Color(0xFF5C3419)));
      for (var x = r.left + 22; x < r.right; x += 26) {
        c.drawLine(Offset(x, r.bottom - 16), Offset(x, r.bottom), Kit.stroke(const Color(0x55000000), 1));
      }
      // Timber beam and posts
      c.drawRRect(Kit.rr(Rect.fromLTWH(r.left + 6, r.top + 6, r.width - 12, 6), 3), Kit.fill(const Color(0xFF6B3D1E)));
      for (final x in [r.left + 8, r.right - 13]) {
        c.drawRect(Rect.fromLTWH(x, r.top + 10, 5, r.height - 26), Kit.fill(const Color(0xFF5A3418)));
      }
      if (art.level == 3) {
        for (var k = 0; k < 5; k++) {
          final phase = (t * 0.7 + k * 0.23) % 1.0;
          final p = Offset(r.left + 70 + k * 22.0, r.top + 30 + math.sin(k * 2.0) * 14);
          Kit.sparkle(c, p, 2.6 * math.sin(phase * math.pi), const Color(0xFFFFF7AE));
        }
      }
    }
    c.restore();

    final border = switch (art.level) {
      3 => Kit.stroke(const Color(0xFFFBBF24), 2.4),
      2 => Kit.stroke(const Color(0xFFB45309), 1.6),
      _ => Kit.stroke(const Color(0xFF78350F), 1.6),
    };
    c.drawRRect(rr, border);
    if (art.priority) {
      c.drawRRect(rr.inflate(2), Kit.stroke(Color.fromRGBO(253, 224, 71, 0.18 + 0.1 * math.sin(t * 2)), 2));
    }

    _paintChest(c, StudyLayout.chestIn(r), art);

    // Acorn progress meter
    final bar = Rect.fromLTWH(r.left + 12, r.bottom - 8, r.width - 24, 4);
    c.drawRRect(Kit.rr(bar, 2), Kit.fill(const Color(0x66000000)));
    final fill = Rect.fromLTWH(bar.left, bar.top, bar.width * (art.percent / 100).clamp(0, 1), bar.height);
    if (fill.width > 0) {
      c.drawRRect(Kit.rr(fill, 2), Kit.linear(fill.centerLeft, fill.centerRight,
          const [Color(0xFFD97706), Color(0xFFFDE047)]));
    }
  }

  void _paintChest(Canvas c, Offset o, ChamberArt art) {
    final custom = game.art.prop('chest_lv${art.level}');
    if (custom != null) {
      c.drawImageRect(custom, Rect.fromLTWH(0, 0, custom.width.toDouble(), custom.height.toDouble()),
          Rect.fromCenter(center: o.translate(0, -2), width: 34, height: 28),
          Paint()..filterQuality = FilterQuality.medium);
      return;
    }
    final trim = art.level == 3 ? const Color(0xFFFDE047) : const Color(0xFFF59E0B);
    c.drawOval(Kit.oval(o.translate(0, 10), 17, 3), Kit.fill(const Color(0x55000000)));
    if (art.level == 3) Kit.glow(c, o.translate(0, -8), 22, const Color(0xFFFDE047), 0.45);
    c.drawRRect(Kit.rr(Rect.fromLTWH(o.dx - 15, o.dy - 11, 30, 20), 4), Kit.fill(const Color(0xFF78350F)));
    c.drawRRect(Kit.rr(Rect.fromLTWH(o.dx - 15, o.dy - 11, 30, 20), 4), Kit.stroke(trim, 1.3));
    if (art.percent >= 40) {
      final bob = math.sin(t * 2.2) * 0.6;
      for (final dx in const [-6.0, 0.0, 6.0]) {
        c.drawCircle(o.translate(dx, -11 + bob - (dx == 0 ? 2 : 0)), 4.2, Kit.fill(const Color(0xFFFACC15)));
        c.drawCircle(o.translate(dx - 1, -12.5 + bob - (dx == 0 ? 2 : 0)), 1.2, Kit.fill(const Color(0xAAFFFFFF)));
      }
    }
    final lidLift = art.level == 3 ? -3.0 : 0.0;
    c.drawRRect(Kit.rr(Rect.fromLTWH(o.dx - 16, o.dy - 14 + lidLift, 32, 6.5), 2), Kit.fill(const Color(0xFF92400E)));
    c.drawRect(Rect.fromLTWH(o.dx - 2, o.dy - 9, 4, 5), Kit.fill(trim));
  }
}

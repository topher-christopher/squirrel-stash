import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

import 'asset_manifest.dart';
import 'paint_kit.dart';
import 'palette.dart';
import 'squirrel_outfits.dart';

enum SquirrelPose { idle, tea, sleep, toss, hauler, researcher, focus, lantern }

/// Costume & prop toggles for a squirrel (see `squirrel_outfits.dart`).
class SquirrelLook {
  const SquirrelLook({
    this.scarf = false,
    this.acorn = false,
    this.golden = false,
    this.hat = SquirrelHat.none,
    this.prop = SquirrelProp.none,
    this.suit = false,
    this.book = false,
  });

  final bool scarf;
  final bool acorn;
  final bool golden;
  final SquirrelHat hat;
  final SquirrelProp prop;

  /// Navy commuter jacket & tie.
  final bool suit;
  final bool book;
}

/// Cozy chibi squirrel (Cats & Soup / Focus Friend aesthetic), drawn in a
/// ~30-unit tall local space with feet at y = +14. Custom sprite sheets in
/// `assets/sprites/squirrels/` replace the procedural body per pose.
abstract final class SquirrelPainter {
  static final Path _tail = Path()
    ..moveTo(-5, 10)
    ..cubicTo(-19, 10, -22, -7, -11, -11)
    ..cubicTo(-5, -13, -3, -5, -7, -1)
    ..cubicTo(-10, 2, -6, 6, -3, 7)
    ..close();

  static final Path _tailFluff = Path()
    ..moveTo(-12, -8)
    ..quadraticBezierTo(-17, -2, -13, 5);

  static TextPainter? _zzz;
  static TextPainter get _zzzText => _zzz ??= TextPainter(
        text: const TextSpan(
          text: 'zZz',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFEF3C7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  static void paint(
    Canvas canvas,
    Offset at, {
    SquirrelPose pose = SquirrelPose.idle,
    double dir = 1,
    double scale = 1,
    SquirrelLook look = const SquirrelLook(),
    double time = 0,
    double seed = 0,
    double squash = 0,
    double hop = 0,
    StashAssetManifest? art,
  }) {
    canvas.save();
    canvas.translate(at.dx, at.dy + hop);
    canvas.scale(dir * scale, scale);

    // Squash & stretch around the feet (taps, hops).
    if (squash != 0) {
      canvas.translate(0, 14);
      canvas.scale(1 + squash * 0.14, 1 - squash * 0.2);
      canvas.translate(0, -14);
    }

    canvas.drawOval(Kit.oval(const Offset(0, 14), 11, 3.5),
        Kit.fill(const Color(0x471C110A)));

    final sheet = art?.squirrel(pose.name);
    if (sheet != null) {
      _paintSprite(canvas, sheet, time + seed);
      canvas.restore();
      return;
    }

    final fur = look.golden ? Pal.goldFur : Pal.fur;
    final belly = look.golden ? Pal.goldBelly : Pal.furBelly;
    final tailColor = look.golden ? Pal.goldTail : Pal.furTail;
    final ink = Kit.stroke(Pal.outline, 1.2);
    final breath = math.sin(time * 2.1 + seed) * 0.45;

    // Plush curled tail with a lazy sway.
    canvas.save();
    canvas.translate(-5, 9);
    canvas.rotate(math.sin(time * 1.7 + seed * 2) * 0.1);
    canvas.translate(5, -9);
    canvas.drawPath(_tail, Kit.fill(tailColor));
    canvas.drawPath(_tail, ink);
    canvas.drawPath(_tailFluff, Kit.stroke(Kit.a(belly, 0.55), 1.1));
    canvas.restore();

    // Feet
    canvas.drawOval(Kit.oval(const Offset(-3, 13.2), 2.8, 1.6), Kit.fill(tailColor));
    canvas.drawOval(Kit.oval(const Offset(3.8, 13.2), 2.8, 1.6), Kit.fill(tailColor));

    // Round body + belly
    final body = Kit.oval(Offset(0, 5 - breath * 0.3), 8.5, 9 + breath * 0.3);
    canvas.drawOval(body, Kit.fill(fur));
    canvas.drawOval(body, ink);
    canvas.drawOval(Kit.oval(const Offset(2.5, 6), 5, 6.2), Kit.fill(belly));
    if (look.suit) SquirrelOutfits.suit(canvas);

    if (look.scarf) {
      canvas.drawRRect(Kit.rr(const Rect.fromLTWH(-7, -2.5, 15, 4.2), 2),
          Kit.fill(Pal.scarf));
      canvas.drawRRect(Kit.rr(const Rect.fromLTWH(-7, -2.5, 15, 4.2), 2),
          Kit.stroke(Pal.scarfDark, 0.9));
      canvas.drawPath(
          Path()
            ..moveTo(-5, 1)
            ..lineTo(-9, 8)
            ..lineTo(-5, 9)
            ..lineTo(-2, 2)
            ..close(),
          Kit.fill(Pal.scarfTail));
    }

    // Head group bobs gently with breath.
    canvas.save();
    canvas.translate(0, breath * 0.5);
    for (final ex in const [-3.5, 4.5]) {
      final ear = Kit.oval(Offset(ex, -14.5), 2.4, 4);
      canvas.drawOval(ear, Kit.fill(fur));
      canvas.drawOval(ear, Kit.stroke(Pal.outline, 1.1));
      canvas.drawOval(Kit.oval(Offset(ex + 0.2, -14), 1.1, 2.2),
          Kit.fill(Kit.a(Pal.cheek, 0.55)));
    }
    canvas.drawCircle(const Offset(1.5, -7), 8.2, Kit.fill(fur));
    canvas.drawCircle(const Offset(1.5, -7), 8.2, ink);
    canvas.drawOval(Kit.oval(const Offset(5.5, -4.2), 3.6, 2.6), Kit.fill(Kit.a(belly, 0.85)));

    _paintHats(canvas, look);
    _paintFace(canvas, pose, time, seed);
    canvas.restore();

    _paintProps(canvas, pose, look, time, seed, fur);

    if (pose == SquirrelPose.sleep) {
      final rise = (time * 0.45 + seed) % 1.0;
      canvas.save();
      canvas.translate(8, -13 - rise * 7);
      canvas.scale(dir, 1); // keep the letters readable when mirrored
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, 0.85 * (1 - rise)));
      _zzzText.paint(canvas, Offset(0, -_zzzText.height / 2));
      canvas.restore();
      canvas.restore();
    }
    canvas.restore();
  }

  static void _paintSprite(Canvas canvas, SpriteSheetSpec sheet, double t) {
    final h = sheet.worldHeight;
    final w = h * sheet.frameSize.width / sheet.frameSize.height;
    final dst = Rect.fromLTWH(-w * sheet.anchor.dx, 14 - h * sheet.anchor.dy, w, h);
    canvas.drawImageRect(sheet.image, sheet.frameRect(t), dst,
        Paint()..filterQuality = FilterQuality.medium);
  }

  static void _paintHats(Canvas canvas, SquirrelLook look) =>
      SquirrelOutfits.hat(canvas, look.hat);

  static void _paintFace(Canvas canvas, SquirrelPose pose, double time, double seed) {
    final ink = Kit.stroke(Pal.outline, 1.3);
    if (pose == SquirrelPose.sleep) {
      canvas.drawPath(
          Path()
            ..moveTo(1, -7.5)
            ..quadraticBezierTo(3.2, -5.8, 5.2, -7.5),
          ink);
    } else {
      final blinking = (time + seed * 1.7) % 4.3 < 0.13;
      if (blinking) {
        canvas.drawLine(const Offset(3.4, -7.8), const Offset(6.2, -7.8), ink);
      } else {
        canvas.drawCircle(const Offset(4.8, -7.8), 1.7, Kit.fill(Pal.eye));
        canvas.drawCircle(const Offset(5.3, -8.3), 0.6, Kit.fill(const Color(0xFFFFFFFF)));
      }
    }
    canvas.drawOval(Kit.oval(const Offset(6.2, -5.2), 1.8, 1.1),
        Kit.fill(Kit.a(Pal.cheek, 0.65)));
    canvas.drawCircle(const Offset(9.2, -6.4), 0.95, Kit.fill(Pal.outline));
    canvas.drawPath(
        Path()
          ..moveTo(7.2, -4.4)
          ..quadraticBezierTo(8.1, -3.6, 9.0, -4.4),
        Kit.stroke(Pal.outline, 0.8));

    if (pose == SquirrelPose.researcher || pose == SquirrelPose.focus) {
      canvas.drawCircle(const Offset(4.8, -7.6), 2.8, Kit.fill(const Color(0x59E0F2FE)));
      canvas.drawCircle(const Offset(4.8, -7.6), 2.8, Kit.stroke(Pal.brass, 1.1));
      canvas.drawLine(const Offset(-1, -8), const Offset(2, -7.6), Kit.stroke(Pal.brass, 1));
    }
  }

  static void _paintProps(Canvas canvas, SquirrelPose pose, SquirrelLook look,
      double time, double seed, Color fur) {
    final paw = Kit.fill(fur);
    switch (pose) {
      case SquirrelPose.tea:
        canvas.save();
        canvas.translate(8, 3);
        canvas.drawRRect(Kit.rr(const Rect.fromLTWH(-3, -3, 6, 6.5), 1.5),
            Kit.fill(const Color(0xFFF8FAFC)));
        canvas.drawRRect(Kit.rr(const Rect.fromLTWH(-3, -3, 6, 6.5), 1.5),
            Kit.stroke(Pal.acornCap, 1));
        final s = (time * 0.42 + seed) % 1.0;
        final steam = Path()
          ..moveTo(0, -5 - s * 3)
          ..quadraticBezierTo(2, -8 - s * 3, 0, -11 - s * 3);
        canvas.drawPath(steam,
            Kit.stroke(Color.fromRGBO(255, 255, 255, 0.85 * math.sin(s * math.pi)), 1.1));
        canvas.restore();
        canvas.drawOval(Kit.oval(const Offset(5.6, 4.2), 2.1, 1.6), paw);
      case SquirrelPose.toss:
        final arc = (math.sin(time * 2.4 + seed)).abs();
        Kit.acorn(canvas, Offset(8, -10 - arc * 9), rx: 3.4, ry: 4.2, strokeWidth: 0.8);
        canvas.drawOval(Kit.oval(const Offset(6.8, -1.5), 2, 1.6), paw);
      case SquirrelPose.lantern:
        canvas.save();
        canvas.translate(10, 2);
        final flicker = 0.3 + 0.08 * math.sin(time * 9 + seed);
        Kit.glow(canvas, const Offset(0, 3), 11, const Color(0xFFFEF08A), flicker + 0.2);
        canvas.drawRRect(Kit.rr(const Rect.fromLTWH(-2.5, 0, 5, 6), 1.2),
            Kit.fill(const Color(0xFFFACC15)));
        canvas.drawRRect(Kit.rr(const Rect.fromLTWH(-2.5, 0, 5, 6), 1.2),
            Kit.stroke(Pal.acornCap, 0.9));
        canvas.drawLine(const Offset(0, 0), const Offset(-2, -3), Kit.stroke(Pal.acornCap, 0.8));
        canvas.restore();
      case SquirrelPose.focus:
      case SquirrelPose.researcher:
        if (look.book) {
          canvas.drawRRect(Kit.rr(const Rect.fromLTWH(4, 1, 9, 6), 1),
              Kit.fill(const Color(0xFF7C2D12)));
          canvas.drawRect(const Rect.fromLTWH(5, 1.6, 7, 4.8),
              Kit.fill(const Color(0xFFFEF3C7)));
          canvas.drawLine(const Offset(8.5, 1.6), const Offset(8.5, 6.4),
              Kit.stroke(Pal.acornCap, 0.6));
        }
        canvas.drawOval(Kit.oval(const Offset(6, 4), 2, 1.6), paw);
      case SquirrelPose.idle:
      case SquirrelPose.sleep:
      case SquirrelPose.hauler:
        break;
    }
    if (look.acorn) {
      Kit.acorn(canvas, const Offset(8, 1), rx: 4.2, ry: 5,
          body: look.golden ? Pal.gold : Pal.acorn);
      canvas.drawOval(Kit.oval(const Offset(4.8, 3), 2, 1.6), paw);
    }
    SquirrelOutfits.prop(canvas, look.prop, time, seed, paw);
  }
}

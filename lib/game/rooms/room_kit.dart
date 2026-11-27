import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

import '../../models/room.dart';
import '../art/asset_manifest.dart';
import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../diorama_snapshot.dart';

/// Per-frame context handed to room painters.
class RoomCtx {
  RoomCtx({
    required this.room,
    required this.r,
    required this.t,
    required this.level,
    required this.detail,
    required this.snap,
    required this.art,
    double? work,
    this.since = _never,
  }) : work = work ?? t;

  static double _never(String _) => 1e9;

  final RoomKey room;
  final Rect r;
  final double t;

  /// 1 Starter, 2 Cozy, 3 Max Unlocked.
  final int level;

  /// 0 zoomed-out panorama → 1 zoomed-in interior detail.
  final double detail;
  final TreeSnapshot snap;
  final StashAssetManifest art;

  /// Colony work clock: advances only while the Hearth is lit, so squirrel
  /// routines freeze (asleep) in the dark. Use [t] for water and flames.
  final double work;

  /// Seconds since a one-shot story beat (see `StashDioramaGame.since`).
  final double Function(String key) since;

  bool get frost => snap.frost;
  bool get lit => snap.lit;
  bool get max => level >= 3;

  /// Local point inside the room from fractions of its width/height.
  Offset at(double fx, double fy) => Offset(r.left + r.width * fx, r.top + r.height * fy);

  /// Floor line (feet of squirrels standing in the room).
  double get floorY => r.bottom - (room.size == RoomSize.pocket ? 10 : 16);
}

/// A room's art: a cached static layer plus a live (animated) layer.
abstract class RoomArt {
  const RoomArt();

  /// Background furniture; recorded once per room level.
  void paintStatic(Canvas c, RoomCtx x);

  /// Animated residents and props, drawn every frame.
  void paintLive(Canvas c, RoomCtx x);
}

/// Shared room-drawing vocabulary.
abstract final class RoomKit {
  /// Carved hollow shell: rough dirt/wood at Lv.1, warm paneling at Lv.2,
  /// gold-trimmed at Lv.3. [wall] tints the back wall.
  static void shell(Canvas c, RoomCtx x, {Color wall = Pal.hollowWarm, bool earthy = false}) {
    final r = x.r;
    final radius = x.room.size == RoomSize.pocket ? 14.0 : 18.0;
    final rr = Kit.rr(r, radius);
    final back = switch (x.level) {
      3 => Color.lerp(wall, const Color(0xFF5B3A12), 0.35)!,
      2 => Color.lerp(wall, const Color(0xFF4A2A12), 0.25)!,
      _ => earthy ? const Color(0xFF2A170B) : wall,
    };
    c.drawRRect(rr, Kit.vertical(r, [Color.lerp(back, const Color(0xFFFFFFFF), 0.04)!, back]));
    c.save();
    c.clipRRect(rr);
    if (x.level == 1) {
      final rng = math.Random(r.left.toInt() * 31 + r.top.toInt());
      for (var k = 0; k < (r.width * r.height / 900).round(); k++) {
        c.drawCircle(Offset(r.left + rng.nextDouble() * r.width, r.top + rng.nextDouble() * r.height),
            0.8 + rng.nextDouble() * 1.8, Kit.fill(const Color(0x22000000)));
      }
    } else {
      // Vertical wood paneling
      for (var px = r.left + 18; px < r.right; px += 22) {
        c.drawLine(Offset(px, r.top), Offset(px, x.floorY), Kit.stroke(const Color(0x1A000000), 1.2));
      }
      c.drawRect(Rect.fromLTRB(r.left, r.top + r.height * 0.55, r.right, r.top + r.height * 0.55 + 3),
          Kit.fill(const Color(0x22FDE68A)));
    }
    // Plank floor
    final floor = Rect.fromLTRB(r.left, x.floorY, r.right, r.bottom);
    c.drawRect(floor, Kit.vertical(floor, const [Pal.plank, Pal.plankDark]));
    for (var px = r.left + 20; px < r.right; px += 26) {
      c.drawLine(Offset(px, floor.top), Offset(px, floor.bottom), Kit.stroke(const Color(0x40000000), 1));
    }
    c.drawLine(floor.topLeft, floor.topRight, Kit.stroke(const Color(0x55FDE68A), 1));
    // Soft inner shadow so the cutaway reads as carved into the trunk
    c.drawRRect(rr, Kit.stroke(const Color(0x66000000), 6));
    c.restore();
    final border = switch (x.level) {
      3 => Kit.stroke(const Color(0xFFFBBF24), 2.6),
      2 => Kit.stroke(const Color(0xFFB45309), 2),
      _ => Kit.stroke(Pal.barkDark, 2),
    };
    c.drawRRect(rr, border);
    if (x.level == 3) {
      for (final corner in [r.topLeft.translate(8, 8), r.topRight.translate(-8, 8)]) {
        c.drawCircle(corner, 2.6, Kit.fill(const Color(0xFFFDE047)));
      }
    }
  }

  /// Hanging lantern with flicker glow.
  static void lamp(Canvas c, Offset at, double t, {Color color = const Color(0xFFFDE68A), double size = 1}) {
    final flick = 0.75 + 0.25 * math.sin(t * 7 + at.dx);
    Kit.glow(c, at.translate(0, 4 * size), 26 * size, color, 0.28 * flick);
    c.drawLine(at.translate(0, -10 * size), at, Kit.stroke(const Color(0xFF451A03), 1));
    c.drawRRect(Kit.rr(Rect.fromCenter(center: at.translate(0, 4 * size), width: 7 * size, height: 9 * size), 2),
        Kit.fill(Color.lerp(color, const Color(0xFFFFFFFF), 0.3)!));
    c.drawRRect(Kit.rr(Rect.fromCenter(center: at.translate(0, 4 * size), width: 7 * size, height: 9 * size), 2),
        Kit.stroke(const Color(0xFF78350F), 1));
  }

  /// Wooden wall shelf.
  static void shelf(Canvas c, double left, double right, double y) {
    c.drawRRect(Kit.rr(Rect.fromLTRB(left, y, right, y + 4), 1.5), Kit.fill(const Color(0xFF8B5A2B)));
    c.drawLine(Offset(left, y + 4), Offset(right, y + 4), Kit.stroke(const Color(0x55000000), 1.2));
    for (final bx in [left + 6, right - 6]) {
      c.drawPath(Path()..moveTo(bx - 3, y + 4)..lineTo(bx + 3, y + 4)..lineTo(bx, y + 9)..close(),
          Kit.fill(const Color(0xFF6B3D1E)));
    }
  }

  /// Small wooden crate.
  static void crate(Canvas c, Rect b, {Color color = const Color(0xFFA16207)}) {
    c.drawRRect(Kit.rr(b, 1.5), Kit.fill(color));
    c.drawRRect(Kit.rr(b, 1.5), Kit.stroke(const Color(0xFF451A03), 1));
    c.drawLine(b.topLeft, b.bottomRight, Kit.stroke(const Color(0x66451A03), 1));
    c.drawLine(b.centerLeft, b.centerRight, Kit.stroke(const Color(0x66451A03), 1));
  }

  /// Cozy oval rug.
  static void rug(Canvas c, Offset center, double rx, Color color) {
    c.drawOval(Kit.oval(center, rx, rx * 0.22), Kit.fill(color));
    c.drawOval(Kit.oval(center, rx * 0.72, rx * 0.15), Kit.stroke(const Color(0x55FFFFFF), 1));
  }

  /// Rising wisp (steam, sparkle trail).
  static void wisp(Canvas c, Offset from, double t, {double height = 12, Color color = const Color(0xFFFFFFFF)}) {
    final s = t % 1.0;
    c.drawPath(
        Path()
          ..moveTo(from.dx, from.dy - s * height * 0.3)
          ..quadraticBezierTo(from.dx + 3, from.dy - height * 0.6 - s * 4, from.dx, from.dy - height - s * 4),
        Kit.stroke(Kit.a(color, 0.7 * math.sin(s * math.pi)), 1.2));
  }

  /// The room's name carved into the front edge of its floor plank (left
  /// side, clear of rugs and props) — the Metro gets a station name plate.
  /// Subtle on purpose: it reads when zoomed in, recedes when zoomed out.
  static void carvedName(Canvas c, RoomCtx x) {
    final r = x.r;
    // Outdoor spots paint their own little signs.
    if (x.room == RoomKey.birdFeeder || x.room == RoomKey.burrow) return;
    if (x.room == RoomKey.metro) {
      final text = _text(x.room.title.toUpperCase(), 7.5, const Color(0xEEF5F5F4), spacing: 1.4);
      final plate = Rect.fromCenter(
          center: Offset(r.center.dx, r.bottom - 34 - 39), width: text.width + 18, height: 11);
      c.drawRRect(rr(plate, 2), fill(const Color(0xFF44403C)));
      c.drawRRect(rr(plate, 2), stroke(const Color(0xFF78716C), 0.8));
      text.paint(c, Offset(plate.center.dx - text.width / 2, plate.center.dy - text.height / 2));
      return;
    }
    final pocket = x.room.size == RoomSize.pocket;
    final size = pocket ? 5.6 : 8.2;
    final band = pocket ? 10.0 : 16.0;
    final ink = _text(x.room.title, size, const Color(0xB83B1E0B));
    final glint = _text(x.room.title, size, const Color(0x40FDE68A));
    final at = Offset(r.left + (pocket ? 7 : 10), r.bottom - band * 0.45 - ink.height / 2);
    glint.paint(c, at.translate(0, 0.7));
    ink.paint(c, at);
  }

  /// Shared text painter (cached by callers that draw every frame).
  static TextPainter text(String text, double size, Color color, {double spacing = 0.6}) =>
      _text(text, size, color, spacing: spacing);

  static TextPainter _text(String text, double size, Color color, {double spacing = 0.6}) => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Fredoka', fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: spacing),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  static Paint fill(Color color) => Kit.fill(color);
  static Paint stroke(Color color, double width) => Kit.stroke(color, width);
  static RRect rr(Rect rect, double radius) => Kit.rr(rect, radius);

  /// Draws a custom PNG room interior if one was dropped in.
  static bool customArt(Canvas c, RoomCtx x) {
    final image = x.art.room(x.room);
    if (image == null) return false;
    c.save();
    c.clipRRect(Kit.rr(x.r, 16));
    c.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), x.r,
        Paint()..filterQuality = FilterQuality.medium);
    c.restore();
    return true;
  }
}

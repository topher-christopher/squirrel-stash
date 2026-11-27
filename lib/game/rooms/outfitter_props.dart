import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show HSVColor;

import '../art/asset_manifest.dart';
import '../art/paint_kit.dart';
import 'room_kit.dart';

/// Props for the Acorn Outfitter skatepark & DJ lounge, drawn in room-local
/// units (298 × 150, floor at y = 134).
abstract final class OutfitterProps {
  // Half-pipe geometry: two quarter-circle walls joined by a flat bottom.
  static const pipeCenter = 218.0;
  static const flatHalf = 36.0;
  static const radius = 34.0;
  static double get _arc => radius * math.pi / 2;
  static double get _total => _arc * 2 + flatHalf * 2;

  /// Point on the ramp surface and the tilt for a rider at [s] in [-1, 1].
  static (Offset, double) rampAt(double s, double floor) {
    final d = (s.clamp(-1.0, 1.0) + 1) / 2 * _total;
    if (d < _arc) {
      final th = (_arc - d) / radius;
      return (Offset(pipeCenter - flatHalf - radius * math.sin(th), floor - radius * (1 - math.cos(th))), th);
    }
    if (d > _arc + flatHalf * 2) {
      final th = (d - _arc - flatHalf * 2) / radius;
      return (Offset(pipeCenter + flatHalf + radius * math.sin(th), floor - radius * (1 - math.cos(th))), -th);
    }
    return (Offset(pipeCenter - flatHalf + (d - _arc), floor), 0.0);
  }

  static void halfPipe(Canvas c, double floor, int level) {
    final l = pipeCenter - flatHalf - radius, r = pipeCenter + flatHalf + radius;
    final top = floor - radius;
    final body = Path()
      ..moveTo(l - 8, top)
      ..lineTo(l, top)
      ..arcToPoint(Offset(pipeCenter - flatHalf, floor), radius: const Radius.circular(radius), clockwise: false)
      ..lineTo(pipeCenter + flatHalf, floor)
      ..arcToPoint(Offset(r, top), radius: const Radius.circular(radius), clockwise: false)
      ..lineTo(r + 6, top)
      ..lineTo(r + 6, floor + 2)
      ..lineTo(l - 8, floor + 2)
      ..close();
    final wood = level >= 2 ? const Color(0xFFC08A52) : const Color(0xFFD6B48A);
    c.drawPath(body, Kit.vertical(Rect.fromLTRB(l, top, r, floor), [wood, Color.lerp(wood, const Color(0xFF000000), 0.25)!]));
    for (var x = l; x < r; x += 12) {
      c.drawLine(Offset(x, top + 4), Offset(x, floor), Kit.stroke(const Color(0x22000000), 0.8));
    }
    if (level >= 3) {
      // Graffiti panels on the ramp sides
      const tags = [Color(0xFFF472B6), Color(0xFF38BDF8), Color(0xFFFDE047), Color(0xFF4ADE80)];
      for (var k = 0; k < 4; k++) {
        final p = Offset(l + 8 + k * 38.0, floor - 8 - (k % 2) * 6.0);
        c.drawOval(Kit.oval(p, 9, 4), Kit.fill(Kit.a(tags[k], 0.7)));
        c.drawLine(p.translate(-6, 0), p.translate(6, -2), Kit.stroke(const Color(0xCC1E1B4B), 1.2));
      }
    }
    if (level >= 2) {
      // Steel coping and deck platforms
      for (final x in [l, r]) {
        c.drawLine(Offset(x - 1, top), Offset(x + 1, top), Kit.stroke(const Color(0xFFE2E8F0), 2.6));
      }
      c.drawRect(Rect.fromLTRB(l - 8, top - 2, l, top + 1), Kit.fill(const Color(0xFF6B3D1E)));
      c.drawRect(Rect.fromLTRB(r, top - 2, r + 6, top + 1), Kit.fill(const Color(0xFF6B3D1E)));
    }
  }

  /// Original holo trading card in a gilt frame (custom PNG drop-in:
  /// assets/images/outfitter/custom_pokemon_card.png).
  static void pokemonCard(Canvas c, Rect card, StashAssetManifest art) {
    c.drawRRect(Kit.rr(card.inflate(3.5), 2), Kit.fill(const Color(0xFF78350F)));
    c.drawRRect(Kit.rr(card.inflate(2), 2), Kit.stroke(const Color(0xFFFBBF24), 1.2));
    final custom = art.outfitter('custom_pokemon_card');
    if (custom != null) {
      c.drawImageRect(custom, Rect.fromLTWH(0, 0, custom.width.toDouble(), custom.height.toDouble()), card,
          Paint()..filterQuality = FilterQuality.medium);
      return;
    }
    c.drawRRect(Kit.rr(card, 2.5), Kit.fill(const Color(0xFFFACC15)));
    final face = card.deflate(2.4);
    c.drawRRect(Kit.rr(face, 1.5), Kit.vertical(face, const [Color(0xFFFEF3C7), Color(0xFFFDE68A)]));
    // Name bar & HP
    final name = RoomKit.text('Acornix', 3.6, const Color(0xFF1C1917), spacing: 0.1);
    name.paint(c, Offset(face.left + 1.5, face.top + 0.6));
    final hp = RoomKit.text('HP120', 3.2, const Color(0xFFB91C1C), spacing: 0.1);
    hp.paint(c, Offset(face.right - hp.width - 1.2, face.top + 0.8));
    // Art window: storm sky, a squirrel silhouette and a lightning bolt
    final win = Rect.fromLTWH(face.left + 1.5, face.top + 6, face.width - 3, face.height * 0.42);
    c.drawRect(win, Kit.vertical(win, const [Color(0xFF7C3AED), Color(0xFFF97316)]));
    c.drawCircle(win.center.translate(-2, 2), 5, Kit.fill(const Color(0xFF7C2D12)));
    c.drawCircle(win.center.translate(1, -3), 3.4, Kit.fill(const Color(0xFF7C2D12)));
    c.drawPath(Path()..moveTo(win.center.dx - 6, win.center.dy + 6)..quadraticBezierTo(win.center.dx - 14, win.center.dy - 2,
        win.center.dx - 8, win.center.dy - 6), Kit.stroke(const Color(0xFF7C2D12), 3));
    c.drawPath(Path()
      ..moveTo(win.right - 7, win.top + 2)
      ..lineTo(win.right - 10, win.center.dy)
      ..lineTo(win.right - 7, win.center.dy)
      ..lineTo(win.right - 10, win.bottom - 2), Kit.stroke(const Color(0xFFFEF08A), 1.2));
    c.drawRect(win, Kit.stroke(const Color(0xFFB45309), 0.8));
    // Energy symbol and two attack lines
    final y0 = win.bottom + 4;
    for (var i = 0; i < 2; i++) {
      final y = y0 + i * 6.0;
      c.drawCircle(Offset(face.left + 3.5, y), 1.6, Kit.fill(const Color(0xFFF59E0B)));
      c.drawLine(Offset(face.left + 6.5, y), Offset(face.right - 6, y), Kit.stroke(const Color(0x88451A03), 0.9));
      final dmg = RoomKit.text(i == 0 ? '30' : '90', 3, const Color(0xFF1C1917), spacing: 0);
      dmg.paint(c, Offset(face.right - dmg.width - 1, y - dmg.height / 2));
    }
  }

  /// 35mm film canisters stacked into a grain-barrel pyramid (custom PNG:
  /// custom_film_canister.png).
  static void filmCanisters(Canvas c, Offset base, StashAssetManifest art) {
    final custom = art.outfitter('custom_film_canister');
    for (final (dx, dy) in const [(0.0, 0.0), (15.0, 0.0), (7.5, -21.0)]) {
      final b = Rect.fromLTWH(base.dx + dx, base.dy + dy - 21, 14, 21);
      if (custom != null) {
        c.drawImageRect(custom, Rect.fromLTWH(0, 0, custom.width.toDouble(), custom.height.toDouble()), b,
            Paint()..filterQuality = FilterQuality.medium);
        continue;
      }
      c.drawRRect(Kit.rr(b, 2), Kit.linear(b.centerLeft, b.centerRight,
          const [Color(0xFF0C0A09), Color(0xFF44403C), Color(0xFF0C0A09)]));
      // Grey snap-on cap with ridges
      final cap = Rect.fromLTWH(b.left - 0.8, b.top - 2.6, b.width + 1.6, 4);
      c.drawRRect(Kit.rr(cap, 1.2), Kit.vertical(cap, const [Color(0xFFE2E8F0), Color(0xFF94A3B8)]));
      for (var k = 1; k < 6; k++) {
        c.drawLine(Offset(cap.left + k * 2.6, cap.top + 0.6), Offset(cap.left + k * 2.6, cap.bottom - 0.4),
            Kit.stroke(const Color(0x5564748B), 0.5));
      }
      // Yellow & red label band with an ISO number
      c.drawRect(Rect.fromLTWH(b.left, b.top + 7, b.width, 7), Kit.fill(const Color(0xFFFACC15)));
      c.drawRect(Rect.fromLTWH(b.left, b.top + 12, b.width, 2), Kit.fill(const Color(0xFFDC2626)));
      final iso = RoomKit.text('400', 3.4, const Color(0xFF1C1917), spacing: 0);
      iso.paint(c, Offset(b.center.dx - iso.width / 2, b.top + 7.4));
      c.drawLine(Offset(b.left + 2.5, b.top + 2), Offset(b.left + 2.5, b.bottom - 2), Kit.stroke(const Color(0x33FFFFFF), 1));
    }
  }

  static void boosterBench(Canvas c, Rect box) {
    c.drawRRect(Kit.rr(box, 2), Kit.linear(box.centerLeft, box.centerRight,
        const [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)]));
    c.drawRRect(Kit.rr(box, 2), Kit.stroke(const Color(0xFF1E1B4B), 1));
    c.drawCircle(box.center, 3.2, Kit.fill(const Color(0xFFFFFFFF)));
    c.drawLine(box.center.translate(-3.2, 0), box.center.translate(3.2, 0), Kit.stroke(const Color(0xFFDC2626), 1));
  }

  /// Mirror disco ball. When [lit], slowly panning, color-shifting light
  /// spots sweep the room (brighter at a Festival).
  static void discoBall(Canvas c, Offset at, double size, double t, {required bool lit, required bool festival}) {
    c.drawLine(Offset(at.dx, at.dy - 20), at.translate(0, -size), Kit.stroke(const Color(0xFF94A3B8), 0.8));
    if (lit) {
      final peak = festival ? 1.6 : 1.0;
      for (var i = 0; i < 7; i++) {
        final hue = (t * 18 + i * 51) % 360;
        final color = HSVColor.fromAHSV(1, hue, 0.65, 1).toColor();
        final sweep = (t * 0.07 + i / 7) % 1.0;
        final p = Offset(12 + sweep * 274, 22 + (math.sin(t * 0.35 + i * 1.7) * 0.5 + 0.5) * 108);
        c.drawPath(Path()
          ..moveTo(at.dx, at.dy)
          ..lineTo(p.dx - 6, p.dy)
          ..lineTo(p.dx + 6, p.dy)
          ..close(), Kit.fill(Kit.a(color, 0.05 * peak)));
        Kit.glow(c, p, 13, color, 0.3 * peak);
      }
    }
    c.drawCircle(at, size, Kit.fill(const Color(0xFF94A3B8)));
    final spin = t * (lit ? 1.4 : 0.2);
    for (var row = -2; row <= 2; row++) {
      for (var col = 0; col < 6; col++) {
        final a = spin + col * math.pi / 3;
        final x = math.cos(a);
        if (x < 0) continue;
        final p = at + Offset(math.sin(a) * size * 0.8 * math.cos(row * 0.45), row * size * 0.36);
        final bright = lit ? (0.4 + 0.6 * ((col + row + (t * 3).floor()) % 3 == 0 ? 1 : 0.3)) : 0.25;
        c.drawRect(Rect.fromCenter(center: p, width: size * 0.32, height: size * 0.28),
            Kit.fill(Color.fromRGBO(240, 249, 255, bright)));
      }
    }
    c.drawCircle(at, size, Kit.stroke(const Color(0xFF475569), 0.7));
  }
}

import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../layout.dart';
import 'diorama_layer.dart';

/// The Great Oak's bark silhouette, carved hollow, floor beams, the central
/// lift shaft (ending at the root concourse), the grassy ground line, the
/// concourse tunnel, and the Canopy Terrace with its stone Display
/// Pedestals (static, cached).
class TrunkLayer extends DioramaLayer {
  TrunkLayer() : super(priority: 10);

  final PictureCache _cache = PictureCache();

  @override
  void render(Canvas canvas) {
    final key = '${snap.frost}|${snap.winter}|${snap.pedestals.join(',')}';
    _cache.draw(canvas, key, _paint);
  }

  void _paint(Canvas c) {
    final trunk = TreeLayout.trunkPath();
    const bounds = Rect.fromLTRB(14, TreeLayout.trunkTop, 586, TreeLayout.groundY + 6);
    c.drawPath(trunk, Kit.linear(bounds.centerLeft, bounds.centerRight,
        const [Pal.barkDark, Pal.bark, Pal.barkLight, Pal.bark, Pal.barkDark], const [0, 0.12, 0.5, 0.88, 1]));
    final rng = math.Random(17);
    for (var k = 0; k < 14; k++) {
      final left = k.isEven;
      final x0 = left ? 30 + rng.nextDouble() * 14 : 556 + rng.nextDouble() * 14;
      final y0 = TreeLayout.trunkTop + rng.nextDouble() * 420;
      c.drawPath(Path()..moveTo(x0, y0)..quadraticBezierTo(x0 + (left ? -4 : 4), y0 + 50, x0 + (left ? -2 : 2), y0 + 100),
          Kit.stroke(const Color(0x44000000), 2));
    }
    // Carved hollow behind the rooms
    const hollow = Rect.fromLTRB(40, 246, 560, 744);
    c.drawRRect(Kit.rr(hollow, 26), Kit.vertical(hollow, const [Pal.hollow, Color(0xFF1E0F06)]));
    c.drawRRect(Kit.rr(hollow, 26), Kit.stroke(const Color(0x88000000), 5));
    Kit.woodGrain(c, hollow.deflate(10), const Color(0x14FDE68A), seed: 4, lines: 18);
    // Floor beams: left hero column and right compact column
    for (final (y, l, r) in const [
      (412.0, 42.0, 350.0), (576.0, 42.0, 350.0), (740.0, 42.0, 350.0),
      (406.0, 378.0, 558.0), (562.0, 378.0, 558.0), (674.0, 378.0, 558.0),
    ]) {
      final beam = Rect.fromLTRB(l, y - 4, r, y + 4);
      c.drawRect(beam, Kit.vertical(beam, const [Color(0xFF6B3D1E), Color(0xFF3B1E0B)]));
      for (var x = l + 18; x < r; x += 64) {
        c.drawCircle(Offset(x, y), 1.2, Kit.fill(const Color(0xFF78716C)));
      }
    }
    _shaft(c);
    _ground(c, rng);
    _concourse(c);
    _deck(c);
  }

  /// The central lift shaft, down through the trunk and the soil, ending
  /// on the concourse floor (it never enters the Metro).
  void _shaft(Canvas c) {
    const shaft = Rect.fromLTRB(TreeLayout.shaftLeft, 232, TreeLayout.shaftRight, TreeLayout.groundY);
    c.drawRect(shaft, Kit.fill(Pal.chuteShaft));
    c.drawRect(shaft, Kit.linear(shaft.centerLeft, shaft.centerRight,
        const [Color(0x55000000), Color(0x00000000), Color(0x55000000)]));
    for (final x in const [TreeLayout.shaftLeft + 2, TreeLayout.shaftRight - 2]) {
      c.drawLine(Offset(x, 232), Offset(x, TreeLayout.shaftBottom), Kit.stroke(Pal.rail, 2.4));
    }
  }

  void _ground(Canvas c, math.Random rng) {
    final snowy = snap.frost || snap.winter;
    final grass = snowy ? Pal.frostGround : Pal.grass;
    final grassDark = snowy ? const Color(0xFFCBD5E1) : Pal.grassDark;
    final terrace = Path()
      ..moveTo(0, TreeLayout.groundY - 4)
      ..quadraticBezierTo(300, TreeLayout.groundY - 14, 600, TreeLayout.groundY - 4)
      ..lineTo(600, TreeLayout.groundY + 12)
      ..lineTo(0, TreeLayout.groundY + 12)
      ..close();
    c.drawPath(terrace, Kit.fill(grass));
    c.drawLine(const Offset(0, TreeLayout.groundY + 12), const Offset(600, TreeLayout.groundY + 12),
        Kit.stroke(grassDark, 3));
    for (var k = 0; k < 40; k++) {
      final x = 6 + k * 15.0 + rng.nextDouble() * 6;
      final y = TreeLayout.groundY - 6 + math.sin(k * 1.3) * 2;
      c.drawLine(Offset(x, y + 4), Offset(x - 2, y - 2), Kit.stroke(grassDark, 1.2));
      c.drawLine(Offset(x, y + 4), Offset(x + 2, y - 3), Kit.stroke(grassDark, 1.2));
    }
    // The shaft punches through the grass as a stone-lined well
    c.drawRect(const Rect.fromLTRB(TreeLayout.shaftLeft - 4, TreeLayout.groundY - 2, TreeLayout.shaftRight + 4,
        TreeLayout.groundY + 14), Kit.fill(const Color(0xFF57534E)));
    c.drawRect(const Rect.fromLTRB(TreeLayout.shaftLeft, TreeLayout.groundY - 2, TreeLayout.shaftRight,
        TreeLayout.shaftBottom), Kit.fill(Pal.chuteShaft));
  }

  /// Root concourse: lift landing, burrow tunnel and stairs to the Metro.
  void _concourse(Canvas c) {
    const r = TreeLayout.concourse;
    c.drawRRect(Kit.rr(r, 10), Kit.vertical(r, const [Color(0xFF2A160A), Color(0xFF1A0D05)]));
    c.drawRRect(Kit.rr(r, 10), Kit.stroke(Pal.rootDark, 2));
    final floor = Rect.fromLTRB(r.left + 4, r.bottom - 5, r.right - 4, r.bottom - 1);
    c.drawRect(floor, Kit.fill(const Color(0xFF5C3419)));
    // Lift landing platform and buffer
    c.drawRect(Rect.fromLTRB(TreeLayout.shaftLeft - 8, r.bottom - 6, TreeLayout.shaftRight + 8, r.bottom - 2),
        Kit.fill(const Color(0xFF8B5A2B)));
    c.drawLine(Offset(TreeLayout.shaftLeft - 8, r.bottom - 6), Offset(TreeLayout.shaftRight + 8, r.bottom - 6),
        Kit.stroke(Pal.brass, 1));
    // Burrow tunnel rising to the hole on the grass
    final hole = TreeLayout.burrowHole;
    c.drawRect(Rect.fromLTRB(hole.dx - 8, TreeLayout.groundY + 2, hole.dx + 8, r.top + 4), Kit.fill(const Color(0xFF1A0D05)));
    // Stairs down to the Metro platform
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(r.left + 30 + i * 6.0, r.bottom - 6 + i * 3.0, 14, 3), Kit.fill(const Color(0xFF78716C)));
    }
    // Hanging root lamps
    for (final x in const [150.0, 260.0, 470.0]) {
      Kit.glow(c, Offset(x, r.top + 9), 12, const Color(0xFFFDE68A), 0.35);
      c.drawCircle(Offset(x, r.top + 9), 2, Kit.fill(const Color(0xFFFEF3C7)));
    }
  }

  /// The Canopy Terrace deck and its stone Display Pedestals.
  void _deck(Canvas c) {
    const y = TreeLayout.deckY;
    final deck = Rect.fromLTRB(70, y, 530, y + 7);
    c.drawRRect(Kit.rr(deck, 2), Kit.vertical(deck, const [Color(0xFF9A5B2C), Color(0xFF5C3419)]));
    for (var x = deck.left + 14; x < deck.right; x += 18) {
      c.drawLine(Offset(x, y), Offset(x, y + 7), Kit.stroke(const Color(0x44000000), 1));
    }
    if (snap.frost || snap.winter) {
      c.drawRRect(Kit.rr(Rect.fromLTRB(deck.left, y - 2, deck.right, y + 1.5), 1.5), Kit.fill(const Color(0xF2FFFFFF)));
    }
    for (var i = 0; i < snap.pedestals.length && i < TreeLayout.pedestals.length; i++) {
      _pedestal(c, TreeLayout.pedestals[i], snap.pedestals[i]);
    }
  }

  static void _pedestal(Canvas c, Offset base, String kind) {
    final column = Rect.fromLTWH(base.dx - 8, base.dy - 20, 16, 20);
    c.drawRect(Rect.fromLTWH(base.dx - 11, base.dy - 4, 22, 5), Kit.fill(const Color(0xFF78716C)));
    c.drawRect(column, Kit.linear(column.centerLeft, column.centerRight,
        const [Color(0xFF78716C), Color(0xFFD6D3D1), Color(0xFF78716C)]));
    c.drawRect(Rect.fromLTWH(base.dx - 11, base.dy - 24, 22, 5), Kit.fill(const Color(0xFFA8A29E)));
    final top = base.translate(0, -24);
    switch (kind) {
      case 'statue':
        Kit.glow(c, top.translate(0, -10), 16, const Color(0xFFFDE047), 0.35);
        c.drawOval(Kit.oval(top.translate(0, -7), 4.2, 5.6), Kit.fill(const Color(0xFFFACC15)));
        c.drawCircle(top.translate(0.5, -14.5), 3.4, Kit.fill(const Color(0xFFFACC15)));
      case 'feat':
        c.drawPath(Path()..moveTo(top.dx - 6, top.dy - 15)..lineTo(top.dx + 6, top.dy - 15)..lineTo(top.dx + 6, top.dy - 7)
          ..quadraticBezierTo(top.dx, top.dy, top.dx - 6, top.dy - 7)..close(), Kit.fill(const Color(0xFF94A3B8)));
        c.drawLine(Offset(top.dx, top.dy - 14), Offset(top.dx, top.dy - 4), Kit.stroke(const Color(0xFFDC2626), 1.4));
      case 'trinket':
        Kit.glow(c, top.translate(0, -8), 14, const Color(0xFF38BDF8), 0.35);
        c.drawCircle(top.translate(0, -6.5), 5.6, Kit.fill(const Color(0xFFC2410C)));
        c.drawCircle(top.translate(0, -6.5), 3.9, Kit.stroke(const Color(0xFFFB923C), 0.8));
      default:
        c.drawCircle(top.translate(0, -5), 3.6, Kit.stroke(const Color(0x66FDE68A), 1));
    }
  }

  @override
  void onRemove() {
    _cache.dispose();
    super.onRemove();
  }
}

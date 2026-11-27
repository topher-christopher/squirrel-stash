import 'dart:math' as math;
import 'dart:ui';

import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../layout.dart';
import 'diorama_layer.dart';

/// The Great Oak's bark silhouette, carved hollow, floor beams, the central
/// lift shaft, the grassy terrace and its Display Pedestals (static, cached).
class TrunkLayer extends DioramaLayer {
  TrunkLayer() : super(priority: 10);

  final PictureCache _cache = PictureCache();

  @override
  void render(Canvas canvas) {
    final key = '${snap.frost}|${snap.pedestals.join(',')}';
    _cache.draw(canvas, key, _paint);
  }

  void _paint(Canvas c) {
    final trunk = TreeLayout.trunkPath();
    const bounds = Rect.fromLTRB(14, TreeLayout.trunkTop, 586, TreeLayout.groundY + 6);
    c.drawPath(trunk, Kit.linear(bounds.centerLeft, bounds.centerRight,
        const [Pal.barkDark, Pal.bark, Pal.barkLight, Pal.bark, Pal.barkDark], const [0, 0.12, 0.5, 0.88, 1]));
    // Bark grooves along both edges
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
    // Floor beams between trunk floors
    for (final y in const [412.0, 576.0, 740.0]) {
      final beam = Rect.fromLTRB(42, y - 4, 558, y + 4);
      c.drawRect(beam, Kit.vertical(beam, const [Color(0xFF6B3D1E), Color(0xFF3B1E0B)]));
      for (var x = 60.0; x < 558; x += 64) {
        c.drawCircle(Offset(x, y), 1.2, Kit.fill(const Color(0xFF78716C)));
      }
    }
    // Central lift shaft (through the trunk and down into the Metro)
    const shaft = Rect.fromLTRB(TreeLayout.shaftLeft, 232, TreeLayout.shaftRight, TreeLayout.shaftBottom);
    c.drawRect(shaft, Kit.fill(Pal.chuteShaft));
    c.drawRect(shaft, Kit.linear(shaft.centerLeft, shaft.centerRight,
        const [Color(0x55000000), Color(0x00000000), Color(0x55000000)]));
    for (final x in const [TreeLayout.shaftLeft + 2, TreeLayout.shaftRight - 2]) {
      c.drawLine(Offset(x, 232), Offset(x, TreeLayout.shaftBottom), Kit.stroke(Pal.rail, 2.4));
    }
    // Ground terrace & grass tufts at the trunk's base
    final grass = snap.frost ? Pal.frostGround : Pal.grass;
    final grassDark = snap.frost ? const Color(0xFFCBD5E1) : Pal.grassDark;
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
    // Shaft keeps going down through the soil as a lined tunnel
    c.drawRect(const Rect.fromLTRB(TreeLayout.shaftLeft - 3, TreeLayout.groundY + 6, TreeLayout.shaftRight + 3, 796),
        Kit.fill(const Color(0xFF3B1E0B)));
    c.drawRect(const Rect.fromLTRB(TreeLayout.shaftLeft, TreeLayout.groundY + 6, TreeLayout.shaftRight, 796),
        Kit.fill(Pal.chuteShaft));
    for (var i = 0; i < TreeLayout.pedestals.length; i++) {
      _pedestal(c, TreeLayout.pedestals[i], i < snap.pedestals.length ? snap.pedestals[i] : '');
    }
  }

  static void _pedestal(Canvas c, Offset base, String kind) {
    final column = Rect.fromLTWH(base.dx - 9, base.dy - 22, 18, 22);
    c.drawRect(Rect.fromLTWH(base.dx - 12, base.dy - 4, 24, 5), Kit.fill(const Color(0xFF78716C)));
    c.drawRect(column, Kit.linear(column.centerLeft, column.centerRight,
        const [Color(0xFF78716C), Color(0xFFD6D3D1), Color(0xFF78716C)]));
    c.drawRect(Rect.fromLTWH(base.dx - 12, base.dy - 26, 24, 5), Kit.fill(const Color(0xFFA8A29E)));
    final top = base.translate(0, -26);
    switch (kind) {
      case 'statue':
        Kit.glow(c, top.translate(0, -10), 16, const Color(0xFFFDE047), 0.35);
        c.drawOval(Kit.oval(top.translate(0, -8), 4.5, 6), Kit.fill(const Color(0xFFFACC15)));
        c.drawCircle(top.translate(0.5, -16), 3.6, Kit.fill(const Color(0xFFFACC15)));
      case 'feat':
        c.drawPath(Path()..moveTo(top.dx - 6, top.dy - 16)..lineTo(top.dx + 6, top.dy - 16)..lineTo(top.dx + 6, top.dy - 8)
          ..quadraticBezierTo(top.dx, top.dy, top.dx - 6, top.dy - 8)..close(), Kit.fill(const Color(0xFF94A3B8)));
        c.drawLine(Offset(top.dx, top.dy - 15), Offset(top.dx, top.dy - 4), Kit.stroke(const Color(0xFFDC2626), 1.4));
      case 'trinket':
        Kit.glow(c, top.translate(0, -8), 14, const Color(0xFF38BDF8), 0.35);
        c.drawCircle(top.translate(0, -7), 6, Kit.fill(const Color(0xFFC2410C)));
        c.drawCircle(top.translate(0, -7), 4.2, Kit.stroke(const Color(0xFFFB923C), 0.8));
      default:
        c.drawCircle(top.translate(0, -6), 4, Kit.stroke(const Color(0x66FDE68A), 1));
    }
  }

  @override
  void onRemove() {
    _cache.dispose();
    super.onRemove();
  }
}

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

import '../art/paint_kit.dart';
import '../art/squirrel_outfits.dart';
import '../art/squirrel_painter.dart';
import '../diorama_snapshot.dart';
import 'room_kit.dart';

/// Hollow Log Bill Vault: a log-ring vault with a safety waterline and a
/// squirrel-scale red Etch A Sketch counting down every bill's due date.
class BillVaultArt extends RoomArt {
  BillVaultArt();

  final Map<String, TextPainter> _text = {};

  @override
  void paintStatic(Canvas c, RoomCtx x) {
    RoomKit.shell(c, x, wall: const Color(0xFF3D2410));
    final r = x.r;
    // Log rings on the back wall
    final ringCenter = Offset(r.right - 28, r.top + 30);
    for (var k = 1; k <= 5; k++) {
      c.drawCircle(ringCenter, k * 6.0, Kit.stroke(const Color(0x22FDE68A), 1.2));
    }
    // Strongbox under the board
    RoomKit.crate(c, Rect.fromLTWH(r.right - 46, x.floorY - 24, 34, 24), color: const Color(0xFF57534E));
    c.drawCircle(Offset(r.right - 29, x.floorY - 12), 4, Kit.stroke(const Color(0xFFFBBF24), 1.4));
  }

  @override
  void paintLive(Canvas c, RoomCtx x) {
    final r = x.r;
    _waterline(c, x);
    EtchASketch.paint(c, Rect.fromLTWH(r.left + 10, r.top + 14, 118, 82), x.snap.etch, x.t, _label);
    // Bookkeeper squirrel in a visor tallying receipts
    SquirrelPainter.paint(c, Offset(r.left + 40 + math.sin(x.t * 0.5) * 12, x.floorY - 14),
        dir: math.cos(x.t * 0.5) > 0 ? 1 : -1, scale: 0.85, time: x.t, seed: 2.9,
        look: SquirrelLook(hat: x.snap.outfits ? SquirrelHat.visor : SquirrelHat.none, scarf: x.frost, book: true),
        pose: SquirrelPose.researcher, art: x.art);
  }

  /// Water rises up the wall as free cash covers more of the unpaid bills.
  void _waterline(Canvas c, RoomCtx x) {
    final r = x.r;
    final top = r.top + 20, bottom = x.floorY;
    final cover = x.snap.billCoverage.clamp(0.0, 1.4) / 1.4;
    final y = bottom - (bottom - top) * cover;
    final band = Rect.fromLTRB(r.left + 3, y, r.right - 3, bottom);
    final safe = x.snap.billCoverage >= 1;
    final color = safe ? const Color(0x3338BDF8) : const Color(0x33F87171);
    c.drawRect(band, Kit.fill(color));
    final wave = Path()..moveTo(band.left, y);
    for (var px = band.left; px <= band.right; px += 6) {
      wave.lineTo(px, y + math.sin(px * 0.2 + x.t * 2) * 1.2);
    }
    c.drawPath(wave, Kit.stroke(safe ? const Color(0x9938BDF8) : const Color(0x99F87171), 1.2));
    // "Safe" mark at full coverage
    final mark = bottom - (bottom - top) / 1.4;
    c.drawLine(Offset(r.right - 10, mark), Offset(r.right - 3, mark), Kit.stroke(const Color(0xFFFDE68A), 1.4));
  }

  TextPainter _label(String text, Color color, double size) => _text.putIfAbsent('$text|${color.toARGB32()}|$size',
      () => TextPainter(
            text: TextSpan(
                text: text,
                style: TextStyle(fontFamily: 'Fredoka', fontSize: size, fontWeight: FontWeight.w600, color: color)),
            textDirection: TextDirection.ltr,
          )..layout());
}

/// The retro red Etch A Sketch with acorn-cap knobs. Shared by the room
/// art; the drawer draws its own Flutter version of the same board.
abstract final class EtchASketch {
  static const red = Color(0xFFDC2626);

  static void paint(Canvas c, Rect b, List<EtchLine> lines, double t,
      TextPainter Function(String, Color, double) label) {
    c.drawRRect(Kit.rr(b.translate(0, 2), 9), Kit.fill(const Color(0x66000000)));
    c.drawRRect(Kit.rr(b, 9), Kit.vertical(b, const [Color(0xFFEF4444), Color(0xFFB91C1C)]));
    c.drawRRect(Kit.rr(b, 9), Kit.stroke(const Color(0xFF7F1D1D), 1.2));
    final screen = Rect.fromLTRB(b.left + 9, b.top + 10, b.right - 9, b.bottom - 18);
    c.drawRRect(Kit.rr(screen, 4), Kit.fill(const Color(0xFFCBD5E1)));
    c.drawRRect(Kit.rr(screen, 4), Kit.stroke(const Color(0xFF94A3B8), 1));
    final title = label('DAYS UNTIL DUE', const Color(0xFFFEF3C7), 5.4);
    title.paint(c, Offset(b.center.dx - title.width / 2, b.top + 2.5));
    final shown = lines.take(5).toList();
    final rowH = screen.height / math.max(5, shown.length);
    for (var i = 0; i < shown.length; i++) {
      final line = shown[i];
      final urgent = !line.paid && line.days <= 5;
      final ink = line.paid
          ? const Color(0xFF64748B)
          : (urgent ? const Color(0xFFB91C1C) : const Color(0xFF334155));
      final y = screen.top + 2 + i * rowH;
      if (urgent && line.days <= 0) {
        final blink = (t * 2) % 1 < 0.6;
        if (blink) c.drawRect(Rect.fromLTWH(screen.left + 2, y, screen.width - 4, rowH - 1), Kit.fill(const Color(0x33DC2626)));
      }
      final name = label(line.label, ink, 6.4);
      name.paint(c, Offset(screen.left + 4, y + (rowH - name.height) / 2));
      final days = line.paid ? 'PAID' : (line.days <= 0 ? (line.days == 0 ? 'TODAY' : 'LATE') : '${line.days}d');
      final d = label(days, ink, 6.4);
      d.paint(c, Offset(screen.right - d.width - 4, y + (rowH - d.height) / 2));
    }
    if (shown.isEmpty) {
      // Doodled spiral when there's nothing due
      final p = Path()..moveTo(screen.center.dx, screen.center.dy);
      for (var a = 0.0; a < 14; a += 0.3) {
        p.lineTo(screen.center.dx + math.cos(a) * a * 1.4, screen.center.dy + math.sin(a) * a * 0.9);
      }
      c.drawPath(p, Kit.stroke(const Color(0xFF475569), 0.8));
    }
    // Acorn-cap knobs that twiddle
    for (final (dx, dir) in [(b.left + 13, 1.0), (b.right - 13, -1.0)]) {
      final knob = Offset(dx, b.bottom - 8);
      c.drawCircle(knob, 6, Kit.fill(const Color(0xFFF8FAFC)));
      c.save();
      c.translate(knob.dx, knob.dy);
      c.rotate(math.sin(t * 0.8) * 0.6 * dir);
      c.drawPath(Path()..moveTo(-6, 0)..quadraticBezierTo(0, -7, 6, 0)..quadraticBezierTo(0, -2, -6, 0)..close(),
          Kit.fill(const Color(0xFF78350F)));
      c.drawLine(const Offset(0, -4), const Offset(1.4, -7), Kit.stroke(const Color(0xFF78350F), 1.2));
      c.restore();
    }
  }
}

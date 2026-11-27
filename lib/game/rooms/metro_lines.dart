import 'dart:ui';

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

import '../art/paint_kit.dart';

/// WMATA line served by a train cycle.
enum MetroLine {
  red('RD', Color(0xFFBF0D3E)),
  orangeSilver('OR/SV', Color(0xFFED8B00));

  const MetroLine(this.code, this.color);
  final String code;
  final Color color;

  static const silver = Color(0xFF919D9D);
}

/// Real stops cycled on the platform sign: one per arriving train.
abstract final class MetroStops {
  static const red = [
    'Shady Grove', 'Rockville', 'Twinbrook', 'North Bethesda', 'Grosvenor-Strathmore', 'Medical Center',
    'Bethesda', 'Friendship Heights', 'Tenleytown-AU', 'Van Ness-UDC', 'Cleveland Park', 'Woodley Park',
    'Dupont Circle', 'Farragut North', 'Metro Center', 'Gallery Place',
  ];

  static const orangeSilver = [
    'Gallery Place', 'Metro Center', 'McPherson Square', 'Farragut West', 'Foggy Bottom-GWU', 'Rosslyn',
    'Court House', 'Clarendon', 'Virginia Square-GMU', 'Ballston-MU',
  ];

  /// Capitals fans pour off trains departing these stops.
  static const fanStops = {'Gallery Place', 'Metro Center'};

  /// The continuous journey: Red Line out to Gallery Place, Orange/Silver
  /// out to Ballston-MU and back, then the Red Line home — looping forever.
  static final List<(MetroLine, String)> route = [
    for (final s in red) (MetroLine.red, s),
    for (final s in orangeSilver.skip(1)) (MetroLine.orangeSilver, s),
    for (final s in orangeSilver.reversed.skip(1)) (MetroLine.orangeSilver, s),
    for (final s in red.reversed.skip(1).take(red.length - 2)) (MetroLine.red, s),
  ];

  static (MetroLine, String) at(int cycle) => route[cycle % route.length];

  static bool fanStop(int cycle) => fanStops.contains(at(cycle).$2);
}

/// The station's LED arrivals board.
abstract final class MetroSign {
  static final Map<String, TextPainter> _cache = {};

  static TextPainter _text(String s, double size, Color color) => _cache.putIfAbsent('$s|$size|${color.toARGB32()}',
      () => TextPainter(
            text: TextSpan(
                text: s,
                style: TextStyle(fontFamily: 'Fredoka', fontSize: size, fontWeight: FontWeight.w600, color: color,
                    letterSpacing: 0.6)),
            textDirection: TextDirection.ltr,
          )..layout());

  static void paint(Canvas c, Rect board, MetroLine line, String stop, {required bool arriving, required double t}) {
    c.drawLine(Offset(board.left + 12, board.top - 8), Offset(board.left + 12, board.top), Kit.stroke(const Color(0xFF57534E), 1));
    c.drawLine(Offset(board.right - 12, board.top - 8), Offset(board.right - 12, board.top), Kit.stroke(const Color(0xFF57534E), 1));
    c.drawRRect(Kit.rr(board, 2), Kit.fill(const Color(0xFF0C0A09)));
    c.drawRRect(Kit.rr(board, 2), Kit.stroke(const Color(0xFF44403C), 1));
    final pill = Rect.fromLTWH(board.left + 4, board.top + 3, line == MetroLine.red ? 14 : 22, board.height - 6);
    c.drawRRect(Kit.rr(pill, 3), Kit.fill(line.color));
    if (line == MetroLine.orangeSilver) {
      c.drawRRect(Kit.rr(Rect.fromLTWH(pill.center.dx, pill.top, pill.width / 2, pill.height), 3), Kit.fill(MetroLine.silver));
    }
    final code = _text(line.code, 4.6, const Color(0xFFFFFFFF));
    code.paint(c, Offset(pill.center.dx - code.width / 2, pill.center.dy - code.height / 2));
    const amber = Color(0xFFFBBF24);
    final blink = arriving && (t * 2) % 1 < 0.5;
    final name = _text(stop, 7, blink ? const Color(0xFFFEF3C7) : amber);
    name.paint(c, Offset(pill.right + 5, board.center.dy - name.height / 2));
    final status = _text(arriving ? 'ARR' : 'BRD', 5, amber);
    status.paint(c, Offset(board.right - status.width - 5, board.center.dy - status.height / 2));
  }
}

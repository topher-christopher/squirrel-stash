import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/finance_providers.dart';

/// Full-screen icy vignette while upcoming bills exceed free cash.
class FrostVignette extends ConsumerWidget {
  const FrostVignette({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frost = ref.watch(financeProvider.select((f) => f.frost));
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: frost ? 1 : 0,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        child: const RepaintBoundary(child: CustomPaint(painter: _FrostPainter(), size: Size.infinite)),
      ),
    );
  }
}

class _FrostPainter extends CustomPainter {
  const _FrostPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          rect.center,
          size.longestSide * 0.62,
          const [Color(0x00000000), Color(0x00000000), Color(0x387DD3FC)],
          const [0, 0.58, 1],
        ),
    );
    // Inset frost glow along each edge.
    const depth = 70.0;
    final edges = [
      (Rect.fromLTWH(0, 0, size.width, depth), Alignment.topCenter, Alignment.bottomCenter),
      (Rect.fromLTWH(0, size.height - depth, size.width, depth), Alignment.bottomCenter, Alignment.topCenter),
      (Rect.fromLTWH(0, 0, depth, size.height), Alignment.centerLeft, Alignment.centerRight),
      (Rect.fromLTWH(size.width - depth, 0, depth, size.height), Alignment.centerRight, Alignment.centerLeft),
    ];
    for (final (r, from, to) in edges) {
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: from,
            end: to,
            colors: const [Color(0xB8BAE6FD), Color(0x40E0F2FE), Color(0x00F0F9FF)],
            stops: const [0, 0.35, 1],
          ).createShader(r),
      );
    }
    // Dendrite crystals growing out of the corners.
    final rng = math.Random(11);
    final line = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final corners = [
      (Offset.zero, math.pi / 4),
      (Offset(size.width, 0), math.pi * 3 / 4),
      (Offset(0, size.height), -math.pi / 4),
      (Offset(size.width, size.height), -math.pi * 3 / 4),
    ];
    for (final (corner, base) in corners) {
      for (var k = 0; k < 7; k++) {
        final a = base + (rng.nextDouble() - 0.5) * 1.3;
        final len = 26 + rng.nextDouble() * 46;
        final start = corner + Offset(math.cos(a), math.sin(a)) * (rng.nextDouble() * 10);
        final tip = start + Offset(math.cos(a), math.sin(a)) * len;
        canvas.drawLine(start, tip, line);
        for (var b = 1; b <= 3; b++) {
          final at = Offset.lerp(start, tip, b / 4)!;
          final bl = len * (0.36 - b * 0.07);
          for (final side in const [-1.0, 1.0]) {
            final ba = a + side * math.pi / 3;
            canvas.drawLine(at, at + Offset(math.cos(ba), math.sin(ba)) * bl, line);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

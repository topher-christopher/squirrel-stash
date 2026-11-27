import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/layout.dart';
import '../../providers/ui_provider.dart';
import '../../theme/app_typography.dart';

/// Custom-art blueprint: outlines the swappable window canvas, the static
/// desk layer and the cellar layer so artists know where PNGs land.
class BlueprintOverlay extends ConsumerWidget {
  const BlueprintOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(uiProvider.select((u) => u.blueprint));
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: on ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Stack(children: [
          const Positioned.fill(child: CustomPaint(painter: _BlueprintPainter())),
          _label(const Rect.fromLTWH(74, 130, 292, 44), const Color(0xFF0369A1), const Color(0xFF7DD3FC),
              'SWAPPABLE WINDOW CANVAS (1200 × 960 px)',
              'Drop meadow.png / alpine.png / harbor.png in assets/images/windows/'),
          _label(const Rect.fromLTWH(14, 382, 236, 20), const Color(0xFF15803D), null, 'FOREGROUND DESK LAYER (Static Wood UI)', null),
          _label(const Rect.fromLTWH(14, 798, 236, 18), const Color(0xFFB45309), null, 'CUTAWAY ROOT CELLAR LAYER', null),
        ]),
      ),
    );
  }

  static Widget _label(Rect r, Color fill, Color? border, String title, String? subtitle) => Positioned.fromRect(
        rect: r,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(8),
            border: border == null ? null : Border.all(color: border, width: 1.5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: AppType.label(9.5, color: Colors.white, weight: FontWeight.w900)),
              if (subtitle != null)
                Text(subtitle, style: AppType.body(8.5, color: const Color(0xFFE0F2FE))),
            ]),
          ),
        ),
      );
}

class _BlueprintPainter extends CustomPainter {
  const _BlueprintPainter();

  void _dashed(Canvas canvas, Path path, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final ui.PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 8), paint);
        d += 13;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final arch = StudyLayout.archPath();
    canvas.drawPath(arch, Paint()..color = const Color(0x380EA5E9));
    _dashed(canvas, arch, const Color(0xFF38BDF8), 3);
    _dashed(canvas, Path()..addRect(const Rect.fromLTWH(6, 376, 428, 136)), const Color(0xFF4ADE80), 2.5);
    _dashed(canvas, Path()..addRect(const Rect.fromLTWH(6, 514, 428, 300)), const Color(0xFFFBBF24), 2.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

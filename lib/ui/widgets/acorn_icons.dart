import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/art_assets_provider.dart';

/// The everyday Acorn currency icon. Drop `assets/images/icons/acorn.png`
/// in to replace the painted version with hand-drawn art.
class AcornIcon extends ConsumerWidget {
  const AcornIcon({super.key, this.size = 16});

  static const assetPath = 'assets/images/icons/acorn.png';

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = ref.watch(artAssetsProvider).contains(assetPath);
    return SizedBox.square(
      dimension: size,
      child: custom
          ? Image.asset(assetPath, filterQuality: FilterQuality.medium)
          : CustomPaint(painter: AcornPainter(golden: false)),
    );
  }
}

/// The rare Golden Acorn icon (`assets/images/icons/golden_acorn.png`).
class GoldenAcornIcon extends ConsumerWidget {
  const GoldenAcornIcon({super.key, this.size = 16});

  static const assetPath = 'assets/images/icons/golden_acorn.png';

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = ref.watch(artAssetsProvider).contains(assetPath);
    return SizedBox.square(
      dimension: size,
      child: custom
          ? Image.asset(assetPath, filterQuality: FilterQuality.medium)
          : CustomPaint(painter: AcornPainter(golden: true)),
    );
  }
}

/// Painted acorn: cap with crosshatch, plump body, shine (and a halo +
/// sparkle for the golden one). Scales to any square size.
class AcornPainter extends CustomPainter {
  AcornPainter({required this.golden});

  final bool golden;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s * 0.56);
    if (golden) {
      canvas.drawCircle(
          c,
          s * 0.5,
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0xFFFDE047).withValues(alpha: 0.55),
              const Color(0xFFFDE047).withValues(alpha: 0),
            ]).createShader(Rect.fromCircle(center: c, radius: s * 0.5)));
    }
    final body = Rect.fromCenter(center: c.translate(0, s * 0.05), width: s * 0.62, height: s * 0.66);
    canvas.drawOval(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: golden
                ? const [Color(0xFFFEF08A), Color(0xFFEAB308), Color(0xFFB45309)]
                : const [Color(0xFFFBBF24), Color(0xFFD97706), Color(0xFF92400E)],
          ).createShader(body));
    canvas.drawOval(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.05
          ..color = golden ? const Color(0xFF92400E) : const Color(0xFF78350F));
    final cap = Path()
      ..moveTo(c.dx - s * 0.37, c.dy - s * 0.14)
      ..quadraticBezierTo(c.dx, c.dy - s * 0.58, c.dx + s * 0.37, c.dy - s * 0.14)
      ..quadraticBezierTo(c.dx, c.dy - s * 0.02, c.dx - s * 0.37, c.dy - s * 0.14)
      ..close();
    canvas.drawPath(cap, Paint()..color = golden ? const Color(0xFFA16207) : const Color(0xFF78350F));
    final hatch = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = s * 0.03;
    for (var k = -2; k <= 2; k++) {
      canvas.drawLine(Offset(c.dx + k * s * 0.09 - s * 0.05, c.dy - s * 0.36),
          Offset(c.dx + k * s * 0.09 + s * 0.05, c.dy - s * 0.12), hatch);
    }
    canvas.drawLine(
        Offset(c.dx, c.dy - s * 0.42),
        Offset(c.dx + s * 0.1, c.dy - s * 0.54),
        Paint()
          ..color = golden ? const Color(0xFFA16207) : const Color(0xFF78350F)
          ..strokeWidth = s * 0.08
          ..strokeCap = StrokeCap.round);
    canvas.drawOval(Rect.fromCenter(center: c.translate(-s * 0.12, s * 0.06), width: s * 0.12, height: s * 0.22),
        Paint()..color = const Color(0x66FFFFFF));
    if (golden) {
      final p = Offset(s * 0.82, s * 0.2);
      final r = s * 0.13;
      canvas.drawPath(
          Path()
            ..moveTo(p.dx, p.dy - r)
            ..quadraticBezierTo(p.dx + r * 0.15, p.dy - r * 0.15, p.dx + r, p.dy)
            ..quadraticBezierTo(p.dx + r * 0.15, p.dy + r * 0.15, p.dx, p.dy + r)
            ..quadraticBezierTo(p.dx - r * 0.15, p.dy + r * 0.15, p.dx - r, p.dy)
            ..quadraticBezierTo(p.dx - r * 0.15, p.dy - r * 0.15, p.dx, p.dy - r)
            ..close(),
          Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  @override
  bool shouldRepaint(AcornPainter old) => old.golden != golden;
}

/// "120 [acorn]" — an amount followed by the currency icon.
class AcornAmount extends StatelessWidget {
  const AcornAmount(this.amount, {super.key, this.golden = false, this.style, this.size = 14});

  final int amount;
  final bool golden;
  final TextStyle? style;
  final double size;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$amount', style: style),
        const SizedBox(width: 3),
        golden ? GoldenAcornIcon(size: size) : AcornIcon(size: size),
      ]);
}

import 'package:material_ui/material_ui.dart';

import '../../core/money.dart';
import '../../models/trophy.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';

/// "Chamber Sealed!" moment: reveals the Time-Capsule Future-Self Note with a
/// typewriter unroll, shows the new relic and the Great Oak level.
Future<void> showReclaimCelebration(
  BuildContext context, {
  required Trophy trophy,
  required int oakLevel,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0xB3000000),
    transitionDuration: const Duration(milliseconds: 520),
    pageBuilder: (context, _, _) => _Celebration(trophy: trophy, oakLevel: oakLevel),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween(begin: 0.82, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

class _Celebration extends StatelessWidget {
  const _Celebration({required this.trophy, required this.oakLevel});

  final Trophy trophy;
  final int oakLevel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3B230E), Color(0xFF1C0F07)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.amberBright.withValues(alpha: 0.7), width: 1.6),
                boxShadow: [BoxShadow(color: AppColors.amberBright.withValues(alpha: 0.25), blurRadius: 40)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.elasticOut,
                  builder: (context, v, child) => Transform.scale(scale: 0.4 + v * 0.6, child: child),
                  child: Container(
                    width: 92,
                    height: 92,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppColors.flame.withValues(alpha: 0.55),
                        AppColors.amber.withValues(alpha: 0.05),
                      ]),
                    ),
                    child: Text(trophy.icon, style: const TextStyle(fontSize: 46, fontFamilyFallback: AppType.emojiFallback)),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Chamber Sealed!', style: AppType.title(26, color: AppColors.amberBright)),
                const SizedBox(height: 4),
                Text('${trophy.name} • ${Money.whole(trophy.amountCents)}',
                    textAlign: TextAlign.center, style: AppType.body(14, weight: FontWeight.w800)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('📜 TIME-CAPSULE NOTE', style: AppType.label(10, color: const Color(0xFF92400E))),
                    const SizedBox(height: 8),
                    _Typewriter(text: '“${trophy.note}”'),
                  ]),
                ),
                const SizedBox(height: 14),
                Text('+25 Golden Leaves  •  Great Oak Lv.$oakLevel',
                    style: AppType.body(13, weight: FontWeight.w800, color: AppColors.leaf)),
                const SizedBox(height: 16),
                PillButton(
                  label: 'Place on Trophy Stand',
                  expand: true,
                  color: AppColors.amberBright,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Typewriter extends StatelessWidget {
  const _Typewriter({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final glyphs = text.characters; // grapheme-safe (emoji never split)
    final ms = (glyphs.length * 28).clamp(600, 3200);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: glyphs.length),
      duration: Duration(milliseconds: ms),
      builder: (context, n, _) => Stack(children: [
        // Reserve the final height so the card doesn't grow as letters appear.
        Opacity(opacity: 0, child: Text(text, style: _style)),
        Text(glyphs.take(n).toString(), style: _style),
      ]),
    );
  }

  static final TextStyle _style =
      AppType.body(15, color: const Color(0xFF451A03), height: 1.4, style: FontStyle.italic);
}

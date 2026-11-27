import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';

/// Opens a slide-up drawer (bottom sheet) with the study's spring timing.
Future<T?> showStashDrawer<T>(BuildContext context, WidgetBuilder builder) {
  Haptics.light();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: const Color(0xA6000000),
    constraints: const BoxConstraints(maxWidth: 560),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 440),
      reverseDuration: Duration(milliseconds: 260),
    ),
    builder: builder,
  );
}

/// Carved-oak drawer chrome: grab handle, emoji badge, title, close peg and
/// a scrollable body that clears the keyboard.
class DrawerShell extends StatelessWidget {
  const DrawerShell({
    super.key,
    required this.emoji,
    required this.title,
    required this.children,
    this.subtitle,
    this.accent = AppColors.amberBright,
  });

  final String emoji;
  final String title;
  final String? subtitle;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E190D), Color(0xFF1C0F07)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: AppColors.amber.withValues(alpha: 0.5), width: 2)),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 30, offset: Offset(0, -6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [accent.withValues(alpha: 0.35), accent.withValues(alpha: 0.08)]),
                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 21, fontFamilyFallback: AppType.emojiFallback)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppType.title(20, color: accent, height: 1.15)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!, style: AppType.body(12.5, color: AppColors.honey.withValues(alpha: 0.75), height: 1.3)),
                      ],
                    ],
                  ),
                ),
                PressScale(
                  onTap: () {
                    Haptics.tap();
                    Navigator.of(context).maybePop();
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: AppColors.stoneDeep, borderRadius: BorderRadius.circular(19)),
                    child: const Icon(Icons.close_rounded, size: 20, color: AppColors.honey),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 22 + media.viewInsets.bottom + media.padding.bottom),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ),
        ],
      ),
    );
  }
}

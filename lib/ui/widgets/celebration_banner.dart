import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/settings_provider.dart';
import '../../providers/ui_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'stash_controls.dart';

/// Celebration toast that drops in under the HUD pill.
class CelebrationBanner extends ConsumerWidget {
  const CelebrationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banner = ref.watch(uiProvider.select((u) => u.banner));
    final zen = ref.watch(settingsProvider.select((s) => s.zenMode));
    final visible = banner != null && !zen;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -0.5), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      child: !visible
          ? const SizedBox.shrink(key: ValueKey('none'))
          : Padding(
              key: ValueKey(banner.id),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: PressScale(
                    onTap: () => ref.read(uiProvider.notifier).dismissBanner(),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                      decoration: BoxDecoration(
                        color: const Color(0xF2451A03),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.amberBright.withValues(alpha: 0.55)),
                        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 20, offset: Offset(0, 8))],
                      ),
                      child: Row(children: [
                        Text(banner.icon, style: const TextStyle(fontSize: 20, fontFamilyFallback: AppType.emojiFallback)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(banner.text,
                              style: AppType.body(13, weight: FontWeight.w700, color: AppColors.cream, height: 1.3)),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.close_rounded, size: 16, color: AppColors.honey),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

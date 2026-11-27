import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/diorama_event.dart';
import '../../game/layout.dart';
import '../../models/window_scene.dart';
import '../../providers/finance_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stash_actions.dart';
import '../../providers/ui_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../drawers/drawers.dart';
import '../widgets/animated_money.dart';
import 'tap_zone.dart';

/// Window-level overlay: Free Cash tag on the acorn pile, Bills tag on the
/// campfire, Professor Hoot's tap target and the lab's "+$ Saved!" bubble.
class WindowPlaques extends ConsumerWidget {
  const WindowPlaques({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zen = ref.watch(settingsProvider.select((s) => s.zenMode));
    final scene = ref.watch(settingsProvider.select((s) => s.scene));
    final f = ref.watch(financeProvider);
    final reaction = ref.watch(uiProvider.select((u) => (u.labReaction, u.labReactionId)));

    return Stack(children: [
      Positioned.fromRect(
        rect: StudyLayout.cashHotspot,
        child: TapZone(
          target: DioramaTarget.cashPile,
          label: 'Free Cash pile. Opens the cash drawer',
          pressAlignment: Alignment.bottomCenter,
          onTap: () => Drawers.cash(context),
          child: Align(
            alignment: Alignment.topCenter,
            child: ZenFade(
              zen: zen,
              child: _Tag(
                border: AppColors.amberBright,
                child: AnimatedMoney(f.freeCashCents,
                    suffix: ' Free', style: AppType.title(10.5, weight: FontWeight.w700, color: AppColors.cream)),
              ),
            ),
          ),
        ),
      ),
      Positioned.fromRect(
        rect: StudyLayout.campfireHotspot,
        child: TapZone(
          target: DioramaTarget.campfire,
          label: 'Bills campfire. Opens the Frostline bills drawer',
          pressAlignment: Alignment.bottomCenter,
          onTap: () => Drawers.bills(context),
          child: Align(
            alignment: Alignment.topCenter,
            child: ZenFade(
              zen: zen,
              child: _Tag(
                border: f.frost ? AppColors.alertSoft : const Color(0xFFFB923C),
                color: f.frost ? const Color(0xEB991B1B) : const Color(0xE01C110A),
                child: AnimatedMoney(f.upcomingBillsCents,
                    prefix: 'Bills ', style: AppType.title(10, weight: FontWeight.w700, color: AppColors.parchment)),
              ),
            ),
          ),
        ),
      ),
      if (scene == WindowScene.meadow)
        Positioned.fromRect(
          rect: StudyLayout.hootHotspot,
          child: TapZone(
            target: DioramaTarget.hoot,
            label: 'Professor Hoot',
            onTap: () => ref.read(stashActionsProvider).greetHoot(),
          ),
        ),
      Positioned(
        left: 22,
        top: 296,
        width: 96,
        height: 26,
        child: IgnorePointer(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.6), end: Offset.zero)
                    .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
                child: child,
              ),
            ),
            child: reaction.$1 == null || zen
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(reaction.$2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
                    ),
                    child: Text(reaction.$1!, style: AppType.title(10.5, weight: FontWeight.w700, color: Colors.white)),
                  ),
          ),
        ),
      ),
    ]);
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.child, required this.border, this.color = const Color(0xE01C110A)});

  final Widget child;
  final Color border;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.2),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 1.5))],
        ),
        child: child,
      );
}

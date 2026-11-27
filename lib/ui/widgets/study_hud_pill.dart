import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/finance_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stash_actions.dart';
import '../../providers/ui_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../drawers/drawers.dart';
import 'animated_money.dart';
import 'stash_controls.dart';

/// Minimal floating Study HUD pill: Free Cash, Total Stash, +Payday, window
/// scenery switcher, art blueprint, settings and the Zen Mode eye.
class StudyHudPill extends ConsumerWidget {
  const StudyHudPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zen = ref.watch(settingsProvider.select((s) => s.zenMode));
    final scene = ref.watch(settingsProvider.select((s) => s.scene));
    final f = ref.watch(financeProvider);
    final blueprint = ref.watch(uiProvider.select((u) => u.blueprint));
    final actions = ref.read(stashActionsProvider);

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 430;
      final roomy = c.maxWidth >= 350;
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: zen ? 0.5 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: zen ? 5 : 8, vertical: 5),
          decoration: BoxDecoration(
            color: zen ? const Color(0x66140C07) : const Color(0xF226170E),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: zen ? const Color(0x1AFFFFFF) : AppColors.amber.withValues(alpha: 0.38)),
            boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 18, offset: Offset(0, 6))],
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (!zen) ...[
                  PressScale(
                    onTap: () => Drawers.cash(context),
                    child: _Segment(
                      label: 'FREE CASH',
                      labelColor: AppColors.emeraldSoft,
                      child: AnimatedMoney(f.freeCashCents,
                          style: AppType.number(15.5, weight: FontWeight.w700, color: AppColors.emeraldBright)),
                    ),
                  ),
                  if (wide) ...[
                    const _Divider(),
                    _Segment(
                      label: 'TOTAL STASH',
                      labelColor: AppColors.honey,
                      child: AnimatedMoney(f.netWorthCents, style: AppType.number(15, weight: FontWeight.w600)),
                    ),
                  ],
                  const _Divider(),
                  _HudButton(
                    onTap: actions.payday,
                    color: AppColors.emeraldButton,
                    child: Text('+Payday', style: AppType.title(13, weight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(width: 6),
                  _HudButton(
                    onTap: actions.cycleScene,
                    color: const Color(0xBF0C4A6E),
                    border: const Color(0x4D38BDF8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(roomy ? scene.chip : scene.emoji,
                          key: ValueKey(scene),
                          style: AppType.title(13, weight: FontWeight.w700, color: const Color(0xFFBAE6FD))),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _IconPeg(
                    icon: Icons.layers_outlined,
                    active: blueprint,
                    tooltip: 'Custom art blueprint',
                    onTap: () => ref.read(uiProvider.notifier).toggleBlueprint(),
                  ),
                  const SizedBox(width: 6),
                  _IconPeg(icon: Icons.tune_rounded, tooltip: 'Settings', onTap: () => Drawers.settings(context)),
                  const SizedBox(width: 6),
                ],
                _IconPeg(
                  icon: zen ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  tooltip: zen ? 'Show numbers & controls' : 'Zen desk mode',
                  onTap: actions.toggleZen,
                ),
              ]),
            ),
          ),
        ),
      );
    });
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.labelColor, required this.child});

  final String label;
  final Color labelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppType.label(9, color: labelColor.withValues(alpha: 0.85))),
          child,
        ]),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: AppColors.amber.withValues(alpha: 0.22),
      );
}

class _HudButton extends StatelessWidget {
  const _HudButton({required this.onTap, required this.color, required this.child, this.border});

  final VoidCallback onTap;
  final Color color;
  final Color? border;
  final Widget child;

  @override
  Widget build(BuildContext context) => PressScale(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: border == null ? null : Border.all(color: border!),
          ),
          child: child,
        ),
      );
}

class _IconPeg extends StatelessWidget {
  const _IconPeg({required this.icon, required this.onTap, required this.tooltip, this.active = false});

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: PressScale(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: active ? AppColors.sky : const Color(0xCC292524),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: active ? Colors.white : AppColors.honey),
          ),
        ),
      );
}

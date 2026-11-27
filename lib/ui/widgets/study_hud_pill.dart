import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../models/room.dart';
import '../../providers/finance_providers.dart';
import '../../providers/focus_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stash_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../drawers/drawers.dart';
import 'acorn_icons.dart';
import 'animated_money.dart';
import 'stash_controls.dart';

/// Clean, collapsible top HUD: Free Cash, Total Stash, Acorns, Golden
/// Acorns, then +Payday, the Focus quick-pill, the Starter/Max room
/// preview switch, Privacy Eye, Cozy Zen and settings.
class StudyHud extends ConsumerStatefulWidget {
  const StudyHud({super.key});

  @override
  ConsumerState<StudyHud> createState() => _StudyHudState();
}

class _StudyHudState extends ConsumerState<StudyHud> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final f = ref.watch(financeProvider);
    final acorns = ref.watch(settingsProvider.select((s) => s.acorns));
    final golden = ref.watch(settingsProvider.select((s) => s.goldenAcorns));
    final money = AppType.number(15, weight: FontWeight.w700, color: AppColors.emeraldBright);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _Pill(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          PressScale(
            onTap: () => Drawers.room(context, RoomKey.treasury),
            child: _Segment(label: 'FREE CASH', labelColor: AppColors.emeraldSoft, child: AnimatedMoney(f.freeCashCents, style: money)),
          ),
          const _Divider(),
          _Segment(
            label: 'TOTAL STASH',
            labelColor: AppColors.honey,
            child: AnimatedMoney(f.netWorthCents, style: AppType.number(15, weight: FontWeight.w600)),
          ),
          const _Divider(),
          PressScale(
            onTap: () => Drawers.upgrades(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AcornAmount(acorns, size: 17, style: AppType.number(15, color: AppColors.amberBright)),
                const SizedBox(width: 10),
                AcornAmount(golden, golden: true, size: 17, style: AppType.number(15, color: AppColors.flame)),
              ]),
            ),
          ),
          PressScale(
            onTap: () {
              Haptics.tap();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 2, right: 2),
              child: AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.honey),
              ),
            ),
          ),
        ]),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: _expanded ? const Padding(padding: EdgeInsets.only(top: 8), child: _Controls()) : const SizedBox(width: double.infinity),
      ),
    ]);
  }
}

class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(stashActionsProvider);
    final privacy = ref.watch(settingsProvider.select((s) => s.privacyMode));
    final allMax = ref.watch(roomsProvider.select((r) => r.allMax));
    final allStarter = ref.watch(roomsProvider.select((r) => r.allStarter));
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _HudButton(
          onTap: actions.payday,
          color: AppColors.emeraldButton,
          child: Text('+Payday', style: AppType.title(13, weight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(width: 6),
        const _FocusPill(),
        const SizedBox(width: 6),
        _LookSwitch(
          max: allMax,
          starter: allStarter,
          onPick: (max) => actions.setAllRoomThemes(max ? RoomLevels.max : 1),
        ),
        const SizedBox(width: 6),
        _IconPeg(
          icon: privacy ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          tooltip: privacy ? 'Show amounts' : 'Privacy Eye (hide amounts)',
          active: privacy,
          onTap: actions.togglePrivacy,
        ),
        const SizedBox(width: 6),
        _IconPeg(icon: Icons.spa_rounded, tooltip: 'Cozy Zen', onTap: actions.toggleZen),
        const SizedBox(width: 6),
        _IconPeg(icon: Icons.tune_rounded, tooltip: 'Settings', onTap: () => Drawers.settings(context)),
      ]),
    );
  }
}

/// Compact Focus Shift timer: live countdown while running, opens the
/// Focus drawer (there is no Focus room in the tree).
class _FocusPill extends ConsumerWidget {
  const _FocusPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.watch(focusProvider);
    final active = focus.running || focus.paused;
    return _HudButton(
      onTap: () => Drawers.focus(context),
      color: active ? const Color(0xCC92400E) : const Color(0xCC292524),
      border: active ? AppColors.amberBright.withValues(alpha: 0.6) : null,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(focus.running ? Icons.hourglass_top_rounded : Icons.timer_outlined, size: 15, color: AppColors.honey),
        const SizedBox(width: 5),
        Text(active ? focus.clock : 'Focus',
            style: AppType.number(13, weight: FontWeight.w700, color: AppColors.honey)),
      ]),
    );
  }
}

/// Starter | Max: re-themes every room in the tree at once (free). When the
/// rooms are a mix of themes neither side is lit.
class _LookSwitch extends StatelessWidget {
  const _LookSwitch({required this.max, required this.starter, required this.onPick});

  final bool max;
  final bool starter;
  final ValueChanged<bool> onPick;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on, bool pickMax) => PressScale(
          onTap: () => onPick(pickMax),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: on ? AppColors.amber.withValues(alpha: 0.85) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(label, style: AppType.title(11.5, weight: FontWeight.w700, color: on ? AppColors.night : AppColors.honey)),
          ),
        );
    return Tooltip(
      message: 'Re-theme every room: Starter or Max',
      child: Container(
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: const Color(0xCC292524), borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [seg('Starter', starter, false), seg('Max', max, true)]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xF226170E),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.38)),
          boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 18, offset: Offset(0, 6))],
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      );
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.labelColor, required this.child});

  final String label;
  final Color labelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
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
        margin: const EdgeInsets.symmetric(horizontal: 3),
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
            decoration: BoxDecoration(color: active ? AppColors.sky : const Color(0xCC292524), shape: BoxShape.circle),
            child: Icon(icon, size: 17, color: active ? Colors.white : AppColors.honey),
          ),
        ),
      );
}

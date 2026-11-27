import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../game/diorama_event.dart';
import '../../game/layout.dart';
import '../../models/goal.dart';
import '../../models/holding.dart';
import '../../providers/diorama_snapshot_provider.dart';
import '../../providers/finance_math.dart';
import '../../providers/finance_providers.dart';
import '../../providers/goals_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/ui_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../drawers/drawers.dart';
import '../widgets/animated_money.dart';
import 'tap_zone.dart';

/// Root cellar overlay: section labels, ‹ › paging pegs, Goal Chamber
/// plaques (or the "Dig New Goal Room" slot) and the reserve plaques.
class CellarPlaques extends ConsumerWidget {
  const CellarPlaques({super.key});

  static const _chamberTargets = [DioramaTarget.chamberLeft, DioramaTarget.chamberRight];
  static const _reserveTargets = [DioramaTarget.amber, DioramaTarget.curio, DioramaTarget.treasury];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zen = ref.watch(settingsProvider.select((s) => s.zenMode));
    final goalCount = ref.watch(goalsProvider.select((g) => g.length));
    final visible = ref.watch(visibleGoalsProvider);
    final page = ref.watch(uiProvider.select((u) => u.goalPage));
    final maxPage = FinanceMath.maxGoalPage(goalCount);
    final f = ref.watch(financeProvider);

    return Stack(children: [
      Positioned(
        left: 18,
        top: 519,
        width: maxPage > 0 ? 338 : 404,
        child: ZenFade(
          zen: zen,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('⛏️ GOAL CHAMBERS (RECLAIM AT 100% TO UPGRADE OAK)',
                style: AppType.label(9.5, color: AppColors.amberBright, letterSpacing: 0.8)),
          ),
        ),
      ),
      if (maxPage > 0 && !zen) ...[
        _Peg(left: 360, symbol: '‹', enabled: page > 0, onTap: () => ref.read(uiProvider.notifier).setGoalPage(page - 1)),
        _Peg(left: 393, symbol: '›', enabled: page < maxPage, onTap: () => ref.read(uiProvider.notifier).setGoalPage(page + 1)),
      ],
      for (var i = 0; i < 2; i++)
        if (i < visible.length)
          Positioned.fromRect(
            rect: StudyLayout.chambers[i],
            child: TapZone(
              target: _chamberTargets[i],
              label: '${visible[i].name} goal chamber, ${visible[i].percent} percent',
              onTap: () => Drawers.goal(context, visible[i].id),
              child: _ChamberPlaque(goal: visible[i], zen: zen),
            ),
          )
        else if (i == visible.length)
          Positioned.fromRect(
            rect: StudyLayout.chambers[i],
            child: TapZone(
              target: _chamberTargets[i],
              label: 'Dig a new goal chamber',
              onTap: () => Drawers.newGoal(context),
              child: ZenFade(
                zen: zen,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('⛏️', style: TextStyle(fontSize: 19, fontFamilyFallback: AppType.emojiFallback)),
                  const SizedBox(height: 4),
                  Text('+ Dig New Goal Room', style: AppType.title(12, weight: FontWeight.w700, color: AppColors.honey)),
                ]),
              ),
            ),
          ),
      Positioned(
        left: 18,
        top: 665,
        width: 404,
        child: ZenFade(
          zen: zen,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('🌳 DEEP OAK-ROOT RESERVES (NON-LIQUID & LONG-TERM)',
                style: AppType.label(9.5, color: AppColors.amberDeep, letterSpacing: 0.8)),
          ),
        ),
      ),
      for (var i = 0; i < 3; i++)
        Positioned.fromRect(
          rect: StudyLayout.reserves[i],
          child: TapZone(
            target: _reserveTargets[i],
            label: ReserveKind.values[i].title,
            onTap: () => Drawers.reserve(context, ReserveKind.values[i]),
            child: _ReservePlaque(kind: ReserveKind.values[i], finance: f, zen: zen),
          ),
        ),
    ]);
  }
}

class _Peg extends StatelessWidget {
  const _Peg({required this.left, required this.symbol, required this.enabled, required this.onTap});

  final double left;
  final String symbol;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Positioned(
        left: left,
        top: 513,
        width: 30,
        height: 24,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled
              ? () {
                  Haptics.tap();
                  onTap();
                }
              : null,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: enabled ? 1 : 0.35,
              child: Container(
                width: 26,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B2110),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.amberDeep),
                ),
                child: Text(symbol, style: AppType.title(13, weight: FontWeight.w700, color: AppColors.honey, height: 1)),
              ),
            ),
          ),
        ),
      );
}

class _ChamberPlaque extends StatelessWidget {
  const _ChamberPlaque({required this.goal, required this.zen});

  final Goal goal;
  final bool zen;

  @override
  Widget build(BuildContext context) => ZenFade(zen: zen, child: Stack(children: [
        Positioned(
          left: 12,
          top: 13,
          right: goal.priority ? 28 : 12,
          child: Text('${goal.icon} ${goal.name}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppType.title(12.5, weight: FontWeight.w700, color: AppColors.cream)),
        ),
        if (goal.priority)
          const Positioned(
            right: 10,
            top: 12,
            child: Text('⭐', style: TextStyle(fontSize: 12, fontFamilyFallback: AppType.emojiFallback)),
          ),
        Positioned(
          left: 12,
          top: 31,
          child: ZenFade(
            zen: zen,
            child: Text('Due ${Dates.short(goal.dueDate)} • ${goal.percent}%',
                style: AppType.body(9.5, weight: FontWeight.w700, color: AppColors.stone)),
          ),
        ),
        Positioned(
          left: 56,
          top: 58,
          right: 8,
          child: ZenFade(
            zen: zen,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedMoney(goal.savedCents, style: AppType.number(13, weight: FontWeight.w700, color: AppColors.honey)),
              Text('of ${Money.whole(goal.targetCents)}', style: AppType.body(9.5, weight: FontWeight.w600, color: AppColors.stoneDim)),
              if (goal.isComplete) const _ReclaimPulse(),
            ]),
          ),
        ),
      ]));
}

class _ReclaimPulse extends StatefulWidget {
  const _ReclaimPulse();

  @override
  State<_ReclaimPulse> createState() => _ReclaimPulseState();
}

class _ReclaimPulseState extends State<_ReclaimPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.55, end: 1.0).animate(_c),
        child: Text('✨ Reclaim!', style: AppType.body(9.5, weight: FontWeight.w900, color: AppColors.emeraldBright)),
      );
}

class _ReservePlaque extends StatelessWidget {
  const _ReservePlaque({required this.kind, required this.finance, required this.zen});

  final ReserveKind kind;
  final FinanceSummary finance;
  final bool zen;

  @override
  Widget build(BuildContext context) {
    final (color, extra, extraColor) = switch (kind) {
      ReserveKind.amber => (AppColors.amberBright, '✨ ~${Money.exact(finance.dailyYieldCents.round())}/day', AppColors.flame),
      ReserveKind.curio => (AppColors.slate, 'Slabs & Bullion', AppColors.slateDim),
      ReserveKind.treasury => (AppColors.cautionSoft, 'Locked Long-Term', AppColors.amberBright),
    };
    return ZenFade(
      zen: zen,
      child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 11, 8, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('${kind.emoji} ${kind.title}', style: AppType.title(10.5, weight: FontWeight.w700)),
        ),
        Text(kind.subtitle, style: AppType.body(8.5, weight: FontWeight.w600, color: AppColors.stone)),
        const SizedBox(height: 6),
        ZenFade(
          zen: zen,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedMoney(finance.reserveCents(kind), style: AppType.number(15, weight: FontWeight.w700, color: color)),
            ),
            Text(extra, style: AppType.body(8.5, weight: FontWeight.w800, color: extraColor)),
          ]),
        ),
      ]),
      ),
    );
  }
}

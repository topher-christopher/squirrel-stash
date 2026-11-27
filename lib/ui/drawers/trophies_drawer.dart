import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../models/feat.dart';
import '../../models/habit.dart';
import '../../models/room.dart';
import '../../providers/awards_provider.dart';
import '../../providers/finance_providers.dart';
import '../../providers/goals_provider.dart';
import '../../providers/impulse_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/acorn_icons.dart';
import '../widgets/stash_controls.dart';
import 'decor_shop.dart';
import 'drawer_shell.dart';
import 'stats_dashboard.dart';

/// Trophy Hall: the lifetime stats ledger, stacking trophies, milestone
/// ladders, mystery feats and the goal statues.
class TrophyHallBody extends ConsumerWidget {
  const TrophyHallBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awards = ref.watch(awardsProvider);
    final statues = ref.watch(trophiesProvider);
    int stacks(String key) => awards.where((a) => a.featKey == key).length;
    final logs = ref.watch(impulseLogsProvider);
    final habits = ref.watch(habitsProvider);
    final hopIds = {for (final h in habits) if (h.key == HabitKeys.shortHop) h.id};
    final progress = <String, int>{
      Feats.ladderSaved: ref.watch(impulseStatsProvider.select((s) => s.allTimeCents)),
      Feats.ladderWins: logs.length,
      Feats.ladderMeals: ref.watch(groceryStatsProvider.select((g) => g.homeMealsTotal)),
      Feats.ladderHops: logs.where((l) => hopIds.contains(l.habitId)).length,
      Feats.ladderFocus: ref.watch(settingsProvider.select((s) => s.focusShiftsCompleted)),
      Feats.ladderGoals: statues.length,
    };
    final seasons = awards.where((a) => a.featKey == Feats.fourSeasonsStage).map((a) => a.periodKey.split('-').last).toSet();
    return RoomPage(children: [
      const SectionLabel('📊 Lifetime Stats Ledger'),
      const StatsDashboard(),
      const SectionLabel('🛡️ Stacking Trophies'),
      for (final def in Feats.all.where((f) => f.kind == FeatKind.repeatable || f.kind == FeatKind.seasonal))
        _FeatTile(
          def: def,
          earned: stacks(def.key) > 0,
          badge: stacks(def.key) > 1 ? 'x${stacks(def.key)}' : null,
          extra: def.kind == FeatKind.seasonal
              ? Wrap(spacing: 6, children: [
                  for (final s in Season.values)
                    Text('${_seasonIcon(s)} ${s.label}',
                        style: AppType.body(11, weight: FontWeight.w800,
                            color: seasons.contains(s.name) ? AppColors.amberBright : AppColors.stoneDim)),
                ])
              : null,
        ),
      const SectionLabel('🪜 Milestone Ladders'),
      for (final def in Feats.all.where((f) => f.kind == FeatKind.ladder))
        _LadderTile(def: def, value: progress[def.key] ?? 0, tiersEarned: stacks(def.key)),
      const SectionLabel('❔ Mystery Feats'),
      for (final def in Feats.all.where((f) => f.kind == FeatKind.mystery))
        stacks(def.key) > 0
            ? _FeatTile(def: def, earned: true, badge: def.mystery!.label)
            : _MysteryTile(tier: def.mystery!),
      const SectionLabel('🗿 Goal Statues'),
      if (statues.isEmpty)
        Text('Reclaim a Goal Chamber at 100% to raise its statue here.', style: AppType.body(12.5, color: AppColors.stoneDim)),
      for (final t in statues)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: StashCard(
            border: AppColors.amberBright.withValues(alpha: 0.35),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.flame.withValues(alpha: 0.5), AppColors.amber.withValues(alpha: 0.05)]),
                ),
                child: Text(t.icon, style: const TextStyle(fontSize: 24, fontFamilyFallback: AppType.emojiFallback)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.name, style: AppType.title(14.5, color: AppColors.honey)),
                  Text('Sealed ${Dates.short(t.reclaimedAt)}, ${t.reclaimedAt.year} • ${Money.whole(t.amountCents)}',
                      style: AppType.body(11, color: AppColors.stoneDim)),
                  Text('“${t.note}”', maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: AppType.body(11.5, color: AppColors.cream.withValues(alpha: 0.85), style: FontStyle.italic)),
                ]),
              ),
            ]),
          ),
        ),
      const RoomUpgradeCard(room: RoomKey.trophyHall),
    ]);
  }

  static String _seasonIcon(Season s) => switch (s) {
        Season.spring => '🌸',
        Season.summer => '☀️',
        Season.fall => '🍂',
        Season.winter => '❄️',
      };
}

class _FeatTile extends StatelessWidget {
  const _FeatTile({required this.def, required this.earned, this.badge, this.extra});

  final FeatDef def;
  final bool earned;
  final String? badge;
  final Widget? extra;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: StashCard(
          border: (earned ? AppColors.amberBright : AppColors.stoneDim).withValues(alpha: earned ? 0.45 : 0.2),
          child: Row(children: [
            Opacity(
              opacity: earned ? 1 : 0.35,
              child: Text(def.icon, style: const TextStyle(fontSize: 24, fontFamilyFallback: AppType.emojiFallback)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(def.name, style: AppType.title(14, color: earned ? AppColors.honey : AppColors.stone)),
                Text(def.description, style: AppType.body(11.5, color: AppColors.stoneDim)),
                if (extra != null) ...[const SizedBox(height: 4), extra!],
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (badge != null) Text(badge!, style: AppType.number(15, color: AppColors.amberBright)),
              if (def.acorns > 0) AcornAmount(def.acorns, size: 12, style: AppType.number(12, color: AppColors.stone)),
              if (def.golden > 0) AcornAmount(def.golden, golden: true, size: 12, style: AppType.number(12, color: AppColors.flame)),
            ]),
          ]),
        ),
      );
}

class _LadderTile extends StatelessWidget {
  const _LadderTile({required this.def, required this.value, required this.tiersEarned});

  final FeatDef def;
  final int value;
  final int tiersEarned;

  String _fmt(int v) => def.moneyLadder ? Money.whole(v) : '$v';

  @override
  Widget build(BuildContext context) {
    final next = tiersEarned < def.tiers.length ? def.tiers[tiersEarned] : null;
    final prev = tiersEarned == 0 ? 0 : def.tiers[tiersEarned - 1].threshold;
    final p = next == null ? 1.0 : ((value - prev) / (next.threshold - prev)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: StashCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text(def.icon, style: const TextStyle(fontSize: 20, fontFamilyFallback: AppType.emojiFallback)),
            const SizedBox(width: 8),
            Expanded(child: Text(def.name, style: AppType.title(14, color: AppColors.honey))),
            Text('Tier $tiersEarned/${def.tiers.length}', style: AppType.number(12.5, color: AppColors.amberBright)),
          ]),
          Text(def.description, style: AppType.body(11, color: AppColors.stoneDim)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 7,
              backgroundColor: const Color(0xFF3B2110),
              valueColor: const AlwaysStoppedAnimation(AppColors.amberBright),
            ),
          ),
          const SizedBox(height: 4),
          Text(next == null ? 'All tiers complete — ${_fmt(value)}' : '${_fmt(value)} / ${_fmt(next.threshold)} for the next tier',
              style: AppType.body(11, color: AppColors.stone)),
        ]),
      ),
    );
  }
}

class _MysteryTile extends StatelessWidget {
  const _MysteryTile({required this.tier});

  final MysteryTier tier;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: StashCard(
          color: const Color(0xCC0C0A09),
          child: Row(children: [
            Text('???', style: AppType.title(18, color: AppColors.stoneDim)),
            const SizedBox(width: 12),
            Expanded(child: Text('A hidden ${tier.label.toLowerCase()} feat awaits…', style: AppType.body(12, color: AppColors.stoneDim))),
            Text(tier.label, style: AppType.label(9.5, color: AppColors.stoneDim)),
          ]),
        ),
      );
}

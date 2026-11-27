import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../providers/finance_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stats_engine.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/acorn_icons.dart';
import '../widgets/stash_controls.dart';

/// Rocket League-style lifetime stats ledger with timeframe filter pills.
/// (Credit card trends live in the Bill Vault, not here.)
class StatsDashboard extends ConsumerStatefulWidget {
  const StatsDashboard({super.key});

  @override
  ConsumerState<StatsDashboard> createState() => _StatsDashboardState();
}

class _StatsDashboardState extends ConsumerState<StatsDashboard> {
  StatsRange _range = StatsRange.allTime;

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dashboardStatsProvider(_range));
    final f = ref.watch(financeProvider);
    final s = ref.watch(settingsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ChoicePills<StatsRange>(
          values: StatsRange.values,
          selected: _range,
          color: AppColors.amberBright,
          label: (r) => r.label,
          onSelected: (r) => setState(() => _range = r),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _Hero(title: 'Willpower Saved', value: Money.whole(d.totalCents), sub: '${d.totalCount} wins', color: AppColors.emeraldBright)),
        const SizedBox(width: 8),
        Expanded(
          child: _Hero(
            title: 'Most Used Habit',
            value: d.mostUsed == null ? '—' : '${d.mostUsed!.icon} ${d.mostUsed!.count}×',
            sub: d.mostUsed?.label ?? 'No wins yet',
            color: AppColors.amberBright,
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: _Hero(
            title: 'Best Week',
            value: d.bestWeek == null ? '—' : Money.whole(d.bestWeek!.$2),
            sub: d.bestWeek == null ? '' : 'Week of ${Dates.short(d.bestWeek!.$1)}',
            color: const Color(0xFF93C5FD),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Hero(
            title: 'Best Month',
            value: d.bestMonth == null ? '—' : Money.whole(d.bestMonth!.$2),
            sub: d.bestMonth == null ? '' : Dates.monthKeyLabel(d.bestMonth!.$1),
            color: const Color(0xFFC4B5FD),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: _Hero(
            title: 'Biggest Single Skip',
            value: d.biggest == null ? '—' : Money.smart(d.biggest!.amountCents),
            sub: d.biggest?.label ?? '',
            color: const Color(0xFFFCA5A5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _Hero(title: 'Longest Streak', value: '${d.longestStreak} days', sub: 'consecutive logging', color: const Color(0xFFFDBA74))),
      ]),
      SectionLabel('Per-Impulse Breakdown', trailing: Text(_range.label, style: AppType.body(11, color: AppColors.stoneDim))),
      for (final h in d.perHabit)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 26, child: Text(h.icon, style: const TextStyle(fontSize: 16, fontFamilyFallback: AppType.emojiFallback))),
            Expanded(child: Text(h.label, style: AppType.body(12.5, color: h.count == 0 ? AppColors.stoneDim : AppColors.cream), overflow: TextOverflow.ellipsis)),
            Text('${h.count}×', style: AppType.number(12.5, color: AppColors.stone)),
            SizedBox(
              width: 76,
              child: Text(Money.smart(h.cents), textAlign: TextAlign.end, style: AppType.number(13, color: AppColors.emeraldBright)),
            ),
          ]),
        ),
      const SizedBox(height: 8),
      _Section(title: '🧺 Groceries', rows: [
        ('Spent', Money.smart(d.groceryCents)),
        ('Trips', '${d.groceryTrips}'),
        ('Avg per trip', Money.smart(d.groceryAvgCents)),
      ]),
      _Section(title: '🚇 DC Metro', rows: [
        ('Rides', '${d.metroRides}'),
        ('Transit spend', Money.smart(d.metroCents)),
      ]),
      _Section(title: '🏛️ Goals & Vaults', rows: [
        ('Goals reclaimed', '${d.goalsReclaimed}'),
        ('Reclaimed value', Money.whole(d.goalsReclaimedCents)),
        ('Vault pockets (now)', Money.whole(f.vaultsCents)),
      ]),
      _Section(title: '🐿️ Colony & Focus (all-time)', rows: [
        ('Focus Shifts', '${s.focusShiftsCompleted}'),
        ('Focus minutes', '${s.focusMinutesTotal}'),
        ('Warm Hearth', s.hearthLabel),
      ], trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        AcornAmount(s.acorns, size: 12, style: AppType.number(12, color: AppColors.amberBright)),
        const SizedBox(width: 8),
        AcornAmount(s.goldenAcorns, golden: true, size: 12, style: AppType.number(12, color: AppColors.flame)),
      ])),
    ]);
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.title, required this.value, required this.sub, required this.color});

  final String title;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), const Color(0xE61C1917)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(), style: AppType.label(9, color: color)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: AppType.number(19))),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.body(10.5, color: AppColors.stoneDim)),
        ]),
      );
}

/// Collapsible stats section.
class _Section extends StatefulWidget {
  const _Section({required this.title, required this.rows, this.trailing});

  final String title;
  final List<(String, String)> rows;
  final Widget? trailing;

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: StashCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PressScale(
              scale: 0.99,
              onTap: () => setState(() => _open = !_open),
              child: Row(children: [
                Expanded(child: Text(widget.title, style: AppType.title(13.5, color: AppColors.honey))),
                ?widget.trailing,
                Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.honey),
              ]),
            ),
            if (_open)
              for (final (label, value) in widget.rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(child: Text(label, style: AppType.body(12.5, color: AppColors.stone))),
                    Text(value, style: AppType.number(13, color: AppColors.cream)),
                  ]),
                ),
          ]),
        ),
      );
}

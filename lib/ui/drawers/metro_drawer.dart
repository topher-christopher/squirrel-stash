import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../models/habit.dart';
import '../../models/metro_ride.dart';
import '../../models/room.dart';
import '../../providers/finance_providers.dart';
import '../../providers/impulse_provider.dart';
import '../../providers/kitchen_metro_provider.dart';
import '../../providers/willpower_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/animated_money.dart';
import '../widgets/stash_controls.dart';
import 'colony_cards.dart';
import 'colony_tiles.dart';
import 'drawer_shell.dart';
import 'habit_editor.dart';
import 'prompts.dart';

/// DC Metro Station: 1-tap WMATA fares, ride counts and fare breakdown, plus
/// a shortcut to log a walked/biked short hop as a willpower win.
class MetroBody extends ConsumerWidget {
  const MetroBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(metroStatsProvider);
    final rides = ref.watch(ridesProvider).take(8).toList();
    final actions = ref.read(willpowerActionsProvider);
    final hop = ref.watch(habitsProvider).where((h) => h.key == HabitKeys.shortHop).firstOrNull;
    return RoomPage(children: [
      Text('TAP A FARE', style: AppType.label(10)),
      const SizedBox(height: 8),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.3,
        children: [
          for (final fare in MetroFare.values)
            _FareButton(
              fare: fare,
              onTap: () async {
                if (fare == MetroFare.custom) {
                  final cents = await promptAmount(context, title: 'Custom fare', confirmLabel: 'Log ride');
                  if (cents != null && cents > 0) actions.logRide(fare, cents: cents);
                } else {
                  actions.logRide(fare);
                }
              },
            ),
        ],
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: StatTile(label: 'Rides (mo)', value: Text('${m.monthRides}'))),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'Spent (mo)', color: const Color(0xFF93C5FD), value: AnimatedMoney(m.monthCents, exact: true))),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'This Year', value: AnimatedMoney(m.yearCents))),
      ]),
      const SectionLabel('This Month by Fare'),
      for (final fare in MetroFare.values)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(fare.label, style: AppType.body(13))),
            Text('${m.monthByFare[fare]!.$1} rides', style: AppType.body(12, color: AppColors.stoneDim)),
            const SizedBox(width: 12),
            SizedBox(
              width: 70,
              child: Text(Money.smart(m.monthByFare[fare]!.$2), textAlign: TextAlign.end,
                  style: AppType.number(13.5, color: AppColors.cream)),
            ),
          ]),
        ),
      if (hop != null) ...[
        const SizedBox(height: 12),
        StashCard(
          color: const Color(0x66022C22),
          border: AppColors.emerald.withValues(alpha: 0.35),
          child: Row(children: [
            const Text('🚲', style: TextStyle(fontSize: 24, fontFamilyFallback: AppType.emojiFallback)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Walked or biked a short hop?', style: AppType.body(13, weight: FontWeight.w800)),
                Text('${m.walkedHopsMonth} this month • ${Money.smart(m.walkedSavedMonthCents)} saved',
                    style: AppType.body(11.5, color: AppColors.emeraldSoft)),
              ]),
            ),
            PillButton(label: '+${Money.smart(hop.amountCents)}', dense: true, color: AppColors.emeraldButton,
                onPressed: () => logHabitFlow(context, ref, hop)),
          ]),
        ),
      ],
      if (rides.isNotEmpty) ...[
        SectionLabel('Recent Rides', trailing: Text('Swipe to undo', style: AppType.body(11, color: AppColors.stoneDim))),
        for (final r in rides)
          Dismissible(
            key: ValueKey(r.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              Haptics.tap();
              ref.read(ridesProvider.notifier).remove(r.id);
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.undo_rounded, color: AppColors.alert),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                const Icon(Icons.subway_rounded, size: 16, color: Color(0xFF93C5FD)),
                const SizedBox(width: 10),
                Expanded(child: Text(r.fare.label, style: AppType.body(13))),
                Text(Dates.relative(r.rideAt), style: AppType.body(11.5, color: AppColors.stoneDim)),
                const SizedBox(width: 10),
                Text(Money.smart(r.amountCents), style: AppType.number(13.5, color: AppColors.cream)),
              ]),
            ),
          ),
      ],
      const SectionLabel('Colony boosts'),
      const RushHourTile(),
      const RoomThemeCard(room: RoomKey.metro),
    ]);
  }
}

class _FareButton extends StatelessWidget {
  const _FareButton({required this.fare, required this.onTap});

  final MetroFare fare;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF44403C), Color(0xFF292524)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF93C5FD).withValues(alpha: 0.4)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(fare.label, style: AppType.body(12.5, weight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(fare == MetroFare.custom ? '\$ ?' : Money.exact(fare.cents),
                  style: AppType.number(14, color: const Color(0xFF93C5FD))),
            ]),
            Text(fare.detail, style: AppType.body(10.5, color: AppColors.stoneDim)),
          ]),
        ),
      );
}

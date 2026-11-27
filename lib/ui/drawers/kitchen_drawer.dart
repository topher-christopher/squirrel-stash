import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../models/room.dart';
import '../../providers/finance_providers.dart';
import '../../providers/kitchen_metro_provider.dart';
import '../../providers/willpower_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/animated_money.dart';
import '../widgets/stash_controls.dart';
import 'colony_cards.dart';
import 'drawer_shell.dart';

/// Squirrel Kitchen: neutral grocery-spend awareness plus the Home-Cooked
/// Meal counter & streak. Grocery trips are tracked, never judged.
class KitchenBody extends ConsumerWidget {
  const KitchenBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(groceryStatsProvider);
    final trips = ref.watch(groceriesProvider).take(8).toList();
    return RoomPage(children: [
      StashCard(
        color: const Color(0x99431407),
        border: AppColors.ember.withValues(alpha: 0.4),
        child: Row(children: [
          const Text('🍲', style: TextStyle(fontSize: 30, fontFamilyFallback: AppType.emojiFallback)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Home-Cooked Meals', style: AppType.title(15, color: const Color(0xFFFDBA74))),
              Text('${g.homeMealsMonth} this month • ${g.homeMealsTotal} total',
                  style: AppType.body(12, color: AppColors.stone)),
              Text('🔥 ${g.homeStreak}-day streak (best ${g.bestHomeStreak})',
                  style: AppType.body(12, weight: FontWeight.w800, color: AppColors.amberBright)),
            ]),
          ),
          PillButton(
            label: '+ Cooked',
            color: AppColors.ember,
            dense: true,
            onPressed: () => ref.read(willpowerActionsProvider).logHomeMeal(),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: StatTile(label: 'This Month', color: AppColors.honey, value: AnimatedMoney(g.monthCents))),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'This Year', value: AnimatedMoney(g.yearCents))),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'Trips (mo)', value: Text('${g.monthTrips}'))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: StatTile(label: 'Avg / Trip', value: AnimatedMoney(g.avgPerTripCents, exact: true))),
        const SizedBox(width: 8),
        Expanded(
          child: StatTile(
            label: 'Days Between Trips',
            value: Text(g.avgDaysBetween == null ? '—' : g.avgDaysBetween!.toStringAsFixed(1)),
          ),
        ),
      ]),
      const SectionLabel('Log a Grocery Trip'),
      const _TripForm(),
      if (trips.isNotEmpty) ...[
        SectionLabel('Recent Trips', trailing: Text('Swipe to remove', style: AppType.body(11, color: AppColors.stoneDim))),
        for (final t in trips)
          Dismissible(
            key: ValueKey(t.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              Haptics.tap();
              ref.read(groceriesProvider.notifier).remove(t.id);
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.alert),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                const Icon(Icons.shopping_basket_rounded, size: 16, color: AppColors.honey),
                const SizedBox(width: 10),
                Expanded(child: Text(t.store, style: AppType.body(13), overflow: TextOverflow.ellipsis)),
                if (t.itemCount != null) Text('${t.itemCount} items  ', style: AppType.body(11, color: AppColors.stoneDim)),
                Text(Dates.relative(t.tripAt), style: AppType.body(11.5, color: AppColors.stoneDim)),
                const SizedBox(width: 10),
                Text(Money.smart(t.amountCents), style: AppType.number(13.5, color: AppColors.honey)),
              ]),
            ),
          ),
      ],
      const RoomThemeCard(room: RoomKey.kitchen),
    ]);
  }
}

class _TripForm extends ConsumerStatefulWidget {
  const _TripForm();

  @override
  ConsumerState<_TripForm> createState() => _TripFormState();
}

class _TripFormState extends ConsumerState<_TripForm> {
  final _store = TextEditingController();
  final _amount = TextEditingController();
  final _items = TextEditingController();

  @override
  void dispose() {
    _store.dispose();
    _amount.dispose();
    _items.dispose();
    super.dispose();
  }

  void _log() {
    final ok = ref.read(willpowerActionsProvider).logGrocery(
        store: _store.text, cents: Money.parse(_amount.text) ?? 0, itemCount: int.tryParse(_items.text.trim()));
    if (!ok) {
      Haptics.warn();
      return;
    }
    _store.clear();
    _amount.clear();
    _items.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        StashField(controller: _store, hint: 'Store or note (e.g. Trader Joe\'s)'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(flex: 3, child: StashField(controller: _amount, money: true, hint: 'Total spent')),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _items,
              keyboardType: TextInputType.number,
              style: AppType.body(14.5, weight: FontWeight.w700),
              decoration: const InputDecoration(hintText: 'Items (opt.)'),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        PillButton(label: 'Log Trip', color: AppColors.ember, expand: true, onPressed: _log),
      ]);
}

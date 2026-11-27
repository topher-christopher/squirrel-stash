import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../models/bill.dart';
import '../../providers/bills_provider.dart';
import '../../providers/finance_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'drawer_shell.dart';
import 'prompts.dart';

/// Campfire & Winter Frostline: upcoming bills vs. free cash.
class BillsDrawer extends ConsumerStatefulWidget {
  const BillsDrawer({super.key});

  @override
  ConsumerState<BillsDrawer> createState() => _BillsDrawerState();
}

class _BillsDrawerState extends ConsumerState<BillsDrawer> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  DateTime _due = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _add() {
    final cents = Money.parse(_amount.text);
    if (_name.text.trim().isEmpty || cents == null || cents <= 0) {
      Haptics.warn();
      return;
    }
    ref.read(billsProvider.notifier).add(name: _name.text.trim(), amountCents: cents, dueDate: _due);
    _name.clear();
    _amount.clear();
    FocusScope.of(context).unfocus();
    Haptics.success();
  }

  Future<void> _edit(Bill bill) async {
    final result = await promptLabelAmount(context,
        title: 'Edit bill', labelHint: 'Bill name', initialLabel: bill.name, initialCents: bill.amountCents);
    if (result != null) {
      ref.read(billsProvider.notifier).upsert(bill.copyWith(name: result.$1, amountCents: result.$2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bills = ref.watch(billsProvider);
    final f = ref.watch(financeProvider);
    return DrawerShell(
      emoji: '🔥',
      title: 'Campfire & Winter Frostline',
      subtitle: 'Toggle unpaid bills to watch frost creep across your study window & viewport',
      accent: const Color(0xFFFDBA74),
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: f.frost ? const Color(0xB3450A0A) : const Color(0x99052E16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: (f.frost ? AppColors.alert : AppColors.emeraldBright).withValues(alpha: 0.5)),
          ),
          child: Text(
            f.frost
                ? '❄️ Frost Warning: Unpaid bills (${Money.whole(f.upcomingBillsCents)}) exceed Free Cash (${Money.whole(f.freeCashCents)})'
                : '☀️ Warm & Covered: Free Cash (${Money.whole(f.freeCashCents)}) covers all unpaid bills (${Money.whole(f.upcomingBillsCents)})',
            style: AppType.body(13, weight: FontWeight.w800, color: f.frost ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5)),
          ),
        ),
        const SizedBox(height: 12),
        if (bills.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text('No bills yet — the campfire is cozy and quiet.',
                textAlign: TextAlign.center, style: AppType.body(13, color: AppColors.stoneDim)),
          ),
        for (final bill in bills) ...[
          Dismissible(
            key: ValueKey(bill.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(color: const Color(0xFF7F1D1D), borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
            confirmDismiss: (_) => confirmAction(context,
                title: 'Remove ${bill.name}?', message: 'This bill will be deleted from the Frostline.',
                confirmLabel: 'Remove', destructive: true),
            onDismissed: (_) => ref.read(billsProvider.notifier).remove(bill.id),
            child: _BillRow(
              bill: bill,
              onTap: () {
                Haptics.tap();
                ref.read(billsProvider.notifier).togglePaid(bill.id);
              },
              onLongPress: () => _edit(bill),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text('Tap to mark paid • Long-press to edit • Swipe left to remove',
            textAlign: TextAlign.center, style: AppType.body(11, color: AppColors.stoneDim)),
        const SectionLabel('+ Add Upcoming Bill'),
        Row(children: [
          Expanded(flex: 3, child: StashField(controller: _name, hint: 'e.g. Phone Plan')),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: StashField(controller: _amount, money: true, hint: '0')),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: PillButton(
              label: '📅 Due ${Dates.short(_due)}',
              outlined: true,
              color: AppColors.honey,
              expand: true,
              onPressed: () async {
                final picked = await pickDate(context, _due);
                if (picked != null) setState(() => _due = picked);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: PillButton(label: 'Add Bill', color: AppColors.ember, expand: true, onPressed: _add)),
        ]),
      ],
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.bill, required this.onTap, required this.onLongPress});

  final Bill bill;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) => PressScale(
        onTap: onTap,
        onLongPress: onLongPress,
        scale: 0.98,
        child: StashCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(bill.name,
                    style: AppType.body(14.5, weight: FontWeight.w800, color: bill.paid ? AppColors.stoneDim : AppColors.cream)
                        .copyWith(decoration: bill.paid ? TextDecoration.lineThrough : null)),
                const SizedBox(height: 2),
                Text('Due ${Dates.short(bill.dueDate)}', style: AppType.body(11.5, color: AppColors.honey.withValues(alpha: 0.7))),
              ]),
            ),
            Text(Money.smart(bill.amountCents), style: AppType.number(15, color: AppColors.honey)),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: bill.paid ? const Color(0xCC064E3B) : const Color(0xCC7C2D12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(bill.paid ? 'Paid ✓' : 'Upcoming',
                  style: AppType.body(11.5, weight: FontWeight.w800,
                      color: bill.paid ? AppColors.emeraldSoft : const Color(0xFFFED7AA))),
            ),
          ]),
        ),
      );
}

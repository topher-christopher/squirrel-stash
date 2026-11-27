import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../models/bill.dart';
import '../../models/room.dart';
import '../../providers/bills_provider.dart';
import '../../providers/finance_providers.dart';
import '../../providers/willpower_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'card_insights_view.dart';
import 'colony_cards.dart';
import 'drawer_shell.dart';
import 'etch_board.dart';
import 'prompts.dart';

/// Hollow Log Bill Vault: the due-date countdown board, the waterline
/// scene, bills (statements for cards), card spend insights and adding
/// bills. (The Etch A Sketch lives only here now, not in the room art.)
class BillsBody extends ConsumerWidget {
  const BillsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsProvider);
    final f = ref.watch(financeProvider);
    return RoomPage(children: [
      const EtchBoard(),
      const SizedBox(height: 12),
      AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: f.frost ? const Color(0xB3450A0A) : const Color(0x990C4A6E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (f.frost ? AppColors.alert : AppColors.sky).withValues(alpha: 0.5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            f.frost
                ? '❄️ Below the waterline: unpaid bills (${Money.whole(f.upcomingBillsCents)}) exceed Free Cash (${Money.whole(f.freeCashCents)})'
                : '🌊 Above the waterline: Free Cash (${Money.whole(f.freeCashCents)}) covers unpaid bills (${Money.whole(f.upcomingBillsCents)})',
            style: AppType.body(12.5, weight: FontWeight.w800, color: f.frost ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE)),
          ),
          const SizedBox(height: 4),
          Text(_scene(f.upcomingBillsCents, f.freeCashCents),
              style: AppType.body(11.5, color: const Color(0xCCE0F2FE), height: 1.3)),
        ]),
      ),
      SectionLabel('Bills', trailing: Text('Tap a bill for options', style: AppType.body(11, color: AppColors.stoneDim))),
      if (bills.isEmpty)
        Text('No bills yet — the vault is quiet.', style: AppType.body(13, color: AppColors.stoneDim)),
      for (final bill in bills) ...[
        _BillRow(bill: bill, onTap: () => _billMenu(context, ref, bill)),
        const SizedBox(height: 8),
      ],
      const SectionLabel('Credit Card Spend Insights'),
      const CardInsightsView(),
      const SectionLabel('+ Add Bill'),
      const _AddBillForm(),
      const RoomThemeCard(room: RoomKey.billVault),
    ]);
  }

  Future<void> _billMenu(BuildContext context, WidgetRef ref, Bill bill) async {
    Haptics.light();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.plaque,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(bill.name, style: AppType.title(16, color: AppColors.honey))),
          if (bill.isCard)
            _option(c, 'statement', Icons.receipt_long_rounded, 'Enter statement balance'),
          _option(c, 'paid', bill.paid ? Icons.undo_rounded : Icons.check_circle_rounded,
              bill.paid ? 'Mark unpaid' : 'Mark paid'),
          _option(c, 'edit', Icons.edit_rounded, 'Edit name & amount'),
          _option(c, 'delete', Icons.delete_outline_rounded, 'Remove bill'),
        ]),
      ),
    );
    if (choice == null || !context.mounted) return;
    final notifier = ref.read(billsProvider.notifier);
    switch (choice) {
      case 'statement':
        final cents = await promptAmount(context,
            title: '${bill.name} statement',
            message: 'Statement balance for ${Dates.monthKeyLabel(bill.cycleKey)}. Saved to your card history.',
            initialCents: bill.amountCents,
            confirmLabel: 'Save statement');
        if (cents != null) ref.read(willpowerActionsProvider).recordStatement(bill, cents);
      case 'paid':
        notifier.togglePaid(bill.id);
        Haptics.tap();
      case 'edit':
        final result = await promptLabelAmount(context,
            title: 'Edit bill', labelHint: 'Bill name', initialLabel: bill.name, initialCents: bill.amountCents);
        if (result != null) notifier.upsert(bill.copyWith(name: result.$1, amountCents: result.$2));
      case 'delete':
        final ok = await confirmAction(context,
            title: 'Remove ${bill.name}?', message: 'The bill and its statement history will be deleted.',
            confirmLabel: 'Remove', destructive: true);
        if (ok) notifier.remove(bill.id);
    }
  }

  /// Which waterline scene the vault is playing (bills ÷ Free Cash).
  static String _scene(int bills, int free) {
    final p = bills == 0 ? 0.0 : (free <= 0 ? 2.0 : bills / free);
    final pct = (p * 100).round();
    if (p < 0.25) return 'Low water ($pct% of Free Cash): a shallow brook, lawn chairs and acorn-cup drinks.';
    if (p <= 0.5) return 'Mid water ($pct%): squirrels paddle a walnut skiff and patch the bark seams.';
    return 'High water ($pct%): the brass scuba diver hunts sunken acorns while the raft angler keeps losing one.';
  }

  static Widget _option(BuildContext c, String value, IconData icon, String label) => ListTile(
        leading: Icon(icon, color: AppColors.honey),
        title: Text(label, style: AppType.body(14)),
        onTap: () => Navigator.of(c).pop(value),
      );
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.bill, required this.onTap});

  final Bill bill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = bill.daysUntilDue(DateTime.now());
    final soon = !bill.paid && days <= EtchBoard.urgentDays;
    return PressScale(
      onTap: onTap,
      scale: 0.98,
      child: StashCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: soon ? AppColors.alert.withValues(alpha: 0.5) : null,
        child: Row(children: [
          Icon(switch (bill.kind) {
            BillKind.card => Icons.credit_card_rounded,
            BillKind.rent => Icons.home_rounded,
            BillKind.other => Icons.receipt_rounded,
          }, size: 20, color: AppColors.honey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bill.name,
                  style: AppType.body(14, weight: FontWeight.w800, color: bill.paid ? AppColors.stoneDim : AppColors.cream)
                      .copyWith(decoration: bill.paid ? TextDecoration.lineThrough : null)),
              Text(
                  '${bill.recurring ? 'Every ${_ordinal(bill.dueDay!)}' : 'Due'} • ${Dates.short(bill.dueDate)}'
                  '${bill.isCard ? ' • variable' : ''}',
                  style: AppType.body(11, color: AppColors.honey.withValues(alpha: 0.7))),
            ]),
          ),
          Text(bill.amountCents == 0 ? 'Set' : Money.smart(bill.amountCents), style: AppType.number(15, color: AppColors.honey)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bill.paid ? const Color(0xCC064E3B) : (soon ? const Color(0xCC7F1D1D) : const Color(0xCC7C2D12)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(bill.paid ? 'Paid' : (days <= 0 ? (days == 0 ? 'Today' : 'Late') : '${days}d'),
                style: AppType.body(11, weight: FontWeight.w800, color: bill.paid ? AppColors.emeraldSoft : const Color(0xFFFED7AA))),
          ),
        ]),
      ),
    );
  }

  static String _ordinal(int d) {
    if (d >= 11 && d <= 13) return '${d}th';
    return switch (d % 10) { 1 => '${d}st', 2 => '${d}nd', 3 => '${d}rd', _ => '${d}th' };
  }
}

class _AddBillForm extends ConsumerStatefulWidget {
  const _AddBillForm();

  @override
  ConsumerState<_AddBillForm> createState() => _AddBillFormState();
}

class _AddBillFormState extends ConsumerState<_AddBillForm> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  BillKind _kind = BillKind.other;
  bool _monthly = true;
  DateTime _due = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _add() {
    final cents = Money.parse(_amount.text) ?? 0;
    if (_name.text.trim().isEmpty) {
      Haptics.warn();
      return;
    }
    final due = _monthly ? Bill.nextOccurrence(_due.day, DateTime.now()) : _due;
    ref.read(billsProvider.notifier).add(
        name: _name.text.trim(), amountCents: cents, dueDate: due, kind: _kind, dueDay: _monthly ? _due.day : null);
    _name.clear();
    _amount.clear();
    FocusScope.of(context).unfocus();
    Haptics.success();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(flex: 3, child: StashField(controller: _name, hint: 'e.g. Phone Plan')),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: StashField(controller: _amount, money: true, hint: '0')),
        ]),
        const SizedBox(height: 8),
        ChoicePills<BillKind>(
          values: BillKind.values,
          selected: _kind,
          label: (k) => k.label,
          onSelected: (k) => setState(() => _kind = k),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: PillButton(
              label: _monthly ? '🔁 Monthly on the ${_due.day}' : '📅 Once • ${Dates.short(_due)}',
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
          PillButton(
            label: _monthly ? 'Monthly' : 'One-off',
            dense: true,
            outlined: true,
            color: AppColors.sky,
            onPressed: () => setState(() => _monthly = !_monthly),
          ),
        ]),
        const SizedBox(height: 8),
        PillButton(label: 'Add Bill', color: AppColors.ember, expand: true, onPressed: _add),
      ]);
}

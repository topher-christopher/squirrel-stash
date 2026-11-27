import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../models/holding.dart';
import '../../models/room.dart';
import '../../providers/finance_providers.dart';
import '../../providers/reserves_provider.dart';
import '../../providers/stash_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/animated_money.dart';
import '../widgets/room_icons.dart';
import '../widgets/stash_controls.dart';
import 'decor_shop.dart';
import 'drawer_shell.dart';
import 'holding_editor.dart';

/// A deep-root vault pocket: total, live price refresh, holdings with
/// quantity / avg cost / live price / value / gain-loss, and pocket extras
/// (ESPP pot, HYSA recurring deposit, silver ounces).
class ReserveBody extends ConsumerStatefulWidget {
  const ReserveBody({super.key, required this.kind});

  final ReserveKind kind;

  @override
  ConsumerState<ReserveBody> createState() => _ReserveBodyState();
}

class _ReserveBodyState extends ConsumerState<ReserveBody> {
  bool _refreshing = false;

  ReserveKind get kind => widget.kind;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    final r = await ref.read(holdingsProvider.notifier).refreshPrices(only: kind);
    if (!mounted) return;
    setState(() => _refreshing = false);
    ref.read(stashActionsProvider).banner(
        r.updated == 0 && r.failed > 0
            ? 'Prices unavailable right now — showing your last saved prices.'
            : 'Updated ${r.updated} live price${r.updated == 1 ? '' : 's'}${r.failed > 0 ? ' (${r.failed} kept cached)' : ''}.',
        icon: '📈');
  }

  @override
  Widget build(BuildContext context) {
    final room = RoomKey.forReserve(kind);
    final accent = RoomIcons.accent(room);
    final total = ref.watch(financeProvider.select((f) => f.reserveCents(kind)));
    final holdings = ref.watch(holdingsProvider).where((h) => h.reserve == kind).toList();
    final gains = holdings.map((h) => h.gainCents).whereType<int>().toList();
    final gain = gains.isEmpty ? null : gains.fold<int>(0, (s, g) => s + g);
    final yieldCents = holdings.fold<double>(0, (s, h) => s + h.dailyYieldCents);
    final tickers = holdings.where((h) => h.isTicker).toList();
    final updated = tickers.map((h) => h.lastUpdatedAt).whereType<DateTime>().fold<DateTime?>(
        null, (a, b) => a == null || b.isAfter(a) ? b : a);
    return RoomPage(children: [
      StashCard(
        border: accent.withValues(alpha: 0.4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedMoney(total, style: AppType.number(30, color: accent)),
          if (gain != null)
            Text('${gain >= 0 ? '+' : '-'}${Money.whole(gain.abs())} vs. cost basis',
                style: AppType.body(12.5, weight: FontWeight.w800, color: gain >= 0 ? AppColors.emeraldBright : AppColors.alert)),
          if (yieldCents > 0)
            Text('~${Money.exact(yieldCents.round())}/day passive yield (manual APY)',
                style: AppType.body(12, color: AppColors.stone)),
          const SizedBox(height: 4),
          Text(_blurb(holdings), style: AppType.body(12, color: AppColors.stoneDim, height: 1.35)),
        ]),
      ),
      if (tickers.isNotEmpty) ...[
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text(
                updated == null ? 'No live prices yet' : 'Prices as of ${DateFormat('MMM d, h:mm a').format(updated)}',
                style: AppType.body(11.5, color: AppColors.stoneDim)),
          ),
          PillButton(
            label: _refreshing ? 'Refreshing…' : 'Refresh prices',
            dense: true,
            outlined: true,
            color: accent,
            onPressed: _refreshing ? null : _refresh,
          ),
        ]),
      ],
      ..._extras(holdings, accent),
      SectionLabel('Holdings', trailing: Text('Tap the pencil to edit', style: AppType.body(11, color: AppColors.stoneDim))),
      if (holdings.isEmpty) Text('Nothing stashed here yet.', style: AppType.body(12.5, color: AppColors.stoneDim)),
      for (final h in holdings) ...[
        _HoldingRow(holding: h, accent: accent, onEdit: () => editHoldingDialog(context, ref, kind, h)),
        const SizedBox(height: 8),
      ],
      PillButton(label: '+ Add holding', expand: true, outlined: true, color: accent,
          onPressed: () => editHoldingDialog(context, ref, kind)),
      RoomUpgradeCard(room: room),
    ]);
  }

  String _blurb(List<Holding> holdings) => switch (kind) {
        ReserveKind.brokerage => 'Your most active pocket: 1–3 day settlement. Ticker holdings refresh from live market prices.',
        ReserveKind.pokemon => 'Graded slabs and sealed product, tracked apart from daily banking.',
        ReserveKind.crypto => 'Live prices from CoinGecko. Crystals glow brighter when you\'re above cost basis.',
        ReserveKind.espp => 'Held company shares, your purchase discount and the payroll pot building toward the next quarterly buy.',
        ReserveKind.hysa => 'Cash reserves. No automatic APY — add one per holding if you want a yield estimate.',
        ReserveKind.retirement => 'Roth IRA + 401(k), locked deep in the roots and guarded by the sleeping Golden Elder.',
        ReserveKind.silver =>
          '${holdings.fold<double>(0, (s, h) => s + (h.quantity ?? 0)).toStringAsFixed(1)} troy oz × silver spot (SI=F).',
      };

  List<Widget> _extras(List<Holding> holdings, Color accent) {
    final notifier = ref.read(holdingsProvider.notifier);
    if (kind == ReserveKind.hysa) {
      final monthly = holdings.map((h) => h.recurringCents).whereType<int>().fold<int>(0, (s, c) => s + c);
      if (monthly <= 0) return const [];
      return [
        const SizedBox(height: 10),
        PillButton(
          label: '+ Log this month\'s deposit (+${Money.whole(monthly)})',
          expand: true,
          color: AppColors.amberDeep,
          onPressed: () {
            final target = holdings.firstWhere((h) => (h.recurringCents ?? 0) > 0);
            notifier.upsert(target.copyWith(valueCents: target.valueCents + monthly));
            Haptics.success();
          },
        ),
      ];
    }
    if (kind == ReserveKind.espp) {
      final h = holdings.where((h) => h.esppCashPotCents != null).firstOrNull;
      if (h == null) return const [];
      final price = h.unitPrice;
      final discount = h.esppDiscountPercent ?? 0;
      final buyPrice = price == null ? null : price * (1 - discount / 100);
      final shares = buyPrice == null || buyPrice <= 0 ? null : h.esppCashPotCents! / 100 / buyPrice;
      return [
        const SizedBox(height: 10),
        StashCard(
          color: const Color(0x660C4A6E),
          border: accent.withValues(alpha: 0.35),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Quarterly Purchase Pot', style: AppType.title(14, color: accent)),
            const SizedBox(height: 4),
            Text('${Money.whole(h.esppCashPotCents!)} saved • ${discount.toStringAsFixed(0)}% discount'
                '${h.recurringCents == null ? '' : ' • +${Money.whole(h.recurringCents!)}/paycheck'}',
                style: AppType.body(12.5)),
            if (shares != null)
              Text('~${shares.toStringAsFixed(2)} shares at ${Money.exact((buyPrice! * 100).round())} after discount',
                  style: AppType.body(11.5, color: AppColors.stoneDim)),
            if (h.recurringCents != null) ...[
              const SizedBox(height: 8),
              PillButton(
                label: '+ Paycheck contribution',
                dense: true,
                color: AppColors.skyDeep,
                onPressed: () {
                  notifier.upsert(h.copyWith(esppCashPotCents: () => h.esppCashPotCents! + h.recurringCents!));
                  Haptics.success();
                },
              ),
            ],
          ]),
        ),
      ];
    }
    return const [];
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({required this.holding, required this.accent, required this.onEdit});

  final Holding holding;
  final Color accent;
  final VoidCallback onEdit;

  static String _price(double? p) {
    if (p == null) return '—';
    if (p >= 1000) return NumberFormat.currency(symbol: r'$', decimalDigits: 0).format(p);
    if (p >= 1) return NumberFormat.currency(symbol: r'$', decimalDigits: 2).format(p);
    return '\$${p.toStringAsPrecision(3)}';
  }

  static String _qty(double? q) => q == null ? '—' : (q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toString());

  @override
  Widget build(BuildContext context) {
    final h = holding;
    final gain = h.gainCents;
    final pct = h.gainPercent;
    final gainColor = (gain ?? 0) >= 0 ? AppColors.emeraldBright : AppColors.alert;
    Widget cell(String label, String value, {Color color = AppColors.cream}) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppType.label(8.5, color: AppColors.stoneDim)),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                child: Text(value, style: AppType.number(12.5, color: color))),
          ]),
        );
    return StashCard(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(h.label, style: AppType.body(14, weight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
          if (h.ticker != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(h.isTicker ? 'LIVE ${h.ticker}' : h.ticker!,
                  style: AppType.body(10.5, weight: FontWeight.w800, color: accent)),
            ),
          IconButton(
            tooltip: 'Edit holding',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.honey),
            onPressed: onEdit,
          ),
        ]),
        Row(children: [
          cell('QTY', _qty(h.quantity)),
          cell('AVG COST', _price(h.costBasisPerUnit)),
          cell(h.isTicker ? 'LIVE PRICE' : 'PRICE', _price(h.unitPrice)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          cell('TOTAL VALUE', Money.whole(h.currentValueCents), color: accent),
          cell('GAIN / LOSS',
              gain == null ? '—' : '${gain >= 0 ? '+' : '-'}${Money.whole(gain.abs())} (${(pct ?? 0).toStringAsFixed(1)}%)',
              color: gain == null ? AppColors.stoneDim : gainColor),
          if (h.apyPercent != null) cell('APY', '${h.apyPercent!.toStringAsFixed(2)}%') else const Spacer(),
        ]),
      ]),
    );
  }
}

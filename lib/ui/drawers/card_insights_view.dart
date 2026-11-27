import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../providers/bills_provider.dart';
import '../../providers/card_insights.dart';
import '../../providers/finance_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';

/// Card colors on the spend-share bar.
const cardColors = [Color(0xFF34D399), Color(0xFF60A5FA), Color(0xFFFBBF24), Color(0xFFF472B6), Color(0xFFA78BFA)];

/// Neutral, informative Credit Card Spend Insights: month-over-month change,
/// rolling high/low callouts, most-used card share and statement history.
class CardInsightsView extends ConsumerWidget {
  const CardInsightsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(cardInsightsProvider);
    if (insights.cards.isEmpty) return const SizedBox.shrink();
    if (insights.isEmpty) {
      return Text('Enter a statement balance on any card to start trend tracking.',
          style: AppType.body(12.5, color: AppColors.stoneDim));
    }
    final shares = insights.shares;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _TrendCard(trend: insights.combined, title: 'All ${insights.cards.length} cards combined', color: AppColors.honey),
      const SizedBox(height: 10),
      Text('MOST-USED CARD (avg monthly statement)', style: AppType.label(9.5)),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 16,
          child: Row(children: [
            for (var i = 0; i < insights.cards.length; i++)
              if (shares[i] > 0)
                Expanded(flex: (shares[i] * 1000).round(), child: Container(color: cardColors[i % cardColors.length])),
          ]),
        ),
      ),
      const SizedBox(height: 6),
      Wrap(spacing: 12, runSpacing: 4, children: [
        for (var i = 0; i < insights.cards.length; i++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: cardColors[i % cardColors.length], shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('${insights.cards[i].name} ${(shares[i] * 100).round()}%', style: AppType.body(11, color: AppColors.stone)),
          ]),
      ]),
      const SizedBox(height: 10),
      for (var i = 0; i < insights.cards.length; i++) ...[
        _TrendCard(trend: insights.cards[i], title: insights.cards[i].name, color: cardColors[i % cardColors.length], expandable: true),
        const SizedBox(height: 8),
      ],
    ]);
  }
}

class _TrendCard extends ConsumerStatefulWidget {
  const _TrendCard({required this.trend, required this.title, required this.color, this.expandable = false});

  final CardTrend trend;
  final String title;
  final Color color;
  final bool expandable;

  @override
  ConsumerState<_TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends ConsumerState<_TrendCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.trend;
    final latest = t.latest;
    final delta = t.deltaCents;
    final pct = t.deltaPercent;
    final badge = t.badge;
    final up = (delta ?? 0) > 0;
    final deltaText = delta == null
        ? 'First statement recorded'
        : '${up ? '+' : '-'}${Money.whole(delta.abs())} / ${up ? '+' : '-'}${(pct ?? 0).abs().toStringAsFixed(0)}% vs. last month';
    return StashCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      border: widget.color.withValues(alpha: 0.35),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title, style: AppType.body(13.5, weight: FontWeight.w800))),
          Text(latest == null ? '—' : Money.whole(latest), style: AppType.number(16, color: widget.color)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Icon(delta == null ? Icons.horizontal_rule_rounded : (up ? Icons.trending_up_rounded : Icons.trending_down_rounded),
              size: 16, color: AppColors.stone),
          const SizedBox(width: 4),
          Expanded(child: Text(deltaText, style: AppType.body(11.5, color: AppColors.stone))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.color.withValues(alpha: 0.45)),
              ),
              child: Text(badge, style: AppType.body(11, weight: FontWeight.w800, color: AppColors.cream)),
            ),
          const Spacer(),
          Text('Avg ${Money.whole(t.averageCents)}/mo', style: AppType.body(11, color: AppColors.stoneDim)),
          if (widget.expandable) ...[
            const SizedBox(width: 4),
            PressScale(
              onTap: () => setState(() => _open = !_open),
              child: Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.honey),
            ),
          ],
        ]),
        if (_open && t.bill != null) _History(billId: t.bill!.id),
      ]),
    );
  }
}

class _History extends ConsumerWidget {
  const _History({required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statements = ref.watch(statementsProvider).where((s) => s.billId == billId).toList().reversed.toList();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(children: [
        for (final s in statements)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Text(Dates.monthKeyLabel(s.yearMonth), style: AppType.body(12, color: AppColors.stone)),
              const Spacer(),
              Text(Money.smart(s.amountCents), style: AppType.number(13, color: AppColors.cream)),
            ]),
          ),
      ]),
    );
  }
}

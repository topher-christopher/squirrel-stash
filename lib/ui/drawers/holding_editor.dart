import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../models/holding.dart';
import '../../providers/reserves_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'prompts.dart';

/// Add or edit a vault holding: manual value or live ticker, quantity, avg
/// cost, optional APY, ESPP discount/cash pot, and a recurring tracker.
Future<void> editHoldingDialog(BuildContext context, WidgetRef ref, ReserveKind kind, [Holding? existing]) async {
  final result = await showDialog<Object>(
      context: context, builder: (_) => _HoldingDialog(kind: kind, existing: existing));
  if (result == null || !context.mounted) return;
  final notifier = ref.read(holdingsProvider.notifier);
  if (result == 'delete' && existing != null) {
    final ok = await confirmAction(context,
        title: 'Remove ${existing.label}?', message: 'Delete this holding from the vault?',
        confirmLabel: 'Remove', destructive: true);
    if (ok) notifier.remove(existing.id);
    return;
  }
  if (result is! Holding) return;
  existing == null ? notifier.add(result) : notifier.upsert(result);
  Haptics.success();
  if (result.isTicker) await notifier.refreshPrices(only: kind);
}

class _HoldingDialog extends StatefulWidget {
  const _HoldingDialog({required this.kind, this.existing});

  final ReserveKind kind;
  final Holding? existing;

  @override
  State<_HoldingDialog> createState() => _HoldingDialogState();
}

class _HoldingDialogState extends State<_HoldingDialog> {
  Holding? get e => widget.existing;
  late TrackingMode _mode = e?.trackingMode ??
      (widget.kind == ReserveKind.crypto || widget.kind == ReserveKind.silver ? TrackingMode.ticker : TrackingMode.manual);
  late final _label = TextEditingController(text: e?.label ?? '');
  late final _ticker = TextEditingController(
      text: e?.ticker ?? (widget.kind == ReserveKind.silver ? 'SI=F' : ''));
  late final _qty = TextEditingController(text: _num(e?.quantity));
  late final _cost = TextEditingController(text: _num(e?.costBasisPerUnit));
  late final _value = TextEditingController(text: e == null ? '' : Money.plain(e!.valueCents));
  late final _apy = TextEditingController(text: _num(e?.apyPercent));
  late final _discount = TextEditingController(text: _num(e?.esppDiscountPercent));
  late final _pot = TextEditingController(text: e?.esppCashPotCents == null ? '' : Money.plain(e!.esppCashPotCents!));
  late final _recurring = TextEditingController(text: e?.recurringCents == null ? '' : Money.plain(e!.recurringCents!));

  static String _num(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v');
  static double? _parse(TextEditingController c) => double.tryParse(c.text.replaceAll(RegExp(r'[\s$,%]'), ''));

  @override
  void dispose() {
    for (final c in [_label, _ticker, _qty, _cost, _value, _apy, _discount, _pot, _recurring]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final label = _label.text.trim().isEmpty ? _ticker.text.trim().toUpperCase() : _label.text.trim();
    final ticker = _ticker.text.trim().toUpperCase();
    final qty = _parse(_qty);
    if (label.isEmpty || (_mode == TrackingMode.ticker && (ticker.isEmpty || qty == null))) {
      Haptics.warn();
      return;
    }
    final cost = _parse(_cost);
    final manualValue = Money.parse(_value.text);
    final base = e ?? Holding(id: '', reserve: widget.kind, label: label, valueCents: 0);
    final value = _mode == TrackingMode.manual
        ? (manualValue ?? (qty != null && cost != null ? (qty * cost * 100).round() : 0))
        : base.valueCents;
    Navigator.of(context).pop(base.copyWith(
      label: label,
      valueCents: value,
      trackingMode: _mode,
      ticker: () => _mode == TrackingMode.ticker ? ticker : (ticker.isEmpty ? null : ticker),
      quantity: () => qty,
      costBasisPerUnit: () => cost,
      lastFetchedPrice: () => _mode == TrackingMode.ticker && ticker == e?.ticker ? e?.lastFetchedPrice : null,
      apyPercent: () => _parse(_apy),
      esppDiscountPercent: () => _parse(_discount),
      esppCashPotCents: () => Money.parse(_pot.text),
      recurringCents: () => Money.parse(_recurring.text),
    ));
  }

  Widget _field(String label, TextEditingController c, {String? hint, bool money = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: AppType.label(9)),
          const SizedBox(height: 4),
          money
              ? StashField(controller: c, money: true, hint: hint)
              : TextField(
                  controller: c,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppType.body(14, weight: FontWeight.w700),
                  decoration: InputDecoration(hintText: hint),
                ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final ticker = _mode == TrackingMode.ticker;
    return AlertDialog(
      title: Text(e == null ? 'New ${kind.title} holding' : 'Edit holding'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ChoicePills<TrackingMode>(
            values: TrackingMode.values,
            selected: _mode,
            label: (m) => m == TrackingMode.ticker ? '📈 Live ticker' : '✍️ Manual value',
            onSelected: (m) => setState(() => _mode = m),
          ),
          const SizedBox(height: 10),
          StashField(controller: _label, hint: 'Name (e.g. ${_example(kind)})'),
          const SizedBox(height: 8),
          if (ticker)
            _field(kind == ReserveKind.crypto ? 'Coin symbol or CoinGecko id' : 'Ticker (Yahoo symbol)', _ticker,
                hint: kind == ReserveKind.crypto ? 'BTC, ETH, SOL…' : (kind == ReserveKind.silver ? 'SI=F (silver spot)' : 'VTI, MSFT…')),
          _field('Quantity (${kind.unit})', _qty, hint: ticker ? 'Required' : 'Optional'),
          _field('Avg cost per ${kind.unit == 'oz' ? 'oz' : 'unit'} (\$)', _cost, hint: 'Optional — enables gain/loss'),
          if (!ticker) _field('Current total value', _value, money: true, hint: 'Leave blank to use qty × cost'),
          _field('APY % (optional)', _apy, hint: 'No yield unless you add one'),
          if (kind == ReserveKind.espp) ...[
            _field('Purchase discount %', _discount, hint: '15'),
            _field('Cash pot toward next quarterly buy', _pot, money: true),
          ],
          if (kind == ReserveKind.hysa || kind == ReserveKind.espp)
            _field(kind == ReserveKind.espp ? 'Contribution per paycheck' : 'Recurring monthly deposit', _recurring,
                money: true, hint: kind == ReserveKind.hysa ? '250' : null),
        ]),
      ),
      actions: [
        if (e != null)
          TextButton(onPressed: () => Navigator.of(context).pop('delete'), child: Text('Remove', style: AppType.body(14, color: AppColors.alert))),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: AppType.body(14, color: AppColors.stone))),
        PillButton(label: 'Save', dense: true, onPressed: _save),
      ],
    );
  }

  static String _example(ReserveKind k) => switch (k) {
        ReserveKind.brokerage => 'Vanguard Total Market',
        ReserveKind.pokemon => 'Charizard PSA 10',
        ReserveKind.crypto => 'Bitcoin',
        ReserveKind.espp => 'Employer Shares',
        ReserveKind.hysa => 'High-Yield Savings',
        ReserveKind.retirement => 'Roth IRA',
        ReserveKind.silver => 'Silver Eagles',
      };
}

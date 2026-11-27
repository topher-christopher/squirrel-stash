import 'dart:math' as math;

import '../models/bill.dart';

/// Neutral trend facts for one card (or all cards combined).
class CardTrend {
  const CardTrend({
    required this.name,
    required this.history,
    this.bill,
  });

  /// Null for the combined series.
  final Bill? bill;
  final String name;

  /// Statement amounts oldest → newest (combined: cycle-aligned sums).
  final List<int> history;

  int? get latest => history.isEmpty ? null : history.last;
  int? get previous => history.length < 2 ? null : history[history.length - 2];

  int? get deltaCents {
    final l = latest, p = previous;
    return l == null || p == null ? null : l - p;
  }

  double? get deltaPercent {
    final d = deltaCents, p = previous;
    if (d == null || p == null || p == 0) return null;
    return d / p * 100;
  }

  /// Average statement over the most recent six cycles.
  int get averageCents {
    final window = _window(history, 6);
    if (window.isEmpty) return 0;
    return (window.fold<int>(0, (s, v) => s + v) / window.length).round();
  }

  /// `Lowest in 4 months` / `Highest in 6 months` / `Near 6-mo average`…
  String? get badge => CardInsights.badgeFor(history);
}

/// Per-card and combined statement analytics for the Hollow Log Bill Vault.
class CardInsights {
  const CardInsights({required this.cards, required this.combined});

  final List<CardTrend> cards;
  final CardTrend combined;

  bool get isEmpty => cards.every((c) => c.history.isEmpty);

  /// Share of average monthly spend per card (0..1), same order as [cards].
  List<double> get shares {
    final total = cards.fold<int>(0, (s, c) => s + c.averageCents);
    if (total == 0) return [for (final _ in cards) 0];
    return [for (final c in cards) c.averageCents / total];
  }

  static CardInsights compute(List<Bill> bills, List<BillStatement> statements) {
    final cards = bills.where((b) => b.isCard).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final trends = <CardTrend>[
      for (final card in cards)
        CardTrend(
          bill: card,
          name: card.name,
          history: (statements.where((s) => s.billId == card.id).toList()
                ..sort((a, b) => a.yearMonth.compareTo(b.yearMonth)))
              .map((s) => s.amountCents)
              .toList(),
        ),
    ];
    // Combined: sum each card's k-th most recent statement so cards with
    // different due days line up by billing cycle.
    final depth = trends.fold<int>(0, (m, t) => math.max(m, t.history.length));
    final combined = <int>[
      for (var k = depth - 1; k >= 0; k--)
        trends.fold<int>(0, (sum, t) {
          final i = t.history.length - 1 - k;
          return i >= 0 ? sum + t.history[i] : sum;
        }),
    ];
    return CardInsights(
      cards: trends,
      combined: CardTrend(name: 'All cards', history: combined),
    );
  }

  static List<int> _windowOf(List<int> h, int n) => _window(h, n);

  /// Neutral callout comparing the newest statement to recent history.
  static String? badgeFor(List<int> history) {
    if (history.length < 3) return null;
    final latest = history.last;
    int extremeRun(bool lowest) {
      var run = 1;
      for (var i = history.length - 2; i >= 0 && run < 12; i--) {
        final beats = lowest ? latest <= history[i] : latest >= history[i];
        if (!beats) break;
        run++;
      }
      return run;
    }

    final low = extremeRun(true);
    final high = extremeRun(false);
    if (low >= 3 && low >= high) return 'Lowest in $low months';
    if (high >= 3) return 'Highest in $high months';
    final window = _windowOf(history, 6);
    final avg = window.fold<int>(0, (s, v) => s + v) / window.length;
    final months = window.length;
    if (avg == 0) return null;
    final off = (latest - avg) / avg;
    if (off.abs() <= 0.1) return 'Near $months-mo average';
    return off > 0 ? 'Above $months-mo average' : 'Below $months-mo average';
  }
}

List<int> _window(List<int> h, int n) =>
    h.length <= n ? h : h.sublist(h.length - n);

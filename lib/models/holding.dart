/// The seven compact Deep-Root Vault Pockets. All render at the same size;
/// Brokerage is listed first because it is the most active.
enum ReserveKind {
  brokerage('Brokerage', 'Stocks & ETFs', 'shares'),
  pokemon('Pokémon Card Gallery', 'Slabs & sealed', 'items'),
  crypto('Crypto Crystal Cavern', 'Coins & tokens', 'coins'),
  espp('ESPP', 'Company shares', 'shares'),
  hysa('HYSA & Savings', 'Cash reserves', 'units'),
  retirement('Retirement Vault', 'Roth IRA & 401(k)', 'shares'),
  silver('Silver & Bullion Alcove', 'Troy ounces', 'oz');

  const ReserveKind(this.title, this.subtitle, this.unit);

  final String title;
  final String subtitle;

  /// What [Holding.quantity] counts (shares, coins, oz…).
  final String unit;

  /// Parses current names and the three v1 reserves.
  static ReserveKind parse(String? raw) => switch (raw) {
        'amber' => brokerage,
        'curio' => pokemon,
        'treasury' => retirement,
        _ => values.firstWhere((r) => r.name == raw, orElse: () => brokerage),
      };
}

/// Manual value vs. a live market ticker.
enum TrackingMode {
  manual,
  ticker;

  static TrackingMode parse(String? raw) =>
      values.firstWhere((m) => m.name == raw, orElse: () => TrackingMode.manual);
}

/// A single line item inside a vault pocket (e.g. "VTI", "Charizard PSA 10").
///
/// Money totals are integer cents. Per-unit prices are stored as dollars
/// (doubles) because crypto and fractional shares need sub-cent precision.
class Holding {
  const Holding({
    required this.id,
    required this.reserve,
    required this.label,
    required this.valueCents,
    this.sortOrder = 0,
    this.trackingMode = TrackingMode.manual,
    this.ticker,
    this.quantity,
    this.costBasisPerUnit,
    this.lastFetchedPrice,
    this.lastUpdatedAt,
    this.apyPercent,
    this.esppDiscountPercent,
    this.esppCashPotCents,
    this.recurringCents,
  });

  final String id;
  final ReserveKind reserve;
  final String label;

  /// Manual value, or the last computed value for ticker holdings.
  final int valueCents;
  final int sortOrder;
  final TrackingMode trackingMode;

  /// Yahoo symbol (VTI, MSFT, SI=F) or crypto symbol / CoinGecko id (BTC).
  final String? ticker;
  final double? quantity;
  final double? costBasisPerUnit;
  final double? lastFetchedPrice;
  final DateTime? lastUpdatedAt;

  /// Optional yield — null means no automatic APY is applied.
  final double? apyPercent;
  final double? esppDiscountPercent;

  /// ESPP payroll cash waiting for the next quarterly purchase.
  final int? esppCashPotCents;

  /// HYSA monthly deposit or ESPP per-paycheck contribution tracker.
  final int? recurringCents;

  bool get isTicker => trackingMode == TrackingMode.ticker;

  /// Live value when a price is cached, else the stored value.
  int get currentValueCents {
    final q = quantity, price = lastFetchedPrice;
    if (isTicker && q != null && price != null) return (q * price * 100).round();
    return valueCents;
  }

  /// Unit price shown on the row (live price, else value ÷ quantity).
  double? get unitPrice {
    if (lastFetchedPrice != null) return lastFetchedPrice;
    final q = quantity;
    if (q == null || q <= 0) return null;
    return valueCents / 100 / q;
  }

  int? get costBasisCents {
    final q = quantity, c = costBasisPerUnit;
    if (q == null || c == null) return null;
    return (q * c * 100).round();
  }

  int? get gainCents {
    final basis = costBasisCents;
    return basis == null ? null : currentValueCents - basis;
  }

  double? get gainPercent {
    final basis = costBasisCents, gain = gainCents;
    if (basis == null || gain == null || basis == 0) return null;
    return gain / basis * 100;
  }

  /// `balance × APY / 365`, only when an APY was entered.
  double get dailyYieldCents {
    final apy = apyPercent;
    if (apy == null || apy <= 0) return 0;
    return currentValueCents * apy / 100 / 365;
  }

  Holding copyWith({
    String? label,
    int? valueCents,
    int? sortOrder,
    TrackingMode? trackingMode,
    String? Function()? ticker,
    double? Function()? quantity,
    double? Function()? costBasisPerUnit,
    double? Function()? lastFetchedPrice,
    DateTime? Function()? lastUpdatedAt,
    double? Function()? apyPercent,
    double? Function()? esppDiscountPercent,
    int? Function()? esppCashPotCents,
    int? Function()? recurringCents,
  }) =>
      Holding(
        id: id,
        reserve: reserve,
        label: label ?? this.label,
        valueCents: valueCents ?? this.valueCents,
        sortOrder: sortOrder ?? this.sortOrder,
        trackingMode: trackingMode ?? this.trackingMode,
        ticker: ticker != null ? ticker() : this.ticker,
        quantity: quantity != null ? quantity() : this.quantity,
        costBasisPerUnit:
            costBasisPerUnit != null ? costBasisPerUnit() : this.costBasisPerUnit,
        lastFetchedPrice:
            lastFetchedPrice != null ? lastFetchedPrice() : this.lastFetchedPrice,
        lastUpdatedAt: lastUpdatedAt != null ? lastUpdatedAt() : this.lastUpdatedAt,
        apyPercent: apyPercent != null ? apyPercent() : this.apyPercent,
        esppDiscountPercent: esppDiscountPercent != null
            ? esppDiscountPercent()
            : this.esppDiscountPercent,
        esppCashPotCents:
            esppCashPotCents != null ? esppCashPotCents() : this.esppCashPotCents,
        recurringCents:
            recurringCents != null ? recurringCents() : this.recurringCents,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'reserve': reserve.name,
        'label': label,
        'value_cents': valueCents,
        'sort_order': sortOrder,
        'tracking_mode': trackingMode.name,
        'ticker': ticker,
        'quantity': quantity,
        'cost_basis_per_unit': costBasisPerUnit,
        'last_fetched_price': lastFetchedPrice,
        'last_updated_at': lastUpdatedAt?.toIso8601String(),
        'apy_percent': apyPercent,
        'espp_discount_percent': esppDiscountPercent,
        'espp_cash_pot_cents': esppCashPotCents,
        'recurring_cents': recurringCents,
      };

  factory Holding.fromMap(Map<String, Object?> m) {
    double? d(String k) => (m[k] as num?)?.toDouble();
    final updated = m['last_updated_at'] as String?;
    return Holding(
      id: m['id']! as String,
      reserve: ReserveKind.parse(m['reserve'] as String?),
      label: m['label']! as String,
      valueCents: (m['value_cents']! as num).toInt(),
      sortOrder: (m['sort_order'] as num? ?? 0).toInt(),
      trackingMode: TrackingMode.parse(m['tracking_mode'] as String?),
      ticker: m['ticker'] as String?,
      quantity: d('quantity'),
      costBasisPerUnit: d('cost_basis_per_unit'),
      lastFetchedPrice: d('last_fetched_price'),
      lastUpdatedAt: updated == null ? null : DateTime.tryParse(updated),
      apyPercent: d('apy_percent'),
      esppDiscountPercent: d('espp_discount_percent'),
      esppCashPotCents: (m['espp_cash_pot_cents'] as num?)?.toInt(),
      recurringCents: (m['recurring_cents'] as num?)?.toInt(),
    );
  }
}

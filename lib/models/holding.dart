/// The three Deep Oak-Root Reserves beneath the cellar.
enum ReserveKind {
  amber('🍯', 'Amber Reserve', 'Brokerage / HYSA'),
  curio('🃏', 'Curio Vault', 'Pokémon & Silver'),
  treasury('👑', 'Deep Treasury', 'Roth IRA & 401(k)');

  const ReserveKind(this.emoji, this.title, this.subtitle);

  final String emoji;
  final String title;
  final String subtitle;

  static ReserveKind parse(String? raw) =>
      values.firstWhere((r) => r.name == raw, orElse: () => ReserveKind.amber);
}

/// A single line item inside a reserve (e.g. "Graded Pokémon Slabs").
class Holding {
  const Holding({
    required this.id,
    required this.reserve,
    required this.label,
    required this.valueCents,
    this.sortOrder = 0,
  });

  final String id;
  final ReserveKind reserve;
  final String label;
  final int valueCents;
  final int sortOrder;

  Holding copyWith({String? label, int? valueCents}) => Holding(
        id: id,
        reserve: reserve,
        label: label ?? this.label,
        valueCents: valueCents ?? this.valueCents,
        sortOrder: sortOrder,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'reserve': reserve.name,
        'label': label,
        'value_cents': valueCents,
        'sort_order': sortOrder,
      };

  factory Holding.fromMap(Map<String, Object?> m) => Holding(
        id: m['id']! as String,
        reserve: ReserveKind.parse(m['reserve'] as String?),
        label: m['label']! as String,
        valueCents: (m['value_cents']! as num).toInt(),
        sortOrder: (m['sort_order'] as num? ?? 0).toInt(),
      );
}

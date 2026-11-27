/// A relic from a reclaimed Goal Chamber, displayed on the Trophy Stand.
class Trophy {
  const Trophy({
    required this.id,
    required this.name,
    required this.icon,
    required this.amountCents,
    required this.reclaimedAt,
    this.note = '',
  });

  final String id;
  final String name;
  final String icon;
  final int amountCents;
  final DateTime reclaimedAt;
  final String note;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'amount_cents': amountCents,
        'reclaimed_at': reclaimedAt.toIso8601String(),
        'note': note,
      };

  factory Trophy.fromMap(Map<String, Object?> m) => Trophy(
        id: m['id']! as String,
        name: m['name']! as String,
        icon: m['icon']! as String,
        amountCents: (m['amount_cents']! as num).toInt(),
        reclaimedAt: DateTime.parse(m['reclaimed_at']! as String),
        note: m['note'] as String? ?? '',
      );
}

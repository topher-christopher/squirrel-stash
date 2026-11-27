/// One grocery run logged in the Ratatouille Squirrel Kitchen (neutral
/// spend awareness — never judged as a win or a loss).
class GroceryTrip {
  const GroceryTrip({
    required this.id,
    required this.store,
    required this.amountCents,
    required this.tripAt,
    this.itemCount,
  });

  final String id;

  /// Store name or a short note ("Trader Joe's", "Farmers market").
  final String store;
  final int amountCents;
  final DateTime tripAt;
  final int? itemCount;

  Map<String, Object?> toMap() => {
        'id': id,
        'store': store,
        'amount_cents': amountCents,
        'item_count': itemCount,
        'trip_at': tripAt.toIso8601String(),
      };

  factory GroceryTrip.fromMap(Map<String, Object?> m) => GroceryTrip(
        id: m['id']! as String,
        store: m['store'] as String? ?? '',
        amountCents: (m['amount_cents']! as num).toInt(),
        itemCount: (m['item_count'] as num?)?.toInt(),
        tripAt: DateTime.parse(m['trip_at']! as String),
      );
}

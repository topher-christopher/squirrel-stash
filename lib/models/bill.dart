/// An upcoming bill feeding the Campfire & Winter Frostline buffer.
class Bill {
  const Bill({
    required this.id,
    required this.name,
    required this.amountCents,
    required this.dueDate,
    this.paid = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final int amountCents;
  final DateTime dueDate;
  final bool paid;
  final int sortOrder;

  Bill copyWith({
    String? name,
    int? amountCents,
    DateTime? dueDate,
    bool? paid,
    int? sortOrder,
  }) =>
      Bill(
        id: id,
        name: name ?? this.name,
        amountCents: amountCents ?? this.amountCents,
        dueDate: dueDate ?? this.dueDate,
        paid: paid ?? this.paid,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'amount_cents': amountCents,
        'due_date': dueDate.toIso8601String(),
        'paid': paid ? 1 : 0,
        'sort_order': sortOrder,
      };

  factory Bill.fromMap(Map<String, Object?> m) => Bill(
        id: m['id']! as String,
        name: m['name']! as String,
        amountCents: (m['amount_cents']! as num).toInt(),
        dueDate: DateTime.parse(m['due_date']! as String),
        paid: (m['paid'] as num? ?? 0) == 1,
        sortOrder: (m['sort_order'] as num? ?? 0).toInt(),
      );
}

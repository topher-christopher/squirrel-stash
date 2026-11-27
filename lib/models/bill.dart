/// What kind of obligation a bill is. Credit cards carry a variable
/// statement balance and feed the Card Spend Insights.
enum BillKind {
  card('Credit Card'),
  rent('Rent'),
  other('Bill');

  const BillKind(this.label);
  final String label;

  static BillKind parse(String? raw) =>
      values.firstWhere((k) => k.name == raw, orElse: () => BillKind.other);
}

/// An upcoming bill feeding the Hollow Log Bill Vault & Winter Frostline.
///
/// Recurring bills carry a [dueDay] (1–31). [dueDate] is always the next
/// unpaid occurrence; once a recurring bill is paid and its date passes it
/// rolls forward a month (see `Bill.rolledForward`).
class Bill {
  const Bill({
    required this.id,
    required this.name,
    required this.amountCents,
    required this.dueDate,
    this.paid = false,
    this.sortOrder = 0,
    this.kind = BillKind.other,
    this.dueDay,
  });

  final String id;
  final String name;
  final int amountCents;
  final DateTime dueDate;
  final bool paid;
  final int sortOrder;
  final BillKind kind;

  /// Day of month for recurring monthly bills (null = one-off).
  final int? dueDay;

  bool get isCard => kind == BillKind.card;
  bool get recurring => dueDay != null;

  /// `2026-12` — the statement month this bill's current cycle belongs to.
  String get cycleKey =>
      '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}';

  /// Whole days from [now]'s date until the due date (negative = overdue).
  int daysUntilDue(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inHours ~/ 24;
  }

  /// The occurrence of [day] in the month of [month], clamped to its length.
  static DateTime onDay(DateTime month, int day) {
    final last = DateTime(month.year, month.month + 1, 0).day;
    return DateTime(month.year, month.month, day > last ? last : day);
  }

  /// First occurrence of [day] that is today or later.
  static DateTime nextOccurrence(int day, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final thisMonth = onDay(today, day);
    return thisMonth.isBefore(today)
        ? onDay(DateTime(today.year, today.month + 1), day)
        : thisMonth;
  }

  /// A paid recurring bill whose due date has passed starts its next cycle
  /// (unpaid, next month). Card balances stay until a new statement lands.
  Bill rolledForward(DateTime now) {
    final day = dueDay;
    if (day == null || !paid || daysUntilDue(now) >= 0) return this;
    var next = dueDate;
    final today = DateTime(now.year, now.month, now.day);
    while (!next.isAfter(today.subtract(const Duration(days: 1)))) {
      next = onDay(DateTime(next.year, next.month + 1), day);
    }
    return copyWith(dueDate: next, paid: false);
  }

  Bill copyWith({
    String? name,
    int? amountCents,
    DateTime? dueDate,
    bool? paid,
    int? sortOrder,
    BillKind? kind,
    int? Function()? dueDay,
  }) =>
      Bill(
        id: id,
        name: name ?? this.name,
        amountCents: amountCents ?? this.amountCents,
        dueDate: dueDate ?? this.dueDate,
        paid: paid ?? this.paid,
        sortOrder: sortOrder ?? this.sortOrder,
        kind: kind ?? this.kind,
        dueDay: dueDay != null ? dueDay() : this.dueDay,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'amount_cents': amountCents,
        'due_date': dueDate.toIso8601String(),
        'paid': paid ? 1 : 0,
        'sort_order': sortOrder,
        'kind': kind.name,
        'due_day': dueDay,
      };

  factory Bill.fromMap(Map<String, Object?> m) => Bill(
        id: m['id']! as String,
        name: m['name']! as String,
        amountCents: (m['amount_cents']! as num).toInt(),
        dueDate: DateTime.parse(m['due_date']! as String),
        paid: (m['paid'] as num? ?? 0) == 1,
        sortOrder: (m['sort_order'] as num? ?? 0).toInt(),
        kind: BillKind.parse(m['kind'] as String?),
        dueDay: (m['due_day'] as num?)?.toInt(),
      );
}

/// One month's statement balance for a bill (credit card history).
class BillStatement {
  const BillStatement({
    required this.id,
    required this.billId,
    required this.yearMonth,
    required this.amountCents,
    required this.recordedAt,
  });

  final String id;
  final String billId;

  /// `yyyy-mm`
  final String yearMonth;
  final int amountCents;
  final DateTime recordedAt;

  BillStatement copyWith({int? amountCents, DateTime? recordedAt}) =>
      BillStatement(
        id: id,
        billId: billId,
        yearMonth: yearMonth,
        amountCents: amountCents ?? this.amountCents,
        recordedAt: recordedAt ?? this.recordedAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'bill_id': billId,
        'year_month': yearMonth,
        'amount_cents': amountCents,
        'recorded_at': recordedAt.toIso8601String(),
      };

  factory BillStatement.fromMap(Map<String, Object?> m) => BillStatement(
        id: m['id']! as String,
        billId: m['bill_id']! as String,
        yearMonth: m['year_month']! as String,
        amountCents: (m['amount_cents']! as num).toInt(),
        recordedAt: DateTime.parse(m['recorded_at']! as String),
      );
}

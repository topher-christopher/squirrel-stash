/// A Fallout-Shelter style Goal Chamber excavated in the root cellar.
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetCents,
    required this.dueDate,
    required this.createdAt,
    this.savedCents = 0,
    this.priority = false,
    this.note = '',
  });

  final String id;
  final String name;
  final String icon;
  final int savedCents;
  final int targetCents;
  final DateTime dueDate;
  final bool priority;

  /// Time-capsule note to the user's future self, revealed on reclaim.
  final String note;
  final DateTime createdAt;

  /// Funded fraction clamped to 0..1 (prototype: min(1, saved / max(1, target))).
  double get progress {
    final target = targetCents < 1 ? 1 : targetCents;
    final p = savedCents / target;
    return p > 1 ? 1 : (p < 0 ? 0 : p);
  }

  /// Whole percent capped at 100, as displayed on the chamber plaque.
  int get percent {
    final target = targetCents < 1 ? 1 : targetCents;
    final pct = (savedCents / target * 100).round();
    return pct > 100 ? 100 : pct;
  }

  bool get isComplete => savedCents >= targetCents;

  int get remainingCents =>
      targetCents - savedCents > 0 ? targetCents - savedCents : 0;

  /// Lv.1 Dirt Alcove → Lv.2 Timber Chamber (≥35%) → Lv.3 Gold Treasury (100%).
  int get roomLevel => percent >= 100 ? 3 : (percent >= 35 ? 2 : 1);

  String get roomName => switch (roomLevel) {
        3 => 'Gold Treasury',
        2 => 'Timber Chamber',
        _ => 'Dirt Alcove',
      };

  Goal copyWith({
    String? name,
    String? icon,
    int? savedCents,
    int? targetCents,
    DateTime? dueDate,
    bool? priority,
    String? note,
  }) =>
      Goal(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        savedCents: savedCents ?? this.savedCents,
        targetCents: targetCents ?? this.targetCents,
        dueDate: dueDate ?? this.dueDate,
        priority: priority ?? this.priority,
        note: note ?? this.note,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'saved_cents': savedCents,
        'target_cents': targetCents,
        'due_date': dueDate.toIso8601String(),
        'priority': priority ? 1 : 0,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  factory Goal.fromMap(Map<String, Object?> m) => Goal(
        id: m['id']! as String,
        name: m['name']! as String,
        icon: m['icon']! as String,
        savedCents: (m['saved_cents'] as num? ?? 0).toInt(),
        targetCents: (m['target_cents']! as num).toInt(),
        dueDate: DateTime.parse(m['due_date']! as String),
        priority: (m['priority'] as num? ?? 0) == 1,
        note: m['note'] as String? ?? '',
        createdAt: DateTime.parse(m['created_at']! as String),
      );
}

/// How a willpower win was earned. Each mode is a colored sand layer in
/// the Impulse Silo: Sky-Blue skips, Mint-Emerald downsizes, Honey-Gold DIY.
enum ImpulseMode {
  skip('Full Skip', '✨'),
  downsize('Downsize', '🥤'),
  diy('DIY Swap', '🍳');

  const ImpulseMode(this.label, this.defaultIcon);

  final String label;
  final String defaultIcon;

  static ImpulseMode parse(String? raw) =>
      values.firstWhere((m) => m.name == raw, orElse: () => ImpulseMode.skip);
}

/// A reusable 1-tap temptation chip in the Foraging & Alchemy Lab.
class ImpulseChip {
  const ImpulseChip({
    required this.id,
    required this.label,
    required this.mode,
    required this.amountCents,
    required this.icon,
    this.sortOrder = 0,
  });

  final String id;
  final String label;
  final ImpulseMode mode;
  final int amountCents;
  final String icon;
  final int sortOrder;

  Map<String, Object?> toMap() => {
        'id': id,
        'label': label,
        'mode': mode.name,
        'amount_cents': amountCents,
        'icon': icon,
        'sort_order': sortOrder,
      };

  factory ImpulseChip.fromMap(Map<String, Object?> m) => ImpulseChip(
        id: m['id']! as String,
        label: m['label']! as String,
        mode: ImpulseMode.parse(m['mode'] as String?),
        amountCents: (m['amount_cents']! as num).toInt(),
        icon: m['icon'] as String? ?? '✨',
        sortOrder: (m['sort_order'] as num? ?? 0).toInt(),
      );
}

/// A logged willpower win. [swept] marks savings already moved into a goal
/// so the same wins can't be swept twice.
class ImpulseLog {
  const ImpulseLog({
    required this.id,
    required this.label,
    required this.mode,
    required this.amountCents,
    required this.loggedAt,
    this.swept = false,
  });

  final String id;
  final String label;
  final ImpulseMode mode;
  final int amountCents;
  final DateTime loggedAt;
  final bool swept;

  ImpulseLog copyWith({bool? swept}) => ImpulseLog(
        id: id,
        label: label,
        mode: mode,
        amountCents: amountCents,
        loggedAt: loggedAt,
        swept: swept ?? this.swept,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'label': label,
        'mode': mode.name,
        'amount_cents': amountCents,
        'logged_at': loggedAt.toIso8601String(),
        'swept': swept ? 1 : 0,
      };

  factory ImpulseLog.fromMap(Map<String, Object?> m) => ImpulseLog(
        id: m['id']! as String,
        label: m['label']! as String,
        mode: ImpulseMode.parse(m['mode'] as String?),
        amountCents: (m['amount_cents']! as num).toInt(),
        loggedAt: DateTime.parse(m['logged_at']! as String),
        swept: (m['swept'] as num? ?? 0) == 1,
      );
}

/// The flavor of a willpower win. Each kind is a colored sand layer in the
/// Foraging Lab silo: Sky-Blue skips, Mint-Emerald downsizes, Honey-Gold swaps.
enum ImpulseMode {
  skip('Full Skip', '✨'),
  downsize('Downsize', '🥤'),
  diy('Swap / DIY', '🍳');

  const ImpulseMode(this.label, this.defaultIcon);

  final String label;
  final String defaultIcon;

  static ImpulseMode parse(String? raw) =>
      values.firstWhere((m) => m.name == raw, orElse: () => ImpulseMode.skip);
}

/// A logged willpower win. [habitId] links it to its habit for per-impulse
/// stats; [swept] marks savings already moved into a goal so the same wins
/// can't be swept twice.
class ImpulseLog {
  const ImpulseLog({
    required this.id,
    required this.label,
    required this.mode,
    required this.amountCents,
    required this.loggedAt,
    this.swept = false,
    this.habitId,
  });

  final String id;
  final String label;
  final ImpulseMode mode;
  final int amountCents;
  final DateTime loggedAt;
  final bool swept;
  final String? habitId;

  /// Stats group: the habit when known, otherwise the label (legacy logs).
  String get groupKey => habitId ?? 'label:$label';

  ImpulseLog copyWith({bool? swept}) => ImpulseLog(
        id: id,
        label: label,
        mode: mode,
        amountCents: amountCents,
        loggedAt: loggedAt,
        swept: swept ?? this.swept,
        habitId: habitId,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'label': label,
        'mode': mode.name,
        'amount_cents': amountCents,
        'logged_at': loggedAt.toIso8601String(),
        'swept': swept ? 1 : 0,
        'habit_id': habitId,
      };

  factory ImpulseLog.fromMap(Map<String, Object?> m) => ImpulseLog(
        id: m['id']! as String,
        label: m['label']! as String,
        mode: ImpulseMode.parse(m['mode'] as String?),
        amountCents: (m['amount_cents']! as num).toInt(),
        loggedAt: DateTime.parse(m['logged_at']! as String),
        swept: (m['swept'] as num? ?? 0) == 1,
        habitId: m['habit_id'] as String?,
      );
}

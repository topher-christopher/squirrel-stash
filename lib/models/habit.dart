import 'impulse.dart';

/// How a habit asks for its dollar amount when logged.
enum HabitEntry {
  /// 1-tap: always logs [Habit.amountCents].
  fixed,

  /// Prompts for a custom amount every time ([Habit.amountCents] pre-fills).
  prompt,

  /// 1-tap default estimate, with an optional custom-difference input.
  both;

  static HabitEntry parse(String? raw) =>
      values.firstWhere((e) => e.name == raw, orElse: () => HabitEntry.fixed);
}

/// Stable keys for built-in habits that trophies, the Kitchen and the
/// Metro read from. Custom habits have no key.
abstract final class HabitKeys {
  static const waterSoda = 'water_soda';
  static const skipAppetizer = 'skip_appetizer';
  static const pickup = 'pickup_delivery';
  static const shortHop = 'short_hop';
  static const homeCooked = 'home_cooked';
}

/// A user-editable, pinnable willpower habit in the Foraging & Willpower Lab
/// (stored in the `impulse_chips` table, which predates habits).
class Habit {
  const Habit({
    required this.id,
    required this.label,
    required this.mode,
    required this.amountCents,
    required this.icon,
    this.sortOrder = 0,
    this.entry = HabitEntry.fixed,
    this.roundTrip = false,
    this.pinned = false,
    this.key,
  });

  /// Up to this many habits can sit on the pinned summary bar.
  static const maxPinned = 4;

  final String id;
  final String label;
  final ImpulseMode mode;

  /// Fixed amount, default estimate, or prompt pre-fill (see [entry]).
  final int amountCents;
  final String icon;
  final int sortOrder;
  final HabitEntry entry;

  /// Offers a round-trip toggle that doubles the amount (Short-Hop Metro).
  final bool roundTrip;
  final bool pinned;
  final String? key;

  Habit copyWith({
    String? label,
    ImpulseMode? mode,
    int? amountCents,
    String? icon,
    int? sortOrder,
    HabitEntry? entry,
    bool? roundTrip,
    bool? pinned,
  }) =>
      Habit(
        id: id,
        label: label ?? this.label,
        mode: mode ?? this.mode,
        amountCents: amountCents ?? this.amountCents,
        icon: icon ?? this.icon,
        sortOrder: sortOrder ?? this.sortOrder,
        entry: entry ?? this.entry,
        roundTrip: roundTrip ?? this.roundTrip,
        pinned: pinned ?? this.pinned,
        key: key,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'label': label,
        'mode': mode.name,
        'amount_cents': amountCents,
        'icon': icon,
        'sort_order': sortOrder,
        'entry': entry.name,
        'round_trip': roundTrip ? 1 : 0,
        'pinned': pinned ? 1 : 0,
        'habit_key': key,
      };

  factory Habit.fromMap(Map<String, Object?> m) => Habit(
        id: m['id']! as String,
        label: m['label']! as String,
        mode: ImpulseMode.parse(m['mode'] as String?),
        amountCents: (m['amount_cents']! as num).toInt(),
        icon: m['icon'] as String? ?? '✨',
        sortOrder: (m['sort_order'] as num? ?? 0).toInt(),
        entry: HabitEntry.parse(m['entry'] as String?),
        roundTrip: (m['round_trip'] as num? ?? 0) == 1,
        pinned: (m['pinned'] as num? ?? 0) == 1,
        key: m['habit_key'] as String?,
      );
}

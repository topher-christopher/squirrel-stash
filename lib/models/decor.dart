/// Golden Leaf cosmetic decor. Strictly cosmetic currency — never USD.
enum DecorKey {
  fairyLights('✨', 'Study Fairy Lights', 20),
  twilightSky('🌌', 'Twilight Firefly Window', 35),
  hats('🎓', 'Chef & Scholar Hats', 25),
  espressoBar('☕', 'Desk Espresso Press', 40);

  const DecorKey(this.emoji, this.label, this.cost);

  final String emoji;
  final String label;
  final int cost;

  static DecorKey? tryParse(String? raw) {
    for (final k in values) {
      if (k.name == raw) return k;
    }
    return null;
  }
}

/// Ownership is permanent; [enabled] toggles whether the decor is shown.
class DecorItemState {
  const DecorItemState({
    required this.key,
    this.owned = false,
    this.enabled = false,
  });

  final DecorKey key;
  final bool owned;
  final bool enabled;

  bool get active => owned && enabled;

  DecorItemState copyWith({bool? owned, bool? enabled}) => DecorItemState(
        key: key,
        owned: owned ?? this.owned,
        enabled: enabled ?? this.enabled,
      );

  Map<String, Object?> toMap() => {
        'key': key.name,
        'owned': owned ? 1 : 0,
        'enabled': enabled ? 1 : 0,
      };

  static DecorItemState? fromMap(Map<String, Object?> m) {
    final key = DecorKey.tryParse(m['key'] as String?);
    if (key == null) return null;
    return DecorItemState(
      key: key,
      owned: (m['owned'] as num? ?? 0) == 1,
      enabled: (m['enabled'] as num? ?? 0) == 1,
    );
  }
}

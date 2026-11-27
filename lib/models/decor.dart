/// Grand Tree looks. Free to switch on and off since v1.2 — Acorns now pay
/// for upkeep and expeditions instead of one-time unlocks.
enum DecorKey {
  lanternBeacon('Treat Lantern Beacon',
      'Projects the Green / Yellow / Red Treat lantern onto the Owl Moonlight Lantern'),
  fairyLights('Canopy Fairy Lights', 'Twinkling garlands along the branches (lit while the Hearth burns)'),
  twilightSky('Twilight Firefly Sky', 'Starry dusk sky with drifting fireflies, all day long'),
  seasonalFoliage('Seasonal Foliage', 'The crown follows the real seasons — blossoms to snowy boughs'),
  hats('Colony Outfits', 'Knight helms, beanies, goggles, visors & DJ headphones for everyone');

  const DecorKey(this.label, this.blurb);

  final String label;
  final String blurb;

  static DecorKey? tryParse(String? raw) {
    for (final k in values) {
      if (k.name == raw) return k;
    }
    return null;
  }
}

/// [enabled] toggles whether the look is shown. [owned] is kept for the
/// schema (every look is owned since v1.2).
class DecorItemState {
  const DecorItemState({
    required this.key,
    this.owned = true,
    this.enabled = false,
  });

  final DecorKey key;
  final bool owned;
  final bool enabled;

  bool get active => enabled;

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
      owned: (m['owned'] as num? ?? 1) == 1,
      enabled: (m['enabled'] as num? ?? 0) == 1,
    );
  }
}

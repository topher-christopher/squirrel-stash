/// Grand Tree upgrades, bought with Acorns + Golden Acorns. Strictly
/// cosmetic currency — never mixed with real USD.
enum DecorKey {
  lanternBeacon('Treat Lantern Beacon',
      'Projects the Green / Yellow / Red Treat lantern onto the canopy birdhouse', 400, 1),
  fairyLights('Canopy Fairy Lights', 'Twinkling garlands strung between the branches', 250, 0),
  twilightSky('Twilight Firefly Sky', 'Starry dusk sky with drifting fireflies', 500, 1),
  seasonalFoliage('Seasonal Foliage', 'The crown follows the real seasons — blossoms to snowy boughs', 600, 2),
  hats('Colony Outfits', 'Knight helms, beanies, aviator goggles & banker visors for everyone', 350, 1);

  const DecorKey(this.label, this.blurb, this.acornCost, this.goldenCost);

  final String label;
  final String blurb;
  final int acornCost;
  final int goldenCost;

  static DecorKey? tryParse(String? raw) {
    for (final k in values) {
      if (k.name == raw) return k;
    }
    return null;
  }
}

/// Ownership is permanent; [enabled] toggles whether the upgrade is shown.
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

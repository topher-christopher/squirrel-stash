/// A Borrower-scale human trinket repurposed in the Acorn Outfitter.
class Trinket {
  const Trinket(this.key, this.name, this.emoji, this.fieldNote, {this.minLevel = 1});

  final String key;
  final String name;
  final String emoji;

  /// The colony's humorous field note, shown when the trinket is tapped.
  final String fieldNote;

  /// Outfitter level at which the trinket appears in the room.
  final int minLevel;

  static const all = <Trinket>[
    Trinket('film_barrels', '35mm Film Canister Grain Barrels', '🎞️',
        'Field Note #12: The humans keep tiny memories in these. We keep 412 sunflower seeds. Ours smell better.'),
    Trinket('card_wall', 'Framed Giant Pokémon Card', '🖼️',
        'Field Note #3: Acquired in a daring windowsill heist. Holo shimmer: excessive. We salute it nightly.'),
    Trinket('booster_bench', 'Booster Box Bench', '📦',
        'Field Note #27: Sealed for maximum resale value. Also an excellent bench. Hazel opened one once. We don\'t talk about Hazel.'),
    Trinket('button_rug', 'Vintage Button Rug', '🔴',
        'Field Note #2: Four holes, four paws. Formerly fastened a very important coat.'),
    Trinket('thumbtack_table', 'Brass Thumbtack Café Table', '📌',
        'Field Note #8: Seats four squirrels or one very confident chipmunk. Point side DOWN. Learned the hard way.',
        minLevel: 2),
    Trinket('bottlecap_firepit', 'Bottle-Cap Firepit', '🔥',
        'Field Note #19: Crinkled edges keep the embers in. Smells faintly of root beer when it rains.', minLevel: 2),
    Trinket('thimble_planter', 'Upside-Down Thimble Moss Planter', '🪴',
        'Field Note #5: The dimples make perfect drainage. The moss is named Gerald.', minLevel: 2),
    Trinket('wheel_ottoman', 'Skateboard Wheel Ottoman', '🛞',
        'Field Note #14: Footrest by day, getaway vehicle by night. Rolls when you least expect it.', minLevel: 2),
    Trinket('sneaker_daybed', 'Mini Sneaker Daybed', '👟',
        'Field Note #31: Lost by a jogger, found by a napper. The left one is still out there. Search ongoing.',
        minLevel: 3),
    Trinket('penny_gong', 'Copper Penny Gong', '🪙',
        'Field Note #22: Struck once for payday, twice for a Golden Acorn, thrice if someone took the last walnut.',
        minLevel: 3),
  ];

  static Trinket? byKey(String key) {
    for (final t in all) {
      if (t.key == key) return t;
    }
    return null;
  }
}

/// Colony wardrobe pieces shown in the Outfitter (worn when the Colony
/// Outfits Grand Tree upgrade is active).
class OutfitPiece {
  const OutfitPiece(this.name, this.emoji, this.wornBy);

  final String name;
  final String emoji;
  final String wornBy;

  static const all = <OutfitPiece>[
    OutfitPiece('Acorn-Cap Knight Helm', '🪖', 'Goal haulers & the Outfitter guard'),
    OutfitPiece('Knit Beanie', '🧶', 'Hammock nappers & skateboarders'),
    OutfitPiece('Brass Aviator Goggles', '🥽', 'Lift operators, lab researchers & cyclists'),
    OutfitPiece("Banker's Visor", '🧢', 'Treasury tellers, bookkeepers & curators'),
  ];
}

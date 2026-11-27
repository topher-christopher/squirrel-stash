/// A Borrower-scale human trinket repurposed by the colony. Every trinket
/// is free to view and to set on a Display Pedestal (no unlocks since v1.2).
class Trinket {
  const Trinket(this.key, this.name, this.emoji, this.fieldNote, {this.room = 'Acorn Outfitter'});

  final String key;
  final String name;
  final String emoji;

  /// The colony's humorous field note, shown when the trinket is tapped.
  final String fieldNote;

  /// Where it lives in the Great Oak.
  final String room;

  static const all = <Trinket>[
    Trinket('film_barrels', '35mm Film Canister Grain Barrels', '🎞️',
        'Field Note #12: The humans keep tiny memories in these. We keep 412 sunflower seeds. Ours smell better.'),
    Trinket('card_wall', 'Giant Framed Pokémon Card', '🖼️',
        'Field Note #3: Acquired in a daring windowsill heist. Holo shimmer: excessive. We salute it nightly.'),
    Trinket('skate_deck', 'Half-Pipe Skate Deck', '🛹',
        'Field Note #40: Found leaning on a bike rack. Now the fastest thing in the Outfitter. Helmets are acorn caps.'),
    Trinket('disco_ball', 'Mirror Disco Ball', '🪩',
        'Field Note #41: Made from 600 tiny mirror shards and one very patient magpie. Spins only when the Hearth is warm.'),
    Trinket('dj_booth', 'Bottle-Cap DJ Turntables', '🎧',
        'Field Note #44: Two root-beer caps on a lazy Susan. DJ Hazelnut only plays the hits: acorn house.'),
    Trinket('booster_bench', 'Booster Box Bench', '📦',
        'Field Note #27: Sealed for maximum resale value. Also an excellent bench. Hazel opened one once. We don\'t talk about Hazel.'),
    Trinket('wheel_ottoman', 'Skateboard Wheel Ottoman', '🛞',
        'Field Note #14: Footrest by day, getaway vehicle by night. Rolls when you least expect it.'),
    Trinket('sneaker_daybed', 'Mini Sneaker Daybed', '👟',
        'Field Note #31: Lost by a jogger, found by a napper. The left one is still out there. Search ongoing.'),
    Trinket('thumbtack_table', 'Brass Thumbpin Dining Table', '📌',
        'Field Note #8: Seats four squirrels or one very confident chipmunk. Point side DOWN. Learned the hard way.',
        room: 'Ratatouille Kitchen'),
    Trinket('button_rug', 'Vintage Button Rug', '🔴',
        'Field Note #2: Four holes, four paws. Formerly fastened a very important coat.', room: 'Ratatouille Kitchen'),
    Trinket('holiday_tree', 'Treehouse Christmas Tree', '🎄',
        'Field Note #50: A pine sprig in a walnut shell. Ornaments are glass beads. The star is a sequin. It is perfect.',
        room: 'Ratatouille Kitchen'),
    Trinket('bottlecap_firepit', 'Bottle-Cap Firepit', '🔥',
        'Field Note #19: Crinkled edges keep the embers in. Smells faintly of root beer when it rains.',
        room: 'Deep-Root Hearth'),
    Trinket('thimble_planter', 'Upside-Down Thimble Moss Planter', '🪴',
        'Field Note #5: The dimples make perfect drainage. The moss is named Gerald.', room: 'Foraging Lab'),
    Trinket('penny_gong', 'Copper Penny Gong', '🪙',
        'Field Note #22: Struck once for payday, twice for a Golden Acorn, thrice if someone took the last walnut.',
        room: 'Canopy Treasury'),
  ];

  static Trinket? byKey(String key) {
    for (final t in all) {
      if (t.key == key) return t;
    }
    return null;
  }
}

/// Colony wardrobe pieces (worn when Colony Outfits is switched on — free).
class OutfitPiece {
  const OutfitPiece(this.name, this.emoji, this.wornBy);

  final String name;
  final String emoji;
  final String wornBy;

  static const all = <OutfitPiece>[
    OutfitPiece('Acorn-Cap Knight Helm', '🪖', 'Goal haulers & branch runners'),
    OutfitPiece('Knit Beanie', '🧶', 'Skateboarders (and everyone in winter)'),
    OutfitPiece('Brass Aviator Goggles', '🥽', 'Lift operators, lab researchers & cyclists'),
    OutfitPiece("Banker's Visor", '🧢', 'Treasury tellers, bookkeepers & curators'),
    OutfitPiece('DJ Headphones', '🎧', 'DJ Hazelnut in the Outfitter lounge'),
    OutfitPiece('Scavenger Backpack', '🎒', 'Burrow squads heading out on expeditions'),
    OutfitPiece('Puffy Winter Jacket', '🧥', 'The whole colony when the Winter theme is on'),
  ];
}

import 'holding.dart';

/// How big a room is drawn in the Great Oak cutaway.
enum RoomSize { hero, medium, pocket }

/// Every room in the Great Oak, in natural top-to-bottom order (canopy →
/// trunk → underground). This order drives the swipeable room drawer.
enum RoomKey {
  treasury('Canopy Treasury', 'Free Cash, Payday & the Treat Lantern', RoomSize.medium),
  outfitter('Acorn Outfitter', 'Stashed trinkets & colony wardrobe', RoomSize.hero),
  lab('Foraging & Willpower Lab', 'Log willpower wins', RoomSize.medium),
  trophyHall('Trophy Hall', 'Trophies & lifetime stats', RoomSize.hero),
  billVault('Hollow Log Bill Vault', 'Bills, due dates & card trends', RoomSize.medium),
  kitchen('Squirrel Kitchen', 'Grocery spend & home cooking', RoomSize.hero),
  goals('Goal Chambers', 'Savings goals that seal at 100%', RoomSize.medium),
  metro('DC Metro Station', 'WMATA transit tracker', RoomSize.hero),
  brokerage('Brokerage', 'Stocks & ETFs', RoomSize.pocket),
  pokemon('Pokémon Gallery', 'Slabs & sealed', RoomSize.pocket),
  crypto('Crypto Cavern', 'Coins & tokens', RoomSize.pocket),
  espp('ESPP', 'Company shares', RoomSize.pocket),
  hysa('HYSA & Savings', 'Cash reserves', RoomSize.pocket),
  retirement('Retirement Vault', 'Roth IRA & 401(k)', RoomSize.pocket),
  silver('Silver Alcove', 'Bullion by the ounce', RoomSize.pocket);

  const RoomKey(this.title, this.tagline, this.size);

  final String title;
  final String tagline;
  final RoomSize size;

  /// The vault pocket's reserve, for the seven deep-root rooms.
  ReserveKind? get reserve => switch (this) {
        brokerage => ReserveKind.brokerage,
        pokemon => ReserveKind.pokemon,
        crypto => ReserveKind.crypto,
        espp => ReserveKind.espp,
        hysa => ReserveKind.hysa,
        retirement => ReserveKind.retirement,
        silver => ReserveKind.silver,
        _ => null,
      };

  static RoomKey forReserve(ReserveKind kind) =>
      values.firstWhere((r) => r.reserve == kind);

  static RoomKey? tryParse(String? raw) {
    for (final r in values) {
      if (r.name == raw) return r;
    }
    return null;
  }
}

/// Visual room levels bought with Acorns: Starter → Cozy → Max.
abstract final class RoomLevels {
  static const max = 3;

  static const names = ['Starter', 'Cozy', 'Max Unlocked'];

  /// Acorn price to reach [level] (2 or 3).
  static int costFor(int level) => level <= 2 ? 300 : 900;

  static String name(int level) => names[(level - 1).clamp(0, 2)];
}

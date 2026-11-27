import 'holding.dart';

/// How big a room is drawn in the Great Oak cutaway.
enum RoomSize { hero, medium, pocket }

/// Every place in the Great Oak, in natural top-to-bottom, left-to-right
/// order (canopy → trunk → grass → underground). This order drives the
/// swipeable room drawer.
enum RoomKey {
  treasury('Canopy Treasury', 'Free Cash, Payday & the Treat Lantern', RoomSize.medium),
  birdFeeder('Canopy Bird Feeder', 'Seed bags, lures & the Visitor Logbook', RoomSize.medium),
  outfitter('Acorn Outfitter', 'Skatepark, DJ lounge & stashed trinkets', RoomSize.hero),
  lab('Foraging & Willpower Lab', 'Log willpower wins', RoomSize.medium),
  kitchen('Ratatouille Kitchen', 'Grocery spend, home cooking & the holiday tree', RoomSize.hero),
  trophyHall('Trophy Hall', 'Trophies & lifetime stats', RoomSize.medium),
  billVault('Hollow Log Bill Vault', 'Bills, due dates & card trends', RoomSize.hero),
  goals('Goals Alcove', 'Savings goals that seal at 100%', RoomSize.medium),
  burrow('Scavenger Burrow', 'Timed seed-foraging expeditions', RoomSize.medium),
  metro('DC Metro Station', 'WMATA transit tracker', RoomSize.hero),
  brokerage('Brokerage', 'Stocks & ETFs', RoomSize.pocket),
  pokemon('Pokémon Gallery', 'Slabs & sealed', RoomSize.pocket),
  crypto('Crypto Cavern', 'Coins & tokens', RoomSize.pocket),
  espp('ESPP', 'Company shares', RoomSize.pocket),
  hysa('HYSA & Savings', 'Cash reserves', RoomSize.pocket),
  retirement('Retirement Vault', 'Roth IRA & 401(k)', RoomSize.pocket),
  silver('Silver Alcove', 'Bullion by the ounce', RoomSize.pocket),
  hearth('Deep-Root Hearth', 'Tree lights, the Granary & Golden upgrades', RoomSize.pocket);

  const RoomKey(this.title, this.tagline, this.size);

  final String title;
  final String tagline;
  final RoomSize size;

  /// The vault pocket's reserve, for the seven deep-root money rooms.
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

/// Room themes: Starter → Cozy → Max. Free to pick since v1.2 (Acorns now
/// pay for upkeep and expeditions instead of one-time unlocks).
abstract final class RoomLevels {
  static const max = 3;

  static const names = ['Starter', 'Cozy', 'Max'];

  static String name(int level) => names[(level - 1).clamp(0, 2)];
}

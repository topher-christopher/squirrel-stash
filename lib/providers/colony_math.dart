import 'dart:math' as math;

import '../models/bird.dart';
import '../models/colony_economy.dart';
import '../models/colony_state.dart';

/// Pure upkeep formulas (no Flutter, fully testable).
abstract final class ColonyMath {
  static DateTime _max(DateTime a, DateTime? b) => b != null && b.isAfter(a) ? b : a;

  /// Advances the canopy acorn collector from [from] to [to]: it fills in
  /// 8h while the Hearth is lit (until [litUntil]) and 12h while dark.
  static double advanceCollector(double progress, DateTime from, DateTime to, DateTime? litUntil) {
    if (!to.isAfter(from)) return progress;
    final total = to.difference(from).inSeconds;
    final litEnd = litUntil == null ? from : (litUntil.isBefore(to) ? litUntil : to);
    final lit = litEnd.isAfter(from) ? litEnd.difference(from).inSeconds : 0;
    final dark = total - lit;
    final gained = lit / (ColonyEconomy.collectorLitHours * 3600) + dark / (ColonyEconomy.collectorDarkHours * 3600);
    return math.min(1.0, progress + gained);
  }

  /// Next fuel deadline after adding [hours] at [now], capped at the
  /// Hearth's burn capacity. Returns null when the Hearth is already full.
  static DateTime? refuel(ColonyState s, DateTime now, int hours) {
    final start = _max(now, s.hearthFuelUntil);
    final cap = now.add(s.hearthCapacity);
    var until = start.add(Duration(hours: hours));
    if (until.isAfter(cap)) until = cap;
    return until.difference(start).inMinutes < 1 ? null : until;
  }

  /// Acorn cost of moving the fuel deadline from its current value to [until].
  static int fuelCost(ColonyState s, DateTime now, DateTime until) {
    final start = _max(now, s.hearthFuelUntil);
    final hours = until.difference(start).inMinutes / 60;
    return (hours.ceil() * ColonyEconomy.fuelAcornsPerHour).clamp(0, 1 << 30);
  }

  /// Extends a timed boost from whichever is later: now or its current end.
  static DateTime extend(DateTime? until, DateTime now, Duration by) => _max(now, until).add(by);

  /// Feeder deadline after pouring one bag of [seed]. Null when the feeder
  /// already holds the maximum of that seed.
  static DateTime? pour(ColonyState s, DateTime now, SeedKind seed) {
    final bag = Duration(hours: seed.feederHours);
    final current = s.seedIn(now);
    if (current != seed) return now.add(bag);
    final cap = now.add(bag * SeedKind.maxBagsInFeeder);
    final until = s.feederUntil!.add(bag);
    if (!s.feederUntil!.isBefore(cap.subtract(const Duration(minutes: 30)))) return null;
    return until.isAfter(cap) ? cap : until;
  }
}

/// Deterministic feeder visit simulation: every 10-minute slot while seed
/// is in the feeder may bring one visitor. Seeded by the slot index, so the
/// same slot always plays out the same way.
abstract final class BirdSim {
  static const slotMinutes = 10;

  /// Longest absence simulated in one go (the feeder never lasts longer).
  static const maxSlots = 7 * 24 * 6;

  static bool isNight(DateTime t) => t.hour >= 19 || t.hour < 7;

  static List<BirdVisit> simulate({
    required DateTime from,
    required DateTime to,
    required SeedKind seed,
    required DateTime feederUntil,
    LureKind? lure,
    DateTime? lureUntil,
    DateTime? festivalUntil,
  }) {
    final end = to.isBefore(feederUntil) ? to : feederUntil;
    if (!end.isAfter(from)) return const [];
    final slotMs = slotMinutes * 60 * 1000;
    var k = from.millisecondsSinceEpoch ~/ slotMs + 1;
    final last = end.millisecondsSinceEpoch ~/ slotMs;
    if (last - k > maxSlots) k = last - maxSlots;
    final visits = <BirdVisit>[];
    for (; k <= last; k++) {
      final at = DateTime.fromMillisecondsSinceEpoch(k * slotMs);
      final activeLure = lureUntil != null && at.isBefore(lureUntil) ? lure : null;
      final festival = festivalUntil != null && at.isBefore(festivalUntil);
      final species = _roll(k, at, seed, activeLure, festival);
      if (species != null) visits.add(BirdVisit(species, at, activeLure));
    }
    return visits;
  }

  static BirdSpecies? _roll(int slot, DateTime at, SeedKind seed, LureKind? lure, bool festival) {
    final rng = math.Random(slot * 7919 + seed.index * 104729);
    final night = isNight(at);
    var rate = seed.visitRate;
    if (lure == LureKind.berrySuet) rate *= 1.5;
    if (lure == LureKind.deluxeFeast) rate *= 2;
    if (night && lure != LureKind.moonOil) rate *= 0.5;
    if (festival) rate *= 1.25;
    if (rng.nextDouble() >= math.min(rate, 0.95)) return null;
    final pool = <(BirdSpecies, double)>[];
    for (final b in seed.visitors) {
      if (b.nightOnly && !night) continue;
      var w = b.weight.toDouble();
      if (lure == LureKind.berrySuet &&
          (b == BirdSpecies.woodpecker || b == BirdSpecies.waxwing || b == BirdSpecies.oriole)) {
        w *= 2;
      }
      if (lure == LureKind.moonOil && b.nightOnly) w *= 3;
      if (b.rarity == BirdRarity.rare && lure == LureKind.deluxeFeast) w *= 1.5;
      if (b.rarity == BirdRarity.rare && festival) w *= 3;
      pool.add((b, w));
    }
    final total = pool.fold<double>(0, (s, e) => s + e.$2);
    var pick = rng.nextDouble() * total;
    for (final (b, w) in pool) {
      pick -= w;
      if (pick <= 0) return b;
    }
    return pool.isEmpty ? null : pool.last.$1;
  }
}

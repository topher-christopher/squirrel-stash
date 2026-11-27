import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio_service.dart';
import '../core/haptics.dart';
import '../game/diorama_event.dart';
import '../models/bird.dart';
import '../models/colony_economy.dart';
import '../models/colony_state.dart';
import '../models/expedition.dart';
import '../models/room.dart';
import 'clock_provider.dart';
import 'colony_math.dart';
import 'colony_provider.dart';
import 'reward_service.dart';
import 'settings_provider.dart';
import 'ui_provider.dart';

final colonyActionsProvider = Provider<ColonyActions>(ColonyActions.new);

/// The Acorn upkeep economy: Hearth fuel & boosts, Golden Acorn
/// infrastructure, Scavenger Burrow expeditions, the Bird Feeder, and the
/// colony clock that settles everything that happened while away.
/// Never touches a real dollar balance.
class ColonyActions {
  ColonyActions(this._ref);

  final Ref _ref;

  DateTime get _now => _ref.read(clockProvider)();
  ColonyState get _colony => _ref.read(colonyProvider);
  ColonyNotifier get _state => _ref.read(colonyProvider.notifier);
  SettingsNotifier get _settings => _ref.read(settingsProvider.notifier);
  RewardService get _rewards => _ref.read(rewardServiceProvider);

  void _emit(DioramaEventKind kind, [RoomKey? room]) =>
      _ref.read(dioramaEventsProvider).emit(DioramaEvent(kind, room: room));

  void _banner(String text, String icon) => _ref.read(uiProvider.notifier).showBanner(text, icon: icon);

  bool _pay(String what, {int acorns = 0, int golden = 0}) {
    if (_settings.trySpend(acorns: acorns, golden: golden)) return true;
    final s = _ref.read(settingsProvider);
    final short = [
      if (s.acorns < acorns) '${acorns - s.acorns} more Acorns',
      if (s.goldenAcorns < golden) '${golden - s.goldenAcorns} more Golden Acorn${golden - s.goldenAcorns == 1 ? '' : 's'}',
    ].join(' and ');
    _banner('$what needs $short — keep foraging!', '🌰');
    Haptics.warn();
    return false;
  }

  void _done(String text, String icon, DioramaEventKind kind, [RoomKey? room]) {
    _emit(kind, room);
    _banner(text, icon);
    Haptics.success();
    _rewards.sfx(Sfx.plink);
  }

  // ----------------------------------------------------------- Hearth
  /// Adds [hours] of burn time (capped at the Hearth's capacity).
  bool fuelHearth(int hours) {
    final now = _now;
    final until = ColonyMath.refuel(_colony, now, hours);
    if (until == null) {
      _banner('The Hearth is already stoked to the brim.', '🔥');
      Haptics.tap();
      return false;
    }
    final cost = ColonyMath.fuelCost(_colony, now, until);
    if (!_pay('Hearth fuel', acorns: cost)) return false;
    final wasDark = !_colony.isLit(now);
    _state.update((c) => c.copyWith(hearthFuelUntil: until));
    _done(wasDark ? 'The Hearth roars back to life — lights on, everyone up!' : 'Hearth fueled (-$cost Acorns).',
        '🔥', DioramaEventKind.hearthFuel, RoomKey.hearth);
    return true;
  }

  /// Tops the Hearth up to its full burn capacity.
  bool fillHearth() => fuelHearth(_colony.hearthCapacity.inHours);

  bool overdrive(int hours) {
    if (!_pay('Hearth Overdrive', acorns: ColonyEconomy.overdriveAcorns(hours))) return false;
    _state.update((c) => c.copyWith(overdriveUntil: ColonyMath.extend(c.overdriveUntil, _now, Duration(hours: hours))));
    _done('Hearth Overdrive! Lights blaze for ${hours}h, fuel or not.', '⚡', DioramaEventKind.hearthFuel, RoomKey.hearth);
    return true;
  }

  // ------------------------------------------------- Golden Acorn upgrades
  bool upgradeGranary() {
    final s = _ref.read(settingsProvider);
    if (s.granaryLevel >= ColonyEconomy.granaryMax) return false;
    final next = s.granaryLevel + 1;
    if (!_pay('Granary storage', golden: ColonyEconomy.granaryGolden[next - 1])) return false;
    _settings.update((x) => x.copyWith(granaryLevel: next).settleOverflow());
    _done('Granary expanded to ${ColonyEconomy.granaryCap(next)} Acorns!', '🏚️', DioramaEventKind.upgrade);
    return true;
  }

  bool upgradeHearth() {
    final level = _colony.hearthLevel;
    if (level >= ColonyEconomy.hearthMax) return false;
    if (!_pay('Hearth burn time', golden: ColonyEconomy.hearthGolden[level])) return false;
    _state.update((c) => c.copyWith(hearthLevel: level + 1));
    final hours = ColonyEconomy.hearthBurnHours[level];
    _done('The Hearth now burns up to ${hours >= 72 ? '3 full days' : '${hours}h'} per fill!', '🔥',
        DioramaEventKind.upgrade, RoomKey.hearth);
    return true;
  }

  bool addPedestal() {
    final extra = _colony.extraPedestals;
    if (extra >= ColonyEconomy.maxExtraPedestals) return false;
    if (!_pay('A terrace pedestal', golden: ColonyEconomy.pedestalGolden[extra])) return false;
    _state.update((c) => c.copyWith(extraPedestals: extra + 1));
    _done('A new stone pedestal rises on the Canopy Terrace!', '🗿', DioramaEventKind.upgrade, RoomKey.treasury);
    return true;
  }

  bool startFestival() {
    if (!_pay('A Colony Festival', golden: ColonyEconomy.festivalGolden)) return false;
    _state.update((c) => c.copyWith(
        festivalUntil: ColonyMath.extend(c.festivalUntil, _now, const Duration(hours: ColonyEconomy.festivalHours))));
    _done('Colony Festival! 24h of confetti, peak disco and rare visitors.', '🎉', DioramaEventKind.festival);
    return true;
  }

  // ------------------------------------------------------- Acorn sinks
  bool rushHour() {
    if (!_pay('Rush hour', acorns: ColonyEconomy.rushHourAcorns)) return false;
    _state.update((c) => c.copyWith(
        rushHourUntil: ColonyMath.extend(c.rushHourUntil, _now, const Duration(hours: ColonyEconomy.rushHourHours))));
    _done('Rush hour! Worker squirrels flood the DC Metro platform.', '🚇', DioramaEventKind.metroRide, RoomKey.metro);
    return true;
  }

  bool hireSecondSquad() {
    if (!_pay('A second squad', acorns: ColonyEconomy.secondSquadAcorns)) return false;
    _state.update((c) => c.copyWith(
        secondSquadUntil:
            ColonyMath.extend(c.secondSquadUntil, _now, const Duration(hours: ColonyEconomy.secondSquadHours))));
    _done('A second scavenger squad joins the burrow for 24h!', '🎒', DioramaEventKind.upgrade, RoomKey.burrow);
    return true;
  }

  bool dispatch(ExpeditionRoute route) {
    final now = _now;
    final out = _ref.read(expeditionsProvider.notifier).active.length;
    if (out >= _colony.squads(now)) {
      _banner('Every squad is already out foraging.', '🎒');
      Haptics.warn();
      return false;
    }
    if (!_pay(route.label, acorns: route.acorns)) return false;
    _ref.read(expeditionsProvider.notifier).dispatch(route, now);
    _done('Squad away on the ${route.label} (${route.hours}h)!', '🎒', DioramaEventKind.expeditionStart, RoomKey.burrow);
    return true;
  }

  bool buyLure(LureKind lure) {
    if (!_pay(lure.label, acorns: lure.acorns)) return false;
    final now = _now;
    _settleBirds(now);
    final current = _colony.lureOn(now);
    final ends = lure.endsAt(now);
    final until = current == lure && _colony.lureUntil!.isAfter(now) && lure != LureKind.moonOil
        ? _colony.lureUntil!.add(ends.difference(now))
        : ends;
    _state.update((c) => c.copyWith(lure: lure, lureUntil: until));
    _done('${lure.label} set out at the feeder (${lure.durationLabel}).', '🪺', DioramaEventKind.lure, RoomKey.birdFeeder);
    return true;
  }

  bool pourSeed(SeedKind seed) {
    final bags = _ref.read(seedBagsProvider.notifier);
    if ((_ref.read(seedBagsProvider)[seed] ?? 0) <= 0) return false;
    final now = _now;
    _settleBirds(now);
    final until = ColonyMath.pour(_colony, now, seed);
    if (until == null) {
      _banner('The feeder is already full of ${seed.label}.', '🪺');
      Haptics.tap();
      return false;
    }
    bags.add(seed, -1);
    _state.update((c) => c.copyWith(feederSeed: seed, feederUntil: until, birdCheckedAt: now));
    _done('Poured a bag of ${seed.label}. Visitors incoming!', '🌻', DioramaEventKind.pourSeed, RoomKey.birdFeeder);
    return true;
  }

  /// Taps the floating canopy bubbles into the Granary. Returns Acorns won.
  int harvestBubbles() {
    tick();
    final n = _colony.bubbles;
    if (n <= 0) return 0;
    final acorns = n * ColonyEconomy.acornsPerBubble;
    _state.update((c) => c.copyWith(collectorProgress: (c.collectorProgress - n / ColonyEconomy.bubbleCount).clamp(0.0, 1.0)));
    _settings.addAcorns(acorns);
    final overflow = _ref.read(settingsProvider).acornsOverflow;
    _done('Harvested $n wild acorn bubble${n == 1 ? '' : 's'}: +$acorns Acorns into the Granary'
        '${overflow > 0 ? ' ($overflow waiting outside)' : ''}.', '🌰', DioramaEventKind.harvest);
    return acorns;
  }

  // ------------------------------------------------------- Colony clock
  /// Settles everything since the last check: feeder visits, the canopy
  /// collector and returning squads. Runs every 20s and on app resume.
  void tick() {
    final now = _now;
    _settleBirds(now);
    final c = _colony;
    final from = c.collectorCheckedAt ?? now;
    if (now.isAfter(from) || c.collectorCheckedAt == null) {
      _state.update((x) => x.copyWith(
          collectorProgress: ColonyMath.advanceCollector(x.collectorProgress, from, now, x.litUntil),
          collectorCheckedAt: now));
    }
    final back = _ref.read(expeditionsProvider.notifier).collectFinished(now);
    if (back.isEmpty) return;
    final bags = _ref.read(seedBagsProvider.notifier);
    for (final e in back) {
      bags.add(e.route.seed, 1);
    }
    final last = back.last;
    _done(
        back.length == 1
            ? 'Scavengers are home from the ${last.route.label} with a bag of ${last.route.seed.label}!'
            : '${back.length} squads came home with seed bags, ready to pour!',
        '🎒',
        DioramaEventKind.expeditionReturn,
        RoomKey.burrow);
  }

  void _settleBirds(DateTime now) {
    final c = _colony;
    final seed = c.feederSeed;
    final from = c.birdCheckedAt;
    if (seed == null || from == null || c.feederUntil == null || !now.isAfter(from)) {
      if (from == null) _state.update((x) => x.copyWith(birdCheckedAt: now));
      return;
    }
    final visits = BirdSim.simulate(
      from: from,
      to: now,
      seed: seed,
      feederUntil: c.feederUntil!,
      lure: c.lure,
      lureUntil: c.lureUntil,
      festivalUntil: c.festivalUntil,
    );
    final unlocked = _ref.read(birdLogProvider.notifier).record(visits);
    _state.update((x) => x.copyWith(
          birdCheckedAt: now,
          recent: [...visits.reversed.take(6), ...x.recent].take(6).toList(),
        ));
    for (final s in unlocked) {
      _banner('Keepsake unlocked: ${s.keepsake} — ${s.label} visited 100 times!', '🪶');
      Haptics.celebrate();
    }
  }
}

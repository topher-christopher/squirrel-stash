import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../models/impulse.dart';
import '../models/room.dart';
import 'art/asset_manifest.dart';
import 'art/palette.dart';
import 'art/squirrel_painter.dart';
import 'components/canopy_layer.dart';
import 'components/canopy_residents.dart';
import 'components/catwalks_layer.dart';
import 'components/colony_life_layer.dart';
import 'components/fx_layer.dart';
import 'components/pulley_lift.dart';
import 'components/rooms_layer.dart';
import 'components/sky_earth_layer.dart';
import 'components/trunk_layer.dart';
import 'components/weather_layer.dart';
import 'diorama_event.dart';
import 'diorama_snapshot.dart';
import 'layout.dart';

/// The 60fps Great Oak: one continuous cutaway from the sunlit canopy
/// through the lively trunk down to the root tunnels, in a 600 × 1150 world.
class StashDioramaGame extends FlameGame {
  StashDioramaGame({TreeSnapshot initial = const TreeSnapshot()}) : _snapshot = initial {
    _wake = initial.lit ? 1 : 0;
  }

  TreeSnapshot _snapshot;
  TreeSnapshot get snapshot => _snapshot;

  /// Seconds since the tree started (drives ambient motion: water, flames).
  double time = 0;

  /// Colony "work clock": advances only while the Hearth is lit, so busy
  /// squirrels freeze (asleep) in place when the tree goes dark.
  double activity = 0;
  double _wake = 1;

  /// 1 while the colony is awake, easing to 0 as it falls asleep.
  double get wake => _wake;

  /// 0 at the zoomed-out panorama → 1 above 1.3x zoom; fades in extra
  /// interior animations. Set by the Flutter stage, not Riverpod.
  double detail = 0;

  /// Custom PNG drop-ins (empty until loaded → procedural art).
  StashAssetManifest art = StashAssetManifest.empty;

  final FxLayer fx = FxLayer();
  final PulleyLift lift = PulleyLift();
  final Map<String, double> _pokes = {};
  final Map<String, double> _marks = {};

  @override
  Color backgroundColor() => const Color(0xFF1E1007);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
    await world.addAll([
      SkyEarthLayer(),
      CanopyLayer(),
      TrunkLayer(),
      RoomsLayer(),
      CatwalksLayer(),
      lift,
      ColonyLifeLayer(),
      CanopyResidents(),
      WeatherLayer(),
      fx,
    ]);
    unawaited(StashAssetManifest.load().then((loaded) => art = loaded));
  }

  @override
  void update(double dt) {
    // Clamp long frames (resume from background) so nothing teleports.
    final step = math.min(dt, 1 / 20);
    time += step;
    _wake += ((_snapshot.lit ? 1.0 : 0.0) - _wake) * math.min(1.0, step * 1.6);
    activity += step * _wake;
    super.update(step);
  }

  @override
  void render(Canvas canvas) {
    // Global squirrel moods for this frame only (reset so Flutter-side
    // painters like the logbook portraits are unaffected).
    SquirrelPainter.sleepAll = _wake < 0.5;
    SquirrelPainter.winterAll = _snapshot.winter;
    SquirrelPainter.clock = time;
    super.render(canvas);
    SquirrelPainter.sleepAll = false;
    SquirrelPainter.winterAll = false;
  }

  void applySnapshot(TreeSnapshot next) => _snapshot = next;

  /// Damped 0→1→0 wobble for a recently tapped room or critter.
  double pokeAmount(String key) {
    final at = _pokes[key];
    if (at == null) return 0;
    final e = (time - at) / 0.55;
    if (e >= 1) return 0;
    return math.sin(e * math.pi * 2) * (1 - e) * 0.9;
  }

  /// Seconds since a one-shot story beat (scavenger departures, returns,
  /// rope hauls…), or a huge number if it never happened.
  double since(String key) {
    final at = _marks[key];
    return at == null ? 1e9 : time - at;
  }

  Offset _roomTop(RoomKey room) => TreeLayout.room(room).topCenter.translate(0, 30);

  void handleEvent(DioramaEvent event) {
    final room = event.room;
    switch (event.kind) {
      case DioramaEventKind.poke:
        final key = event.pokeKey;
        if (key != null) _pokes[key] = time;
      case DioramaEventKind.payday:
        fx.burst(TreeLayout.room(RoomKey.treasury).center,
            count: 18, colors: const [Pal.gold, Pal.acorn, Color(0xFFFFFFFF)]);
      case DioramaEventKind.impulseWin:
        final color = switch (event.mode) {
          ImpulseMode.skip => Pal.sandSkip,
          ImpulseMode.downsize => Pal.sandDownsize,
          _ => Pal.sandDiy,
        };
        _pokes[RoomKey.lab.name] = time;
        fx.burst(_roomTop(RoomKey.lab), count: 16, colors: [color, Pal.gold, const Color(0xFFFFFFFF)], speed: 70);
      case DioramaEventKind.allocate:
        lift.dropAcorn(room ?? RoomKey.goals);
      case DioramaEventKind.reclaim:
        fx.confetti(TreeLayout.room(RoomKey.trophyHall).center);
        fx.burst(TreeLayout.room(RoomKey.trophyHall).center,
            count: 26, colors: const [Pal.gold, Pal.brass, Color(0xFFFFFFFF)], speed: 110);
      case DioramaEventKind.hootGift:
        _pokes[DioramaEvent.hoot] = time;
        fx.leaves(TreeLayout.hoot, count: 14);
      case DioramaEventKind.focusComplete:
        fx.leaves(TreeLayout.room(RoomKey.treasury).center, count: 22);
      case DioramaEventKind.upgrade:
        final at = room == null ? const Offset(300, 140) : TreeLayout.room(room).center;
        fx.burst(at, count: 24, colors: const [Pal.gold, Color(0xFF38BDF8), Color(0xFF4ADE80)], speed: 120);
      case DioramaEventKind.metroRide:
        _pokes[RoomKey.metro.name] = time;
        fx.burst(_roomTop(RoomKey.metro), count: 10, colors: const [Color(0xFFFDE68A), Color(0xFFFFFFFF)], speed: 60);
      case DioramaEventKind.kitchen:
        _pokes[RoomKey.kitchen.name] = time;
        fx.burst(_roomTop(RoomKey.kitchen), count: 12, colors: const [Color(0xFFFFFFFF), Color(0xFFF97316)], speed: 50);
      case DioramaEventKind.trophy:
        fx.burst(TreeLayout.room(RoomKey.trophyHall).center,
            count: 20, colors: const [Pal.gold, Color(0xFFFFFFFF)], speed: 90);
      case DioramaEventKind.harvest:
        for (final p in TreeLayout.bubbleSpots) {
          fx.burst(p, count: 8, colors: const [Pal.acorn, Pal.gold, Color(0xFFE0F2FE)], speed: 60);
        }
        fx.leaves(const Offset(300, 60), count: 10);
      case DioramaEventKind.expeditionStart:
        _marks['burrowOut'] = time;
      case DioramaEventKind.expeditionReturn:
        _marks['burrowBack'] = time;
        fx.burst(TreeLayout.burrowHole.translate(30, -6), count: 10,
            colors: const [Color(0xFFD9B26F), Color(0xFFFFFFFF)], speed: 50);
      case DioramaEventKind.pourSeed:
        _marks['ropeHaul'] = time;
        fx.burst(TreeLayout.feederHook.translate(0, 44), count: 14,
            colors: const [Color(0xFFFDE68A), Color(0xFFD9B26F), Color(0xFFFFFFFF)], speed: 55);
      case DioramaEventKind.hearthFuel:
        _marks['hearth'] = time;
        fx.burst(TreeLayout.room(RoomKey.hearth).center, count: 20,
            colors: const [Color(0xFFFB923C), Color(0xFFFDE047), Color(0xFFFFFFFF)], speed: 80);
      case DioramaEventKind.festival:
        for (final p in const [Offset(300, 120), Offset(200, 420), Offset(420, 600), Offset(300, 760)]) {
          fx.confetti(p);
        }
      case DioramaEventKind.lure:
        fx.burst(TreeLayout.feederHook.translate(0, 50), count: 14,
            colors: const [Color(0xFFF472B6), Color(0xFFFDE68A), Color(0xFFA78BFA)], speed: 60);
    }
  }
}

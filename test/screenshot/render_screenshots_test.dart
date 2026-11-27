import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:squirrel_stash/app.dart';
import 'package:squirrel_stash/database/seed_data.dart';
import 'package:squirrel_stash/models/room.dart';
import 'package:squirrel_stash/models/stash_snapshot.dart';
import 'package:squirrel_stash/providers/rooms_provider.dart';
import 'package:squirrel_stash/providers/ui_provider.dart';
import 'package:squirrel_stash/ui/drawers/drawers.dart';

import '../helpers/test_harness.dart';

/// Renders real frames of the app (Flame Great Oak + Flutter UI) to
/// docs/screenshots/*.png for visual review. Not a golden comparison, so
/// it never fails on pixel differences between machines.
///
///   flutter test test/screenshot
const _outDir = 'docs/screenshots';

Future<void> _loadFont(String family, String path) async {
  final file = File(path);
  if (!file.existsSync()) return;
  final bytes = file.readAsBytesSync();
  final loader = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _loadFont('Fredoka', 'assets/fonts/Fredoka-Variable.ttf');
    await _loadFont('Nunito', 'assets/fonts/Nunito-Variable.ttf');
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      await _loadFont('MaterialIcons', '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    }
    await _loadFont('Apple Color Emoji', '/System/Library/Fonts/Apple Color Emoji.ttc');
    Directory(_outDir).createSync(recursive: true);
    for (final f in Directory(_outDir).listSync().whereType<File>()) {
      if (f.path.endsWith('.png')) f.deleteSync();
    }
  });

  Future<void> shoot(
    WidgetTester tester,
    String name,
    StashSnapshot snapshot, {
    Future<void> Function(WidgetTester tester, BuildContext context, ProviderContainer c)? interact,
    int settle = 40,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final harness = TestHarness(snapshot);
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: ProviderScope(overrides: harness.overrides, child: const SquirrelStashApp()),
    ));
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    if (interact != null) {
      final context = tester.element(find.byType(Scaffold).first);
      await interact(tester, context, ProviderScope.containerOf(context));
      for (var i = 0; i < settle; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_outDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
    await tester.pump(const Duration(seconds: 6));
  }

  final demo = SeedData.demo(DateTime.now());

  testWidgets('great oak panorama (1.0x, icons only)', (t) => shoot(t, '01_great_oak', demo));

  testWidgets('max unlocked preview', (t) => shoot(t, '02_max_unlocked', demo,
      interact: (tester, context, c) async => c.read(roomsProvider.notifier).setAll(3)));

  testWidgets('frostline', (t) => shoot(t, '03_frost', demoWith({'checking_cents': '600000'})));

  testWidgets('cozy zen', (t) => shoot(t, '04_cozy_zen', demoWith({'zen_mode': '1'})));

  testWidgets('zoomed into the trunk (LOD labels)', (t) => shoot(t, '05_zoom_trunk', demo,
      interact: (tester, context, c) async => c.read(uiProvider.notifier).focusCamera(RoomKey.trophyHall)));

  testWidgets('zoomed into the roots', (t) => shoot(t, '06_zoom_roots', demo,
      interact: (tester, context, c) async => c.read(uiProvider.notifier).focusCamera(RoomKey.crypto)));

  // Drawer futures complete only when the sheet closes, so don't await them.
  for (final (i, room) in const [
    (7, RoomKey.lab),
    (8, RoomKey.billVault),
    (9, RoomKey.trophyHall),
    (10, RoomKey.kitchen),
    (11, RoomKey.metro),
    (12, RoomKey.brokerage),
    (13, RoomKey.outfitter),
  ]) {
    testWidgets('${room.name} drawer', (t) => shoot(t, '${i.toString().padLeft(2, '0')}_${room.name}_drawer', demo,
        interact: (tester, context, c) async => unawaited(Drawers.room(context, room))));
  }

  testWidgets('lab drawer expanded', (t) => shoot(t, '15_lab_drawer_expanded', demo,
      interact: (tester, context, c) async {
        unawaited(Drawers.room(context, RoomKey.lab));
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.drag(find.text('Foraging & Willpower Lab'), const Offset(0, -600));
      }));

  testWidgets('colony shop', (t) => shoot(t, '14_colony_shop', demo,
      interact: (tester, context, c) async => unawaited(Drawers.upgrades(context))));

  testWidgets('settings drawer (backup & restore)', (t) => shoot(t, '16_settings_drawer', demo,
      interact: (tester, context, c) async => unawaited(Drawers.settings(context))));

  // v1.2 colony
  for (final (i, room) in const [
    (17, RoomKey.birdFeeder),
    (18, RoomKey.burrow),
    (19, RoomKey.hearth),
  ]) {
    testWidgets('${room.name} drawer', (t) => shoot(t, '${i}_${room.name}_drawer', demo,
        interact: (tester, context, c) async => unawaited(Drawers.room(context, room))));
  }

  testWidgets('bird feeder drawer scrolled to the logbook', (t) => shoot(t, '20_logbook', demo,
      interact: (tester, context, c) async {
        unawaited(Drawers.room(context, RoomKey.birdFeeder));
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.drag(find.text('Canopy Bird Feeder'), const Offset(0, -600));
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.scrollUntilVisible(find.textContaining('Keepsakes:'), 300,
            scrollable: find.byType(Scrollable).last);
      }));

  final past = DateTime.now().subtract(const Duration(hours: 2)).toIso8601String();
  testWidgets('hearth out: twilight dim, colony asleep', (t) => shoot(t, '21_hearth_dark', demoWith({'hearth_fuel_until': past})));

  for (final (name, room) in const [
    ('22_zoom_canopy', RoomKey.birdFeeder),
    ('23_zoom_outfitter', RoomKey.outfitter),
    ('24_zoom_burrow', RoomKey.burrow),
    ('25_zoom_metro', RoomKey.metro),
  ]) {
    testWidgets(name, (t) => shoot(t, name, demo,
        interact: (tester, context, c) async => c.read(uiProvider.notifier).focusCamera(room)));
  }

  testWidgets('bill vault low water', (t) => shoot(t, '26_vault_low_water', demoWith({'checking_cents': '1700000'}),
      interact: (tester, context, c) async => c.read(uiProvider.notifier).focusCamera(RoomKey.billVault)));

  testWidgets('bill vault mid water', (t) => shoot(t, '27_vault_mid_water', demoWith({'checking_cents': '1300000'}),
      interact: (tester, context, c) async => c.read(uiProvider.notifier).focusCamera(RoomKey.billVault)));

  testWidgets('max themes everywhere', (t) => shoot(t, '28_zoom_trunk_max', demo,
      interact: (tester, context, c) async {
        c.read(roomsProvider.notifier).setAll(3);
        c.read(uiProvider.notifier).focusCamera(RoomKey.kitchen);
      }));
}

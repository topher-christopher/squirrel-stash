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
import 'package:squirrel_stash/models/decor.dart';
import 'package:squirrel_stash/models/stash_snapshot.dart';
import 'package:squirrel_stash/ui/drawers/drawers.dart';

import '../helpers/test_harness.dart';

/// Renders real frames of the app (Flame diorama + Flutter UI) to
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

StashSnapshot _withDecor(StashSnapshot s, Set<DecorKey> active) => StashSnapshot(
      settings: s.settings,
      bills: s.bills,
      goals: s.goals,
      trophies: s.trophies,
      chips: s.chips,
      logs: s.logs,
      holdings: s.holdings,
      decor: [for (final k in DecorKey.values) DecorItemState(key: k, owned: true, enabled: active.contains(k))],
    );

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
  });

  Future<void> shoot(
    WidgetTester tester,
    String name,
    StashSnapshot snapshot, {
    Future<void> Function(WidgetTester tester, BuildContext context)? interact,
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
      await interact(tester, tester.element(find.byType(Scaffold).first));
      for (var i = 0; i < 40; i++) {
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

  testWidgets('meadow (default demo)', (t) => shoot(t, '01_meadow', SeedData.demo(DateTime.now())));

  testWidgets('frostline', (t) => shoot(t, '02_frost', demoWith({'checking_cents': '470000'})));

  testWidgets('alpine twilight', (t) => shoot(t, '03_alpine_twilight',
      _withDecor(demoWith({'window_scene': 'alpine'}), {DecorKey.twilightSky, DecorKey.fairyLights, DecorKey.hats, DecorKey.espressoBar})));

  testWidgets('harbor', (t) => shoot(t, '04_harbor', demoWith({'window_scene': 'harbor'})));

  testWidgets('zen mode', (t) => shoot(t, '05_zen', demoWith({'zen_mode': '1'})));

  // Drawer futures complete only when the sheet closes, so don't await them.
  testWidgets('lab drawer', (t) => shoot(t, '06_lab_drawer', SeedData.demo(DateTime.now()),
      interact: (tester, context) async => unawaited(Drawers.lab(context))));

  testWidgets('focus drawer', (t) => shoot(t, '07_focus_drawer', SeedData.demo(DateTime.now()),
      interact: (tester, context) async => unawaited(Drawers.focus(context))));

  testWidgets('goal detail drawer', (t) => shoot(t, '08_goal_drawer', SeedData.demo(DateTime.now()),
      interact: (tester, context) async => unawaited(Drawers.goal(context, 'g1'))));
}

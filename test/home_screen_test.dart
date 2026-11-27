import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:squirrel_stash/app.dart';
import 'package:squirrel_stash/ui/diorama/diorama_stage.dart';

import 'helpers/test_harness.dart';

Future<void> _pumpFrames(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('study renders HUD, diorama plaques and responds to taps', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final harness = TestHarness();
    await tester.pumpWidget(ProviderScope(overrides: harness.overrides, child: const SquirrelStashApp()));
    await _pumpFrames(tester);

    expect(find.byType(DioramaStage), findsOneWidget);
    expect(find.text('FREE CASH'), findsOneWidget);
    expect(find.text(r'$2,050'), findsWidgets);
    expect(find.text('TREAT YOURSELF!'), findsOneWidget);
    expect(find.textContaining('Japan Trip'), findsOneWidget);

    await tester.tap(find.text('+Payday'));
    await _pumpFrames(tester, 50);
    expect(find.textContaining('Payday delivery!'), findsOneWidget);
    expect(find.text(r'$3,250'), findsWidgets);

    // Open the Foraging & Alchemy Lab from the silo plaque.
    await tester.tap(find.text('🧪 IMPULSE SAVED'));
    await _pumpFrames(tester, 40);
    expect(find.text('Foraging & Alchemy Lab'), findsOneWidget);
    // First match is the 1-tap chip (the label also appears under Recent Wins).
    await tester.tap(find.text('Skipped Grocery Ice Cream').first);
    await _pumpFrames(tester, 10);
    expect(find.text(r'+$7 Saved!'), findsOneWidget);

    // Let banners / reactions time out so no timers are left pending.
    await tester.pump(const Duration(seconds: 6));
  });
}

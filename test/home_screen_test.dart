import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:squirrel_stash/app.dart';
import 'package:squirrel_stash/ui/diorama/tree_stage.dart';
import 'package:squirrel_stash/ui/drawers/half_sheet.dart';
import 'package:squirrel_stash/ui/drawers/room_drawer.dart';

import 'helpers/test_harness.dart';

Future<void> _pumpFrames(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('Great Oak renders the HUD, opens a room drawer and swipes rooms', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final harness = TestHarness();
    await tester.pumpWidget(ProviderScope(overrides: harness.overrides, child: const SquirrelStashApp()));
    await _pumpFrames(tester);

    expect(find.byType(TreeStage), findsOneWidget);
    expect(find.text('FREE CASH'), findsOneWidget);
    expect(find.text(r'$3,600'), findsWidgets);
    expect(find.text('+Payday'), findsOneWidget);
    expect(find.text('Starter'), findsOneWidget);

    await tester.tap(find.text('+Payday'));
    await _pumpFrames(tester, 50);
    expect(find.textContaining('Payday delivery!'), findsOneWidget);
    expect(find.text(r'$4,800'), findsWidgets);

    // Tap the Foraging Lab room: the camera glides there and its drawer opens.
    await tester.tap(find.bySemanticsLabel('Foraging & Willpower Lab'));
    await _pumpFrames(tester, 60);
    expect(find.byType(RoomDrawer), findsOneWidget);
    expect(find.text('Smart Downsize'), findsOneWidget);

    // It opens at half height; dragging the header up fills the screen and
    // dragging it back down returns to half.
    final screenH = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final half = tester.getSize(find.byType(HalfSheet)).height;
    expect(half, lessThan(screenH * 0.6));
    await tester.drag(find.text('Foraging & Willpower Lab'), const Offset(0, -500));
    await _pumpFrames(tester, 30);
    expect(tester.getSize(find.byType(HalfSheet)).height, greaterThan(screenH * 0.85));
    await tester.drag(find.text('Foraging & Willpower Lab'), const Offset(0, 300));
    await _pumpFrames(tester, 30);
    expect(tester.getSize(find.byType(HalfSheet)).height, closeTo(half, 2));
    await tester.ensureVisible(find.text('Skipped Grocery Ice Cream'));
    await _pumpFrames(tester, 20);
    await tester.tap(find.text('Skipped Grocery Ice Cream'));
    await _pumpFrames(tester, 10);
    expect(find.text(r'+$7 Saved! +70'), findsOneWidget);

    // Swipe left to the next room (the Ratatouille Kitchen) without closing the drawer.
    await tester.dragFrom(tester.getTopLeft(find.byType(PageView)) + const Offset(300, 12), const Offset(-260, 0));
    await _pumpFrames(tester, 60);
    expect(find.text('Home-Cooked Meals'), findsOneWidget);

    // Let banners / reactions time out so no timers are left pending.
    await tester.pump(const Duration(seconds: 6));
  });
}

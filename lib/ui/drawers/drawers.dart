import 'package:material_ui/material_ui.dart';

import '../../models/room.dart';
import 'decor_shop.dart';
import 'drawer_shell.dart';
import 'focus_drawer.dart';
import 'goal_detail_drawer.dart';
import 'new_goal_drawer.dart';
import 'room_drawer.dart';
import 'settings_drawer.dart';

/// One entry point per slide-up drawer, so tree rooms and the HUD never
/// need to know drawer internals.
abstract final class Drawers {
  /// The swipeable room drawer, opened on [room].
  static Future<void> room(BuildContext c, RoomKey room) =>
      showStashDrawer(c, (_) => RoomDrawer(initial: room), lightBarrier: true, enableDrag: false);

  static Future<void> focus(BuildContext c) => showStashDrawer(c, (_) => const FocusDrawer());
  static Future<void> newGoal(BuildContext c) => showStashDrawer(c, (_) => const NewGoalDrawer());
  static Future<void> settings(BuildContext c) => showStashDrawer(c, (_) => const SettingsDrawer());
  static Future<void> upgrades(BuildContext c) => showStashDrawer(c, (_) => const UpgradesDrawer());

  static Future<void> goal(BuildContext c, String goalId) =>
      showStashDrawer(c, (_) => GoalDetailDrawer(goalId: goalId));
}

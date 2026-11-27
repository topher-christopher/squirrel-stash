import 'package:material_ui/material_ui.dart';

import '../../models/holding.dart';
import 'bills_drawer.dart';
import 'cash_drawer.dart';
import 'drawer_shell.dart';
import 'focus_drawer.dart';
import 'goal_detail_drawer.dart';
import 'lab_drawer.dart';
import 'new_goal_drawer.dart';
import 'reserve_drawer.dart';
import 'settings_drawer.dart';
import 'trophies_drawer.dart';

/// One entry point per slide-up drawer, so diorama hotspots and the HUD
/// never need to know drawer internals.
abstract final class Drawers {
  static Future<void> cash(BuildContext c) => showStashDrawer(c, (_) => const CashDrawer());
  static Future<void> bills(BuildContext c) => showStashDrawer(c, (_) => const BillsDrawer());
  static Future<void> lab(BuildContext c) => showStashDrawer(c, (_) => const LabDrawer());
  static Future<void> focus(BuildContext c) => showStashDrawer(c, (_) => const FocusDrawer());
  static Future<void> trophies(BuildContext c) => showStashDrawer(c, (_) => const TrophiesDrawer());
  static Future<void> newGoal(BuildContext c) => showStashDrawer(c, (_) => const NewGoalDrawer());
  static Future<void> settings(BuildContext c) => showStashDrawer(c, (_) => const SettingsDrawer());

  static Future<void> goal(BuildContext c, String goalId) =>
      showStashDrawer(c, (_) => GoalDetailDrawer(goalId: goalId));

  static Future<void> reserve(BuildContext c, ReserveKind kind) =>
      showStashDrawer(c, (_) => ReserveDrawer(kind: kind));
}

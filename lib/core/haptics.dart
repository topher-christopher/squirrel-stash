import 'package:flutter/services.dart';

/// Tactile feedback vocabulary. Disabled globally from Settings.
abstract final class Haptics {
  static bool enabled = true;

  /// Chips, toggles, pegs.
  static void tap() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// Opening drawers, tapping diorama objects.
  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Logged a win, allocated acorns, payday.
  static void success() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  /// Not enough Acorns, nothing to sweep.
  static void warn() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  /// Reclaim & Upgrade, Focus Shift complete: a little drum roll.
  static Future<void> celebrate() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 110));
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.lightImpact();
  }
}

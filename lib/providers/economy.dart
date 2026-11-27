import 'dart:math' as math;

/// The unified Acorn & Golden Acorn economy (cosmetic currencies only —
/// never mixed with real USD).
abstract final class Economy {
  /// 10 Acorns per $1 of willpower saved.
  static int acornsForSavings(int cents) => cents <= 0 ? 0 : cents ~/ 10;

  /// One Golden Acorn per $100 of cumulative willpower savings.
  static int goldenMilestones(int lifetimeSavedCents) =>
      lifetimeSavedCents <= 0 ? 0 : lifetimeSavedCents ~/ 10000;

  /// Acorns for a finished Focus Shift: max(10, minutes × 2 × hearth).
  static int focusReward({required int totalSeconds, required int warmth}) {
    final mult = warmth >= 3 ? 1.5 : (warmth == 2 ? 1.25 : 1.0);
    return math.max(10, (totalSeconds / 60 * 2 * mult).round());
  }

  static const goalReclaimAcorns = 250;
  static const goalReclaimGolden = 1;
  static const hootGiftAcorns = 50;
}

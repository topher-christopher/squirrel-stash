import 'dart:ui' show Color;

enum TreatLevel { green, yellow, red }

/// The Green / Yellow / Red "Treat Yourself!" lantern verdict.
class TreatStatus {
  const TreatStatus({
    required this.level,
    required this.label,
    required this.sublabel,
    required this.badge,
    required this.hint,
    required this.background,
    required this.dot,
    required this.border,
  });

  final TreatLevel level;

  /// `TREAT YOURSELF!` / `MINDFUL PACE` / `FROST ALERT`
  final String label;
  final String sublabel;

  /// `GREENLIGHT` / `PACING` / `FROST`
  final String badge;

  /// Short desk-plaque hint.
  final String hint;
  final Color background;
  final Color dot;
  final Color border;

  static const frostAlert = TreatStatus(
    level: TreatLevel.red,
    label: 'FROST ALERT',
    sublabel: 'Shelter acorns for upcoming bills first',
    badge: 'FROST',
    hint: 'Save for bills',
    background: Color(0xFF7F1D1D),
    dot: Color(0xFFF87171),
    border: Color(0xFFFCA5A5),
  );

  static const mindfulPace = TreatStatus(
    level: TreatLevel.yellow,
    label: 'MINDFUL PACE',
    sublabel: 'Bills safe • Goals still warming up',
    badge: 'PACING',
    hint: 'Goals warming up',
    background: Color(0xFF854D0E),
    dot: Color(0xFFFACC15),
    border: Color(0xFFFDE047),
  );

  static TreatStatus greenlight({required bool hasGoals}) => TreatStatus(
        level: TreatLevel.green,
        label: 'TREAT YOURSELF!',
        sublabel: hasGoals
            ? 'Bills safe & goals on track — guilt-free treat OK!'
            : 'No active goals & bills covered — enjoy guilt-free!',
        badge: 'GREENLIGHT',
        hint: 'Guilt-free buy OK!',
        background: const Color(0xFF14532D),
        dot: const Color(0xFF4ADE80),
        border: const Color(0xFF86EFAC),
      );
}

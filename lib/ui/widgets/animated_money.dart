import 'package:material_ui/material_ui.dart';

import '../../core/money.dart';

/// Money text that counts smoothly to its new value (payday tick-ups).
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney(
    this.cents, {
    super.key,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.exact = false,
  });

  final int cents;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  /// Show cents (`$2.50`) instead of whole dollars.
  final bool exact;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: cents.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final v = value.round();
        return Text(
          '$prefix${exact ? Money.smart(v) : Money.whole(v)}$suffix',
          style: style,
          maxLines: 1,
          softWrap: false,
        );
      },
    );
  }
}

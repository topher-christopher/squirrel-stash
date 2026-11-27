import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Scales its child down while pressed — the tactile "squish" used by every
/// button in the study.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.onTap, this.onLongPress, this.scale = 0.95});

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 90 : 220),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Rounded, chunky pill button.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.amber,
    this.foreground,
    this.outlined = false,
    this.dense = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color? foreground;
  final bool outlined;
  final bool dense;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = foreground ??
        (outlined ? color : (color.computeLuminance() > 0.45 ? AppColors.night : Colors.white));
    final child = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.45,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: dense || expand ? 10 : 16, vertical: dense ? 8 : 12),
        decoration: BoxDecoration(
          gradient: outlined
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(color, Colors.white, 0.12)!, color],
                ),
          color: outlined ? color.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(dense ? 12 : 15),
          border: Border.all(color: outlined ? color.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.12)),
          boxShadow: outlined
              ? null
              : [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        alignment: expand ? Alignment.center : null,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: AppType.title(dense ? 13 : 14.5, weight: FontWeight.w600, color: fg)),
        ),
      ),
    );
    return PressScale(
      onTap: enabled
          ? () {
              Haptics.tap();
              onPressed!();
            }
          : null,
      child: child,
    );
  }
}

/// Inset card used throughout drawers.
class StashCard extends StatelessWidget {
  const StashCard({super.key, required this.child, this.color, this.border, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final Color? color;
  final Color? border;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? const Color(0xE61C1917),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border ?? AppColors.amber.withValues(alpha: 0.2)),
        ),
        child: child,
      );
}

/// Labeled number tile ("TOTAL BANK  $6,050").
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.color = AppColors.cream, this.highlight = false});

  final String label;
  final Widget value;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) => StashCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        color: highlight ? const Color(0xCC052E16) : null,
        border: highlight ? AppColors.emeraldBright.withValues(alpha: 0.45) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: AppType.label(9.5, color: highlight ? AppColors.emeraldSoft : AppColors.honey.withValues(alpha: 0.75))),
            const SizedBox(height: 4),
            DefaultTextStyle(
              style: AppType.number(17, color: color),
              child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: value),
            ),
          ],
        ),
      );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = AppColors.honey, this.trailing});

  final String text;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Row(children: [
          Expanded(child: Text(text, style: AppType.title(14, color: color))),
          ?trailing,
        ]),
      );
}

/// Single-select row of pills.
class ChoicePills<T> extends StatelessWidget {
  const ChoicePills({super.key, required this.values, required this.selected, required this.label, required this.onSelected, this.color = AppColors.amber});

  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final ValueChanged<T> onSelected;
  final Color color;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in values)
            PressScale(
              onTap: () {
                Haptics.tap();
                onSelected(v);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: v == selected ? color.withValues(alpha: 0.22) : AppColors.barkDeep,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: v == selected ? color : AppColors.amber.withValues(alpha: 0.2)),
                ),
                child: Text(label(v),
                    style: AppType.body(13, weight: FontWeight.w700, color: v == selected ? AppColors.cream : AppColors.stone)),
              ),
            ),
        ],
      );
}

/// Cozy text field.
class StashField extends StatelessWidget {
  const StashField({
    super.key,
    required this.controller,
    this.hint,
    this.money = false,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? hint;
  final bool money;
  final int maxLines;
  final TextAlign textAlign;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        textAlign: textAlign,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        textCapitalization: money ? TextCapitalization.none : TextCapitalization.sentences,
        keyboardType: money ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: AppType.body(14.5, weight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          prefixText: money ? r'$ ' : null,
          prefixStyle: AppType.body(14.5, weight: FontWeight.w800, color: AppColors.honey),
        ),
      );
}

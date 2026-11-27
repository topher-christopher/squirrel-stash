import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Typography helpers. Fredoka (rounded, cozy) is used for titles and
/// numbers; Nunito for body copy and labels. Both are bundled variable
/// fonts, so every style sets the `wght` axis explicitly.
abstract final class AppType {
  static const displayFamily = 'Fredoka';
  static const bodyFamily = 'Nunito';
  static const emojiFallback = <String>[
    'Apple Color Emoji',
    'Noto Color Emoji',
    'Segoe UI Emoji',
  ];

  static List<FontVariation> _wght(FontWeight w) =>
      [FontVariation('wght', w.value.toDouble())];

  /// Rounded display face for headings, plaques and money.
  static TextStyle title(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.cream,
    double? height,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: displayFamily,
        fontFamilyFallback: emojiFallback,
        fontSize: size,
        fontWeight: weight,
        fontVariations: _wght(weight),
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Tabular rounded numerals (timers, balances that tick).
  static TextStyle number(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.cream,
    double? height,
  }) =>
      title(size, weight: weight, color: color, height: height).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Friendly body copy.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.cream,
    double? height,
    FontStyle? style,
  }) =>
      TextStyle(
        fontFamily: bodyFamily,
        fontFamilyFallback: emojiFallback,
        fontSize: size,
        fontWeight: weight,
        fontVariations: _wght(weight),
        color: color,
        height: height,
        fontStyle: style,
      );

  /// Small uppercase tracking label ("FREE CASH", "THIS MONTH").
  static TextStyle label(
    double size, {
    Color color = AppColors.honey,
    FontWeight weight = FontWeight.w800,
    double letterSpacing = 0.9,
  }) =>
      body(size, weight: weight, color: color, height: 1.1)
          .copyWith(letterSpacing: letterSpacing);
}

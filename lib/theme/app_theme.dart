import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Material theme tuned for the warm, dark Hollow Oak Study.
abstract final class AppTheme {
  static ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.amber,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.amberBright,
      onPrimary: AppColors.night,
      secondary: AppColors.emeraldBright,
      surface: AppColors.bark,
      onSurface: AppColors.cream,
      error: AppColors.alert,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.night,
      fontFamily: AppType.bodyFamily,
      fontFamilyFallback: AppType.emojiFallback,
      splashFactory: InkRipple.splashFactory,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.amber.withValues(alpha: 0.28)),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.cream,
        displayColor: AppColors.cream,
        fontFamily: AppType.bodyFamily,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.barkDeep,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: AppType.body(13, color: AppColors.stoneDim),
        labelStyle: AppType.body(13, color: AppColors.honey),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.amberBright, width: 1.4),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.amberBright,
        selectionColor: Color(0x55FBBF24),
        selectionHandleColor: AppColors.amberBright,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.plaque,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.amber.withValues(alpha: 0.35)),
        ),
        titleTextStyle: AppType.title(19, color: AppColors.honey),
        contentTextStyle: AppType.body(14, color: AppColors.cream),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.plaque,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.oak,
        headerForegroundColor: AppColors.cream,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.oakDark,
        contentTextStyle: AppType.body(13),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.oakDark,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: AppType.body(12),
      ),
    );
  }
}

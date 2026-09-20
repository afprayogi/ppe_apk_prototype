import 'package:flutter/material.dart';

abstract final class AppColors {
  static const brand = Color(0xFFFF6B00);
  static const amber = Color(0xFFFFB300);
  static const ink = Color(0xFF0F172A);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, amber],
  );
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFFFF8A3D) : const Color(0xFFA83600),
          onPrimary: isDark ? AppColors.ink : Colors.white,
          surface: isDark ? const Color(0xFF0B1120) : const Color(0xFFF6F7FB),
          surfaceContainerLowest: isDark
              ? const Color(0xFF0E1526)
              : Colors.white,
          surfaceContainerLow: isDark ? const Color(0xFF111A2E) : Colors.white,
          surfaceContainer: isDark
              ? const Color(0xFF16223A)
              : const Color(0xFFEEF0F7),
          surfaceContainerHigh: isDark
              ? const Color(0xFF1E2C48)
              : const Color(0xFFE4E7F1),
          outlineVariant: isDark
              ? const Color(0xFF25334F)
              : const Color(0xFFE1E5EF),
        );

    final base = ThemeData(brightness: brightness).textTheme;
    final text = base
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.1,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.15,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: AppColors.brand.withValues(alpha: 0.45),
          disabledForegroundColor: AppColors.ink.withValues(alpha: 0.6),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary.withValues(alpha: 0.16)
                : scheme.surfaceContainerLow,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurface,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primary.withValues(alpha: 0.16),
        labelStyle: text.labelLarge,
        showCheckmark: false,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// A version of [color] that stays readable (WCAG AA, 4.5:1 by default) as
/// *text* on the current surface, optionally on a translucent [tint] of itself.
///
/// Status colours (green/amber/red) are fine for icons and bars, but too light
/// to read as small text on a light theme, so text uses this adjusted shade.
Color readableColor(
  BuildContext context,
  Color color, {
  double tint = 0.15,
  double minContrast = 4.5,
}) {
  final surface = Theme.of(context).colorScheme.surface;
  final bg = Color.alphaBlend(color.withValues(alpha: tint), surface);
  final darken = bg.computeLuminance() > 0.5;
  var hsl = HSLColor.fromColor(color);
  var out = color;
  double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  var guard = 0;
  while (ratio(out, bg) < minContrast && guard++ < 60) {
    final next = hsl.lightness + (darken ? -0.02 : 0.02);
    if (next < 0 || next > 1) break;
    hsl = hsl.withLightness(next);
    out = hsl.toColor();
  }
  return out;
}

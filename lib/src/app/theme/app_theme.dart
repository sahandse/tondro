import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const accent = Color(0xFF42CFFF);
  static const accentDeep = Color(0xFF168AF5);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData amoled() => _build(Brightness.dark, amoled: true);
  static ThemeData ocean() => _build(Brightness.dark, ocean: true);

  static ThemeData _build(
    Brightness brightness, {
    bool amoled = false,
    bool ocean = false,
  }) {
    final dark = brightness == Brightness.dark;
    final accentColor = ocean ? const Color(0xFF4DB8FF) : accent;
    final accentLight = ocean ? const Color(0xFF90D6FF) : accent;
    final darkPrimary = ocean ? const Color(0xFF4DB8FF) : accent;
    final lightPrimary = ocean ? const Color(0xFF1769AA) : const Color(0xFF137DEB);
    final background = amoled
        ? Colors.black
        : ocean
            ? const Color(0xFF07111C)
            : dark
                ? const Color(0xFF0A0C0E)
                : const Color(0xFFF5FAFF);
    final surface = amoled
        ? const Color(0xFF050505)
        : ocean
            ? const Color(0xFF0D1B2A)
            : dark
                ? const Color(0xFF121619)
                : const Color(0xFFFFFFFF);
    final elevated = amoled
        ? const Color(0xFF101010)
        : ocean
            ? const Color(0xFF14263A)
            : dark
                ? const Color(0xFF181C20)
                : const Color(0xFFEAF5FF);
    final foreground =
        dark ? const Color(0xFFF3F5F2) : const Color(0xFF152B46);
    final muted =
        dark ? const Color(0xFF8A9289) : const Color(0xFF657D99);
    final border =
        dark ? const Color(0xFF272D28) : const Color(0xFFD8E9F8);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? darkPrimary : lightPrimary,
      onPrimary: dark ? const Color(0xFF101510) : Colors.white,
      secondary: dark ? darkPrimary : lightPrimary,
      onSecondary: dark ? const Color(0xFF101510) : Colors.white,
      tertiary: const Color(0xFF9AA39A),
      onTertiary: foreground,
      error: dark ? const Color(0xFFFF7B7B) : const Color(0xFFC43B3B),
      onError: Colors.white,
      surface: surface,
      onSurface: foreground,
      surfaceContainerHighest: elevated,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: border.withValues(alpha: .55),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: foreground,
      onInverseSurface: background,
      inversePrimary: accentColor,
      primaryContainer:
          dark ? const Color(0xFF1D2A12) : const Color(0xFFE2F4FF),
      onPrimaryContainer: foreground,
      secondaryContainer:
          dark ? const Color(0xFF1D2A12) : const Color(0xFFE2F4FF),
      onSecondaryContainer: foreground,
      tertiaryContainer:
          dark ? const Color(0xFF232824) : const Color(0xFFE9ECE8),
      onTertiaryContainer: foreground,
      errorContainer:
          dark ? const Color(0xFF351C1C) : const Color(0xFFFFE7E7),
      onErrorContainer: foreground,
      surfaceTint: Colors.transparent,
    );

    final baseText = GoogleFonts.vazirmatnTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: baseText.apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: baseText.titleLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w900,
        ),
      ),
      dividerColor: border,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? (dark
                    ? const Color(0xFF202A18)
                    : const Color(0xFFE2F4FF))
                : surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? (dark ? darkPrimary : lightPrimary)
                : muted,
          ),
          side: WidgetStateProperty.all(BorderSide(color: border)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: dark ? darkPrimary : lightPrimary,
        foregroundColor: dark ? const Color(0xFF111511) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintStyle: baseText.bodyMedium?.copyWith(color: muted),
        labelStyle: baseText.bodyMedium?.copyWith(color: muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: dark ? darkPrimary : lightPrimary,
            width: 1.4,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: dark ? darkPrimary : lightPrimary,
          foregroundColor: dark ? const Color(0xFF111511) : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: baseText.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: dark ? darkPrimary : lightPrimary,
        linearTrackColor: elevated,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            dark ? const Color(0xFF181D19) : const Color(0xFF182018),
        contentTextStyle: baseText.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: accentLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (dark ? const Color(0xFF121512) : Colors.white)
              : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (dark ? darkPrimary : lightPrimary)
              : null,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF070707) : const Color(0xFFF2F2F2);
    final surface = dark ? const Color(0xFF111111) : Colors.white;
    final elevated = dark ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8);
    final foreground = dark ? Colors.white : Colors.black;
    final muted = dark ? const Color(0xFFA9A9A9) : const Color(0xFF5E5E5E);
    final border = dark ? const Color(0xFF3B3B3B) : const Color(0xFFB8B8B8);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: foreground,
      onPrimary: background,
      secondary: foreground,
      onSecondary: background,
      error: dark ? Colors.white : Colors.black,
      onError: background,
      surface: surface,
      onSurface: foreground,
      surfaceContainerHighest: elevated,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: border.withValues(alpha: .65),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: foreground,
      onInverseSurface: background,
      inversePrimary: background,
      tertiary: foreground,
      onTertiary: background,
      primaryContainer: elevated,
      onPrimaryContainer: foreground,
      secondaryContainer: elevated,
      onSecondaryContainer: foreground,
      tertiaryContainer: elevated,
      onTertiaryContainer: foreground,
      errorContainer: elevated,
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
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: border.withValues(alpha: .7),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: border, width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: foreground,
        disabledColor: elevated,
        labelStyle: baseText.labelMedium?.copyWith(color: foreground),
        secondaryLabelStyle: baseText.labelMedium?.copyWith(color: background),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: foreground,
        foregroundColor: background,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: surface,
        indicatorColor: foreground,
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => baseText.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected) ? foreground : muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? background : foreground,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: baseText.bodyMedium?.copyWith(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: foreground, width: 1.8),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: foreground,
        linearTrackColor: elevated,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: foreground,
        contentTextStyle: baseText.bodyMedium?.copyWith(color: background),
        actionTextColor: background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

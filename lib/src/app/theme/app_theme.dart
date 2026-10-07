import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const cyan = Color(0xFF56E6FF);
  static const blue = Color(0xFF2788FF);
  static const violet = Color(0xFF6D63FF);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background =
        dark ? const Color(0xFF090D14) : const Color(0xFFF5F8FC);
    final surface =
        dark ? const Color(0xFF111722) : const Color(0xFFFFFFFF);
    final elevated =
        dark ? const Color(0xFF171F2D) : const Color(0xFFF0F4F9);
    final foreground =
        dark ? const Color(0xFFF6F8FC) : const Color(0xFF11151D);
    final muted =
        dark ? const Color(0xFF95A0B2) : const Color(0xFF687386);
    final border =
        dark ? const Color(0xFF283243) : const Color(0xFFDCE3EC);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: blue,
      onPrimary: Colors.white,
      secondary: cyan,
      onSecondary: const Color(0xFF041014),
      tertiary: violet,
      onTertiary: Colors.white,
      error: dark ? const Color(0xFFFF7D7D) : const Color(0xFFC63A3A),
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
      inversePrimary: cyan,
      primaryContainer:
          dark ? const Color(0xFF122A49) : const Color(0xFFE5F1FF),
      onPrimaryContainer: foreground,
      secondaryContainer:
          dark ? const Color(0xFF102B32) : const Color(0xFFE4FAFF),
      onSecondaryContainer: foreground,
      tertiaryContainer:
          dark ? const Color(0xFF241F47) : const Color(0xFFEFEDFF),
      onTertiaryContainer: foreground,
      errorContainer:
          dark ? const Color(0xFF361D22) : const Color(0xFFFFE8E8),
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
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: baseText.titleLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
      dividerColor: border.withValues(alpha: .7),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border.withValues(alpha: .7)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: elevated,
        selectedColor: dark
            ? const Color(0xFF173A62)
            : const Color(0xFFE4F2FF),
        disabledColor: elevated,
        labelStyle: baseText.labelMedium?.copyWith(color: foreground),
        secondaryLabelStyle: baseText.labelMedium?.copyWith(
          color: dark ? cyan : blue,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide(color: border.withValues(alpha: .55)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: dark
            ? const Color(0xF2111722)
            : const Color(0xF2FFFFFF),
        indicatorColor: dark
            ? const Color(0xFF183A61)
            : const Color(0xFFE2F1FF),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => baseText.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? (dark ? cyan : blue)
                : muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? (dark ? cyan : blue)
                : muted,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: baseText.bodyMedium?.copyWith(color: muted),
        labelStyle: baseText.bodyMedium?.copyWith(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: border.withValues(alpha: .55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark ? cyan : blue,
            width: 1.6,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: baseText.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cyan,
        linearTrackColor: elevated,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(22),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border.withValues(alpha: .6)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            dark ? const Color(0xFF172131) : const Color(0xFF111A27),
        contentTextStyle: baseText.bodyMedium?.copyWith(
          color: Colors.white,
        ),
        actionTextColor: cyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? blue
              : null,
        ),
      ),
    );
  }
}

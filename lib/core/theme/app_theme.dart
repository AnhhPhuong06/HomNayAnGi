import 'package:flutter/material.dart';
import 'appearance.dart';

ThemeData appTheme(
  Brightness brightness, {
  AppAccent accent = AppAccent.forest,
}) {
  final dark = brightness == Brightness.dark;
  final forest =
      ColorScheme.fromSeed(
        seedColor: const Color(0xff24553d),
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xffcbe9a3) : const Color(0xff24553d),
        onPrimary: dark ? const Color(0xff193021) : Colors.white,
        primaryContainer: dark
            ? const Color(0xff30452c)
            : const Color(0xffe7f1d4),
        onPrimaryContainer: dark
            ? const Color(0xffe0f4c4)
            : const Color(0xff24402b),
        secondary: dark ? const Color(0xfff3bc84) : const Color(0xff91562c),
        secondaryContainer: dark
            ? const Color(0xff3a3125)
            : const Color(0xfff6eadb),
        onSecondaryContainer: dark
            ? const Color(0xfff5dcb8)
            : const Color(0xff60452d),
        surface: dark ? const Color(0xff111b16) : const Color(0xfff7f8f2),
        onSurface: dark ? const Color(0xffedf3e9) : const Color(0xff1d3025),
        onSurfaceVariant: dark
            ? const Color(0xffadbcaf)
            : const Color(0xff647267),
        surfaceContainerLow: dark ? const Color(0xff1a2720) : Colors.white,
        surfaceContainerHighest: dark
            ? const Color(0xff29372e)
            : const Color(0xffedf0e6),
        outlineVariant: dark
            ? const Color(0xff34443a)
            : const Color(0xffe0e6d9),
      );
  final scheme = accent == AppAccent.forest
      ? forest
      : ColorScheme.fromSeed(seedColor: accent.color, brightness: brightness);
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'BeVietnamPro',
  );
  final text = base.textTheme.copyWith(
    headlineLarge: base.textTheme.headlineLarge?.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -1.2,
    ),
    headlineMedium: base.textTheme.headlineMedium?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -.9,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      letterSpacing: -.5,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.6),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.6),
    bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.5),
  );
  return base.copyWith(
    textTheme: text,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: GentlePageTransitions(),
        TargetPlatform.iOS: RespectfulCupertinoTransitions(),
        TargetPlatform.macOS: GentlePageTransitions(),
        TargetPlatform.windows: GentlePageTransitions(),
        TargetPlatform.linux: GentlePageTransitions(),
      },
    ),
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 68,
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .65)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        side: BorderSide(color: scheme.outlineVariant),
        textStyle: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 10,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      selectedColor: scheme.primaryContainer,
      side: BorderSide(color: scheme.outlineVariant),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: TextStyle(
        fontFamily: 'BeVietnamPro',
        color: scheme.onSurface,
        fontSize: 12,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      constraints: const BoxConstraints(maxWidth: 720),
      backgroundColor: scheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
  );
}

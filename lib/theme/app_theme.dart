import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// "Ledger" (light, the default) — the theme `MaterialApp.theme` gets.
ThemeData buildAppTheme() => buildLedgerTheme(LedgerColors.ledger);

/// "Night ledger" — the theme `MaterialApp.darkTheme` gets.
ThemeData buildNightTheme() => buildLedgerTheme(LedgerColors.night);

ThemeData buildLedgerTheme(LedgerColors c) {
  final dark = c.paper.computeLuminance() < 0.5;
  final scheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: c.primary,
    onPrimary: c.onPrimary,
    secondary: c.result,
    onSecondary: c.paper,
    error: c.error,
    onError: c.paper,
    surface: c.paper,
    onSurface: c.ink,
    onSurfaceVariant: c.inkSoft,
    surfaceContainerLowest: c.paper,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface,
    surfaceContainerHighest: c.surface,
    outline: c.inkSoft,
    outlineVariant: c.rule,
  );

  const squareish = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(Radii.button)));

  final base = ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.paper,
    canvasColor: c.paper,
    fontFamily: Fonts.ui,
    dividerColor: c.rule,
    extensions: [c],
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: c.paper,
      foregroundColor: c.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle:
          dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
          fontFamily: Fonts.ui,
          color: c.ink,
          fontSize: 18,
          fontWeight: FontWeight.w600),
    ),
    dividerTheme: DividerThemeData(color: c.rule, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: c.ink),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        shape: squareish,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(
            fontFamily: Fonts.ui, fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        side: BorderSide(color: c.rule),
        shape: squareish,
        minimumSize: const Size(48, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.primary,
        shape: squareish,
        minimumSize: const Size(48, 48),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: c.inkSoft),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide(color: c.rule)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide(color: c.rule)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide(color: c.primary, width: 1.5)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(Radii.sheetTop))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: squareish,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          side: BorderSide(color: c.rule)),
      textStyle: TextStyle(fontFamily: Fonts.ui, color: c.ink, fontSize: 15),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(fontFamily: Fonts.ui, color: c.paper),
      actionTextColor: c.paper,
      behavior: SnackBarBehavior.floating,
      shape: squareish,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? c.primary : c.rule),
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? c.onPrimary : c.inkSoft),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.primary,
      selectionColor: c.primary.withValues(alpha: 0.25),
      selectionHandleColor: c.primary,
    ),
  );
}

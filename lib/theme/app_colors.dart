import 'package:flutter/material.dart';

import 'app_style.dart';

/// Deeper navy-blue system with frosted glass panels, dark UI strokes and
/// muted azure accents. `gold` stays amber only for the Late/Warning status.
class AppColors {
  AppColors._();

  static const ink900 = Color(0xFF050E21); // deep navy base
  static const ink800 = Color(0x990B1C38); // translucent panels / app bar
  static const ink700 = Color(0xB312294C); // raised cards / input fill

  static const line = Color(0xFF0E2749); // darker blue glass strokes
  static const leaf = Color(0xFF4CAF50); // Present status
  static const lime = Color(0xFF5B9FE8); // azure accent (kept name for API)
  static const forest = Color(0xFF164C87); // primary dark blue
  static const gold = Color(0xFFF5C518); // Late status only
  static const goldHi = Color(0xFF9BC7F0); // bright blue highlight

  static const text = Color(0xFFF2F7FF);
  static const muted = Color(0xFF9CB0CE);
  static const label = Color(0xFF8FB8E8);
  static const hint = Color(0xFF59779F);
  static const danger = Color(0xFFFF5D6C);
  static const ok = Color(0xFF3ECF9A);
  static const warn = Color(0xFFF2B84B);

  /// Colour from an RGB hex value (e.g. 0xF5C518) with an alpha from 0 to 1.
  static Color alpha(int rgb, double a) =>
      Color(0xFF000000 | rgb).withAlpha((a * 255).round());
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.forest,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.lime,
    onPrimary: Colors.white,
    secondary: AppColors.goldHi,
    onSecondary: AppColors.ink900,
    surface: const Color(0xFF09182F),
    onSurface: AppColors.text,
    error: AppColors.danger,
    onError: Colors.white,
  );

  OutlineInputBorder border(Color color,
          [double width = AppStyle.strokeWidth]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // The photograph is painted by AppBackground in MaterialApp.builder.
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: AppStyle.glassRaised,
    splashColor: AppColors.alpha(0x5B9FE8, 0.16),
    highlightColor: AppColors.alpha(0x5B9FE8, 0.08),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: AppColors.muted),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.text),
      bodyMedium: TextStyle(color: AppColors.text),
      bodySmall: TextStyle(color: AppColors.muted),
      titleLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800),
      titleMedium:
          TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x9904122A),
      labelStyle: const TextStyle(color: AppColors.label),
      floatingLabelStyle: const TextStyle(color: AppColors.lime),
      hintStyle: const TextStyle(color: AppColors.hint),
      prefixStyle: const TextStyle(color: AppColors.muted),
      border: border(AppStyle.stroke),
      enabledBorder: border(AppStyle.stroke),
      focusedBorder: border(AppColors.lime, 1.6),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.lime,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.alpha(0x5B9FE8, 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lime,
        side: BorderSide(
          color: AppStyle.strokeRaised,
          width: AppStyle.strokeWidth,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lime,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.muted,
        hoverColor: AppColors.alpha(0x5B9FE8, 0.15),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppStyle.glassRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyle.radius),
        side: const BorderSide(
          color: AppStyle.stroke,
          width: AppStyle.strokeWidth,
        ),
      ),
      titleTextStyle: const TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppStyle.glassRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppStyle.radius)),
        side: BorderSide(
          color: AppStyle.stroke,
          width: AppStyle.strokeWidth,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppStyle.glass,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyle.radius),
        side: const BorderSide(
          color: AppStyle.stroke,
          width: AppStyle.strokeWidth,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppStyle.glassRaised,
      labelStyle: const TextStyle(color: AppColors.text),
      side: const BorderSide(
        color: AppStyle.stroke,
        width: AppStyle.strokeWidth,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      indicator: BoxDecoration(
        gradient: AppStyle.activeGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(
          color: AppStyle.strokeHover,
          width: AppStyle.strokeWidth,
        ),
      ),
      indicatorColor: Colors.transparent,
      labelColor: AppColors.goldHi,
      unselectedLabelColor: AppColors.muted,
      dividerColor: AppStyle.stroke,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      unselectedLabelStyle:
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    dividerTheme: const DividerThemeData(
      color: AppStyle.stroke,
      thickness: AppStyle.strokeWidth,
      space: 1,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppStyle.glassRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: AppStyle.stroke,
          width: AppStyle.strokeWidth,
        ),
      ),
      textStyle: const TextStyle(color: AppColors.text, fontSize: 13),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppStyle.glassRaised,
      contentTextStyle: const TextStyle(color: AppColors.text, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
        side: const BorderSide(
          color: AppStyle.stroke,
          width: AppStyle.strokeWidth,
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.lime,
      linearTrackColor: Color(0x330E2749),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.lime,
      selectionColor: Color(0x555B9FE8),
      selectionHandleColor: AppColors.lime,
    ),
  );
}

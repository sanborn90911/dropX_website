import 'package:flutter/material.dart';

import 'app_colors.dart';

const String kFontFamily = 'RobotoCondensed';

/// Same ThemeData as the dropX app's `main.dart`, plus tooltip styling the
/// website needs.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: kFontFamily,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.background,
      primary: AppColors.accentGreen,
      secondary: AppColors.accentCyan,
      error: AppColors.error,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
      fontFamily: kFontFamily,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      contentTextStyle: TextStyle(fontFamily: kFontFamily, fontSize: 14, color: AppColors.textPrimary),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceRaised,
      contentTextStyle: TextStyle(fontFamily: kFontFamily, color: AppColors.textPrimary),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      textStyle: const TextStyle(fontFamily: kFontFamily, color: AppColors.textPrimary, fontSize: 12),
      waitDuration: const Duration(milliseconds: 250),
    ),
    dividerColor: AppColors.border,
  );
}

/// Desktop (landscape, ~16:9) vs mobile (portrait, ~9:16) layout switch. Any
/// window at least 1024px wide is treated as desktop.
bool isWideLayout(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width >= 1024 || (size.width >= 720 && size.width >= size.height);
}

import 'package:flutter/material.dart';

/// Mirrors `dropsync_app/lib/core/constants/app_colors.dart` exactly, so the
/// website and the app share one palette. Tixati-inspired utilitarian dark
/// palette. High contrast, no gradients.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceRaised = Color(0xFF232323);
  static const Color border = Color(0xFF333333);

  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF9A9A9A);
  static const Color textDisabled = Color(0xFF5A5A5A);

  static const Color accentGreen = Color(0xFF39FF14);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF5252);

  /// Website-only: the "light border" shown on hover, before a click turns
  /// it into a solid accent border.
  static final Color hoverBorder = textSecondary.withValues(alpha: 0.45);

  /// Website-only: the low-strength divider under the header / above the
  /// footer.
  static final Color divider = border.withValues(alpha: 0.7);
}

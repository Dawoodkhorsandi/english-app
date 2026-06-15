import 'package:flutter/material.dart';

/// Semantic color tokens used across the app.
///
/// Colors that live outside of [ColorScheme] — brand colors, feedback
/// colors, and other semantic tokens that M3 doesn't cover natively.
///
/// For standard surface/text colors, always prefer
/// `Theme.of(context).colorScheme.*` instead of these constants.
abstract final class AppColors {
  // ---- Brand ----
  /// The seed color used to generate the M3 [ColorScheme].
  static const Color seed = Color(0xFF2563EB); // Modern blue

  /// Telegram brand color (used on the login screen).
  static const Color telegram = Color(0xFF0088CC);

  // ---- Feedback ----
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color onSuccessContainer = Color(0xFF14532D);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerContainer = Color(0xFFFEE2E2);
  static const Color onDangerContainer = Color(0xFF7F1D1D);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF78350F);

  // ---- Misc ----
  /// Bookmark star / favourite accent.
  static const Color bookmark = Color(0xFFF59E0B);

  /// Subtle border used in cards and dividers (alpha-based, adapts to
  /// both light and dark backgrounds).
  static const Color subtleBorder = Color(0x1A000000); // 10% black

  // ---- Heatmap intensity scale (light theme) ----
  static const Color heatmapEmpty = Color(0xFFF3F4F6);
  static const Color heatmapLow = Color(0xFFBBF7D0);
  static const Color heatmapMed = Color(0xFF4ADE80);
  static const Color heatmapHigh = Color(0xFF16A34A);

  // ---- Heatmap intensity scale (dark theme) ----
  static const Color heatmapEmptyDark = Color(0xFF1F2937);
  static const Color heatmapLowDark = Color(0xFF14532D);
  static const Color heatmapMedDark = Color(0xFF15803D);
  static const Color heatmapHighDark = Color(0xFF22C55E);
}

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

  // ---- Gradient (indigo -> violet hero cards) ----
  static const Color gradientStart = Color(0xFF4F46E5); // indigo
  static const Color gradientEnd = Color(0xFF7C3AED); // violet

  /// The hero gradient used on review / highlight cards.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---- Accent chips (icon foreground + soft background) ----
  // Used for quick-action tiles, category icons, and metric chips.
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentPurpleBg = Color(0xFFEDE9FE);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentTealBg = Color(0xFFCCFBF1);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color accentOrangeBg = Color(0xFFFFEDD5);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentBlueBg = Color(0xFFDBEAFE);

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

  // ---- Page surfaces ----
  /// Light gray page background; white cards lift off it.
  static const Color pageLight = Color(0xFFF4F5F7);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFE7E8EC);

  /// Dark page background and card surfaces.
  static const Color pageDark = Color(0xFF0F1115);
  static const Color cardDark = Color(0xFF1A1D24);
  static const Color cardBorderDark = Color(0xFF2A2E37);

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

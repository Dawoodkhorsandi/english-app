/// Design tokens for consistent spacing throughout the app.
///
/// Based on a 4-point grid. Every spatial value in the app should
/// reference one of these constants instead of using magic numbers.
abstract final class AppSpacing {
  // ---- Base scale (4pt grid) ----
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
  static const double massive = 64;

  // ---- Semantic aliases ----

  /// Default page padding (all sides).
  static const double pagePadding = lg;

  /// Padding inside a card body.
  static const double cardPadding = lg;

  /// Vertical gap between sections on a page.
  static const double sectionGap = xxl;

  /// Vertical gap between items in a list/column.
  static const double itemGap = sm;

  /// Gap between chips in a row/wrap.
  static const double chipGap = sm;

  /// Height of the shimmer/skeleton placeholder lines.
  static const double skeletonLineHeight = lg;
}

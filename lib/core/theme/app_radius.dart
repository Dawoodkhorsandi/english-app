import 'package:flutter/material.dart';

/// Design tokens for border radii.
///
/// Inspired by shadcn/ui: a single [base] value from which a scale
/// is derived. Changing [base] updates every radius in the app.
abstract final class AppRadius {
  // ---- Base ----
  static const double base = 12;

  // ---- Derived scale ----
  static const double xs = base * 0.25; //  3
  static const double sm = base * 0.5; //  6
  static const double md = base * 0.75; //  9
  static const double lg = base; // 12
  static const double xl = base * 1.33; // ~16
  static const double xxl = base * 1.67; // ~20
  static const double full = 999; // pill / circle

  // ---- Pre-built BorderRadius values ----
  static final BorderRadius borderXs = BorderRadius.circular(xs);
  static final BorderRadius borderSm = BorderRadius.circular(sm);
  static final BorderRadius borderMd = BorderRadius.circular(md);
  static final BorderRadius borderLg = BorderRadius.circular(lg);
  static final BorderRadius borderXl = BorderRadius.circular(xl);
  static final BorderRadius borderXxl = BorderRadius.circular(xxl);
  static final BorderRadius borderFull = BorderRadius.circular(full);

  // ---- Shape helpers for theme config ----
  static final RoundedRectangleBorder shapeLg = RoundedRectangleBorder(
    borderRadius: borderLg,
  );
  static final RoundedRectangleBorder shapeMd = RoundedRectangleBorder(
    borderRadius: borderMd,
  );
  static final RoundedRectangleBorder shapeSm = RoundedRectangleBorder(
    borderRadius: borderSm,
  );
}

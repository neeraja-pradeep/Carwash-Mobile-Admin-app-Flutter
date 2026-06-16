import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Typographic helpers built on the Figtree family (matches `ds-tokens.css`).
///
/// The prototype uses many bespoke inline font specs, so [figtree] is a general
/// factory; the named roles cover the recurring semantic styles. Font sizes use
/// `.sp` so they never go in `const` contexts (a `const` would not scale).
class AppText {
  const AppText._();

  /// General Figtree style factory. [size] is in design px and is scaled via
  /// `.sp`; pass [scaleSize] = false for values already scaled by the caller.
  static TextStyle figtree({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.fgPrimary,
    double? height,
    double? letterSpacing,
    bool scaleSize = true,
  }) {
    return GoogleFonts.figtree(
      fontSize: scaleSize ? size.sp : size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ── Named roles ──
  static TextStyle get h1 =>
      figtree(size: 32, weight: FontWeight.w700, height: 1);

  static TextStyle get h2 => figtree(
        size: 24,
        weight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.6,
      );

  static TextStyle get h3 =>
      figtree(size: 20, weight: FontWeight.w700, height: 1);

  static TextStyle get titleBar =>
      figtree(size: 18, weight: FontWeight.w700, letterSpacing: -0.2);

  static TextStyle get body =>
      figtree(size: 16, weight: FontWeight.w400, color: AppColors.fgSecondary);

  static TextStyle get bodyStrong => figtree(size: 16, weight: FontWeight.w500);

  static TextStyle get caption =>
      figtree(size: 14, weight: FontWeight.w400, color: AppColors.fgSecondary);

  /// Uppercase section eyebrow (e.g. `SECTION HEAD`).
  static TextStyle get eyebrow => figtree(
        size: 11,
        weight: FontWeight.w700,
        color: AppColors.fgSecondary,
        letterSpacing: 1.1,
      );
}

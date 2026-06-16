import 'package:flutter/material.dart';

/// Brand palette tokens for the DriveDeck Admin app.
///
/// Mirrors the design-system tokens defined in `ds-tokens.css` and the badge
/// families from `admin.css`. Primary brand colour is the DriveTo yellow
/// (`#FAD93A`) on a `#F8F8F8` page background with black text.
class AppColors {
  const AppColors._();

  // ── Brand — yellow ──
  static const Color brandYellow = Color(0xFFFAD93A);
  static const Color brandYellowPress = Color(0xFFF1C700);
  static const Color brandYellowWarm = Color(0xFFFEC319);
  static const Color brandYellowDeep = Color(0xFFF2C800);
  static const Color brandYellowLight = Color(0xFFFCE16A);
  static const Color brandWarning = Color(0xFFFFC107);

  // ── Foreground (text & icons) ──
  static const Color fgPrimary = Color(0xFF000000);
  static const Color fgSecondary = Color(0xFF575757);
  static const Color fgTertiary = Color(0xFF7F7F7F);
  static const Color fgMuted = Color(0xFF999999);
  static const Color fgOnBrand = Color(0xFF000000);
  static const Color fgOnDark = Color(0xFFFFFFFF);

  // ── Surfaces ──
  static const Color bgPage = Color(0xFFF8F8F8);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgInput = Color(0xFFFFFFFF);
  static const Color bgSplash = Color(0xFF020202);
  static const Color bgOverlay = Color(0x80000000);

  // ── Borders & dividers ──
  static const Color borderStrong = Color(0xFF85888E);
  static const Color borderDefault = Color(0xFFD7D7D7);
  static const Color borderSoft = Color(0xFFEEEEEE);
  static const Color borderFaint = Color(0xFFDDDDDD);

  // ── Semantic ──
  static const Color success = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFFF3D00);
  static const Color info = Color(0xFF1976D2);
  static const Color infoAccent = Color(0xFF407BFF);
  static const Color slate = Color(0xFF263238);

  // ── Toast surface ──
  static const Color toastBg = Color(0xFF1D1E22);

  // ── Badge families (tone → bg / fg / dot) ──
  static const Color amberBg = Color(0xFFFFF3D6);
  static const Color amberFg = Color(0xFF8A5B00);
  static const Color amberDot = Color(0xFFE59B12);

  static const Color blueBg = Color(0xFFE8F0FE);
  static const Color blueFg = Color(0xFF15539E);
  static const Color blueDot = Color(0xFF2C7BE5);

  static const Color greenBg = Color(0xFFE3F4E7);
  static const Color greenFg = Color(0xFF1E7A33);
  static const Color greenDot = Color(0xFF2E9E48);

  static const Color redBg = Color(0xFFFCE8E1);
  static const Color redFg = Color(0xFFBC360F);
  static const Color redDot = Color(0xFFE04F26);

  static const Color greyBg = Color(0xFFEEEFF1);
  static const Color greyFg = Color(0xFF54565B);
  static const Color greyDot = Color(0xFF9A9CA1);

  // ── Avatar placeholder ──
  static const Color avatarBg = Color(0xFFEAEBEE);
}

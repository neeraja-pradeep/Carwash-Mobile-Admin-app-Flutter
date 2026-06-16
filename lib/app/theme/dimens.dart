/// Spacing, radius and sizing primitives (raw logical pixels).
///
/// These are the design-system scale values from `ds-tokens.css`. Widgets apply
/// `flutter_screenutil` extensions (`.w`, `.h`, `.r`, `.sp`) on top of them so
/// layouts scale proportionally from the 380×800 design baseline.
class Dimens {
  const Dimens._();

  // ── Spacing scale (8-pt) ──
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20; // page padding
  static const double s6 = 24;
  static const double s7 = 32;
  static const double s8 = 40;
  static const double s9 = 48;
  static const double s10 = 64;

  // ── Radii ──
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12; // default — buttons, cards, inputs
  static const double radiusCard = 14;
  static const double radiusLg = 20;
  static const double radiusSheet = 24;
  static const double radiusPill = 999;

  // ── Sizes ──
  static const double hitMin = 44;
  static const double inputH = 55;
  static const double btnH = 60;
  static const double btnHSm = 48;
  static const double topBarH = 54;
  static const double pagePad = 20;
  static const double fabSize = 56;
  static const double fabBottom = 96;

  // ── Design baseline (matches the prototype's `.screen`: 380×800) ──
  static const double designWidth = 380;
  static const double designHeight = 800;
}

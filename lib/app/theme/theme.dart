import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Assembles the [ThemeData] for the DriveDeck Admin app.
///
/// The design is light-only with a `#F8F8F8` page background, black text and a
/// yellow brand accent. Most surfaces are styled per-widget (see `core/widgets`)
/// so this theme only sets the global defaults.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgPage,
      primaryColor: AppColors.brandYellow,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandYellow,
        onPrimary: AppColors.fgOnBrand,
        secondary: AppColors.slate,
        surface: AppColors.bgCard,
        onSurface: AppColors.fgPrimary,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.figtreeTextTheme(base.textTheme).apply(
        bodyColor: AppColors.fgPrimary,
        displayColor: AppColors.fgPrimary,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      dividerColor: AppColors.borderSoft,
    );
  }
}

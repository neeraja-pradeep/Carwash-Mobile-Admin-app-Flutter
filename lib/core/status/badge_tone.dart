import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// Soft-fill status pill tones (mirrors the badge families in `admin.css`).
///
/// Every status across the three services maps onto one of these five tones so
/// colour usage stays consistent: amber = needs attention, blue = in progress,
/// green = done, red = terminal/cancelled, grey = neutral/inactive.
enum BadgeTone { amber, blue, green, red, grey }

/// Background / foreground / dot colours for a [BadgeTone].
extension BadgeToneColors on BadgeTone {
  Color get background => switch (this) {
        BadgeTone.amber => AppColors.amberBg,
        BadgeTone.blue => AppColors.blueBg,
        BadgeTone.green => AppColors.greenBg,
        BadgeTone.red => AppColors.redBg,
        BadgeTone.grey => AppColors.greyBg,
      };

  Color get foreground => switch (this) {
        BadgeTone.amber => AppColors.amberFg,
        BadgeTone.blue => AppColors.blueFg,
        BadgeTone.green => AppColors.greenFg,
        BadgeTone.red => AppColors.redFg,
        BadgeTone.grey => AppColors.greyFg,
      };

  Color get dot => switch (this) {
        BadgeTone.amber => AppColors.amberDot,
        BadgeTone.blue => AppColors.blueDot,
        BadgeTone.green => AppColors.greenDot,
        BadgeTone.red => AppColors.redDot,
        BadgeTone.grey => AppColors.greyDot,
      };
}

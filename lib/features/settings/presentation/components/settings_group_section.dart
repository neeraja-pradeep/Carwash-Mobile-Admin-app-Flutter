import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../app/theme/typography.dart';
import '../../../../../core/widgets/app_card.dart';

/// A labelled group card wrapping a list of [SettingsItem]s.
///
/// Mirrors the `Group` component in `screen_settings.jsx`: an uppercase
/// eyebrow label above a zero-padding [AppCard] containing child rows.
class SettingsGroupSection extends StatelessWidget {
  const SettingsGroupSection({
    required this.label,
    required this.children,
    super.key,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 2.w, bottom: 8.h),
            child: Text(
              label.toUpperCase(),
              style: AppText.eyebrow,
            ),
          ),
        AppCard(
          padded: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ],
    );
  }
}

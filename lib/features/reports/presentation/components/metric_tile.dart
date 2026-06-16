import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';

/// A single metric tile: eyebrow label, large value, optional sub-text.
/// Mirrors `Metric` in `screen_reports.jsx`.
class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    this.color,
    this.sub,
    super.key,
  });

  final String label;
  final String value;
  final Color? color;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppText.figtree(
              size: 9.5,
              weight: FontWeight.w700,
              color: AppColors.fgTertiary,
              letterSpacing: 0.9,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: AppText.figtree(
              size: 21,
              weight: FontWeight.w800,
              color: color ?? AppColors.fgPrimary,
              letterSpacing: -0.5,
            ),
          ),
          if (sub != null) ...[
            SizedBox(height: 3.h),
            Text(
              sub!,
              style: AppText.figtree(
                size: 11,
                weight: FontWeight.w500,
                color: AppColors.fgMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

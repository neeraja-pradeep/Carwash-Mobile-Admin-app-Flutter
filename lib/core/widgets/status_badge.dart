import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/typography.dart';
import '../status/badge_tone.dart';

/// Soft-fill status pill: coloured dot + label (colour **and** label, never
/// colour alone — WCAG safe). Matches the `.badge` soft style in `admin.css`.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.tone, super.key});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.r,
            height: 6.r,
            decoration: BoxDecoration(
              color: tone.foreground,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: AppText.figtree(
              size: 11.5,
              weight: FontWeight.w600,
              color: tone.foreground,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

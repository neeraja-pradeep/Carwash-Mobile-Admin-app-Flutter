import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';

/// A quick-action button — mirrors `QuickAction` in `screen_dashboard.jsx`.
///
/// Renders an icon box on the left and a bold label on the right, inside a
/// card-style surface with a soft shadow.
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13.r),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(13.r),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0A14141E),
                offset: Offset(0, 1.h),
                blurRadius: 2.r,
              ),
              BoxShadow(
                color: const Color(0x1A14141E),
                offset: Offset(0, 6.h),
                blurRadius: 16.r,
                spreadRadius: -6.r,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: AppColors.bgPage,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18.sp, color: AppColors.fgPrimary),
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: Text(
                    label,
                    style: AppText.figtree(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: AppColors.fgPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

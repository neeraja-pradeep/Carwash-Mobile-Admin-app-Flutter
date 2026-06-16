import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';

/// A 3-column module shortcut tile — mirrors `ModuleTile` in
/// `screen_dashboard.jsx`.
///
/// Icon centred at top, label below. Optional numeric [badge] renders a red
/// pill in the top-right corner.
class ModuleTile extends StatelessWidget {
  const ModuleTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Optional unread/alert count badge.
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.bgPage,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 21.sp, color: AppColors.fgPrimary),
                    ),
                    SizedBox(height: 9.h),
                    Text(
                      label,
                      style: AppText.figtree(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.fgPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Positioned(
                  top: 10.h,
                  right: 12.w,
                  child: Container(
                    constraints: BoxConstraints(minWidth: 18.w),
                    height: 18.h,
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      '$badge',
                      style: AppText.figtree(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: AppColors.fgOnDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

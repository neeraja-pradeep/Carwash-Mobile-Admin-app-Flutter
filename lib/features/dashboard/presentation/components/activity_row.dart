import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';

import '../../domain/entities/activity_item.dart';

/// A single row in the Recent Activity feed — mirrors `ActivityRow` in
/// `screen_dashboard.jsx`.
///
/// Icon is resolved from [ActivityItem.iconKey]. Tapping the row navigates
/// to the booking detail via [onTap].
class ActivityRow extends StatelessWidget {
  const ActivityRow({
    required this.item,
    required this.onTap,
    super.key,
  });

  final ActivityItem item;
  final VoidCallback onTap;

  static IconData _resolveIcon(String key) {
    switch (key) {
      case 'inbox':
        return AppIcons.inbox;
      case 'droplet':
        return AppIcons.droplet;
      case 'car':
        return AppIcons.car;
      case 'receipt':
        return AppIcons.receipt;
      case 'star':
        return AppIcons.star;
      default:
        return AppIcons.dot;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 11.h),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.bgPage,
                borderRadius: BorderRadius.circular(9.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                _resolveIcon(item.iconKey),
                size: 17.sp,
                color: AppColors.fgSecondary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                item.text,
                style: AppText.figtree(
                  size: 13.5,
                  weight: FontWeight.w500,
                  color: AppColors.fgPrimary,
                  height: 1.35,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              item.time,
              style: AppText.figtree(
                size: 11.5,
                weight: FontWeight.w500,
                color: AppColors.fgMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

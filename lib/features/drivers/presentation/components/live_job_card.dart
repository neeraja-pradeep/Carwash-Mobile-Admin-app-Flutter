import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';

import '../../domain/entities/field_driver.dart';

/// The green-accented "Live · On a job" card shown at the top of DriverDetailScreen
/// when the driver has an active [DriverCurrentJob].
///
/// Mirrors the live-job section in `screen_drivers.jsx` DriverDetail component.
class LiveJobCard extends StatelessWidget {
  const LiveJobCard({
    required this.job,
    required this.onOpenBooking,
    required this.onReassign,
    super.key,
  });

  final DriverCurrentJob job;
  final VoidCallback onOpenBooking;
  final VoidCallback onReassign;

  @override
  Widget build(BuildContext context) {
    final loc = job.location;
    // Shorten booking ID prefix for display
    final shortId = job.bookingId
        .replaceFirst(RegExp(r'^DD-KL-2026|^SR-[A-Z]{2}-2026'), '#…');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14.r),
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
      child: Stack(
        children: [
          // Green left accent
          Positioned(
            left: -16.w,
            top: -16.h,
            bottom: -16.h,
            child: Container(
              width: 3.w,
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14.r),
                  bottomLeft: Radius.circular(14.r),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: live dot + label + type chip
              Row(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x2E2E9E48),
                          blurRadius: 0,
                          spreadRadius: 3.r,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Live · On a job',
                    style: AppText.figtree(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.success,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgPage,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      job.type.toUpperCase(),
                      style: AppText.figtree(
                        size: 10.5,
                        weight: FontWeight.w600,
                        color: AppColors.fgSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 13.h),

              // Customer + stage + booking ref
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.customer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.figtree(
                            size: 15,
                            weight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Stage: ${job.stage}',
                          style: AppText.figtree(
                            size: 12.5,
                            weight: FontWeight.w500,
                            color: AppColors.fgTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    shortId,
                    style: AppText.figtree(
                      size: 11.5,
                      weight: FontWeight.w500,
                      color: AppColors.fgTertiary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 13.h),

              // Location tile
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.bgPage,
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Icon(
                        loc.moving ? AppIcons.nav : AppIcons.pin,
                        size: 18.sp,
                        color: loc.moving ? AppColors.blueFg : AppColors.fgSecondary,
                      ),
                    ),
                    SizedBox(width: 11.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT LOCATION',
                            style: AppText.figtree(
                              size: 9.5,
                              weight: FontWeight.w700,
                              color: AppColors.fgTertiary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  loc.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.figtree(
                                    size: 12.5,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 7.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 7.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: loc.moving
                                      ? AppColors.blueBg
                                      : AppColors.greyBg,
                                  borderRadius: BorderRadius.circular(5.r),
                                ),
                                child: Text(
                                  loc.moving ? 'Moving' : 'Static',
                                  style: AppText.figtree(
                                    size: 9,
                                    weight: FontWeight.w600,
                                    color: loc.moving
                                        ? AppColors.blueFg
                                        : AppColors.greyFg,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Updated ${loc.lastUpdate}',
                            style: AppText.figtree(
                              size: 11,
                              weight: FontWeight.w500,
                              color: AppColors.fgMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 13.h),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: AppIcons.refresh,
                      label: 'Reassign',
                      onTap: onReassign,
                      filled: false,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _ActionButton(
                      icon: AppIcons.arrowRight,
                      label: 'Open booking',
                      onTap: onOpenBooking,
                      filled: true,
                      iconTrailing: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.filled,
    this.iconTrailing = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool iconTrailing;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 15.sp, color: AppColors.fgPrimary);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: filled ? AppColors.brandYellow : AppColors.bgCard,
          borderRadius: BorderRadius.circular(11.r),
          border: filled ? null : Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!iconTrailing) ...[
              iconWidget,
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: AppText.figtree(
                size: 13,
                weight: FontWeight.w700,
              ),
            ),
            if (iconTrailing) ...[
              SizedBox(width: 6.w),
              iconWidget,
            ],
          ],
        ),
      ),
    );
  }
}

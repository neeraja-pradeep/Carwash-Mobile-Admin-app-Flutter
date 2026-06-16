import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../drivers/domain/entities/driver_job.dart';
import 'route_ladder.dart';

/// Driver-app job list card — mirrors `DJobCard` in `screen_driver_app.jsx`.
///
/// Shows a neutral job-type pill + time, customer, vehicle, the pickup→drop
/// route ladder, the driver's payout, and the trailing actions: completed jobs
/// show a "View summary" button; active/upcoming jobs show Call + Navigate
/// icon buttons and a "View" (active) / "Start" (upcoming) button.
class DriverJobCard extends StatelessWidget {
  const DriverJobCard({
    required this.job,
    required this.onTap,
    this.onCall,
    this.onNavigate,
    super.key,
  });

  final DriverJob job;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final isCompleted = job.state == DriverJobState.completed;
    final isActive = job.state == DriverJobState.active;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: type pill (neutral) + time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TypePill(type: job.type),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.clock, size: 14.sp, color: AppColors.fgPrimary),
                  SizedBox(width: 6.w),
                  Text(
                    job.time,
                    style: AppText.figtree(size: 13, weight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 11.h),

          // Customer + vehicle
          Text(
            job.customer,
            style: AppText.figtree(size: 15.5, weight: FontWeight.w700),
          ),
          SizedBox(height: 3.h),
          Text(
            job.vehicle,
            style: AppText.figtree(
              size: 12.5,
              weight: FontWeight.w500,
              color: AppColors.fgTertiary,
            ),
          ),
          SizedBox(height: 12.h),

          // Route ladder (top-divider, filled dots)
          const Divider(height: 1, color: AppColors.borderSoft),
          SizedBox(height: 12.h),
          RouteLadder(pickup: job.pickup, drop: job.drop, dense: true),
          SizedBox(height: 12.h),

          const Divider(height: 1, color: AppColors.borderSoft),
          SizedBox(height: 11.h),

          // Footer: payout + actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'YOUR PAYOUT',
                    style: AppText.figtree(
                      size: 10,
                      weight: FontWeight.w700,
                      color: AppColors.fgTertiary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    Formatters.money(job.payout),
                    style: AppText.figtree(size: 16, weight: FontWeight.w700),
                  ),
                ],
              ),
              if (isCompleted)
                _SummaryButton(onTap: onTap)
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconBtn(icon: AppIcons.phone, onTap: onCall ?? () {}),
                    SizedBox(width: 8.w),
                    _IconBtn(icon: AppIcons.nav, onTap: onNavigate ?? () {}),
                    SizedBox(width: 8.w),
                    AppButton(
                      label: isActive ? 'View' : 'Start',
                      size: AppButtonSize.sm,
                      onPressed: onTap,
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

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final isCarwash = type == 'Carwash';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCarwash ? AppIcons.droplet : AppIcons.car,
            size: 13.sp,
            color: AppColors.fgSecondary,
          ),
          SizedBox(width: 6.w),
          Text(
            type,
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryButton extends StatelessWidget {
  const _SummaryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 42.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(11.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View summary',
              style: AppText.figtree(size: 13, weight: FontWeight.w700),
            ),
            SizedBox(width: 6.w),
            Icon(AppIcons.chevRight, size: 15.sp, color: AppColors.fgPrimary),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42.r,
        height: 42.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(11.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Icon(icon, size: 18.sp, color: AppColors.fgPrimary),
      ),
    );
  }
}

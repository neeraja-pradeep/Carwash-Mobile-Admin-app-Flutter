import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../drivers/domain/entities/driver_job.dart';

/// Driver-app job list card — mirrors `DJobCard` in `screen_driver_app.jsx`.
///
/// Shows job type badge, time, customer, vehicle, route connector, payout and
/// quick-action buttons (call, navigate, View / Start).
class DriverJobCard extends StatelessWidget {
  const DriverJobCard({
    required this.job,
    required this.onTap,
    this.onCall,
    this.onStart,
    super.key,
  });

  final DriverJob job;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final isActive = job.state == DriverJobState.active;
    final isCompleted = job.state == DriverJobState.completed;
    final isHire = job.type == 'Driver hire';

    return AppCard(
      accent: isActive ? AppColors.brandYellow : null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: type badge + time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TypeBadge(type: job.type, isActive: isActive),
              Text(
                job.time,
                style: AppText.figtree(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.fgTertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Customer + vehicle
          Text(
            job.customer,
            style: AppText.figtree(size: 15, weight: FontWeight.w700),
          ),
          SizedBox(height: 2.h),
          Text(
            job.vehicle,
            style: AppText.figtree(
              size: 12.5,
              weight: FontWeight.w400,
              color: AppColors.fgTertiary,
            ),
          ),
          SizedBox(height: 10.h),

          // Route connector
          _RouteConnector(pickup: job.pickup, drop: job.drop),
          SizedBox(height: 10.h),

          // Stage chip (active jobs)
          if (isActive) ...[
            _StagePill(stage: job.stage),
            SizedBox(height: 10.h),
          ],

          const Divider(height: 1, color: AppColors.borderFaint),
          SizedBox(height: 10.h),

          // Footer: payout + action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.money(job.payout),
                    style: AppText.figtree(
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (isHire && job.fare.collect > 0)
                    Text(
                      '+ collect ${Formatters.money(job.fare.collect)}',
                      style: AppText.figtree(
                        size: 11,
                        weight: FontWeight.w500,
                        color: AppColors.amberFg,
                      ),
                    ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCompleted) ...[
                    _IconBtn(
                      icon: AppIcons.phone,
                      onTap: onCall ?? () {},
                    ),
                    SizedBox(width: 8.w),
                    _IconBtn(
                      icon: AppIcons.nav,
                      onTap: () {},
                    ),
                    SizedBox(width: 8.w),
                  ],
                  AppButton(
                    label: isCompleted
                        ? 'Done'
                        : isActive
                            ? 'View'
                            : 'View',
                    size: AppButtonSize.sm,
                    kind: isCompleted
                        ? AppButtonKind.ghost
                        : AppButtonKind.primary,
                    disabled: isCompleted,
                    onPressed: isCompleted ? null : onTap,
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

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.isActive});

  final String type;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isHire = type == 'Driver hire';
    final bg = isHire ? AppColors.blueBg : AppColors.amberBg;
    final fg = isHire ? AppColors.blueFg : AppColors.amberFg;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHire ? AppIcons.car : AppIcons.droplet,
            size: 11.sp,
            color: fg,
          ),
          SizedBox(width: 4.w),
          Text(
            type,
            style: AppText.figtree(
              size: 11.5,
              weight: FontWeight.w600,
              color: fg,
            ),
          ),
          if (isActive) ...[
            SizedBox(width: 6.w),
            Container(
              width: 6.r,
              height: 6.r,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector({required this.pickup, required this.drop});

  final String pickup;
  final String drop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.pin, size: 14.sp, color: AppColors.brandYellow),
            SizedBox(
              height: 18.h,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.borderDefault,
              ),
            ),
            Icon(AppIcons.pin, size: 14.sp, color: AppColors.fgTertiary),
          ],
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickup,
                style: AppText.figtree(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: AppColors.fgPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                drop,
                style: AppText.figtree(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: AppColors.fgSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StagePill extends StatelessWidget {
  const _StagePill({required this.stage});

  final String stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.greenBg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        stage,
        style: AppText.figtree(
          size: 11.5,
          weight: FontWeight.w600,
          color: AppColors.greenFg,
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
        width: 36.r,
        height: 36.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Icon(icon, size: 18.sp, color: AppColors.fgSecondary),
      ),
    );
  }
}

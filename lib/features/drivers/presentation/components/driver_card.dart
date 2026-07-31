import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/avatar.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/status_badge.dart';

import '../../domain/entities/field_driver.dart';

/// List card for a hired field driver — mirrors `DriverCard` in screen_drivers.jsx.
///
/// Shows avatar, name, status badge, phone, "On a job" chip (when active + on
/// a job), and a footer row: Role · Jobs done · License status.
class DriverCard extends StatelessWidget {
  const DriverCard({
    required this.driver,
    required this.onTap,
    super.key,
  });

  final FieldDriver driver;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onJob = driver.onJob && driver.status == DriverStatus.online;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(14.r),
      child: Column(
        children: [
          Row(
            children: [
              Avatar(name: driver.name, size: 44),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            driver.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.figtree(
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        StatusBadge(
                          label: driver.status.label,
                          tone: driver.status.tone,
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      driver.phone,
                      style: AppText.figtree(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onJob) ...[
                SizedBox(width: 8.w),
                _OnAJobBadge(),
              ],
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.only(top: 11.h),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FooterStat(
                    label: 'Role',
                    value: driver.role,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 16.w),
                _FooterStat(
                  label: 'Jobs',
                  value: driver.jobsDone.toString(),
                ),
                SizedBox(width: 16.w),
                _LicenseStat(verified: driver.license.verified),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnAJobBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.r,
            height: 6.r,
            decoration: BoxDecoration(
              color: AppColors.greenDot,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            'On a job',
            style: AppText.figtree(
              size: 10.5,
              weight: FontWeight.w700,
              color: AppColors.blueFg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  const _FooterStat({
    required this.label,
    required this.value,
    this.overflow,
  });

  final String label;
  final String value;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.figtree(
            size: 9.5,
            weight: FontWeight.w700,
            color: AppColors.fgTertiary,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          maxLines: 1,
          overflow: overflow,
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LicenseStat extends StatelessWidget {
  const _LicenseStat({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'LICENSE',
          style: AppText.figtree(
            size: 9.5,
            weight: FontWeight.w700,
            color: AppColors.fgTertiary,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: 3.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              verified ? AppIcons.checkCircle : AppIcons.clock,
              size: 13.sp,
              color: verified ? AppColors.greenFg : AppColors.amberFg,
            ),
            SizedBox(width: 4.w),
            Text(
              verified ? 'Verified' : 'Pending',
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w600,
                color: verified ? AppColors.greenFg : AppColors.amberFg,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

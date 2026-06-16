import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/status_badge.dart';

import '../../domain/entities/service_request.dart';

/// List card for a single [ServiceRequest].
///
/// Mirrors the `SrCard` component in `screen_servicereq.jsx`:
/// kind pill + status badge, customer name, vehicle/reason line,
/// when/duration, location, fee row, assignee or "Needs assignee" flag.
class SrRequestCard extends StatelessWidget {
  const SrRequestCard({
    required this.request,
    required this.assigneeName,
    required this.onTap,
    super.key,
  });

  final ServiceRequest request;

  /// Resolved assignee name (or null when unassigned).
  final String? assigneeName;

  final VoidCallback onTap;

  bool get _isUnassigned =>
      request.assigneeId == null &&
      request.status != ServiceRequestStatus.cancelled &&
      request.status != ServiceRequestStatus.completed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kind pill + status badge.
          Row(
            children: [
              _KindPill(kind: request.kind),
              const Spacer(),
              StatusBadge(
                label: request.status.label,
                tone: request.status.tone,
              ),
            ],
          ),
          SizedBox(height: 11.h),

          // Customer name.
          Text(
            request.customer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.figtree(size: 16, weight: FontWeight.w700),
          ),
          SizedBox(height: 3.h),

          // Vehicle + optional reason.
          Text(
            [
              request.vehicle.title,
              if (request.reason != null) request.reason!,
            ].join(' · '),
            style: AppText.figtree(
              size: 12.5,
              weight: FontWeight.w500,
              color: AppColors.fgTertiary,
            ),
          ),
          SizedBox(height: 12.h),

          // When / location rows.
          Container(
            padding: EdgeInsets.only(top: 11.h),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: AppIcons.clock,
                  primary: request.when,
                  secondary: '· ${request.duration}',
                ),
                SizedBox(height: 7.h),
                _InfoRow(
                  icon: AppIcons.pin,
                  primary: request.location,
                  isLocation: true,
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Fee + assignee row.
          Container(
            padding: EdgeInsets.only(top: 11.h),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Row(
              children: [
                Text(
                  request.fee != null
                      ? Formatters.money(request.fee!)
                      : 'Fee TBD',
                  style: AppText.figtree(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: request.fee != null
                        ? AppColors.fgPrimary
                        : AppColors.fgMuted,
                  ),
                ),
                const Spacer(),
                if (_isUnassigned)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppIcons.alert,
                        size: 14.sp,
                        color: AppColors.amberFg,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'Needs assignee',
                        style: AppText.figtree(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.amberFg,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        request.kind == SrKind.driver
                            ? AppIcons.car
                            : AppIcons.users,
                        size: 14.sp,
                        color: AppColors.fgTertiary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        assigneeName ?? '—',
                        style: AppText.figtree(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: AppColors.fgSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kind pill: "DRIVER HIRE" or "INSPECTION" with a matching icon.
class _KindPill extends StatelessWidget {
  const _KindPill({required this.kind});

  final SrKind kind;

  @override
  Widget build(BuildContext context) {
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
            kind == SrKind.driver ? AppIcons.car : AppIcons.search,
            size: 14.sp,
            color: AppColors.fgSecondary,
          ),
          SizedBox(width: 6.w),
          Text(
            kind.label.toUpperCase(),
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              letterSpacing: 0.04 * 11,
              color: AppColors.fgSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.primary,
    this.secondary,
    this.isLocation = false,
  });

  final IconData icon;
  final String primary;
  final String? secondary;
  final bool isLocation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: AppColors.fgTertiary),
        SizedBox(width: 8.w),
        if (isLocation)
          Expanded(
            child: Text(
              primary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w500,
                color: AppColors.fgSecondary,
              ),
            ),
          )
        else ...[
          Text(
            primary,
            style: AppText.figtree(
              size: 12.5,
              weight: FontWeight.w600,
            ),
          ),
          if (secondary != null) ...[
            SizedBox(width: 4.w),
            Text(
              secondary!,
              style: AppText.figtree(
                size: 12,
                weight: FontWeight.w500,
                color: AppColors.fgTertiary,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

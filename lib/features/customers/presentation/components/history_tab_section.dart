import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/status/booking_status.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/customer.dart';

/// History tab content for the Customer Detail screen.
///
/// Renders one server page of [CustomerBookingRef] rows as tappable cards,
/// with a "Showing N of M · K per page" footer and prev/next paging controls.
class HistoryTabSection extends StatelessWidget {
  const HistoryTabSection({
    required this.page,
    required this.onTapBooking,
    required this.onPrev,
    required this.onNext,
    super.key,
  });

  final CustomerHistoryPage page;

  /// Called with a [CustomerBookingRef]; the parent decides navigation vs. toast.
  final void Function(CustomerBookingRef) onTapBooking;

  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (page.rows.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Text(
            'No bookings yet.',
            style: AppText.figtree(
              size: 13.5,
              weight: FontWeight.w500,
              color: AppColors.fgMuted,
            ),
          ),
        ),
      );
    }

    final shownSoFar = (page.page - 1) * page.pageSize + page.rows.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final h in page.rows) ...[
          _HistoryCard(row: h, onTap: () => onTapBooking(h)),
          SizedBox(height: 12.h),
        ],
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Text(
              'Showing $shownSoFar of ${page.count} · ${page.pageSize} per page',
              style: AppText.figtree(
                size: 11.5,
                weight: FontWeight.w500,
                color: AppColors.fgMuted,
              ),
            ),
          ),
        ),
        if (page.hasPrevious || page.hasNext) ...[
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PageButton(
                label: 'Previous',
                enabled: page.hasPrevious,
                onTap: onPrev,
              ),
              SizedBox(width: 12.w),
              _PageButton(
                label: 'Next',
                enabled: page.hasNext,
                onTap: onNext,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.borderDefault),
          color: enabled ? AppColors.bgCard : AppColors.bgPage,
        ),
        child: Text(
          label,
          style: AppText.figtree(
            size: 13,
            weight: FontWeight.w700,
            color: enabled ? AppColors.fgPrimary : AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.row, required this.onTap});

  final CustomerBookingRef row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(14.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                label: row.status.label,
                tone: row.status.tone,
              ),
              Text(
                row.id,
                style: AppText.figtree(
                  size: 11.5,
                  weight: FontWeight.w500,
                  color: AppColors.fgTertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.shop,
                      style: AppText.figtree(
                        size: 13.5,
                        weight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      row.date,
                      style: AppText.figtree(
                        size: 12,
                        weight: FontWeight.w500,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.money(row.amount),
                style: AppText.figtree(
                  size: 15,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

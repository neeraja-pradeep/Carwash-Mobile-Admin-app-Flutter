import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/status/booking_status.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/customer.dart';

/// History tab content for the Customer Detail screen.
///
/// Renders each [CustomerBookingRef] as a tappable card with booking ID,
/// status badge, shop, date, and amount. Tapping navigates to booking detail
/// when the booking exists in the live dataset, otherwise shows a toast.
class HistoryTabSection extends StatelessWidget {
  const HistoryTabSection({
    required this.history,
    required this.totalBookings,
    required this.onTapBooking,
    super.key,
  });

  final List<CustomerBookingRef> history;
  final int totalBookings;

  /// Called with a [CustomerBookingRef]; the parent decides navigation vs. toast.
  final void Function(CustomerBookingRef) onTapBooking;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const EmptyState(
        icon: AppIcons.cal,
        title: 'No bookings yet',
        body: 'This customer has no booking history to display.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final h in history) ...[
          _HistoryCard(ref: h, onTap: () => onTapBooking(h)),
          SizedBox(height: 12.h),
        ],
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Text(
              'Showing ${history.length} of $totalBookings · 20 per page',
              style: AppText.figtree(
                size: 11.5,
                weight: FontWeight.w500,
                color: AppColors.fgMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.ref, required this.onTap});

  final CustomerBookingRef ref;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Trim the long prefix to a short display form matching the JSX:
    // "DD-KL-20260529-0042" → "#…0529-0042"
    final shortId = ref.id.replaceFirst('DD-KL-2026', '#…');

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(14.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                label: ref.status.label,
                tone: ref.status.tone,
              ),
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
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.shop,
                      style: AppText.figtree(
                        size: 13.5,
                        weight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${ref.date} 2026',
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
                Formatters.money(ref.amount),
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

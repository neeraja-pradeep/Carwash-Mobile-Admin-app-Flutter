import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/status/booking_status.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/features/bookings/domain/entities/booking.dart';

/// A status-action descriptor (mirrors the ACTIONS array in `screen_detail.jsx`).
class BookingAction {
  const BookingAction({
    required this.label,
    required this.from,
    required this.to,
    this.damage,
  });

  final String label;
  final BookingStatus from;
  final BookingStatus to;

  /// `'pickup'` | `'drop'` | null — whether this action requires a damage check.
  final String? damage;
}

/// The forward lifecycle actions matching the JSX ACTIONS array.
const List<BookingAction> kBookingActions = [
  BookingAction(
    label: 'Assign Me',
    from: BookingStatus.created,
    to: BookingStatus.assigned,
  ),
  BookingAction(
    label: 'Going for Pickup',
    from: BookingStatus.assigned,
    to: BookingStatus.going,
  ),
  BookingAction(
    label: 'Car Picked Up',
    from: BookingStatus.going,
    to: BookingStatus.picked,
    damage: 'pickup',
  ),
  BookingAction(
    label: 'Dropped at Shop',
    from: BookingStatus.picked,
    to: BookingStatus.atShop,
  ),
  BookingAction(
    label: 'Wash Started',
    from: BookingStatus.atShop,
    to: BookingStatus.washing,
  ),
  BookingAction(
    label: 'Wash Done',
    from: BookingStatus.washing,
    to: BookingStatus.done,
  ),
  BookingAction(
    label: 'Picked Up from Shop',
    from: BookingStatus.done,
    to: BookingStatus.returning,
  ),
  BookingAction(
    label: 'Dropped to Customer',
    from: BookingStatus.returning,
    to: BookingStatus.completed,
    damage: 'drop',
  ),
];

/// Inline status-update block. Each row is green (done), yellow (current),
/// or greyed-out (future). Rows that require a damage check show a label.
///
/// [status] is the current booking status; [onAdvance] is called when the
/// user taps the current action (may trigger a damage check in the parent).
class StatusUpdateBlock extends StatelessWidget {
  const StatusUpdateBlock({
    required this.status,
    required this.timeline,
    required this.onAdvance,
    super.key,
  });

  final BookingStatus status;
  final List<TimelineEntry> timeline;
  final void Function(BookingAction action) onAdvance;

  @override
  Widget build(BuildContext context) {
    if (status == BookingStatus.cancelled) {
      return AppCard(
        child: Row(
          children: [
            Icon(
              Icons.close_rounded,
              size: 20.sp,
              color: AppColors.redFg,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'This booking was cancelled. No further actions.',
                style: AppText.figtree(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: AppColors.redFg,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final ci = kBookingStatusOrder.indexOf(status);

    String? timeAt(BookingStatus s) {
      try {
        return timeline.firstWhere((t) => t.status == s).at;
      } catch (_) {
        return null;
      }
    }

    return AppCard(
      padded: false,
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Column(
          children: [
            for (final action in kBookingActions)
              _ActionRow(
                action: action,
                ci: ci,
                timeAt: timeAt(action.to),
                onTap: () => onAdvance(action),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.action,
    required this.ci,
    required this.timeAt,
    required this.onTap,
  });

  final BookingAction action;
  final int ci;
  final String? timeAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ti = kBookingStatusOrder.indexOf(action.to);
    final done = ti <= ci;
    final current = action.from == kBookingStatusOrder[ci];

    return Padding(
      padding: EdgeInsets.only(bottom: 9.h),
      child: GestureDetector(
        onTap: current ? onTap : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: current ? AppColors.brandYellow : AppColors.bgCard,
            borderRadius: BorderRadius.circular(11.r),
            border: Border.all(
              color: current ? AppColors.brandYellowDeep : AppColors.borderSoft,
            ),
          ),
          child: Opacity(
            opacity: (done || current) ? 1.0 : 0.5,
            child: Row(
              children: [
                // Status dot / check / arrow
                Container(
                  width: 22.r,
                  height: 22.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? AppColors.greenFg
                        : current
                            ? AppColors.fgPrimary
                            : AppColors.borderSoft,
                  ),
                  child: done
                      ? Icon(
                          AppIcons.check,
                          size: 14.sp,
                          color: AppColors.fgOnDark,
                        )
                      : current
                          ? Icon(
                              AppIcons.arrowRight,
                              size: 14.sp,
                              color: AppColors.fgOnDark,
                            )
                          : Center(
                              child: Container(
                                width: 6.r,
                                height: 6.r,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.fgMuted,
                                ),
                              ),
                            ),
                ),
                SizedBox(width: 11.w),

                // Label
                Expanded(
                  child: Text(
                    action.label,
                    style: AppText.figtree(
                      size: 14,
                      weight: current ? FontWeight.w700 : FontWeight.w600,
                      color: done ? AppColors.fgTertiary : AppColors.fgPrimary,
                    ),
                  ),
                ),

                // Done timestamp
                if (done && timeAt != null)
                  Text(
                    timeAt!,
                    style: AppText.figtree(
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppColors.greenFg,
                    ),
                  ),

                // Damage check label
                if (action.damage != null && current)
                  Text(
                    'Damage check',
                    style: AppText.figtree(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: const Color(0x8C000000),
                      letterSpacing: 0.4,
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

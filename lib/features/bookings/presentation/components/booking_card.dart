import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/status/badge_tone.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/status_badge.dart';

import '../../domain/entities/carwash_booking.dart';

/// Ride-hailing style "route-ladder" card for a car-wash booking.
///
/// Displays: status badge + reference, customer + vehicle, pickup (yellow-dot) →
/// shop (black store badge) ladder with addresses, driver or "Assign →"
/// button in the footer, and ₹ amount + payment status.
class BookingCard extends StatelessWidget {
  const BookingCard({
    required this.booking,
    required this.onTap,
    required this.onAssign,
    super.key,
  });

  final CarwashBooking booking;
  final VoidCallback onTap;
  final VoidCallback? onAssign;

  String _getStatusLabel() {
    if (booking.status == 'cancelled') return 'Cancelled';

    final isAssigned = booking.assigneeName != null && booking.assigneeName!.isNotEmpty;

    switch (booking.washingStatus) {
      case 'crew_en_route':
        return 'Going';
      case 'picked_up':
        return 'Picked';
      case 'dropped_at_shop':
        return 'At Shop';
      case 'in_progress':
        return 'Washing';
      case 'wash_done':
        return 'Done';
      case 'returning':
        return 'Returning';
      case 'completed':
        return 'Completed';
      default:
        if (booking.status == 'completed') return 'Completed';
        return isAssigned ? 'Assigned' : 'New';
    }
  }

  BadgeTone _getStatusTone() {
    final status = _getStatusLabel();
    switch (status) {
      case 'New':
        return BadgeTone.amber;
      case 'Assigned':
        return BadgeTone.blue;
      case 'Going':
      case 'Washing':
      case 'Picked':
      case 'At Shop':
        return BadgeTone.blue;
      case 'Returning':
        return BadgeTone.blue;
      case 'Done':
        return BadgeTone.green;
      case 'Completed':
        return BadgeTone.green;
      case 'Cancelled':
        return BadgeTone.red;
      default:
        return BadgeTone.grey;
    }
  }

  bool get _isUnassigned =>
      (booking.assigneeName == null || booking.assigneeName!.isEmpty) &&
      booking.status != 'cancelled' &&
      booking.status != 'completed';

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padded: false,
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: time anchor + reference + status badge
            Row(
              children: [
                Icon(
                  AppIcons.clock,
                  size: 15.sp,
                  color: AppColors.fgTertiary,
                ),
                SizedBox(width: 5.w),
                Text(
                  booking.startSlotTime ?? '—',
                  style: AppText.figtree(
                    size: 15,
                    weight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    '· ${booking.reference}',
                    overflow: TextOverflow.ellipsis,
                    style: AppText.figtree(
                      size: 11.5,
                      weight: FontWeight.w500,
                      color: AppColors.fgMuted,
                    ),
                  ),
                ),
                StatusBadge(
                  label: _getStatusLabel(),
                  tone: _getStatusTone(),
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // Row 2: customer name + vehicle
            Text(
              booking.customerName ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.figtree(
                size: 16,
                weight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              booking.vehicleLabel ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w500,
                color: AppColors.fgTertiary,
              ),
            ),

            // Row 3: route ladder
            Padding(
              padding: EdgeInsets.only(top: 13.h),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.borderSoft)),
                ),
                padding: EdgeInsets.only(top: 13.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ladder connector
                    Column(
                      children: [
                        // Yellow dot — pickup
                        Container(
                          width: 11.r,
                          height: 11.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brandYellow,
                            border: Border.all(
                              color: AppColors.brandYellowDeep,
                              width: 2,
                            ),
                          ),
                        ),
                        // Dotted line
                        Container(
                          width: 0,
                          height: 36.h,
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: AppColors.borderDefault,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                          ),
                        ),
                        // Store black square — shop
                        Container(
                          width: 16.r,
                          height: 16.r,
                          decoration: BoxDecoration(
                            color: AppColors.fgPrimary,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Icon(
                            AppIcons.store,
                            size: 10.sp,
                            color: AppColors.fgOnDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 10.w),

                    // Addresses
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pickup
                          Text(
                            'PICKUP · CUSTOMER',
                            style: AppText.figtree(
                              size: 9.5,
                              weight: FontWeight.w700,
                              color: AppColors.fgTertiary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            booking.pickupAddress ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.figtree(
                              size: 12.5,
                              weight: FontWeight.w500,
                            ),
                          ),

                          SizedBox(height: 12.h),

                          // Drop — shop
                          Text(
                            'DROP · SHOP',
                            style: AppText.figtree(
                              size: 9.5,
                              weight: FontWeight.w700,
                              color: AppColors.fgTertiary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.shopName ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.figtree(
                                  size: 12.5,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              if (booking.shopArea != null)
                                Text(
                                  booking.shopArea!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.figtree(
                                    size: 11.5,
                                    weight: FontWeight.w500,
                                    color: AppColors.fgTertiary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer: money + payment | driver / assign
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.borderSoft)),
                ),
                padding: EdgeInsets.only(top: 11.h),
                child: Row(
                  children: [
                    // Money + payment
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            booking.amount ?? '₹0',
                            style: AppText.figtree(
                              size: 16,
                              weight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            width: 3.r,
                            height: 3.r,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.borderDefault,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            booking.isPaid == true ? 'Paid' : (booking.paymentStatus ?? 'Pending'),
                            style: AppText.figtree(
                              size: 12,
                              weight: FontWeight.w600,
                              color: booking.isPaid == true
                                  ? AppColors.greenFg
                                  : AppColors.amberFg,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Assign or driver
                    if (_isUnassigned && onAssign != null)
                      GestureDetector(
                        onTap: onAssign,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow,
                            borderRadius: BorderRadius.circular(9.r),
                            border: Border.all(
                              color: AppColors.brandYellowDeep,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Assign',
                                style: AppText.figtree(
                                  size: 12,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Icon(
                                AppIcons.arrowRight,
                                size: 14.sp,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.car,
                            size: 14.sp,
                            color: AppColors.fgTertiary,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            booking.assigneeName ?? '—',
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
            ),
          ],
        ),
      ),
    );
  }
}

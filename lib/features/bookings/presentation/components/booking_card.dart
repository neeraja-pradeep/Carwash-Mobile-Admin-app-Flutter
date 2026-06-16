import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/status/booking_status.dart';
import 'package:new_flutter_project/core/status/payment_status.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/status_badge.dart';
import 'package:new_flutter_project/features/shops/application/providers/shops_providers.dart';
import 'package:new_flutter_project/features/drivers/application/providers/drivers_providers.dart';

import '../../domain/entities/booking.dart';

/// Ride-hailing style "route-ladder" card for a car-wash booking.
///
/// Displays: status badge + ID, customer + vehicle, pickup (yellow-dot) →
/// shop (black store badge) ladder with addresses, driver or "Assign →"
/// button in the footer, and ₹ total + payment status.
class BookingCard extends ConsumerWidget {
  const BookingCard({
    required this.booking,
    required this.onTap,
    required this.onAssign,
    super.key,
  });

  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopByIdProvider(booking.shopId));
    final driverAsync = booking.driverId != null
        ? ref.watch(assigneeByIdProvider(booking.driverId!))
        : null;

    final unassigned = booking.driverId == null &&
        booking.status != BookingStatus.cancelled &&
        booking.status != BookingStatus.completed;

    final shortId = booking.id.replaceAll('DD-KL-20260529-', '#');

    return AppCard(
      onTap: onTap,
      padded: false,
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: time anchor + status badge
            Row(
              children: [
                Icon(
                  AppIcons.clock,
                  size: 15.sp,
                  color: AppColors.fgTertiary,
                ),
                SizedBox(width: 5.w),
                Text(
                  booking.pickup.time,
                  style: AppText.figtree(
                    size: 15,
                    weight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    '· $shortId',
                    overflow: TextOverflow.ellipsis,
                    style: AppText.figtree(
                      size: 11.5,
                      weight: FontWeight.w500,
                      color: AppColors.fgMuted,
                    ),
                  ),
                ),
                StatusBadge(
                  label: booking.status.label,
                  tone: booking.status.tone,
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // Row 2: customer name + vehicle
            Text(
              booking.customer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.figtree(
                size: 16,
                weight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              '${booking.vehicle.make} ${booking.vehicle.model} · ${booking.vehicle.plate ?? ""}',
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
                            booking.pickup.address,
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
                          shopAsync.when(
                            loading: () => Container(
                              height: 14.h,
                              width: 120.w,
                              color: AppColors.borderSoft,
                            ),
                            error: (_, __) => Text(
                              booking.shopId,
                              style: AppText.figtree(
                                size: 12.5,
                                weight: FontWeight.w600,
                              ),
                            ),
                            data: (shop) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop?.name ?? booking.shopId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.figtree(
                                    size: 12.5,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                if (shop?.area != null)
                                  Text(
                                    shop!.area,
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
                            Formatters.money(booking.total),
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
                            booking.payment.label,
                            style: AppText.figtree(
                              size: 12,
                              weight: FontWeight.w600,
                              color: _paymentColor(booking.payment),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Assign or driver
                    if (unassigned)
                      GestureDetector(
                        onTap: () {
                          onAssign();
                        },
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
                          driverAsync != null
                              ? driverAsync.when(
                                  loading: () => Container(
                                    height: 12.h,
                                    width: 60.w,
                                    color: AppColors.borderSoft,
                                  ),
                                  error: (_, __) => Text(
                                    '—',
                                    style: AppText.figtree(
                                      size: 12.5,
                                      weight: FontWeight.w500,
                                      color: AppColors.fgSecondary,
                                    ),
                                  ),
                                  data: (driver) => Text(
                                    driver?.name ?? '—',
                                    style: AppText.figtree(
                                      size: 12.5,
                                      weight: FontWeight.w500,
                                      color: AppColors.fgSecondary,
                                    ),
                                  ),
                                )
                              : Text(
                                  '—',
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

  Color _paymentColor(PaymentStatus p) {
    switch (p) {
      case PaymentStatus.paid:
        return AppColors.greenFg;
      case PaymentStatus.refunded:
        return AppColors.redFg;
      case PaymentStatus.pending:
        return AppColors.amberFg;
    }
  }
}

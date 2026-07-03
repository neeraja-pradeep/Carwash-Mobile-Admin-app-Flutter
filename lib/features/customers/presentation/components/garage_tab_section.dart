import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../domain/entities/customer.dart';

/// Garage tab content for the Customer Detail screen.
///
/// Shows each vehicle as a card with make/model, type + booking count, plate
/// tag, and a Default badge when applicable. Read-only.
class GarageTabSection extends StatelessWidget {
  const GarageTabSection({required this.vehicles, super.key});

  final List<GarageVehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final v in vehicles) ...[
          _VehicleCard(vehicle: v),
          SizedBox(height: 12.h),
        ],
        Center(
          child: Text(
            'Read-only · managed by customer',
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w500,
              color: AppColors.fgMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});

  final GarageVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bgPage,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              AppIcons.car,
              size: 22.sp,
              color: AppColors.fgSecondary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        vehicle.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.figtree(
                          size: 15,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (vehicle.isDefault) ...[
                      SizedBox(width: 7.w),
                      // Flexible so the pill can ellipsise instead of pushing
                      // the row past its width when the column is squeezed
                      // (long name / plate + large system font scale).
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blueBg,
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          child: Text(
                            'Default'.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: AppText.figtree(
                              size: 9,
                              weight: FontWeight.w600,
                              color: AppColors.blueFg,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  '${vehicle.type} · ${vehicle.bookings} bookings',
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: AppColors.fgTertiary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // Cap the plate width so it keeps its natural size normally (the
          // greedy middle column is undisturbed) but ellipsises instead of
          // overflowing under a large system font scale.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 0.42.sw),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.bgPage,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Text(
                vehicle.plate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AppText.figtree(
                  size: 12,
                  weight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

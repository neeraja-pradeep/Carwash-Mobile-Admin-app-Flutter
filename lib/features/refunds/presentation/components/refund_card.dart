import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/status_badge.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import '../../domain/entities/refund.dart';

/// A single refund row card for the list screen.
class RefundCard extends StatelessWidget {
  const RefundCard({
    required this.refund,
    required this.onTap,
    super.key,
  });

  final Refund refund;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.money(refund.amount),
                style: AppText.figtree(
                  size: 19,
                  weight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              StatusBadge(label: refund.statusLabel, tone: refund.tone),
            ],
          ),
          SizedBox(height: 7.h),
          Text(
            refund.bookingId,
            style: AppText.figtree(
              size: 11.5,
              weight: FontWeight.w500,
              color: AppColors.fgTertiary,
            ),
          ),
          SizedBox(height: 11.h),
          Divider(height: 1.h, color: AppColors.borderSoft),
          SizedBox(height: 11.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          refund.customer.name,
                          style: AppText.figtree(
                            size: 13.5,
                            weight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          refund.customer.phone,
                          style: AppText.figtree(
                            size: 12,
                            weight: FontWeight.w500,
                            color: AppColors.fgTertiary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    RichText(
                      text: TextSpan(
                        style: AppText.figtree(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: AppColors.fgSecondary,
                        ),
                        children: [
                          TextSpan(text: refund.reason),
                          TextSpan(
                            text: ' · ${refund.tier}',
                            style: AppText.figtree(
                              size: 12.5,
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
          SizedBox(height: 6.h),
          Text(
            'Created ${refund.createdAt}',
            style: AppText.figtree(
              size: 11.5,
              weight: FontWeight.w500,
              color: AppColors.fgMuted,
            ),
          ),
        ],
      ),
    );
  }
}

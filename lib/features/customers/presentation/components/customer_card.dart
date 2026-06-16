import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/status/badge_tone.dart';
import '../../domain/entities/customer.dart';

/// A compact customer summary card: avatar, name+status badge, phone, and
/// the three stat cells (bookings, spend, last active). Tapping opens the
/// customer detail screen.
class CustomerCard extends StatelessWidget {
  const CustomerCard({
    required this.customer,
    required this.onTap,
    super.key,
  });

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(name: customer.name, size: 42),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.figtree(
                              size: 15.5,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        StatusBadge(
                          label: customer.blocked ? 'Blocked' : 'Active',
                          tone: customer.blocked ? BadgeTone.grey : BadgeTone.green,
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      customer.phone,
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
          SizedBox(height: 13.h),
          Container(
            padding: EdgeInsets.only(top: 13.h),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Row(
              children: [
                _StatCell(
                  value: '${customer.bookings}',
                  label: 'Bookings',
                ),
                SizedBox(width: 18.w),
                _StatCell(
                  value: Formatters.money(customer.spend),
                  label: 'Spent',
                ),
                const Spacer(),
                Text(
                  'Last ${customer.lastBooking}',
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: AppColors.fgSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppText.figtree(size: 14, weight: FontWeight.w700),
        ),
        SizedBox(height: 3.h),
        Text(
          label.toUpperCase(),
          style: AppText.figtree(
            size: 10,
            weight: FontWeight.w600,
            color: AppColors.fgTertiary,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/status_badge.dart';
import 'package:new_flutter_project/core/status/badge_tone.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import '../../domain/repositories/payouts_repository.dart';

/// A single payout row card for the list screen (API-based PayoutLogItem)
class PayoutCard extends ConsumerWidget {
  const PayoutCard({
    required this.payout,
    required this.onTap,
    super.key,
  });

  final PayoutLogItem payout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusLabel =
        payout.status == 'paid' ? 'Paid' : payout.status.toUpperCase();
    final tone = payout.status == 'paid' ? BadgeTone.green : BadgeTone.amber;
    final periodDisplay = '${payout.periodStart} to ${payout.periodEnd}';

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  payout.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.figtree(
                    size: 15,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              StatusBadge(label: statusLabel, tone: tone),
            ],
          ),
          SizedBox(height: 5.h),
          Text(
            periodDisplay,
            style: AppText.figtree(
              size: 12,
              weight: FontWeight.w500,
              color: AppColors.fgTertiary,
            ),
          ),
          SizedBox(height: 11.h),
          Divider(height: 1.h, color: AppColors.borderSoft),
          SizedBox(height: 11.h),
          Wrap(
            spacing: 16.w,
            runSpacing: 6.h,
            children: [
              _CalcItem(
                label: 'Gross',
                value: Formatters.money(payout.grossAmount.toInt()),
              ),
              _CalcItem(
                label: 'Comm',
                value: Formatters.money(payout.commissionAmount.toInt()),
              ),
              if (payout.refundsTotal > 0)
                _CalcItem(
                  label: 'Refunds',
                  value: Formatters.money(payout.refundsTotal.toInt()),
                  valueColor: AppColors.redFg,
                ),
              _NetItem(
                value: Formatters.money(payout.totalAmount.toInt()),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'PO: ${payout.reference} | Created ${payout.createdAt.year}-${payout.createdAt.month.toString().padLeft(2, '0')}-${payout.createdAt.day.toString().padLeft(2, '0')}',
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

class _CalcItem extends StatelessWidget {
  const _CalcItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppText.figtree(
          size: 12.5,
          weight: FontWeight.w500,
          color: AppColors.fgSecondary,
        ),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: AppText.figtree(
              size: 12.5,
              weight: FontWeight.w700,
              color: valueColor ?? AppColors.fgPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetItem extends StatelessWidget {
  const _NetItem({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppText.figtree(
          size: 15,
          weight: FontWeight.w800,
          color: AppColors.fgPrimary,
        ),
        children: [
          TextSpan(
            text: 'Net ',
            style: AppText.figtree(
              size: 12.5,
              weight: FontWeight.w500,
              color: AppColors.fgSecondary,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

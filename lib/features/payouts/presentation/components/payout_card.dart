import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/status_badge.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/features/shops/application/providers/shops_providers.dart';
import '../../domain/entities/payout.dart';

/// A single payout row card for the list screen.
class PayoutCard extends ConsumerWidget {
  const PayoutCard({
    required this.payout,
    required this.onTap,
    super.key,
  });

  final Payout payout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopByIdProvider(payout.shopId));
    final shopName = shopAsync.valueOrNull?.name ?? payout.shopId;
    final c = payout.calc;

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
                  shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.figtree(
                    size: 15,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              StatusBadge(label: payout.statusLabel, tone: payout.tone),
            ],
          ),
          SizedBox(height: 5.h),
          Text(
            'Period: ${payout.period}',
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
              _CalcItem(label: 'Gross', value: Formatters.money(c.gross)),
              _CalcItem(label: 'Comm', value: Formatters.money(c.commission)),
              if (c.refunds > 0)
                _CalcItem(
                  label: 'Refunds',
                  value: Formatters.money(c.refunds),
                  valueColor: AppColors.redFg,
                ),
              _NetItem(value: Formatters.money(c.net)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Created ${payout.createdAt}',
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

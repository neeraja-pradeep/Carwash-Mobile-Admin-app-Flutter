import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/core/widgets/widgets.dart';

import '../../application/providers/settlement_providers.dart';
import '../../domain/entities/shop.dart';

/// Settlement tab body for ShopDetailScreen using API exclusively.
/// No mock data - all failures show error to user.
class SettlementSection extends ConsumerWidget {
  const SettlementSection({
    required this.shop,
    required this.onCreatePayout,
    super.key,
  });

  final Shop shop;
  final VoidCallback onCreatePayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingSettlementsProvider(shop.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pending settlements section
        pendingAsync.when(
          loading: () => AppCard(
            padded: false,
            child: SizedBox(
              height: 120.h,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (err, st) => AppCard(
            child: ErrorView(
              onRetry: () => ref.invalidate(pendingSettlementsProvider(shop.id)),
            ),
          ),
          data: (pending) {
            final rows = pending.items;
            final totNet = pending.pendingTotal;

            return Column(
              children: [
                // KPI header
                AppCard(
                  padded: false,
                  child: Row(
                    children: [
                      _SettleCell(
                        value: Formatters.money(totNet.toInt()),
                        label: 'Pending',
                        valueColor: totNet > 0 ? AppColors.amberFg : null,
                        isFirst: true,
                      ),
                      _SettleCell(
                        value: pending.lastSettled != null
                            ? '${pending.lastSettled!.day}/${pending.lastSettled!.month}/${pending.lastSettled!.year}'
                            : '—',
                        label: 'Last settled',
                      ),
                      _SettleCell(
                        value: Formatters.money(pending.lifetimePaid.toInt()),
                        label: 'Lifetime paid',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // Pending settlements list
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PENDING SETTLEMENTS',
                        style: AppText.figtree(
                          size: 11,
                          weight: FontWeight.w700,
                          color: AppColors.fgSecondary,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (rows.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: Center(
                            child: Text(
                              'Nothing pending — all settled.',
                              style: AppText.figtree(
                                size: 13,
                                weight: FontWeight.w500,
                                color: AppColors.fgMuted,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        SizedBox(height: 6.h),
                        ...List.generate(rows.length, (i) {
                          final item = rows[i];
                          return Container(
                            padding: EdgeInsets.symmetric(vertical: 11.h),
                            decoration: i < rows.length - 1
                                ? const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: AppColors.borderSoft),
                                    ),
                                  )
                                : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.reference,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.fgSecondary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      Formatters.money(item.net.toInt()),
                                      style: AppText.figtree(
                                        size: 14,
                                        weight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5.h),
                                Wrap(
                                  spacing: 12.w,
                                  children: [
                                    Text(
                                      item.appointmentDate,
                                      style: AppText.figtree(
                                        size: 11.5,
                                        weight: FontWeight.w500,
                                        color: AppColors.fgTertiary,
                                      ),
                                    ),
                                    Text(
                                      'Gross ${Formatters.money(item.gross.toInt())}',
                                      style: AppText.figtree(
                                        size: 11.5,
                                        weight: FontWeight.w500,
                                        color: AppColors.fgTertiary,
                                      ),
                                    ),
                                    Text(
                                      '− Comm ${Formatters.money(item.commission.toInt())}',
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
                          );
                        }),
                        Container(
                          margin: EdgeInsets.only(top: 12.h),
                          padding: EdgeInsets.only(top: 12.h),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.borderDefault,
                                width: 1.5.h,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Net payable',
                                style: AppText.figtree(
                                  size: 14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                Formatters.money(totNet.toInt()),
                                style: AppText.figtree(
                                  size: 19,
                                  weight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),
                        AppButton(
                          label: 'Create Payout for This Shop',
                          full: true,
                          size: AppButtonSize.sm,
                          icon: AppIcons.wallet,
                          onPressed: onCreatePayout,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                // History only loads AFTER pending data is available
                _PayoutHistorySection(shopId: shop.id),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Payout history section (loads only after pending completes)
class _PayoutHistorySection extends ConsumerWidget {
  const _PayoutHistorySection({required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(payoutHistoryProvider(shopId));

    return historyAsync.when(
      loading: () => AppCard(
        child: SizedBox(
          height: 120.h,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, st) => AppCard(
        child: ErrorView(
          onRetry: () => ref.invalidate(payoutHistoryProvider(shopId)),
        ),
      ),
      data: (history) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PAYOUT HISTORY',
                style: AppText.figtree(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.fgSecondary,
                  letterSpacing: 0.1,
                ),
              ),
              if (history.payouts.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Center(
                    child: Text(
                      'No payouts yet.',
                      style: AppText.figtree(
                        size: 13,
                        weight: FontWeight.w500,
                        color: AppColors.fgMuted,
                      ),
                    ),
                  ),
                )
              else ...[
                SizedBox(height: 6.h),
                ...List.generate(history.payouts.length, (i) {
                  final payout = history.payouts[i];
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: i < history.payouts.length - 1
                        ? const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.borderSoft),
                            ),
                          )
                        : null,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${payout.periodStart} to ${payout.periodEnd}',
                              style: AppText.figtree(
                                size: 13.5,
                                weight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Bookings: ${payout.bookingCount}',
                              style: AppText.figtree(
                                size: 11.5,
                                weight: FontWeight.w500,
                                color: AppColors.fgTertiary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.money(payout.totalAmount.toInt()),
                              style: AppText.figtree(
                                size: 15,
                                weight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.greenBg,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                payout.status.toUpperCase(),
                                style: AppText.figtree(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: AppColors.greenFg,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SettleCell extends StatelessWidget {
  const _SettleCell({
    required this.value,
    required this.label,
    this.valueColor,
    this.isFirst = false,
  });

  final String value;
  final String label;
  final Color? valueColor;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : Border(left: BorderSide(color: AppColors.borderSoft)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppText.figtree(
                size: 16,
                weight: FontWeight.w800,
                color: valueColor ?? AppColors.fgPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppText.figtree(
                size: 10,
                weight: FontWeight.w600,
                color: AppColors.fgSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

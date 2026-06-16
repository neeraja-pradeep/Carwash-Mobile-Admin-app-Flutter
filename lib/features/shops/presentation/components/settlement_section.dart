import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/core/widgets/widgets.dart';

import '../../domain/entities/shop.dart';

/// Settlement tab body for ShopDetailScreen.
/// Mirrors `SettlementTab` in `screen_shopdetail.jsx`.
class SettlementSection extends StatelessWidget {
  const SettlementSection({
    required this.shop,
    required this.onCreatePayout,
    super.key,
  });

  final Shop shop;
  final VoidCallback onCreatePayout;

  @override
  Widget build(BuildContext context) {
    final st = shop.settlement;
    final rows = st.pending
        .map((p) => (
              pending: p,
              net: p.net,
            ))
        .toList();

    final totGross =
        st.pending.fold<int>(0, (a, r) => a + r.gross);
    final totComm =
        st.pending.fold<int>(0, (a, r) => a + r.commission);
    final totRef =
        st.pending.fold<int>(0, (a, r) => a + r.refund);
    final totNet = totGross - totComm - totRef;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top KPI strip
        AppCard(
          padded: false,
          child: Row(
            children: [
              _SettleCell(
                value: Formatters.money(totNet),
                label: 'Pending',
                valueColor:
                    totNet > 0 ? AppColors.amberFg : AppColors.fgPrimary,
                isFirst: true,
              ),
              _SettleCell(value: st.lastSettled, label: 'Last settled'),
              _SettleCell(
                value: Formatters.money(st.lifetimePaid),
                label: 'Lifetime paid',
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Pending settlements
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
                  final r = rows[i].pending;
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    decoration: i < rows.length - 1
                        ? const BoxDecoration(
                            border: Border(
                              bottom:
                                  BorderSide(color: AppColors.borderSoft),
                            ),
                          )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              r.bookingId.replaceAll('DD-KL-2026', '#…'),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.fgSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              Formatters.money(r.net),
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
                              r.date,
                              style: AppText.figtree(
                                size: 11.5,
                                weight: FontWeight.w500,
                                color: AppColors.fgTertiary,
                              ),
                            ),
                            Text(
                              'Gross ${Formatters.money(r.gross)}',
                              style: AppText.figtree(
                                size: 11.5,
                                weight: FontWeight.w500,
                                color: AppColors.fgTertiary,
                              ),
                            ),
                            Text(
                              '− Comm ${Formatters.money(r.commission)}',
                              style: AppText.figtree(
                                size: 11.5,
                                weight: FontWeight.w500,
                                color: AppColors.fgTertiary,
                              ),
                            ),
                            if (r.refund > 0)
                              Text(
                                '− Ref ${Formatters.money(r.refund)}',
                                style: AppText.figtree(
                                  size: 11.5,
                                  weight: FontWeight.w500,
                                  color: AppColors.redFg,
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
                        Formatters.money(totNet),
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

        // Payout history
        AppCard(
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
              SizedBox(height: 6.h),
              ...List.generate(st.history.length, (i) {
                final h = st.history[i];
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: i < st.history.length - 1
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
                            h.period,
                            style: AppText.figtree(
                              size: 13.5,
                              weight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'UTR ${h.utr}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5.sp,
                              color: AppColors.fgTertiary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        Formatters.money(h.net),
                        style: AppText.figtree(
                          size: 14,
                          weight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _HistoryPill(label: h.status),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
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
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 8.w),
        decoration: isFirst
            ? null
            : const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.borderSoft),
                ),
              ),
        child: Column(
          children: [
            Text(
              value,
              style: AppText.figtree(
                size: 16,
                weight: FontWeight.w800,
                color: valueColor ?? AppColors.fgPrimary,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              label.toUpperCase(),
              style: AppText.figtree(
                size: 10,
                weight: FontWeight.w600,
                color: AppColors.fgTertiary,
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryPill extends StatelessWidget {
  const _HistoryPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.greenBg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.r,
            height: 5.r,
            decoration: const BoxDecoration(
              color: AppColors.greenFg,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            label,
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.greenFg,
            ),
          ),
        ],
      ),
    );
  }
}

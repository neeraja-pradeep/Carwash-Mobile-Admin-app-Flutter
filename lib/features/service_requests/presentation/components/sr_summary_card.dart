import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';

import '../../domain/entities/service_request.dart';

/// Completion summary card shown on completed service requests.
///
/// Mirrors the Service Summary section in `screen_servicereq.jsx` (lines
/// 243–279): a yellow header bar, conditional duration / extra-distance rows,
/// base fee, an amber "additional charge" sub-box with its reason, the
/// total (labelled "payable" when extra is owed, "collected" otherwise) and a
/// collect-extra / paid-in-full footer line.
class SrSummaryCard extends StatelessWidget {
  const SrSummaryCard({required this.summary, super.key});

  final SrSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasExtra = summary.extraCharge > 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.brandYellowDeep),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yellow header bar.
          Container(
            width: double.infinity,
            color: AppColors.brandYellow,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
            child: Row(
              children: [
                Icon(AppIcons.receipt, size: 17.sp, color: AppColors.fgPrimary),
                SizedBox(width: 9.w),
                Text(
                  'Service Summary',
                  style: AppText.figtree(size: 13, weight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // Body.
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Duration — only when actual hours were captured.
                if (summary.actualHours > 0)
                  _Row(
                    label: 'Duration',
                    value:
                        '${summary.plannedHours}h planned · ${summary.actualHours}h actual',
                  ),
                // Extra distance — only when > 0.
                if (summary.extraKm > 0)
                  _Row(
                    label: 'Extra distance',
                    value: '${summary.extraKm} km',
                  ),
                _Row(
                  label: 'Base fee',
                  value: Formatters.money(summary.baseFee),
                ),

                // Additional charge — amber sub-box with reason.
                if (hasExtra) ...[
                  SizedBox(height: 4.h),
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.amberBg,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Additional charge',
                              style: AppText.figtree(
                                size: 13,
                                weight: FontWeight.w700,
                                color: AppColors.amberFg,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '+ ${Formatters.money(summary.extraCharge)}',
                              style: AppText.figtree(
                                size: 13,
                                weight: FontWeight.w700,
                                color: AppColors.amberFg,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          summary.extraReason,
                          style: AppText.figtree(
                            size: 11.5,
                            weight: FontWeight.w500,
                            color: AppColors.amberFg,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Total.
                Container(
                  margin: EdgeInsets.only(top: 10.h),
                  padding: EdgeInsets.only(top: 11.h),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: AppColors.borderDefault, width: 1.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        hasExtra ? 'Total payable' : 'Total collected',
                        style:
                            AppText.figtree(size: 14, weight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        Formatters.money(summary.total),
                        style:
                            AppText.figtree(size: 18, weight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),

                // Footer status line.
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      summary.paid ? AppIcons.checkCircle : AppIcons.alert,
                      size: 14.sp,
                      color:
                          summary.paid ? AppColors.greenFg : AppColors.amberFg,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        summary.paid
                            ? 'Paid in full'
                            : hasExtra
                                ? 'Collect extra ${Formatters.money(summary.extraCharge)} from customer'
                                : 'Mark collected on payment',
                        style: AppText.figtree(
                          size: 12,
                          weight: FontWeight.w600,
                          color: summary.paid
                              ? AppColors.greenFg
                              : AppColors.amberFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        children: [
          Text(
            label,
            style: AppText.figtree(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.fgSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppText.figtree(size: 13, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

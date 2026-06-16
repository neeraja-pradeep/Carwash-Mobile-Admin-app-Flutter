import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/status_badge.dart';
import 'package:new_flutter_project/core/status/badge_tone.dart';

import '../../domain/entities/service_request.dart';

/// Completion summary card shown on completed service requests.
///
/// Mirrors the Service Summary section in `screen_servicereq.jsx`:
/// planned vs actual hours, deviation, base fee, extra charge, total, paid status.
class SrSummaryCard extends StatelessWidget {
  const SrSummaryCard({required this.summary, super.key});

  final SrSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Service Summary',
                style: AppText.figtree(size: 14, weight: FontWeight.w700),
              ),
              const Spacer(),
              StatusBadge(
                label: summary.paid ? 'Paid' : 'Unpaid',
                tone: summary.paid ? BadgeTone.green : BadgeTone.amber,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _SummaryRow(
            label: 'Planned duration',
            value: '${summary.plannedHours} hrs',
          ),
          _SummaryRow(
            label: 'Actual duration',
            value: '${summary.actualHours} hrs',
            highlight: summary.actualHours > summary.plannedHours,
          ),
          if (summary.extraCharge > 0) ...[
            _SummaryRow(
              label: 'Base fee',
              value: Formatters.money(summary.baseFee),
            ),
            _SummaryRow(
              label: 'Extra charge',
              value: '+${Formatters.money(summary.extraCharge)}',
              highlight: true,
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Text(
                summary.extraReason,
                style: AppText.figtree(
                  size: 12,
                  weight: FontWeight.w400,
                  color: AppColors.fgTertiary,
                  height: 1.4,
                ),
              ),
            ),
          ],
          Container(
            padding: EdgeInsets.only(top: 11.h),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Row(
              children: [
                Text(
                  'Total',
                  style: AppText.figtree(size: 14, weight: FontWeight.w700),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      AppIcons.rupee,
                      size: 15.sp,
                      color: AppColors.fgPrimary,
                    ),
                    Text(
                      Formatters.money(summary.total)
                          .replaceFirst('₹', ''),
                      style: AppText.figtree(
                        size: 16,
                        weight: FontWeight.w800,
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Text(
            label,
            style: AppText.figtree(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.fgTertiary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppText.figtree(
              size: 13.5,
              weight: FontWeight.w600,
              color: highlight ? AppColors.amberFg : AppColors.fgPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';

/// Weekly earnings bar chart — mirrors the 7-day bar chart in the Earnings tab
/// of `screen_driver_app.jsx`.
///
/// Each day is a vertical bar scaled to the week's max: a day with earnings is
/// brand-yellow, a zero day shows a short [AppColors.borderSoft] stub. The
/// weekday's first letter sits below each bar. No "today" emphasis or tooltips
/// (the design has none).
class EarningsBarChart extends StatelessWidget {
  const EarningsBarChart({required this.byDay, super.key});

  /// Ordered `(weekday label, amount)` pairs, e.g. `[('Mon', 480), ...]`.
  final List<(String, int)> byDay;

  static const double _maxBarH = 50;

  @override
  Widget build(BuildContext context) {
    final maxAmount = byDay.fold<int>(1, (m, e) => e.$2 > m ? e.$2 : m);

    return SizedBox(
      height: 72.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: byDay.map((entry) {
          final label = entry.$1;
          final amount = entry.$2;
          final barH = (amount / maxAmount * _maxBarH).clamp(4.0, _maxBarH);

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.5.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: _maxBarH.h,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        height: barH.h,
                        decoration: BoxDecoration(
                          color: amount > 0
                              ? AppColors.brandYellow
                              : AppColors.borderSoft,
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    label.isEmpty ? '' : label[0],
                    style: AppText.figtree(
                      size: 10,
                      weight: FontWeight.w600,
                      color: AppColors.fgTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

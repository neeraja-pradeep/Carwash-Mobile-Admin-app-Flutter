import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';

/// Weekly earnings bar chart — mirrors the 7-day bar chart in
/// `screen_driver_app.jsx` Earnings tab.
///
/// Renders vertical brand-yellow bars scaled relative to the week max,
/// with weekday labels below and the highlighted today column.
class EarningsBarChart extends StatelessWidget {
  const EarningsBarChart({
    required this.byDay,
    this.todayLabel = 'Wed',
    super.key,
  });

  /// Ordered list of `(weekday label, amount)` pairs e.g. `[('Mon', 320), ...]`.
  final List<(String, int)> byDay;

  /// Which weekday label should be highlighted as "today".
  final String todayLabel;

  static const double _maxBarH = 80;

  @override
  Widget build(BuildContext context) {
    final maxAmount = byDay.fold<int>(
      0,
      (max, e) => e.$2 > max ? e.$2 : max,
    );

    return SizedBox(
      height: (_maxBarH + 36).h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: byDay.map((entry) {
          final label = entry.$1;
          final amount = entry.$2;
          final isToday = label == todayLabel;
          final frac = maxAmount == 0 ? 0.0 : amount / maxAmount;
          final barH = (_maxBarH * frac).clamp(4.0, _maxBarH);

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Amount tooltip above active bar
                if (isToday && amount > 0)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      Formatters.money(amount),
                      style: AppText.figtree(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.fgPrimary,
                      ),
                    ),
                  )
                else
                  SizedBox(height: 18.h),

                // Bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  height: barH.h,
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.brandYellow
                        : amount == 0
                            ? AppColors.borderSoft
                            : AppColors.brandYellowLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4.r),
                    ),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: const Color(0x66D6B112),
                              offset: Offset(0, 2.h),
                              blurRadius: 6.r,
                            ),
                          ]
                        : null,
                  ),
                ),

                SizedBox(height: 6.h),
                Text(
                  label,
                  style: AppText.figtree(
                    size: 11,
                    weight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday ? AppColors.fgPrimary : AppColors.fgTertiary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

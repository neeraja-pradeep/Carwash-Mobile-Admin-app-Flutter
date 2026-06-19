import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../drivers/domain/entities/driver_earnings.dart';
import '../../application/providers/driver_app_providers.dart';
import '../components/earnings_bar_chart.dart';

/// Driver app "Earnings" tab — today/week/month totals, bar chart (7-day or
/// 4-week), breakdown rows, and last payout info.
/// Period toggle: Week | Month.
class DriverEarningsScreen extends ConsumerWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(earningsPeriodProvider);
    final earningsAsync = ref.watch(driverEarningsByPeriodProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with period toggle
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border:
                    Border(bottom: BorderSide(color: AppColors.borderSoft)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Earnings',
                      style: AppText.figtree(
                        size: 18,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Period toggle: Week | Month
                  _PeriodToggle(
                    period: period,
                    onChanged: (p) =>
                        ref.read(earningsPeriodProvider.notifier).state = p,
                  ),
                ],
              ),
            ),

            Expanded(
              child: earningsAsync.when(
                loading: () => ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: 3,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, __) => const SkeletonCard(),
                ),
                error: (_, __) => const Center(
                  child: Text('Could not load earnings.'),
                ),
                data: (earnings) => _EarningsBody(
                  earnings: earnings,
                  period: period,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Period toggle ─────────────────────────────────────────────────────────────

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.period, required this.onChanged});

  final String period;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodBtn(
            label: 'Week',
            active: period == 'week',
            onTap: () => onChanged('week'),
          ),
          SizedBox(width: 2.w),
          _PeriodBtn(
            label: 'Month',
            active: period == 'month',
            onTap: () => onChanged('month'),
          ),
        ],
      ),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  const _PeriodBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? AppColors.bgCard : Colors.transparent,
          borderRadius: BorderRadius.circular(7.r),
          border: active
              ? Border.all(color: AppColors.borderSoft)
              : null,
        ),
        child: Text(
          label,
          style: AppText.figtree(
            size: 12.5,
            weight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.fgPrimary : AppColors.fgTertiary,
          ),
        ),
      ),
    );
  }
}

class _EarningsBody extends StatelessWidget {
  const _EarningsBody({required this.earnings, required this.period});

  final DriverEarnings earnings;
  final String period;

  @override
  Widget build(BuildContext context) {
    final isMonth = period == 'month';
    final periodLabel = isMonth ? 'This Month' : 'This Week';
    final periodTotal = earnings.weekTotal; // weekTotal field holds the period total
    // For the bar chart, month view uses week labels; week view uses day labels.
    final todayLabel = isMonth ? '' : 'Wed'; // no today-highlight in month view

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        // Period totals card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                periodLabel,
                style: AppText.figtree(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.fgTertiary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                Formatters.money(periodTotal),
                style: AppText.figtree(
                  size: 28,
                  weight: FontWeight.w700,
                  color: AppColors.fgPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  if (!isMonth) ...[
                    _MiniBadge(
                      label: 'Today ${Formatters.money(earnings.todayTotal)}',
                      tone: _MiniBadgeTone.yellow,
                    ),
                    SizedBox(width: 8.w),
                  ],
                  _MiniBadge(
                    label: 'Pending ${Formatters.money(earnings.pending)}',
                    tone: _MiniBadgeTone.amber,
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              EarningsBarChart(byDay: earnings.byDay, todayLabel: todayLabel),
            ],
          ),
        ),

        SizedBox(height: 12.h),

        // Breakdown
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Breakdown',
                style: AppText.figtree(
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 14.h),
              ...earnings.breakdown.map(
                (row) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _BreakdownRow(row: row),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 12.h),

        // Last payout
        AppCard(
          child: Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  AppIcons.checkCircle,
                  size: 20.sp,
                  color: AppColors.greenFg,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Payout',
                      style: AppText.figtree(
                        size: 12,
                        weight: FontWeight.w500,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      Formatters.money(earnings.lastPayout.amount),
                      style: AppText.figtree(
                        size: 16,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      earnings.lastPayout.date,
                      style: AppText.figtree(
                        size: 12,
                        weight: FontWeight.w400,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'UTR',
                    style: AppText.figtree(
                      size: 10,
                      weight: FontWeight.w500,
                      color: AppColors.fgMuted,
                    ),
                  ),
                  Text(
                    earnings.lastPayout.utr,
                    style: AppText.figtree(
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppColors.fgTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.row});

  final EarningsBreakdownRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.label,
              style: AppText.figtree(size: 14, weight: FontWeight.w500),
            ),
            Text(
              Formatters.count(row.count, 'job'),
              style: AppText.figtree(
                size: 12,
                weight: FontWeight.w400,
                color: AppColors.fgTertiary,
              ),
            ),
          ],
        ),
        Text(
          Formatters.money(row.amount),
          style: AppText.figtree(size: 15, weight: FontWeight.w700),
        ),
      ],
    );
  }
}

enum _MiniBadgeTone { yellow, amber }

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.tone});

  final String label;
  final _MiniBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final bg = tone == _MiniBadgeTone.yellow
        ? AppColors.brandYellowLight
        : AppColors.amberBg;
    final fg = tone == _MiniBadgeTone.yellow
        ? AppColors.brandYellowDeep
        : AppColors.amberFg;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: AppText.figtree(
          size: 11.5,
          weight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

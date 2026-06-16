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

/// Driver app "Earnings" tab — a weekly total + bar chart, a per-category
/// breakdown, and a pending-payout card. Mirrors the `earnings` branch of
/// `DriverApp` in `screen_driver_app.jsx`.
class DriverEarningsScreen extends ConsumerWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(driverEarningsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: earningsAsync.when(
                loading: () => ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: 3,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, __) => const SkeletonCard(),
                ),
                error: (_, __) =>
                    const Center(child: Text('Could not load earnings.')),
                data: (earnings) => _EarningsBody(earnings: earnings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Earnings',
              style: AppText.figtree(size: 18, weight: FontWeight.w700),
            ),
          ),
          Icon(AppIcons.wallet, size: 22.sp, color: AppColors.fgTertiary),
        ],
      ),
    );
  }
}

class _EarningsBody extends StatelessWidget {
  const _EarningsBody({required this.earnings});

  final DriverEarnings earnings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        // This week + bar chart
        AppCard(
          padding: EdgeInsets.all(18.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THIS WEEK',
                style: AppText.figtree(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: AppColors.fgTertiary,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                Formatters.money(earnings.weekTotal),
                style: AppText.figtree(
                  size: 30,
                  weight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(height: 16.h),
              EarningsBarChart(byDay: earnings.byDay),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // Breakdown
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "THIS WEEK'S BREAKDOWN",
                style: AppText.figtree(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.fgSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 6.h),
              for (var i = 0; i < earnings.breakdown.length; i++)
                _BreakdownRow(
                  row: earnings.breakdown[i],
                  showDivider: i < earnings.breakdown.length - 1,
                ),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // Pending payout
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PENDING PAYOUT',
                      style: AppText.figtree(
                        size: 11,
                        weight: FontWeight.w700,
                        color: AppColors.fgTertiary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      Formatters.money(earnings.pending),
                      style: AppText.figtree(size: 20, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Last paid ${earnings.lastPayout.date}',
                    style: AppText.figtree(
                      size: 11,
                      weight: FontWeight.w400,
                      color: AppColors.fgTertiary,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    Formatters.money(earnings.lastPayout.amount),
                    style: AppText.figtree(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AppColors.greenFg,
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
  const _BreakdownRow({required this.row, required this.showDivider});

  final EarningsBreakdownRow row;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.borderSoft))
            : null,
      ),
      padding: EdgeInsets.symmetric(vertical: 11.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: AppText.figtree(size: 13.5, weight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              Text(
                '${row.count} ${row.count == 1 ? 'item' : 'items'}',
                style: AppText.figtree(
                  size: 11.5,
                  weight: FontWeight.w500,
                  color: AppColors.fgTertiary,
                ),
              ),
            ],
          ),
          Text(
            Formatters.money(row.amount),
            style: AppText.figtree(size: 14, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../drivers/domain/entities/driver_job.dart';
import '../../application/providers/driver_app_providers.dart';
import '../components/driver_job_card.dart';

/// Driver app "Today" tab — Online/Offline toggle, today earnings strip,
/// Active Now job card and Up Next jobs. No back button (tab root).
class DriverTodayScreen extends ConsumerWidget {
  const DriverTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(signedInDriverProvider);
    final jobsAsync = ref.watch(driverJobsProvider);
    final earningsAsync = ref.watch(driverEarningsProvider);
    final isOnline = ref.watch(driverOnlineProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            _DriverHeader(
              driverAsync: driverAsync,
              isOnline: isOnline,
              onToggle: () =>
                  ref.read(driverOnlineProvider.notifier).state = !isOnline,
            ),

            // ── Today Earnings Strip ─────────────────────────────────────────
            earningsAsync.when(
              loading: () => const _EarningsStripSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
              data: (earnings) => _EarningsStrip(
                today: earnings.todayTotal,
                jobsAsync: jobsAsync,
                pending: earnings.pending,
              ),
            ),

            // ── Jobs ─────────────────────────────────────────────────────────
            Expanded(
              child: jobsAsync.when(
                loading: () => ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: 2,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, __) => const SkeletonCard(),
                ),
                error: (_, __) => const Center(
                  child: Text('Could not load jobs.'),
                ),
                data: (jobs) {
                  final active = jobs
                      .where((j) => j.state == DriverJobState.active)
                      .toList();
                  final upcoming = jobs
                      .where((j) => j.state == DriverJobState.upcoming)
                      .toList();

                  return ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                    children: [
                      // Active Now
                      if (active.isNotEmpty) ...[
                        _SectionLabel(label: 'Active Now'),
                        SizedBox(height: 8.h),
                        ...active.map(
                          (job) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: DriverJobCard(
                              job: job,
                              onTap: () =>
                                  context.push(Routes.driverJob(job.id)),
                            ),
                          ),
                        ),
                      ],

                      // Up Next
                      if (upcoming.isNotEmpty) ...[
                        SizedBox(height: active.isNotEmpty ? 8.h : 0),
                        _SectionLabel(label: 'Up Next'),
                        SizedBox(height: 8.h),
                        ...upcoming.map(
                          (job) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: DriverJobCard(
                              job: job,
                              onTap: () =>
                                  context.push(Routes.driverJob(job.id)),
                            ),
                          ),
                        ),
                      ],

                      if (active.isEmpty && upcoming.isEmpty)
                        _EmptyToday(isOnline: isOnline),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _DriverHeader extends StatelessWidget {
  const _DriverHeader({
    required this.driverAsync,
    required this.isOnline,
    required this.onToggle,
  });

  final AsyncValue driverAsync;
  final bool isOnline;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          driverAsync.when(
            loading: () => Container(
              width: 40.r,
              height: 40.r,
              decoration: const BoxDecoration(
                color: AppColors.bgInput,
                shape: BoxShape.circle,
              ),
            ),
            error: (_, __) => const Avatar(name: 'Manoj Kumar'),
            data: (driver) => Avatar(
              name: driver?.name ?? 'Driver',
              size: 40,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: driverAsync.when(
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100.w,
                    height: 14.h,
                    color: AppColors.bgInput,
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: 70.w,
                    height: 11.h,
                    color: AppColors.bgInput,
                  ),
                ],
              ),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Manoj Kumar',
                      style:
                          AppText.figtree(size: 15, weight: FontWeight.w700)),
                  Text('Wash driver',
                      style: AppText.figtree(
                        size: 12,
                        weight: FontWeight.w400,
                        color: AppColors.fgTertiary,
                      )),
                ],
              ),
              data: (driver) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    driver?.name.split(' ').first ?? 'Driver',
                    style: AppText.figtree(size: 15, weight: FontWeight.w700),
                  ),
                  Text(
                    driver?.role ?? 'Driver',
                    style: AppText.figtree(
                      size: 12,
                      weight: FontWeight.w400,
                      color: AppColors.fgTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Online toggle
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isOnline ? AppColors.greenBg : AppColors.borderSoft,
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(
                  color: isOnline
                      ? AppColors.greenDot
                      : AppColors.borderDefault,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7.r,
                    height: 7.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline
                          ? AppColors.greenFg
                          : AppColors.fgTertiary,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: AppText.figtree(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: isOnline
                          ? AppColors.greenFg
                          : AppColors.fgTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsStrip extends StatelessWidget {
  const _EarningsStrip({
    required this.today,
    required this.jobsAsync,
    required this.pending,
  });

  final int today;
  final AsyncValue<List<DriverJob>> jobsAsync;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final jobCount = jobsAsync.maybeWhen(
      data: (jobs) => jobs.length,
      orElse: () => 0,
    );

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          _StripStat(
            label: 'Today',
            value: Formatters.money(today),
            accent: true,
          ),
          _StripDivider(),
          _StripStat(
            label: 'Jobs',
            value: '$jobCount',
          ),
          _StripDivider(),
          _StripStat(
            label: 'Pending',
            value: Formatters.money(pending),
          ),
        ],
      ),
    );
  }
}

class _StripStat extends StatelessWidget {
  const _StripStat({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppText.figtree(
              size: 16,
              weight: FontWeight.w700,
              color: accent
                  ? AppColors.brandYellowDeep
                  : AppColors.fgPrimary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w500,
              color: AppColors.fgTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StripDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28.h,
      color: AppColors.borderSoft,
    );
  }
}

class _EarningsStripSkeleton extends StatelessWidget {
  const _EarningsStripSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      color: AppColors.bgCard,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppText.figtree(
        size: 13,
        weight: FontWeight.w700,
        color: AppColors.fgTertiary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 48.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.check, size: 40.sp, color: AppColors.fgMuted),
            SizedBox(height: 12.h),
            Text(
              isOnline ? 'All caught up!' : 'You are offline',
              style: AppText.figtree(size: 16, weight: FontWeight.w700),
            ),
            SizedBox(height: 4.h),
            Text(
              isOnline
                  ? 'No active or upcoming jobs.'
                  : 'Go online to receive jobs.',
              style: AppText.figtree(
                size: 13,
                weight: FontWeight.w400,
                color: AppColors.fgTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

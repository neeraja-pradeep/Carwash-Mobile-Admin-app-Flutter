import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../drivers/domain/entities/driver_job.dart';
import '../../application/providers/driver_app_providers.dart';
import '../components/driver_job_card.dart';

/// Driver app "Today" tab — driver header with Online/Offline toggle, today
/// earnings strip, an "Active now" job card and the "Up next" queue.
/// Mirrors the `today` branch of `DriverApp` in `screen_driver_app.jsx`.
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
            // ── Header (avatar + name/role + online toggle) ──────────────────
            _DriverHeader(
              driverAsync: driverAsync,
              isOnline: isOnline,
              onToggle: () {
                ref.read(driverOnlineProvider.notifier).state = !isOnline;
                AppToast.show(
                  context,
                  isOnline ? "You're now offline" : "You're online",
                );
              },
            ),

            // ── Jobs + earnings strip ────────────────────────────────────────
            Expanded(
              child: jobsAsync.when(
                loading: () => ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                  children: const [
                    _EarningsStripSkeleton(),
                    SkeletonCard(),
                  ],
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
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    children: [
                      // Earnings strip
                      earningsAsync.when(
                        loading: () => const _EarningsStripSkeleton(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (earnings) => _EarningsStrip(
                          today: earnings.todayTotal,
                          jobs: driverAsync.maybeWhen(
                            data: (d) => d?.today.jobs ?? active.length,
                            orElse: () => active.length,
                          ),
                          pending: earnings.pending,
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Active now
                      if (active.isNotEmpty) ...[
                        const _SectionLabel('Active now'),
                        SizedBox(height: 8.h),
                        ...active.map(
                          (job) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _jobCard(context, job),
                          ),
                        ),
                        SizedBox(height: 2.h),
                      ],

                      // Up next (always shown; falls back to an empty card)
                      const _SectionLabel('Up next'),
                      SizedBox(height: 8.h),
                      if (upcoming.isEmpty)
                        const _EmptyUpNextCard()
                      else
                        ...upcoming.map(
                          (job) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _jobCard(context, job),
                          ),
                        ),
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

  Widget _jobCard(BuildContext context, DriverJob job) {
    return DriverJobCard(
      job: job,
      onTap: () => context.push(Routes.driverJob(job.id)),
      onCall: () => AppToast.show(context, 'Calling ${job.customer}…'),
      onNavigate: () => AppToast.show(context, 'Opening Maps…'),
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
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
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
                color: AppColors.avatarBg,
                shape: BoxShape.circle,
              ),
            ),
            error: (_, __) => const Avatar(name: 'Manoj Kumar'),
            data: (driver) => Avatar(name: driver?.name ?? 'Driver', size: 40),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  driverAsync.maybeWhen(
                    data: (d) => d?.name.split(' ').first ?? 'Driver',
                    orElse: () => 'Manoj',
                  ),
                  style: AppText.figtree(
                    size: 15,
                    weight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  driverAsync.maybeWhen(
                    data: (d) => d?.role ?? 'Driver',
                    orElse: () => 'Wash driver',
                  ),
                  style: AppText.figtree(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: AppColors.fgTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Online / Offline toggle
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 36.h,
              padding: EdgeInsets.symmetric(horizontal: 13.w),
              decoration: BoxDecoration(
                color: isOnline ? AppColors.greenBg : AppColors.bgCard,
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(
                  color: isOnline ? AppColors.greenFg : AppColors.borderDefault,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? AppColors.greenFg : AppColors.fgMuted,
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: AppText.figtree(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color:
                          isOnline ? AppColors.greenFg : AppColors.fgSecondary,
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
    required this.jobs,
    required this.pending,
  });

  final int today;
  final int jobs;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padded: false,
      child: Row(
        children: [
          _StripStat(label: 'Today', value: Formatters.money(today)),
          const _StripDivider(),
          _StripStat(label: 'Jobs', value: '$jobs'),
          const _StripDivider(),
          _StripStat(label: 'Pending', value: Formatters.money(pending)),
        ],
      ),
    );
  }
}

class _StripStat extends StatelessWidget {
  const _StripStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppText.figtree(
                size: 17,
                weight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              label.toUpperCase(),
              style: AppText.figtree(
                size: 9.5,
                weight: FontWeight.w600,
                color: AppColors.fgTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripDivider extends StatelessWidget {
  const _StripDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36.h, color: AppColors.borderSoft);
  }
}

class _EarningsStripSkeleton extends StatelessWidget {
  const _EarningsStripSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: SizedBox(height: 36.h),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 2.w),
      child: Text(
        label.toUpperCase(),
        style: AppText.figtree(
          size: 11,
          weight: FontWeight.w700,
          color: AppColors.fgSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _EmptyUpNextCard extends StatelessWidget {
  const _EmptyUpNextCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Center(
          child: Text(
            'No more jobs today.',
            style: AppText.figtree(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}

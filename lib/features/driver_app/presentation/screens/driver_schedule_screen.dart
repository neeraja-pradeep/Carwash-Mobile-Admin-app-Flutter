import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/constants.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../drivers/domain/entities/driver_job.dart';
import '../../application/providers/driver_app_providers.dart';
import '../components/driver_job_card.dart';

/// Driver app "Schedule" tab — lists all assigned/upcoming and completed jobs.
class DriverScheduleScreen extends ConsumerWidget {
  const DriverScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(driverJobsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Schedule',
                          style: AppText.figtree(
                            size: 18,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          AppConstants.sampleToday,
                          style: AppText.figtree(
                            size: 12,
                            weight: FontWeight.w500,
                            color: AppColors.fgTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(AppIcons.cal, size: 22.sp, color: AppColors.fgTertiary),
                ],
              ),
            ),

            // Jobs list
            Expanded(
              child: jobsAsync.when(
                loading: () => ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: 3,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, __) => const SkeletonCard(),
                ),
                error: (_, __) => const Center(
                  child: Text('Could not load schedule.'),
                ),
                data: (jobs) {
                  final active = jobs
                      .where((j) => j.state == DriverJobState.active)
                      .toList();
                  final upcoming = jobs
                      .where((j) => j.state == DriverJobState.upcoming)
                      .toList();
                  final completed = jobs
                      .where((j) => j.state == DriverJobState.completed)
                      .toList();

                  final hasAny = active.isNotEmpty ||
                      upcoming.isNotEmpty ||
                      completed.isNotEmpty;

                  if (!hasAny) {
                    return EmptyState(
                      icon: AppIcons.cal,
                      title: 'No jobs today',
                      body: 'Your schedule is clear for today.',
                    );
                  }

                  return ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                    children: [
                      if (active.isNotEmpty) ...[
                        _SectionHeader(label: 'Active', count: active.length),
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
                        SizedBox(height: 8.h),
                      ],
                      if (upcoming.isNotEmpty) ...[
                        _SectionHeader(
                            label: 'Upcoming', count: upcoming.length),
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
                        SizedBox(height: 8.h),
                      ],
                      if (completed.isNotEmpty) ...[
                        _SectionHeader(
                            label: 'Completed', count: completed.length),
                        SizedBox(height: 8.h),
                        ...completed.map(
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppText.figtree(
            size: 13,
            weight: FontWeight.w700,
            color: AppColors.fgTertiary,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppColors.borderSoft,
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Text(
            '$count',
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

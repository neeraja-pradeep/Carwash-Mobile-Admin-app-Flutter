import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/constants.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../drivers/domain/entities/driver_job.dart';
import '../../application/providers/driver_app_providers.dart';
import '../components/driver_job_card.dart';

/// Driver app "Schedule" tab — today's assigned jobs (active + upcoming) then
/// completed jobs. Mirrors the `schedule` branch of `DriverApp` in
/// `screen_driver_app.jsx`.
class DriverScheduleScreen extends ConsumerWidget {
  const DriverScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(driverJobsProvider);

    // "Today · 29 May" — the schedule heading uses a short DD-MMM form.
    final todayShort =
        AppConstants.sampleToday.split(' ').take(2).join(' '); // "29 May"

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
                    child: Text(
                      'Schedule',
                      style: AppText.figtree(size: 18, weight: FontWeight.w700),
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
                error: (_, __) =>
                    const Center(child: Text('Could not load schedule.')),
                data: (jobs) {
                  final today = jobs
                      .where((j) =>
                          j.state == DriverJobState.active ||
                          j.state == DriverJobState.upcoming)
                      .toList();
                  final completed = jobs
                      .where((j) => j.state == DriverJobState.completed)
                      .toList();

                  if (today.isEmpty && completed.isEmpty) {
                    return EmptyState(
                      icon: AppIcons.cal,
                      title: 'No jobs today',
                      body: 'Your schedule is clear for today.',
                    );
                  }

                  return ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                    children: [
                      _SectionLabel('Today · $todayShort'),
                      SizedBox(height: 8.h),
                      ...today.map((job) => _card(context, job)),
                      if (completed.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        _SectionLabel('Completed'),
                        SizedBox(height: 8.h),
                        ...completed.map((job) => _card(context, job)),
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

  Widget _card(BuildContext context, DriverJob job) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: DriverJobCard(
        job: job,
        onTap: () => context.push(Routes.driverJob(job.id)),
        onCall: () => AppToast.show(context, 'Calling ${job.customer}…'),
        onNavigate: () => AppToast.show(context, 'Opening Maps…'),
      ),
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

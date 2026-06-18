import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../application/providers/schedule_provider.dart';
import '../../application/providers/available_jobs_provider.dart';
import '../../application/providers/claim_job_provider.dart';
import '../../domain/entities/job.dart';
import '../components/route_ladder.dart';

/// Driver app "Schedule" tab — upcoming assigned jobs grouped by day, then
/// completed jobs with pagination. Integrates with the worker/schedule API.
class DriverScheduleScreen extends ConsumerStatefulWidget {
  const DriverScheduleScreen({super.key});

  @override
  ConsumerState<DriverScheduleScreen> createState() =>
      _DriverScheduleScreenState();
}

class _DriverScheduleScreenState extends ConsumerState<DriverScheduleScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialized = false;
  }

  Future<void> _loadSchedule() async {
    if (!mounted) return;
    await ref.read(scheduleStateProvider.notifier).loadSchedule();
  }

  Future<void> _loadAvailableJobs() async {
    if (!mounted) return;
    await ref.read(availableJobsStateProvider.notifier).loadAvailableJobs();
  }

  void _navigateToJobDetail(BuildContext context, Job job) {
    // Route to correct detail screen based on job source
    debugPrint('Navigating to job detail: id=${job.id}, source=${job.source}, status=${job.status}');

    if (job.source == 'carwash' || job.kind == 'carwash' || job.washingStatus != null) {
      debugPrint('→ Opening CarwashDetailScreen');
      // Pass job status as query parameter
      final url = job.status == 'completed'
        ? '${Routes.driverCarwash(job.id.toString())}?completed=true'
        : Routes.driverCarwash(job.id.toString());
      context.push(url);
    } else {
      debugPrint('→ Opening DriverJobDetailScreen');
      context.push(Routes.driverJob(job.id.toString()));
    }
  }

  Future<void> _claimJob(Job job) async {
    if (!mounted) return;
    try {
      if (job.source == 'carwash') {
        await ref.read(claimJobStateProvider.notifier).claimCarwashJob(job.id.toString());
      } else {
        await ref.read(claimJobStateProvider.notifier).claimDriverHireJob(job.id.toString());
      }

      if (mounted) {
        AppToast.show(context, '✓ Job claimed! It\'s now in your schedule.');
        // Refresh schedule to show the newly claimed job
        await _loadSchedule();
        // Refresh available jobs
        await _loadAvailableJobs();
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        AppToast.show(context, errorMsg);
      }
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
    }
  }

  Future<void> _launchMaps(double? latitude, double? longitude) async {
    if (latitude == null || longitude == null) {
      return;
    }

    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps?q=$latitude,$longitude',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize data only once on first build
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSchedule();
        _loadAvailableJobs();
      });
    }

    final scheduleState = ref.watch(scheduleStateProvider);
    final availableJobsState = ref.watch(availableJobsStateProvider);

    return scheduleState.when(
      initial: () => _buildLoading(),
      loading: () => _buildLoading(),
      success: (schedule) {
        final upcomingJobs = schedule.schedule.days;
        final completedJobs = schedule.schedule.completed;

        if (upcomingJobs.isEmpty && completedJobs.isEmpty) {
          return EmptyState(
            icon: AppIcons.cal,
            title: 'No jobs',
            body: 'You have no upcoming or completed jobs.',
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
          children: [
            // Upcoming jobs grouped by day
            ...upcomingJobs.map((day) => [
              _SectionLabel(day.label),
              SizedBox(height: 8.h),
              ...day.jobs.map((job) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _JobCard(
                  job: job,
                  onTap: () => _navigateToJobDetail(context, job),
                  onCall: () => _launchPhone(job.customerPhone),
                  onNavigate: () => _launchMaps(job.pickupLat, job.pickupLng),
                ),
              )),
            ]).expand((x) => x),

            // Available jobs to claim section
            availableJobsState.when(
              initial: () => const SizedBox.shrink(),
              loading: () => Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: const Center(child: CircularProgressIndicator()),
              ),
              success: (jobs) {
                if (jobs.jobs.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      _SectionLabel('Available to Claim'),
                      SizedBox(height: 8.h),
                      ...jobs.jobs.map((job) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _AvailableJobCard(
                          job: job,
                          onClaim: () => _claimJob(job),
                          onCall: () => _launchPhone(job.customerPhone),
                          onNavigate: () => _launchMaps(job.pickupLat, job.pickupLng),
                        ),
                      )),
                      if (jobs.nextPageUrl != null) ...[
                        SizedBox(height: 8.h),
                        AppButton(
                          label: 'Load more available jobs',
                          kind: AppButtonKind.secondary,
                          onPressed: jobs.isLoadingMore
                              ? null
                              : () async {
                            try {
                              await ref
                                  .read(availableJobsStateProvider.notifier)
                                  .loadNextPage();
                            } catch (e) {
                              if (mounted) {
                                AppToast.show(context, 'Failed to load more jobs');
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
              error: (_) => const SizedBox.shrink(),
            ),

            // Completed jobs section
            if (completedJobs.isNotEmpty) ...[
              SizedBox(height: 2.h),
              _SectionLabel('Completed'),
              SizedBox(height: 8.h),
              ...completedJobs.map((job) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _JobCard(
                  job: job,
                  onTap: () => _navigateToJobDetail(context, job),
                  onCall: () => _launchPhone(job.customerPhone),
                  onNavigate: () => _launchMaps(job.pickupLat, job.pickupLng),
                ),
              )),
            ],

            // Load more button for completed jobs
            if (schedule.schedule.completedPagination.next != null) ...[
              SizedBox(height: 16.h),
              AppButton(
                label: 'Load more completed jobs',
                kind: AppButtonKind.secondary,
                onPressed: schedule.isLoadingMore
                    ? null
                    : () async {
                  try {
                    await ref
                        .read(scheduleStateProvider.notifier)
                        .loadNextPage();
                  } catch (e) {
                    if (mounted) {
                      AppToast.show(context, 'Failed to load more jobs');
                    }
                  }
                },
              ),
            ],
          ],
        );
      },
      error: (error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.alert, size: 48.sp, color: AppColors.danger),
            SizedBox(height: 16.h),
            Text(
              'Could not load schedule',
              style: AppText.figtree(size: 16, weight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Text(
              error.message,
              style: AppText.figtree(size: 14, color: AppColors.fgMuted),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            AppButton(
              label: 'Retry',
              onPressed: _loadSchedule,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      padding: EdgeInsets.all(16.r),
      itemCount: 3,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }
}

// ── Job Card ──────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.onTap,
    required this.onCall,
    required this.onNavigate,
  });

  final Job job;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Type pill + Time + Status
          Row(
            children: [
              _TypePill(label: job.label),
              const Spacer(),
              Text(
                job.startTime.split(':').take(2).join(':'),
                style: AppText.figtree(
                  size: 13,
                  weight: FontWeight.w500,
                  color: AppColors.fgSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Customer name
          Text(
            job.customerName,
            style: AppText.figtree(size: 15, weight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),

          // Vehicle info
          Text(
            job.vehicle,
            style: AppText.figtree(
              size: 12,
              weight: FontWeight.w500,
              color: AppColors.fgTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 10.h),

          // Route ladder
          RouteLadder(
            pickup: job.pickupAddress,
            drop: job.dropAddress,
          ),
          SizedBox(height: 11.h),

          // Footer: Payout + Action buttons
          Row(
            children: [
              Text(
                Formatters.money((double.tryParse(job.payout) ?? 0).toInt()),
                style: AppText.figtree(size: 15, weight: FontWeight.w700),
              ),
              const Spacer(),
              _IconButton(icon: AppIcons.phone, onTap: onCall),
              SizedBox(width: 8.w),
              _IconButton(icon: AppIcons.nav, onTap: onNavigate, filled: true),
              SizedBox(width: 8.w),
              // View/View Summary button routes to appropriate detail screen
              AppButton(
                label: job.status == 'completed' ? 'View Summary' : 'View',
                size: AppButtonSize.sm,
                onPressed: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Type Pill ──────────────────────────────────────────────────────────────

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final (icon) = switch (label) {
      'CARWASH' => AppIcons.droplet,
      _ => AppIcons.car,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: AppColors.fgSecondary),
          SizedBox(width: 6.w),
          Text(
            label,
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Available Job Card (with claim button) ──────────────────────────────────

class _AvailableJobCard extends StatelessWidget {
  const _AvailableJobCard({
    required this.job,
    required this.onClaim,
    required this.onCall,
    required this.onNavigate,
  });

  final Job job;
  final VoidCallback onClaim;
  final VoidCallback onCall;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    // Don't navigate on tap for available jobs - only show claim button
    return AppCard(
      onTap: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Type pill + Time
          Row(
            children: [
              _TypePill(label: job.label),
              const Spacer(),
              Text(
                job.startTime.split(':').take(2).join(':'),
                style: AppText.figtree(
                  size: 13,
                  weight: FontWeight.w500,
                  color: AppColors.fgSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Customer name
          Text(
            job.customerName,
            style: AppText.figtree(size: 15, weight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),

          // Vehicle info
          Text(
            job.vehicle,
            style: AppText.figtree(
              size: 12,
              weight: FontWeight.w500,
              color: AppColors.fgTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 10.h),

          // Route ladder
          RouteLadder(
            pickup: job.pickupAddress,
            drop: job.dropAddress,
          ),
          SizedBox(height: 11.h),

          // Footer: Payout + Action buttons
          Row(
            children: [
              Text(
                Formatters.money((double.tryParse(job.payout) ?? 0).toInt()),
                style: AppText.figtree(size: 15, weight: FontWeight.w700),
              ),
              const Spacer(),
              _IconButton(icon: AppIcons.phone, onTap: onCall),
              SizedBox(width: 8.w),
              _IconButton(icon: AppIcons.nav, onTap: onNavigate, filled: true),
              SizedBox(width: 8.w),
              AppButton(
                label: 'Claim',
                size: AppButtonSize.sm,
                onPressed: onClaim,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Icon Button ────────────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42.r,
        height: 42.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.brandYellow : AppColors.bgCard,
          borderRadius: BorderRadius.circular(11.r),
          border: filled ? null : Border.all(color: AppColors.borderDefault),
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: filled ? AppColors.fgPrimary : AppColors.fgSecondary,
        ),
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────

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

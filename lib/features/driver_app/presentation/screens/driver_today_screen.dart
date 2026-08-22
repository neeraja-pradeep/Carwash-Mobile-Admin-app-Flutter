import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../application/providers/driver_home_provider.dart';
import '../../application/states/driver_home_state.dart';
import '../../domain/entities/job.dart';
import '../components/route_ladder.dart';

/// Driver app "Today" tab with real API integration.
/// Shows: Availability toggle, earnings stats, and active/upcoming jobs.
class DriverTodayScreen extends ConsumerStatefulWidget {
  const DriverTodayScreen({super.key});

  @override
  ConsumerState<DriverTodayScreen> createState() => _DriverTodayScreenState();
}

class _DriverTodayScreenState extends ConsumerState<DriverTodayScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Mark that we should initialize on first build
    _initialized = false;
  }

  Future<void> _loadHomeData() async {
    if (!mounted) return;
    try {
      await ref.read(driverHomeStateProvider.notifier).loadHomeData();
    } catch (e) {
      debugPrint('Error loading home data: $e');
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          AppToast.show(context, 'Could not launch phone app');
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Error launching phone app: $e');
      }
    }
  }

  void _viewJobDetail(BuildContext context, Job job) {
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

  Future<void> _launchMaps(
    double? latitude,
    double? longitude,
    String label,
  ) async {
    final opened = await launchMapPin(
      latitude: latitude,
      longitude: longitude,
      label: label,
    );
    if (!opened && mounted) {
      AppToast.show(context, 'No location available for this job.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize data only once on first build
    if (!_initialized) {
      _initialized = true;
      // Use WidgetsBinding to call after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadHomeData();
      });
    }

    final homeState = ref.watch(driverHomeStateProvider);

    if (homeState is DriverHomeLoading || homeState is DriverHomeInitial) {
      return _buildLoading();
    }

    if (homeState is DriverHomeSuccess) {
      return RefreshIndicator(
        onRefresh: _loadHomeData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            _buildStatsStrip(homeState.stats),
            SizedBox(height: 24.h),
            if (homeState.jobFeed.activeNow.isNotEmpty) ...[
              Text(
                'ACTIVE NOW',
                style: AppText.figtree(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: AppColors.fgSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              ...homeState.jobFeed.activeNow.map((job) => _buildJobCard(job)),
              SizedBox(height: 24.h),
            ],
            if (homeState.jobFeed.upNext.isNotEmpty) ...[
              Text(
                'UP NEXT',
                style: AppText.figtree(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: AppColors.fgSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              ...homeState.jobFeed.upNext.map((job) => _buildJobCard(job)),
            ] else if (homeState.jobFeed.activeNow.isEmpty) ...[
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.h),
                  child: Text(
                    'No jobs scheduled today',
                    style: AppText.figtree(size: 14, color: AppColors.fgMuted),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (homeState is DriverHomeError) {
      return _buildError(homeState.message);
    }

    return _buildLoading();
  }

  Widget _buildLoading() {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      children: [
        const SkeletonCard(),
        SizedBox(height: 16.h),
        const SkeletonCard(),
        SizedBox(height: 16.h),
        const SkeletonCard(),
      ],
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.alert, size: 48.sp, color: AppColors.danger),
          SizedBox(height: 16.h),
          Text(
            'Could not load today\'s data',
            style: AppText.figtree(size: 16, weight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: AppText.figtree(size: 14, color: AppColors.fgMuted),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          AppButton(label: 'Retry', onPressed: _loadHomeData),
        ],
      ),
    );
  }

  Widget _buildStatsStrip(dynamic stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(label: 'TODAY', value: '₹${stats.earnings}'),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(label: 'JOBS', value: '${stats.jobs}'),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(label: 'PENDING', value: '₹${stats.pending}'),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String label, required String value}) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w600,
              color: AppColors.fgTertiary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: AppText.figtree(
              size: 16,
              weight: FontWeight.w700,
              color: AppColors.fgPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: type pill + time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TypePill(label: job.label),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.clock, size: 14.sp, color: AppColors.fgPrimary),
                    SizedBox(width: 6.w),
                    Text(
                      job.startTime,
                      style: AppText.figtree(size: 13, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 11.h),

            // Customer + vehicle
            Text(
              job.customerName,
              style: AppText.figtree(size: 15.5, weight: FontWeight.w700),
            ),
            SizedBox(height: 3.h),
            Text(
              job.vehicle,
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w500,
                color: AppColors.fgTertiary,
              ),
            ),
            SizedBox(height: 12.h),

            // Route ladder with dividers
            const Divider(height: 1, color: AppColors.borderSoft),
            SizedBox(height: 12.h),
            RouteLadder(
              pickup: job.pickupAddress,
              drop: job.dropAddress,
              dense: true,
            ),
            SizedBox(height: 12.h),
            const Divider(height: 1, color: AppColors.borderSoft),
            SizedBox(height: 11.h),

            // Footer: payout + actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'YOUR PAYOUT',
                      style: AppText.figtree(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.fgTertiary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      Formatters.money(
                        (double.tryParse(job.payout) ?? 0).toInt(),
                      ),
                      style: AppText.figtree(size: 16, weight: FontWeight.w700),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconButton(
                      icon: AppIcons.phone,
                      onTap: () => _launchPhone(job.customerPhone),
                    ),
                    SizedBox(width: 8.w),
                    _IconButton(
                      icon: AppIcons.nav,
                      onTap: () => _launchMaps(
                        job.pickupLat,
                        job.pickupLng,
                        job.pickupAddress,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    AppButton(
                      label: 'View',
                      size: AppButtonSize.sm,
                      onPressed: () => _viewJobDetail(context, job),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _TypePill({required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.droplet,
            size: 13.sp,
            color: AppColors.fgSecondary,
          ),
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

  Widget _IconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42.r,
        height: 42.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(11.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Icon(icon, size: 18.sp, color: AppColors.fgPrimary),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../application/providers/driver_home_provider.dart';
import '../../application/states/driver_home_state.dart';
import '../../domain/entities/job.dart';

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
      return ListView(
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
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    job.label,
                    style: AppText.figtree(
                      size: 10,
                      weight: FontWeight.w700,
                      color: AppColors.brandYellow,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  job.reference,
                  style: AppText.figtree(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.fgSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${job.payout}',
                  style: AppText.figtree(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              job.customerName,
              style: AppText.figtree(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.fgPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              job.customerPhone,
              style: AppText.figtree(size: 12, color: AppColors.fgTertiary),
            ),
            SizedBox(height: 8.h),
            Text(
              job.vehicle,
              style: AppText.figtree(size: 12, color: AppColors.fgSecondary),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(AppIcons.phone, size: 14.sp, color: AppColors.fgTertiary),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    job.pickupAddress,
                    style: AppText.figtree(
                      size: 12,
                      color: AppColors.fgSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'View',
                    kind: AppButtonKind.secondary,
                    size: AppButtonSize.sm,
                    onPressed: () {},
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: AppButton(
                    label: 'Call',
                    kind: AppButtonKind.secondary,
                    size: AppButtonSize.sm,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

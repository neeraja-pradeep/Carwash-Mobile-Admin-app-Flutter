import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../../drivers/domain/entities/driver_job.dart';
import '../../application/providers/driver_app_providers.dart';
import '../components/otp_modal.dart';

/// Full detail view for a driver job, pushed via Routes.driverJob(id).
/// Shows customer/vehicle/route with Call+Navigate, status/payout card,
/// Start/End Job OTP modal, and Trip Summary on completion.
class DriverJobDetailScreen extends ConsumerWidget {
  const DriverJobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(driverJobByIdProvider(jobId));
    final otpModalOpen = ref.watch(otpModalOpenProvider);
    final otpFlowKind = ref.watch(otpFlowKindProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.bgPage,
          body: SafeArea(
            bottom: false,
            child: jobAsync.when(
              loading: () => Column(
                children: [
                  TopBar(title: 'Job Detail', onBack: () => Navigator.of(context).pop()),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.all(16.r),
                      itemCount: 3,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (_, __) => const SkeletonCard(),
                    ),
                  ),
                ],
              ),
              error: (_, __) => Column(
                children: [
                  TopBar(
                    title: 'Job Detail',
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Center(child: Text('Could not load job.')),
                  ),
                ],
              ),
              data: (job) {
                if (job == null) {
                  return Column(
                    children: [
                      TopBar(
                        title: 'Job Detail',
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Center(child: Text('Job not found.')),
                      ),
                    ],
                  );
                }
                return _JobDetailBody(
                  job: job,
                  onBack: () => Navigator.of(context).pop(),
                  onStartJob: () {
                    ref.read(otpFlowKindProvider.notifier).state = 'start';
                    ref.read(otpModalOpenProvider.notifier).state = true;
                  },
                  onEndJob: () {
                    ref.read(otpFlowKindProvider.notifier).state = 'end';
                    ref.read(otpModalOpenProvider.notifier).state = true;
                  },
                );
              },
            ),
          ),
        ),

        // OTP overlay
        if (otpModalOpen)
          jobAsync.maybeWhen(
            data: (job) {
              if (job == null) return const SizedBox.shrink();
              return OtpModal(
                kind: otpFlowKind ?? 'start',
                expectedOtp: job.otp,
                onConfirmed: () {
                  ref.read(otpModalOpenProvider.notifier).state = false;
                  ref.read(otpFlowKindProvider.notifier).state = null;
                  // In a real app this would update job state via a notifier.
                  // For this static demo we just close the modal.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        otpFlowKind == 'start'
                            ? 'Job started!'
                            : 'Job completed!',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                onDismiss: () {
                  ref.read(otpModalOpenProvider.notifier).state = false;
                  ref.read(otpFlowKindProvider.notifier).state = null;
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
      ],
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _JobDetailBody extends StatelessWidget {
  const _JobDetailBody({
    required this.job,
    required this.onBack,
    required this.onStartJob,
    required this.onEndJob,
  });

  final DriverJob job;
  final VoidCallback onBack;
  final VoidCallback onStartJob;
  final VoidCallback onEndJob;

  @override
  Widget build(BuildContext context) {
    final isActive = job.state == DriverJobState.active;
    final isCompleted = job.state == DriverJobState.completed;
    final isHire = job.type == 'Driver hire';

    return Column(
      children: [
        TopBar(
          title: job.type,
          subtitle: job.time,
          onBack: onBack,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
            children: [
              // Customer card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44.r,
                          height: 44.r,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.brandYellowLight,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            AppIcons.users,
                            size: 22.sp,
                            color: AppColors.brandYellowDeep,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.customer,
                                style: AppText.figtree(
                                    size: 16, weight: FontWeight.w700),
                              ),
                              Text(
                                job.phone,
                                style: AppText.figtree(
                                  size: 13,
                                  weight: FontWeight.w400,
                                  color: AppColors.fgTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _IconBtn(
                          icon: AppIcons.phone,
                          onTap: () {},
                        ),
                        SizedBox(width: 8.w),
                        _IconBtn(
                          icon: AppIcons.nav,
                          onTap: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    // Vehicle
                    _DetailRow(
                      icon: AppIcons.car,
                      label: 'Vehicle',
                      value: job.vehicle,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Route card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route',
                      style: AppText.figtree(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _RouteConnector(pickup: job.pickup, drop: job.drop),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Status / payout card
              AppCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailRow(
                          icon: AppIcons.clock,
                          label: 'Status',
                          value: job.stage,
                          compact: true,
                        ),
                        _StatusBadge(state: job.state),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    const Divider(height: 1, color: AppColors.borderFaint),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Payout',
                          style: AppText.figtree(
                            size: 13,
                            weight: FontWeight.w500,
                            color: AppColors.fgTertiary,
                          ),
                        ),
                        Text(
                          Formatters.money(job.payout),
                          style: AppText.figtree(
                            size: 18,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (isHire && job.fare.plannedHours != null) ...[
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Planned hours',
                            style: AppText.figtree(
                              size: 12,
                              weight: FontWeight.w400,
                              color: AppColors.fgTertiary,
                            ),
                          ),
                          Text(
                            '${job.fare.plannedHours}h',
                            style: AppText.figtree(
                              size: 13,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Trip/Job Summary (completed or hire)
              if (isCompleted || isHire) _FareSummaryCard(job: job),
            ],
          ),
        ),

        // Sticky footer action
        Container(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            border: Border(top: BorderSide(color: AppColors.borderSoft)),
          ),
          child: SafeArea(
            top: false,
            child: isCompleted
                ? AppButton(
                    label: 'Completed',
                    full: true,
                    disabled: true,
                    onPressed: null,
                  )
                : isActive
                    ? AppButton(
                        label: 'End Job',
                        full: true,
                        icon: AppIcons.checkCircle,
                        onPressed: onEndJob,
                      )
                    : AppButton(
                        label: 'Start Job',
                        full: true,
                        icon: AppIcons.play,
                        onPressed: onStartJob,
                      ),
          ),
        ),
      ],
    );
  }
}

// ── Fare summary card ────────────────────────────────────────────────────────

class _FareSummaryCard extends StatelessWidget {
  const _FareSummaryCard({required this.job});

  final DriverJob job;

  @override
  Widget build(BuildContext context) {
    final isCompleted = job.state == DriverJobState.completed;
    final isHire = job.type == 'Driver hire';
    final title = isHire ? 'Trip Summary' : 'Job Summary';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.figtree(size: 14, weight: FontWeight.w700),
          ),
          SizedBox(height: 14.h),

          // Base fare
          _FareRow(label: 'Base fare', amount: job.fare.base),

          // Item lines
          ...job.fare.items.map(
            (item) => _FareRow(label: item.label, amount: item.amount),
          ),

          // Extra
          if (job.fare.extra > 0)
            _FareRow(
              label: 'Extra charges',
              amount: job.fare.extra,
              highlight: true,
            ),

          const Divider(height: 1, color: AppColors.borderFaint),
          SizedBox(height: 10.h),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style:
                    AppText.figtree(size: 14, weight: FontWeight.w700),
              ),
              Text(
                Formatters.money(job.fare.total),
                style: AppText.figtree(size: 16, weight: FontWeight.w700),
              ),
            ],
          ),

          // Collect from customer alert
          if (job.fare.collect > 0) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.amberBg,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.amberDot),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.alert,
                      size: 18.sp, color: AppColors.amberFg),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Collect extra ${Formatters.money(job.fare.collect)} from customer',
                      style: AppText.figtree(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppColors.amberFg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isCompleted) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.greenBg,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.checkCircle,
                      size: 18.sp, color: AppColors.greenFg),
                  SizedBox(width: 10.w),
                  Text(
                    'Nothing extra to collect',
                    style: AppText.figtree(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.greenFg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  const _FareRow({
    required this.label,
    required this.amount,
    this.highlight = false,
  });

  final String label;
  final int amount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppText.figtree(
              size: 13,
              weight: FontWeight.w400,
              color: highlight ? AppColors.amberFg : AppColors.fgSecondary,
            ),
          ),
          Text(
            Formatters.money(amount),
            style: AppText.figtree(
              size: 13,
              weight: FontWeight.w600,
              color: highlight ? AppColors.amberFg : AppColors.fgPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});

  final DriverJobState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      DriverJobState.active => 'Active',
      DriverJobState.upcoming => 'Upcoming',
      DriverJobState.completed => 'Completed',
    };
    final bg = switch (state) {
      DriverJobState.active => AppColors.greenBg,
      DriverJobState.upcoming => AppColors.amberBg,
      DriverJobState.completed => AppColors.greyBg,
    };
    final fg = switch (state) {
      DriverJobState.active => AppColors.greenFg,
      DriverJobState.upcoming => AppColors.amberFg,
      DriverJobState.completed => AppColors.greyFg,
    };

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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.sp, color: AppColors.fgTertiary),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.figtree(
                  size: 11,
                  weight: FontWeight.w500,
                  color: AppColors.fgMuted,
                ),
              ),
              Text(
                value,
                style: AppText.figtree(
                  size: compact ? 13 : 14,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector({required this.pickup, required this.drop});

  final String pickup;
  final String drop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.pin, size: 16.sp, color: AppColors.brandYellow),
            SizedBox(
              height: 24.h,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.borderDefault,
              ),
            ),
            Icon(AppIcons.pin, size: 16.sp, color: AppColors.fgTertiary),
          ],
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickup,
                style: AppText.figtree(size: 14, weight: FontWeight.w600),
              ),
              SizedBox(height: 16.h),
              Text(
                drop,
                style: AppText.figtree(
                  size: 14,
                  weight: FontWeight.w500,
                  color: AppColors.fgSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38.r,
        height: 38.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Icon(icon, size: 18.sp, color: AppColors.fgSecondary),
      ),
    );
  }
}

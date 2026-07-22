import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/carwash_provider.dart';
import '../../application/states/carwash_state.dart';
import '../../domain/entities/carwash_booking.dart';
import '../components/route_ladder.dart';

/// Carwash job detail screen with washing status flow.
/// No OTP required - driver advances through washing steps.
class CarwashJobDetailScreen extends ConsumerStatefulWidget {
  const CarwashJobDetailScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<CarwashJobDetailScreen> createState() =>
      _CarwashJobDetailScreenState();
}

class _CarwashJobDetailScreenState extends ConsumerState<CarwashJobDetailScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialized = false;
  }

  Future<void> _loadBooking() async {
    if (!mounted) return;
    try {
      await ref
          .read(carwashStateProvider(widget.bookingId).notifier)
          .loadBooking();
    } catch (e) {
      debugPrint('Error loading booking: $e');
    }
  }

  Future<void> _advanceStatus() async {
    final state = ref.read(carwashStateProvider(widget.bookingId));
    if (state is! CarwashSuccess) return;

    final currentStatus = state.booking.washingStatus;
    final nextStatus = WashingStatusStep.nextStatus(currentStatus);

    if (nextStatus == null) {
      AppToast.show(context, 'Job already completed');
      return;
    }

    try {
      await ref
          .read(carwashStateProvider(widget.bookingId).notifier)
          .advanceWashingStatus(nextStatus);

      final currentIndex = WashingStatusStep.indexOfValue(currentStatus) ?? 0;
      final nextIndex = currentIndex + 1;
      final stepLabel =
          nextIndex < WashingStatusStep.steps.length
              ? WashingStatusStep.steps[nextIndex].label
              : 'Completed';

      if (mounted) {
        AppToast.show(context, stepLabel);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        AppToast.show(context, errorMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize data only once on first build
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBooking();
      });
    }

    final bookingState = ref.watch(carwashStateProvider(widget.bookingId));

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: _buildStateView(bookingState),
      ),
    );
  }

  Widget _buildStateView(CarwashState state) {
    if (state is CarwashLoading || state is CarwashInitial) {
      return _buildLoading();
    } else if (state is CarwashSuccess) {
      return _CarwashDetailBody(
        booking: state.booking,
        isUpdating: state.isUpdating,
        onRefresh: _loadBooking,
        onBack: () => Navigator.of(context).pop(),
        onAdvanceStatus: _advanceStatus,
      );
    } else if (state is CarwashError) {
      return Column(
        children: [
          TopBar(title: 'Job', onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.alert, size: 48.sp, color: AppColors.danger),
                  SizedBox(height: 16.h),
                  Text(
                    'Could not load job',
                    style: AppText.figtree(size: 16, weight: FontWeight.w600),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    state.message,
                    style:
                        AppText.figtree(size: 14, color: AppColors.fgMuted),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  AppButton(
                    label: 'Retry',
                    onPressed: _loadBooking,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return _buildLoading();
  }

  Widget _buildLoading() {
    return Column(
      children: [
        TopBar(title: 'Job', onBack: () => Navigator.of(context).pop()),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(16.r),
            itemCount: 3,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (_, __) => const SkeletonCard(),
          ),
        ),
      ],
    );
  }
}

// ── Body widget ──────────────────────────────────────────────────────────────

class _CarwashDetailBody extends StatelessWidget {
  const _CarwashDetailBody({
    required this.booking,
    this.isUpdating = false,
    required this.onRefresh,
    required this.onBack,
    required this.onAdvanceStatus,
  });

  final dynamic booking;
  final bool isUpdating;
  final Future<void> Function() onRefresh;
  final VoidCallback onBack;
  final VoidCallback onAdvanceStatus;

  bool get _isCompleted => booking.washingStatus == 'completed';

  int? get _currentStepIndex =>
      WashingStatusStep.indexOfValue(booking.washingStatus);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          title: 'Carwash Job',
          subtitle: '${booking.appointmentDate} · ${booking.status.toUpperCase()}',
          onBack: onBack,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
              children: [
                _CustomerCard(booking: booking),
                SizedBox(height: 14.h),
                _StatusCard(booking: booking),
                SizedBox(height: 14.h),
                _WashingStatusFlow(
                  currentStatus: booking.washingStatus,
                  currentStepIndex: _currentStepIndex,
                ),
                SizedBox(height: 14.h),
                _PayoutCard(booking: booking),
              ],
            ),
          ),
        ),
        // Sticky footer action
        Container(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            border: Border(top: BorderSide(color: AppColors.borderSoft)),
          ),
          child: SafeArea(
            top: false,
            child: _isCompleted
                ? AppButton(
                    label: 'Job completed',
                    full: true,
                    kind: AppButtonKind.secondary,
                    disabled: true,
                  )
                : AppButton(
                    label: 'Next Step',
                    full: true,
                    disabled: isUpdating,
                    onPressed: onAdvanceStatus,
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Customer card ────────────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.booking});

  final dynamic booking;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
                      style: AppText.figtree(size: 16, weight: FontWeight.w700),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      booking.vehicleText,
                      style: AppText.figtree(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              GestureDetector(
                onTap: () => AppToast.show(
                  context,
                  'Calling ${booking.customerName}…',
                ),
                child: Container(
                  width: 42.r,
                  height: 42.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(11.r),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Icon(AppIcons.phone, size: 18.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 13.h),
          const Divider(height: 1, color: AppColors.borderSoft),
          SizedBox(height: 13.h),
          RouteLadder(
            pickup: booking.address,
            drop: booking.address,
            dropLabel: 'Shop Address',
          ),
        ],
      ),
    );
  }
}

// ── Status card ──────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.booking});

  final dynamic booking;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(booking.amount) ?? 0;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueBg,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(AppIcons.nav, size: 19.sp, color: AppColors.blueFg),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status'.toUpperCase(),
                  style: AppText.figtree(
                    size: 9.5,
                    weight: FontWeight.w700,
                    color: AppColors.fgTertiary,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  booking.status.toUpperCase(),
                  style: AppText.figtree(size: 14, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Your payout'.toUpperCase(),
                style: AppText.figtree(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: AppColors.fgTertiary,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                Formatters.money(amount.toInt()),
                style: AppText.figtree(size: 16, weight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Washing status flow ──────────────────────────────────────────────────────

class _WashingStatusFlow extends StatelessWidget {
  const _WashingStatusFlow({
    required this.currentStatus,
    this.currentStepIndex,
  });

  final String currentStatus;
  final int? currentStepIndex;

  @override
  Widget build(BuildContext context) {
    final steps = WashingStatusStep.steps;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Washing Progress'.toUpperCase(),
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 16.h),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isCompleted = currentStepIndex != null && index <= currentStepIndex!;
            final isCurrent = index == currentStepIndex;

            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 24.r,
                      height: 24.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success
                            : AppColors.borderDefault,
                        shape: BoxShape.circle,
                      ),
                      child: isCompleted
                          ? Icon(AppIcons.checkCircle,
                              size: 12.sp, color: AppColors.fgOnDark)
                          : null,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        step.label,
                        style: AppText.figtree(
                          size: 13,
                          weight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.fgPrimary
                              : AppColors.fgSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1) ...[
                  SizedBox(height: 6.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.w),
                    child: Container(
                      width: 1.r,
                      height: 8.h,
                      color: isCompleted
                          ? AppColors.success
                          : AppColors.borderDefault,
                    ),
                  ),
                  SizedBox(height: 6.h),
                ]
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Payout card ──────────────────────────────────────────────────────────────

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.booking});

  final dynamic booking;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(booking.amount) ?? 0;

    return AppCard(
      accent: AppColors.success,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'You will receive'.toUpperCase(),
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            Formatters.money(amount.toInt()),
            style: AppText.figtree(
              size: 20,
              weight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

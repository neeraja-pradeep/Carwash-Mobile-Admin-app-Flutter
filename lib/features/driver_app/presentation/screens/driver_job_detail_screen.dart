import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/job_detail_provider.dart';
import '../../application/providers/schedule_provider.dart';
import '../../application/states/job_detail_state.dart';
import '../components/otp_modal.dart';
import '../components/route_ladder.dart';

/// Full driver-facing job detail with real API integration.
/// Handles driver-inspection-requests with OTP flow for start/end job.
class DriverJobDetailScreen extends ConsumerStatefulWidget {
  const DriverJobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<DriverJobDetailScreen> createState() =>
      _DriverJobDetailScreenState();
}

class _DriverJobDetailScreenState extends ConsumerState<DriverJobDetailScreen> {
  bool _initialized = false;
  String? _otpKind; // 'start' | 'end' | null

  @override
  void initState() {
    super.initState();
    _initialized = false;
  }

  Future<void> _loadJobDetail() async {
    if (!mounted) return;
    try {
      await ref.read(jobDetailStateProvider(widget.jobId).notifier).loadJobDetail();
    } catch (e) {
      debugPrint('Error loading job detail: $e');
    }
  }

  void _handleBack() {
    // Refresh schedule when returning from detail screen
    ref.invalidate(scheduleStateProvider);
    Navigator.of(context).pop();
  }

  Future<void> _handleArrive() async {
    try {
      await ref.read(jobDetailStateProvider(widget.jobId).notifier).arrive();
      if (mounted) {
        AppToast.show(context, 'Marked as arrived');
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        AppToast.show(context, errorMsg);
      }
    }
  }

  Future<void> _handleStartOtp(String otp) async {
    await ref
        .read(jobDetailStateProvider(widget.jobId).notifier)
        .verifyStartOtp(otp);
    if (mounted) {
      AppToast.show(context, 'Job started · location shared');
    }
  }

  Future<void> _handleEndOtp(String otp) async {
    await ref
        .read(jobDetailStateProvider(widget.jobId).notifier)
        .verifyEndOtp(otp);
    if (mounted) {
      final state = ref.read(jobDetailStateProvider(widget.jobId));
      if (state is JobDetailSuccess) {
        final balanceDue = double.tryParse(state.job.balanceDue) ?? 0;
        AppToast.show(
          context,
          balanceDue > 0
              ? 'Job done · collect ₹${state.job.balanceDue}'
              : 'Job completed',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize data only once on first build
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadJobDetail();
      });
    }

    final jobState = ref.watch(jobDetailStateProvider(widget.jobId));

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: _buildStateView(jobState),
      ),
    );
  }

  Widget _buildStateView(JobDetailState state) {
    if (state is JobDetailLoading || state is JobDetailInitial) {
      return _buildLoading();
    } else if (state is JobDetailSuccess) {
      return _JobDetailBody(
        job: state.job,
        bill: state.bill,
        isLoading: state.isLoading,
        otpKind: _otpKind,
        onRefresh: _loadJobDetail,
        onBack: () => Navigator.of(context).pop(),
        onArrive: _handleArrive,
        onStartOtp: _handleStartOtp,
        onEndOtp: _handleEndOtp,
        onDismissOtp: () => setState(() => _otpKind = null),
        onTapStartJob: () => setState(() => _otpKind = 'start'),
        onTapEndJob: () => setState(() => _otpKind = 'end'),
      );
    } else if (state is JobDetailError) {
      return Column(
        children: [
          TopBar(title: 'Job', onBack: _handleBack),
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
                    onPressed: _loadJobDetail,
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

class _JobDetailBody extends StatelessWidget {
  const _JobDetailBody({
    required this.job,
    this.bill,
    this.isLoading = false,
    this.otpKind,
    required this.onRefresh,
    required this.onBack,
    required this.onArrive,
    required this.onStartOtp,
    required this.onEndOtp,
    required this.onDismissOtp,
    required this.onTapStartJob,
    required this.onTapEndJob,
  });

  final dynamic job;
  final dynamic bill;
  final bool isLoading;
  final String? otpKind;
  final Future<void> Function() onRefresh;
  final VoidCallback onBack;
  final VoidCallback onArrive;
  final Future<void> Function(String) onStartOtp;
  final Future<void> Function(String) onEndOtp;
  final VoidCallback onDismissOtp;
  final VoidCallback onTapStartJob;
  final VoidCallback onTapEndJob;

  String get _stageMsg => job.status;
  bool get _isCompleted => job.status == 'completed';
  bool get _isInProgress => job.status == 'in_progress';
  bool get _isArrived => job.status == 'arrived';
  bool get _isAssigned => job.status == 'assigned';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            TopBar(
              title: 'Job',
              subtitle: '${job.appointmentDate} · ${_stageMsg.toUpperCase()}',
              onBack: onBack,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
                  children: [
                    _CustomerRouteCard(job: job),
                    SizedBox(height: 14.h),
                    _StatusCard(job: job),
                    if (_isCompleted && bill != null) ...[
                      SizedBox(height: 14.h),
                      _FareSummaryCard(job: job, bill: bill),
                    ],
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
                    : _isInProgress
                        ? AppButton(
                            label: 'End Job',
                            full: true,
                            icon: AppIcons.checkCircle,
                            disabled: isLoading,
                            onPressed: onTapEndJob,
                          )
                        : _isArrived
                            ? AppButton(
                                label: 'Start Job',
                                full: true,
                                icon: AppIcons.play,
                                disabled: isLoading,
                                onPressed: onTapStartJob,
                              )
                            : _isAssigned
                                ? AppButton(
                                    label: 'Arrive at Location',
                                    full: true,
                                    disabled: isLoading,
                                    onPressed: onArrive,
                                  )
                                : AppButton(
                                    label: 'Unable to process',
                                    full: true,
                                    kind: AppButtonKind.secondary,
                                    disabled: true,
                                  ),
              ),
            ),
          ],
        ),
        if (otpKind != null)
          OtpModal(
            kind: otpKind!,
            onVerifyOtp:
                otpKind == 'start' ? onStartOtp : onEndOtp,
            onDismiss: onDismissOtp,
          ),
      ],
    );
  }
}

// ── Customer + route card ────────────────────────────────────────────────────

class _CustomerRouteCard extends StatelessWidget {
  const _CustomerRouteCard({required this.job});

  final dynamic job;

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
                      job.customerName,
                      style: AppText.figtree(size: 16, weight: FontWeight.w700),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      job.vehicleText,
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
              _ActionBtn(
                icon: AppIcons.phone,
                filled: false,
                onTap: () => _launchPhone(job.customerPhone),
              ),
              SizedBox(width: 8.w),
              _ActionBtn(
                icon: AppIcons.nav,
                filled: true,
                onTap: () => _launchMaps(
                  job.dropLatitude,
                  job.dropLongitude,
                ),
              ),
            ],
          ),
          SizedBox(height: 13.h),
          const Divider(height: 1, color: AppColors.borderSoft),
          SizedBox(height: 13.h),
          RouteLadder(
            pickup: job.addressText,
            drop: job.dropAddressText ?? job.addressText,
            dropLabel: 'Address',
          ),
        ],
      ),
    );
  }
}

// ── Status / payout card ─────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.job});

  final dynamic job;

  @override
  Widget build(BuildContext context) {
    final status = job.status;
    final (chipBg, chipFg, icon) = switch (status) {
      'completed' => (
          AppColors.greenBg,
          AppColors.greenFg,
          AppIcons.checkCircle,
        ),
      'in_progress' => (
          AppColors.blueBg,
          AppColors.blueFg,
          AppIcons.nav,
        ),
      _ => (
          AppColors.bgPage,
          AppColors.fgSecondary,
          AppIcons.clock,
        ),
    };


    // quoted_fee arrives as '0' when the API sends null, so treat 0 as
    // "no quote" and fall back to the estimated fee.
    final quoted = double.tryParse(job.quotedFee) ?? 0;
    final payout = quoted > 0 ? quoted : (double.tryParse(job.estimatedFee) ?? 0);

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 19.sp, color: chipFg),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Eyebrow('Status'),
                SizedBox(height: 2.h),
                Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: AppText.figtree(size: 14, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Eyebrow('Your payout'),
              SizedBox(height: 2.h),
              Text(
                Formatters.money(payout.toInt()),
                style: AppText.figtree(size: 16, weight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bill summary card (completed only) ───────────────────────────────────────

class _FareSummaryCard extends StatelessWidget {
  const _FareSummaryCard({required this.job, required this.bill});

  final dynamic job;
  final dynamic bill;

  @override
  Widget build(BuildContext context) {
    if (bill == null) {
      return const SizedBox.shrink();
    }

    final balanceDue = double.tryParse(bill.balanceDue) ?? 0;
    final advancePaid = double.tryParse(bill.advancePaid) ?? 0;
    final additionalCharges = double.tryParse(bill.additionalCharges) ?? 0;
    final finalTotal = double.tryParse(bill.finalTotal) ?? 0;

    return AppCard(
      accent: AppColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.receipt, size: 16.sp, color: AppColors.fgSecondary),
              SizedBox(width: 8.w),
              Text(
                'Job Summary'.toUpperCase(),
                style: AppText.figtree(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.fgSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _SummaryRow(label: 'Base fare', valueText: Formatters.money(advancePaid.toInt())),
          if (additionalCharges > 0)
            _SummaryRow(
              label: 'Additional charges',
              valueText: '+ ${Formatters.money(additionalCharges.toInt())}',
              amber: true,
            ),
          SizedBox(height: 8.h),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderDefault)),
            ),
            padding: EdgeInsets.only(top: 11.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppText.figtree(size: 14, weight: FontWeight.w700),
                ),
                Text(
                  Formatters.money(finalTotal.toInt()),
                  style: AppText.figtree(size: 18, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          if (balanceDue > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.amberBg,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.alert, size: 15.sp, color: AppColors.amberFg),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Collect extra ${Formatters.money(balanceDue.toInt())} from customer',
                      style: AppText.figtree(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: AppColors.amberFg,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Icon(AppIcons.checkCircle,
                    size: 14.sp, color: AppColors.greenFg),
                SizedBox(width: 6.w),
                Text(
                  'Nothing extra to collect',
                  style: AppText.figtree(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.greenFg,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.valueText,
    this.amber = false,
  });

  final String label;
  final String valueText;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.figtree(
                size: amber ? 12.5 : 13,
                weight: FontWeight.w500,
                color: amber ? AppColors.fgTertiary : AppColors.fgSecondary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            valueText,
            style: AppText.figtree(
              size: amber ? 12.5 : 13,
              weight: FontWeight.w600,
              color: amber ? AppColors.amberFg : AppColors.fgPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.figtree(
        size: 9.5,
        weight: FontWeight.w700,
        color: AppColors.fgTertiary,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

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
        child: Icon(icon, size: 18.sp, color: AppColors.fgPrimary),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/job_detail_provider.dart';
import '../../application/providers/schedule_provider.dart';
import '../../application/states/job_detail_state.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/job_detail.dart';
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

  /// Confirms, then settles the outstanding balance as a cash payment.
  ///
  /// The amount is taken from the job rather than typed by the driver — the
  /// API only accepts a figure equal to `balance_due`.
  Future<void> _handleCollectCash() async {
    final current = ref.read(jobDetailStateProvider(widget.jobId));
    if (current is! JobDetailSuccess) return;

    final amountText = Formatters.money(_amount(current.job.balanceDue));
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Collected in cash?',
      body: 'Confirm you have received $amountText in cash from the customer. '
          'This settles the balance and cannot be undone from the app.',
      confirmLabel: 'Yes, collected',
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(jobDetailStateProvider(widget.jobId).notifier).collectCash();
      if (mounted) {
        AppToast.show(context, 'Cash collected · balance settled');
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
        onCollectCash: _handleCollectCash,
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
    required this.onCollectCash,
    required this.onDismissOtp,
    required this.onTapStartJob,
    required this.onTapEndJob,
  });

  final JobDetail job;
  final Bill? bill;
  final bool isLoading;
  final String? otpKind;
  final Future<void> Function() onRefresh;
  final VoidCallback onBack;
  final VoidCallback onArrive;
  final Future<void> Function(String) onStartOtp;
  final Future<void> Function(String) onEndOtp;
  final Future<void> Function() onCollectCash;
  final VoidCallback onDismissOtp;
  final VoidCallback onTapStartJob;
  final VoidCallback onTapEndJob;

  String get _stageMsg => job.status;

  /// Cash the driver still has to take from the customer. Mirrors the figures
  /// in [_FareSummaryCard] — the bill wins when it loaded, else the job.
  double get _balanceDue => _amount(bill?.balanceDue ?? job.balanceDue);
  bool get _balancePaid => job.balancePaid || (bill?.balancePaid ?? false);
  bool get _toCollect => _balanceDue > 0 && !_balancePaid;

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
                    SizedBox(height: 14.h),
                    _FareSummaryCard(
                      job: job,
                      bill: bill,
                      isCompleted: _isCompleted,
                    ),
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
                // An unsettled balance outranks the stage label — collecting it
                // is the only thing left for the driver to do.
                child: _toCollect
                    ? AppButton(
                        label:
                            'Collect ${Formatters.money(_balanceDue)} in cash',
                        full: true,
                        icon: AppIcons.receipt,
                        disabled: isLoading,
                        onPressed: () => onCollectCash(),
                      )
                    : _isCompleted
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

  final JobDetail job;

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

  Future<void> _launchMaps(
    BuildContext context,
    double? latitude,
    double? longitude,
    String label,
  ) async {
    final opened = await launchMapPin(
      latitude: latitude,
      longitude: longitude,
      label: label,
    );
    if (!opened && context.mounted) {
      AppToast.show(context, 'No location available for this job.');
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
                  context,
                  job.dropLatitude,
                  job.dropLongitude,
                  job.dropAddressText ?? '',
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

  final JobDetail job;

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
                Formatters.money(payout),
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

/// Payment state for the job the driver is on.
///
/// Two independent money events: the upfront booking payment (`is_paid` /
/// `paid_at`) and, once the job ends, the balance for extra time or charges
/// (`balance_due` / `balance_paid` / `balance_paid_at`). The driver needs to
/// know whether the customer has settled *both* — anything outstanding is cash
/// they still have to collect.
///
/// Figures come from the final-bill endpoint when it loaded, otherwise from the
/// job detail payload itself; the paid flags always come from the job, since
/// the bill carries no timestamps.
class _FareSummaryCard extends StatelessWidget {
  const _FareSummaryCard({
    required this.job,
    required this.bill,
    required this.isCompleted,
  });

  final JobDetail job;
  final Bill? bill;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final b = bill;

    // quoted_fee arrives as '0' when the API sends null.
    final quoted = _amount(job.quotedFee);
    final baseFare = _amount(b?.advancePaid) > 0
        ? _amount(b?.advancePaid)
        : (quoted > 0 ? quoted : _amount(job.estimatedFee));
    final additionalCharges =
        _amount(b?.additionalCharges ?? job.additionalCharges);
    final finalTotal = _amount(b?.finalTotal ?? job.finalTotal);
    final balanceDue = _amount(b?.balanceDue ?? job.balanceDue);
    final balancePaid = job.balancePaid || (b?.balancePaid ?? false);
    final actualHours = b?.actualHours ?? job.actualHours?.toString();

    // Settlement figures are only meaningful once the job has ended.
    final showSettlement = isCompleted || balancePaid || balanceDue > 0;
    final toCollect = balanceDue > 0 && !balancePaid;
    final fullyPaid = job.isPaid && !toCollect;

    return AppCard(
      accent: fullyPaid ? AppColors.success : AppColors.amberDot,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.receipt, size: 16.sp, color: AppColors.fgSecondary),
              SizedBox(width: 8.w),
              Text(
                'PAYMENT',
                style: AppText.figtree(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.fgSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              _PaidChip(
                label: !job.isPaid
                    ? 'UNPAID'
                    : toCollect
                        ? 'BALANCE DUE'
                        : 'PAID',
                positive: fullyPaid,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _SummaryRow(
            label: 'Base fare',
            valueText: Formatters.money(baseFare),
            note: job.isPaid
                ? _withStamp('Paid in advance', job.paidAt)
                : 'Not paid by customer',
            noteColor: job.isPaid ? AppColors.greenFg : AppColors.redFg,
          ),
          if (showSettlement) ...[
            if (additionalCharges > 0)
              _SummaryRow(
                label: actualHours == null
                    ? 'Additional charges'
                    : 'Additional charges · $actualHours hr worked',
                valueText: '+ ${Formatters.money(additionalCharges)}',
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
                    Formatters.money(finalTotal),
                    style: AppText.figtree(size: 18, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            if (toCollect)
              _Banner(
                icon: AppIcons.alert,
                bg: AppColors.amberBg,
                fg: AppColors.amberFg,
                text:
                    'Collect ${Formatters.money(balanceDue)} from customer — final amount not paid',
              )
            else if (balancePaid)
              _Banner(
                icon: AppIcons.checkCircle,
                bg: AppColors.greenBg,
                fg: AppColors.greenFg,
                text: _withStamp(
                  'Final amount of ${Formatters.money(balanceDue)} paid by customer',
                  job.balancePaidAt,
                ),
              )
            else
              _Banner(
                icon: AppIcons.checkCircle,
                bg: AppColors.greenBg,
                fg: AppColors.greenFg,
                text: 'Nothing extra to collect',
              ),
          ],
        ],
      ),
    );
  }
}

class _PaidChip extends StatelessWidget {
  const _PaidChip({required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: positive ? AppColors.greenBg : AppColors.redBg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: AppText.figtree(
          size: 10,
          weight: FontWeight.w700,
          color: positive ? AppColors.greenFg : AppColors.redFg,
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.text,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15.sp, color: fg),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w700,
                color: fg,
              ),
            ),
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
    this.note,
    this.noteColor,
    this.amber = false,
  });

  final String label;
  final String valueText;
  final String? note;
  final Color? noteColor;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.figtree(
                    size: amber ? 12.5 : 13,
                    weight: FontWeight.w500,
                    color:
                        amber ? AppColors.fgTertiary : AppColors.fgSecondary,
                  ),
                ),
                if (note != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    note!,
                    style: AppText.figtree(
                      size: 11,
                      weight: FontWeight.w600,
                      color: noteColor ?? AppColors.fgTertiary,
                    ),
                  ),
                ],
              ],
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

/// `"437.56"` → `437.56`; null/garbage → `0`.
double _amount(String? raw) => double.tryParse(raw?.trim() ?? '') ?? 0;

/// Appends ` · 5 Aug, 10:56 AM` when the timestamp parses, else returns [text].
String _withStamp(String text, String? iso) {
  if (iso == null || iso.isEmpty) return text;
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return text;
  return '$text · ${DateFormat('d MMM, h:mm a').format(parsed.toLocal())}';
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

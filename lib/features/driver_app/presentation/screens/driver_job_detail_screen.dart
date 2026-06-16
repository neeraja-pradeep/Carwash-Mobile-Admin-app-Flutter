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
import '../../../drivers/domain/entities/driver_job.dart';
import '../../application/providers/driver_app_providers.dart';
import '../components/otp_modal.dart';
import '../components/route_ladder.dart';

/// Full driver-facing job detail, pushed via Routes.driverJob(id).
///
/// Mirrors `DJobDetail` in `screen_driver_app.jsx`: a combined customer +
/// route card (Call + Navigate), a status / payout card, the trip/job summary
/// on completion, and a sticky Start → OTP → Active → End → OTP → Completed
/// flow. Status is tracked locally so the demo flow runs end to end.
class DriverJobDetailScreen extends ConsumerWidget {
  const DriverJobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(driverJobByIdProvider(jobId));

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: jobAsync.when(
          loading: () => Column(
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
          ),
          error: (_, __) => Column(
            children: [
              TopBar(title: 'Job', onBack: () => Navigator.of(context).pop()),
              const Expanded(child: Center(child: Text('Could not load job.'))),
            ],
          ),
          data: (job) {
            if (job == null) {
              return Column(
                children: [
                  TopBar(
                    title: 'Job',
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(child: Center(child: Text('Job not found.'))),
                ],
              );
            }
            return _JobDetailBody(
              job: job,
              onBack: () => Navigator.of(context).pop(),
            );
          },
        ),
      ),
    );
  }
}

// ── Body (stateful: local status transitions on OTP verify) ──────────────────

class _JobDetailBody extends StatefulWidget {
  const _JobDetailBody({required this.job, required this.onBack});

  final DriverJob job;
  final VoidCallback onBack;

  @override
  State<_JobDetailBody> createState() => _JobDetailBodyState();
}

class _JobDetailBodyState extends State<_JobDetailBody> {
  late DriverJobState _status = widget.job.state;
  String? _otpKind; // 'start' | 'end' | null

  DriverJob get job => widget.job;
  bool get isHire => job.type == 'Driver hire';

  String get _stageMsg => switch (_status) {
        DriverJobState.upcoming => 'Not started',
        DriverJobState.active => job.stage.isEmpty ? 'In progress' : job.stage,
        DriverJobState.completed => 'Completed',
      };

  void _onVerified() {
    final isStart = _otpKind == 'start';
    setState(() {
      _status = isStart ? DriverJobState.active : DriverJobState.completed;
      _otpKind = null;
    });
    if (isStart) {
      AppToast.show(context, 'Job started · location shared');
    } else {
      AppToast.show(
        context,
        job.fare.collect > 0
            ? 'Job done · collect ${Formatters.money(job.fare.collect)}'
            : 'Job completed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _status == DriverJobState.completed;
    final isActive = _status == DriverJobState.active;

    return Stack(
      children: [
        Column(
          children: [
            TopBar(
              title: '${isHire ? 'Driver Hire' : 'Carwash'} Job',
              subtitle: '${job.time} · $_stageMsg',
              onBack: widget.onBack,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
                children: [
                  _CustomerRouteCard(job: job, isHire: isHire),
                  SizedBox(height: 14.h),
                  _StatusCard(
                    status: _status,
                    stageMsg: _stageMsg,
                    payout: job.payout,
                  ),
                  if (isCompleted) ...[
                    SizedBox(height: 14.h),
                    _FareSummaryCard(job: job, isHire: isHire),
                  ],
                ],
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
                child: isCompleted
                    ? AppButton(
                        label: 'Job completed',
                        full: true,
                        kind: AppButtonKind.secondary,
                        disabled: true,
                      )
                    : isActive
                        ? AppButton(
                            label: 'End Job',
                            full: true,
                            icon: AppIcons.checkCircle,
                            onPressed: () => setState(() => _otpKind = 'end'),
                          )
                        : AppButton(
                            label: 'Start Job',
                            full: true,
                            icon: AppIcons.play,
                            onPressed: () => setState(() => _otpKind = 'start'),
                          ),
              ),
            ),
          ],
        ),
        if (_otpKind != null)
          OtpModal(
            kind: _otpKind!,
            expectedOtp: job.otp,
            onConfirmed: _onVerified,
            onDismiss: () => setState(() => _otpKind = null),
          ),
      ],
    );
  }
}

// ── Customer + route card ────────────────────────────────────────────────────

class _CustomerRouteCard extends StatelessWidget {
  const _CustomerRouteCard({required this.job, required this.isHire});

  final DriverJob job;
  final bool isHire;

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
                      job.customer,
                      style: AppText.figtree(size: 16, weight: FontWeight.w700),
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
                    if (isHire && job.reason != null) ...[
                      SizedBox(height: 5.h),
                      Text(
                        job.reason!,
                        style: AppText.figtree(
                          size: 11.5,
                          weight: FontWeight.w600,
                          color: AppColors.fgSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              _ActionBtn(
                icon: AppIcons.phone,
                filled: false,
                onTap: () => AppToast.show(
                  context,
                  'Calling ${job.customer}…',
                ),
              ),
              SizedBox(width: 8.w),
              _ActionBtn(
                icon: AppIcons.nav,
                filled: true,
                onTap: () => AppToast.show(context, 'Opening Maps…'),
              ),
            ],
          ),
          SizedBox(height: 13.h),
          const Divider(height: 1, color: AppColors.borderSoft),
          SizedBox(height: 13.h),
          RouteLadder(
            pickup: job.pickup,
            drop: job.drop,
            dropLabel: isHire ? 'Trip' : 'Drop',
          ),
        ],
      ),
    );
  }
}

// ── Status / payout card ─────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.stageMsg,
    required this.payout,
  });

  final DriverJobState status;
  final String stageMsg;
  final int payout;

  @override
  Widget build(BuildContext context) {
    final (chipBg, chipFg, icon) = switch (status) {
      DriverJobState.completed => (
          AppColors.greenBg,
          AppColors.greenFg,
          AppIcons.checkCircle,
        ),
      DriverJobState.active => (
          AppColors.blueBg,
          AppColors.blueFg,
          AppIcons.nav,
        ),
      DriverJobState.upcoming => (
          AppColors.bgPage,
          AppColors.fgSecondary,
          AppIcons.clock,
        ),
    };

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
                  stageMsg,
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

// ── Trip / job summary card (completed only) ─────────────────────────────────

class _FareSummaryCard extends StatelessWidget {
  const _FareSummaryCard({required this.job, required this.isHire});

  final DriverJob job;
  final bool isHire;

  @override
  Widget build(BuildContext context) {
    final f = job.fare;
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
                (isHire ? 'Trip Summary' : 'Job Summary').toUpperCase(),
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
          if (isHire && f.plannedHours != null)
            _SummaryRow(
              label: 'Duration',
              valueText:
                  '${f.plannedHours}h planned · ${f.actualHours}h actual',
            ),
          _SummaryRow(label: 'Base fare', valueText: Formatters.money(f.base)),
          ...f.items.map(
            (it) => _SummaryRow(
              label: it.label,
              valueText: '+ ${Formatters.money(it.amount)}',
              amber: true,
            ),
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
                  Formatters.money(f.total),
                  style: AppText.figtree(size: 18, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          if (f.collect > 0)
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
                      'Collect extra ${Formatters.money(f.collect)} from customer',
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

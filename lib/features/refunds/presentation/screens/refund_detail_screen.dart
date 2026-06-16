import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/status/badge_tone.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_dialog.dart';
import 'package:new_flutter_project/core/widgets/app_icon_button.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/skeleton_card.dart';
import 'package:new_flutter_project/core/widgets/status_badge.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/app/router/app_router.dart';
import '../../application/providers/refunds_providers.dart';
import '../../domain/entities/refund.dart';

/// Refund detail screen — pushed via Navigator.push from RefundsScreen.
class RefundDetailScreen extends ConsumerStatefulWidget {
  const RefundDetailScreen({required this.refundId, super.key});

  final String refundId;

  @override
  ConsumerState<RefundDetailScreen> createState() => _RefundDetailScreenState();
}

class _RefundDetailScreenState extends ConsumerState<RefundDetailScreen> {
  /// Local mutable status (demo only — not persisted).
  String? _localStatus;

  @override
  void dispose() {
    super.dispose();
  }

  String _statusFor(Refund r) => _localStatus ?? r.status;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(refundByIdProvider(widget.refundId));

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => _Loading(),
          error: (_, __) => _ErrorState(),
          data: (refund) {
            if (refund == null) return _ErrorState();
            final status = _statusFor(refund);
            final declined = status == 'declined';
            final tone = _toneFor(status);
            final label = _labelFor(status);
            return Column(
              children: [
                TopBar(
                  title: 'Refund',
                  onBack: () => Navigator.of(context).pop(),
                  actions: [
                    AppIconButton(
                      icon: AppIcons.more,
                      iconSize: 22,
                      semanticLabel: 'More',
                      onTap: () =>
                          AppToast.show(context, 'Copy ID · Export breakdown'),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
                    children: [
                      // Header amount card
                      AppCard(
                        padding: EdgeInsets.all(18.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StatusBadge(label: label, tone: tone),
                                Text(
                                  refund.id,
                                  style: AppText.figtree(
                                    size: 11.5,
                                    weight: FontWeight.w500,
                                    color: AppColors.fgTertiary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'REFUND AMOUNT',
                              style: AppText.figtree(
                                size: 10.5,
                                weight: FontWeight.w700,
                                color: AppColors.fgTertiary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.money(refund.amount),
                                  style: AppText.figtree(
                                    size: 32,
                                    weight: FontWeight.w800,
                                    letterSpacing: -1,
                                  ),
                                ),
                                Text(
                                  'Tier: ${refund.tier}',
                                  style: AppText.figtree(
                                    size: 12.5,
                                    weight: FontWeight.w600,
                                    color: AppColors.fgSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Workflow stepper (only if not declined)
                      if (!declined) ...[
                        _WorkflowStepper(status: status),
                        SizedBox(height: 14.h),
                      ],

                      // Customer + booking ref card
                      AppCard(
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 11.h),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CUSTOMER',
                                        style: AppText.figtree(
                                          size: 11,
                                          weight: FontWeight.w700,
                                          color: AppColors.fgTertiary,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      SizedBox(height: 5.h),
                                      Text(
                                        refund.customer.name,
                                        style: AppText.figtree(
                                          size: 14.5,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        refund.customer.phone,
                                        style: AppText.figtree(
                                          size: 12.5,
                                          weight: FontWeight.w500,
                                          color: AppColors.fgTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () => AppToast.show(
                                        context, 'Calling…'),
                                    child: Container(
                                      width: 34.r,
                                      height: 34.r,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.bgCard,
                                        borderRadius:
                                            BorderRadius.circular(9.r),
                                        border: Border.all(
                                            color: AppColors.borderDefault),
                                      ),
                                      child: Icon(AppIcons.phone,
                                          size: 17.sp,
                                          color: AppColors.fgSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1.h, color: AppColors.borderSoft),
                            // Booking row (tappable if booking exists in sample)
                            GestureDetector(
                              onTap: () => context
                                  .push(Routes.bookingDetail(refund.bookingId)),
                              child: Padding(
                                padding:
                                    EdgeInsets.fromLTRB(0, 12.h, 0, 4.h),
                                child: Row(
                                  children: [
                                    Icon(AppIcons.cal,
                                        size: 17.sp,
                                        color: AppColors.fgTertiary),
                                    SizedBox(width: 10.w),
                                    SizedBox(
                                      width: 64.w,
                                      child: Text(
                                        'Booking',
                                        style: AppText.figtree(
                                          size: 12,
                                          weight: FontWeight.w500,
                                          color: AppColors.fgTertiary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        refund.bookingId,
                                        style: AppText.figtree(
                                          size: 12.5,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Icon(AppIcons.chevRight,
                                        size: 17.sp,
                                        color: AppColors.fgTertiary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Reason + notes card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REASON',
                              style: AppText.figtree(
                                size: 11,
                                weight: FontWeight.w700,
                                color: AppColors.fgTertiary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              refund.reason,
                              style: AppText.figtree(
                                size: 14,
                                weight: FontWeight.w600,
                              ),
                            ),
                            if (refund.notes.isNotEmpty) ...[
                              SizedBox(height: 6.h),
                              Text(
                                refund.notes,
                                style: AppText.figtree(
                                  size: 13,
                                  weight: FontWeight.w400,
                                  color: AppColors.fgSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // UTR / proof card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PAYMENT PROOF',
                              style: AppText.figtree(
                                size: 11,
                                weight: FontWeight.w700,
                                color: AppColors.fgTertiary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            if (refund.utr.isNotEmpty) ...[
                              Text(
                                refund.utr,
                                style: AppText.figtree(
                                  size: 13,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 5.h),
                              Row(
                                children: [
                                  Icon(AppIcons.checkCircle,
                                      size: 14.sp,
                                      color: AppColors.greenFg),
                                  SizedBox(width: 5.w),
                                  Text(
                                    'Screenshot on file',
                                    style: AppText.figtree(
                                      size: 12,
                                      weight: FontWeight.w500,
                                      color: AppColors.greenFg,
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              Text(
                                'Required before marking Paid',
                                style: AppText.figtree(
                                  size: 13,
                                  weight: FontWeight.w500,
                                  color: AppColors.fgMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Timestamps
                      Text(
                        _buildTimestamps(refund, status),
                        textAlign: TextAlign.center,
                        style: AppText.figtree(
                          size: 11.5,
                          weight: FontWeight.w500,
                          color: AppColors.fgMuted,
                        ),
                      ),
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),

                // Sticky footer
                _buildFooter(context, refund, status, declined),
              ],
            );
          },
        ),
      ),
    );
  }

  String _buildTimestamps(Refund r, String status) {
    var s = 'Created ${r.createdAt}';
    if (r.approvedAt != null) s += ' · Approved ${r.approvedAt}';
    if (r.paidAt != null) s += ' · Paid ${r.paidAt}';
    // local overrides
    return s;
  }

  Widget _buildFooter(
      BuildContext context, Refund refund, String status, bool declined) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Builder(
          builder: (ctx) {
            if (status == 'paid') {
              return AppButton(
                label: 'Refund settled',
                full: true,
                kind: AppButtonKind.secondary,
                disabled: true,
                onPressed: null,
              );
            }
            if (declined) {
              return AppButton(
                label: 'Refund declined',
                full: true,
                kind: AppButtonKind.secondary,
                disabled: true,
                onPressed: null,
              );
            }
            return Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _confirmDecline(context, refund),
                    child: Container(
                      height: 50.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.redBg,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.redFg),
                      ),
                      child: Text(
                        'Decline',
                        style: AppText.figtree(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.redFg,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 2,
                  child: status == 'requested'
                      ? AppButton(
                          label: 'Approve',
                          full: true,
                          onPressed: () {
                            setState(() => _localStatus = 'approved');
                            AppToast.show(context, 'Refund approved');
                          },
                        )
                      : AppButton(
                          label: 'Mark Paid',
                          full: true,
                          onPressed: () =>
                              _showMarkPaidModal(context, refund),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDecline(BuildContext context, Refund refund) async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'Decline this refund?',
      body: "The customer will not be refunded. This can't be undone.",
      confirmLabel: 'Decline',
      destructive: true,
    );
    if (ok && mounted) {
      setState(() => _localStatus = 'declined');
      AppToast.show(context, 'Refund declined');
    }
  }

  Future<void> _showMarkPaidModal(BuildContext context, Refund refund) async {
    await showAppModal<void>(
      context: context,
      builder: (modalCtx) => _MarkPaidModal(
        amount: refund.amount,
        onConfirm: (utr) {
          Navigator.of(modalCtx).pop();
          setState(() => _localStatus = 'paid');
          AppToast.show(context, 'Refund marked Paid');
        },
        onBack: () => Navigator.of(modalCtx).pop(),
      ),
    );
  }

  BadgeTone _toneFor(String status) => switch (status) {
        'approved' => BadgeTone.blue,
        'paid' => BadgeTone.green,
        'declined' => BadgeTone.red,
        _ => BadgeTone.amber,
      };

  String _labelFor(String status) => switch (status) {
        'approved' => 'Approved',
        'paid' => 'Paid',
        'declined' => 'Declined',
        _ => 'Requested',
      };
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _WorkflowStepper extends StatelessWidget {
  const _WorkflowStepper({required this.status});

  final String status;

  static const List<(String, String)> _steps = [
    ('requested', 'Requested'),
    ('approved', 'Approved'),
    ('paid', 'Paid'),
  ];

  int get _currentIndex {
    final idx = _steps.indexWhere((s) => s.$1 == status);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final ci = _currentIndex;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS',
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                _StepDot(
                  label: _steps[i].$2,
                  active: i <= ci,
                ),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2.h,
                      margin: EdgeInsets.only(bottom: 18.h),
                      color: i < ci
                          ? AppColors.greenFg
                          : AppColors.borderSoft,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26.r,
          height: 26.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.greenFg : AppColors.borderSoft,
            shape: BoxShape.circle,
          ),
          child: active
              ? Icon(AppIcons.check, size: 15.sp, color: Colors.white)
              : Container(
                  width: 6.r,
                  height: 6.r,
                  decoration: const BoxDecoration(
                    color: AppColors.fgMuted,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: AppText.figtree(
            size: 11,
            weight: FontWeight.w600,
            color: active ? AppColors.fgPrimary : AppColors.fgMuted,
          ),
        ),
      ],
    );
  }
}

class _MarkPaidModal extends StatefulWidget {
  const _MarkPaidModal({
    required this.amount,
    required this.onConfirm,
    required this.onBack,
  });

  final int amount;
  final void Function(String utr) onConfirm;
  final VoidCallback onBack;

  @override
  State<_MarkPaidModal> createState() => _MarkPaidModalState();
}

class _MarkPaidModalState extends State<_MarkPaidModal> {
  final _utr = TextEditingController();
  bool _proof = false;

  @override
  void dispose() {
    _utr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mark refund paid',
          style: AppText.figtree(size: 19, weight: FontWeight.w700),
        ),
        SizedBox(height: 6.h),
        Text(
          'Process ${Formatters.money(widget.amount)} externally, then log the reference here.',
          style: AppText.figtree(
            size: 13.5,
            weight: FontWeight.w400,
            color: AppColors.fgSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: 18.h),
        _LabeledInput(
          label: 'UTR / reference',
          controller: _utr,
          placeholder: 'e.g. UPI/HDFC/889201144',
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 14.h),
        GestureDetector(
          onTap: () => setState(() => _proof = !_proof),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(13.r),
            decoration: BoxDecoration(
              color: _proof ? AppColors.greenBg : AppColors.bgCard,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _proof ? AppColors.greenFg : AppColors.borderDefault,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _proof ? AppIcons.checkCircle : AppIcons.plus,
                  size: 20.sp,
                  color: _proof ? AppColors.greenFg : AppColors.fgTertiary,
                ),
                SizedBox(width: 10.w),
                Text(
                  _proof ? 'Screenshot attached' : 'Attach screenshot (optional)',
                  style: AppText.figtree(
                    size: 13,
                    weight: FontWeight.w600,
                    color: _proof ? AppColors.greenFg : AppColors.fgSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Back',
                kind: AppButtonKind.secondary,
                full: true,
                onPressed: widget.onBack,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AppButton(
                label: 'Mark Paid',
                full: true,
                disabled: _utr.text.trim().isEmpty,
                onPressed: _utr.text.trim().isEmpty
                    ? null
                    : () => widget.onConfirm(_utr.text.trim()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w600,
            color: AppColors.fgSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppText.figtree(
              size: 13.5,
              weight: FontWeight.w400,
              color: AppColors.fgMuted,
            ),
            filled: true,
            fillColor: AppColors.bgPage,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppColors.fgPrimary, width: 1.5),
            ),
          ),
          style: AppText.figtree(size: 13.5, weight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(title: 'Refund', onBack: () => Navigator.of(context).pop()),
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              const SkeletonCard(),
              SizedBox(height: 14.h),
              const SkeletonCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(title: 'Refund', onBack: () => Navigator.of(context).pop()),
        Expanded(
          child: Center(
            child: Text(
              'Refund not found.',
              style: AppText.figtree(
                size: 14,
                weight: FontWeight.w500,
                color: AppColors.fgMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

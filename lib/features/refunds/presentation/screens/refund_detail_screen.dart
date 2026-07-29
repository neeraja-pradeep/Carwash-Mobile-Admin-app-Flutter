import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
import 'package:new_flutter_project/features/bookings/application/providers/bookings_providers.dart';
import '../../application/providers/refunds_providers.dart';
import '../../domain/entities/refund.dart';

/// Refund detail screen — pushed via Navigator.push from RefundsScreen.
class RefundDetailScreen extends ConsumerStatefulWidget {
  const RefundDetailScreen({required this.refundId, this.seed, super.key});

  /// Numeric refund id or `RF-…` reference (the detail key).
  final String refundId;

  /// The list row this screen was opened from, when there is one.
  ///
  /// Needed for `kind: "request"` entries: those are synthesized by the list
  /// endpoint for bookings awaiting a decision and have no refund row, so the
  /// detail endpoint answers 404 for them. The list row already carries
  /// everything such an entry can show, so it is rendered directly.
  final Refund? seed;

  @override
  ConsumerState<RefundDetailScreen> createState() => _RefundDetailScreenState();
}

class _RefundDetailScreenState extends ConsumerState<RefundDetailScreen> {
  bool _busy = false;

  /// The `RF-…` key of the row created by approving/declining a request here.
  /// Until then a request has no row to fetch, so this stays null.
  String? _resolvedKey;

  /// What to resolve against the detail endpoint.
  String get _detailKey => _resolvedKey ?? widget.refundId;

  /// Whether to render from [RefundDetailScreen.seed] rather than fetching.
  /// False again once Approve or Decline has created the real row.
  bool get _seedOnly =>
      _resolvedKey == null && (widget.seed?.isRequestOnly ?? false);

  @override
  Widget build(BuildContext context) {
    if (_seedOnly) {
      return Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(bottom: false, child: _buildLoaded(widget.seed!)),
      );
    }

    final async = ref.watch(refundByIdProvider(_detailKey));

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => _Loading(),
          error: (_, __) => _ErrorState(),
          data: (refund) {
            if (refund == null) return _ErrorState();
            return _buildLoaded(refund);
          },
        ),
      ),
    );
  }

  Widget _buildLoaded(Refund refund) {
    final status = refund.status;
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
              onTap: () => AppToast.show(context, 'Copy ID · Export breakdown'),
            ),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(refundByIdProvider(_detailKey));
              await ref.read(refundByIdProvider(_detailKey).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                            refund.reference ?? refund.id,
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

                // Workflow stepper (driven by steps[]), only if not declined
                if (!declined && refund.displaySteps.isNotEmpty) ...[
                  _WorkflowStepper(steps: refund.displaySteps),
                  SizedBox(height: 14.h),
                ],

                // Customer + booking ref card
                AppCard(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 11.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                              onTap: () => AppToast.show(context, 'Calling…'),
                              child: Container(
                                width: 34.r,
                                height: 34.r,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.bgCard,
                                  borderRadius: BorderRadius.circular(9.r),
                                  border: Border.all(
                                      color: AppColors.borderDefault),
                                ),
                                child: Icon(AppIcons.phone,
                                    size: 17.sp, color: AppColors.fgSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1.h, color: AppColors.borderSoft),
                      _BookingRef(
                        bookingId: refund.bookingId,
                        label: refund.bookingLabel,
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
                        refund.reasonDisplay,
                        style: AppText.figtree(
                          size: 14,
                          weight: FontWeight.w600,
                        ),
                      ),
                      if ((refund.reasonSubtitle ?? '').isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          refund.reasonSubtitle!,
                          style: AppText.figtree(
                            size: 13,
                            weight: FontWeight.w400,
                            color: AppColors.fgSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
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

                // Payment proof card
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
                        if (refund.proof) ...[
                          SizedBox(height: 5.h),
                          Row(
                            children: [
                              Icon(AppIcons.checkCircle,
                                  size: 14.sp, color: AppColors.greenFg),
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
                        ],
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
                  _buildTimestamps(refund),
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
        ),

        // Sticky footer
        _buildFooter(context, refund),
      ],
    );
  }

  String _buildTimestamps(Refund r) {
    var s = 'Created ${r.createdAt}';
    if (r.approvedAt != null) s += ' · Approved ${r.approvedAt}';
    if (r.paidAt != null) s += ' · Paid ${r.paidAt}';
    return s;
  }

  Widget _buildFooter(BuildContext context, Refund refund) {
    final next = refund.displayNextAction;
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
            // Terminal — no next action.
            if (next == null) {
              return AppButton(
                label: refund.status == 'declined'
                    ? 'Refund declined'
                    : 'Refund settled',
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
                    onTap: _busy ? null : () => _confirmDecline(refund),
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
                  child: next == 'approve'
                      ? AppButton(
                          label: 'Approve',
                          full: true,
                          disabled: _busy,
                          onPressed: _busy ? null : () => _approve(refund),
                        )
                      : AppButton(
                          label: 'Mark Paid',
                          full: true,
                          disabled: _busy,
                          onPressed: _busy
                              ? null
                              : () => _showMarkPaidModal(context, refund),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _approve(Refund refund) async {
    final bookingRef = refund.bookingReference;
    if (bookingRef == null || bookingRef.isEmpty) {
      AppToast.show(context, 'Missing booking reference');
      return;
    }
    setState(() => _busy = true);
    try {
      final approved = await ref.read(refundActionsProvider).approve(
            bookingReference: bookingRef,
            percent: refund.percent?.round(),
            reason: refund.reason.isNotEmpty ? refund.reason : null,
            comment: refund.notes.isNotEmpty ? refund.notes : null,
            // A request has no row yet, so there is no key of ours to refresh —
            // let the action invalidate the one it just created.
            detailKey: _seedOnly ? null : _detailKey,
          );
      // Approving a request creates the real row: adopt its key so the screen
      // stops rendering the seed and starts reading the detail endpoint.
      if (mounted) {
        setState(() => _resolvedKey = approved.detailKey);
        AppToast.show(context, 'Refund approved');
      }
    } catch (e) {
      if (mounted) AppToast.show(context, _msg(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDecline(Refund refund) async {
    final bookingRef = refund.bookingReference;
    if (bookingRef == null || bookingRef.isEmpty) {
      AppToast.show(context, 'Missing booking reference');
      return;
    }
    final ok = await showConfirmDialog(
      context: context,
      title: 'Decline this refund?',
      body: "The customer will not be refunded. This can't be undone.",
      confirmLabel: 'Decline',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final declinedRow = await ref.read(refundActionsProvider).decline(
            bookingReference: bookingRef,
            reason: refund.reason.isNotEmpty ? refund.reason : null,
            comment: refund.notes.isNotEmpty ? refund.notes : null,
            detailKey: _seedOnly ? null : _detailKey,
          );
      // Declining a request also writes a real (₹0 audit) row — adopt its key.
      if (mounted) {
        setState(() => _resolvedKey = declinedRow.detailKey);
        AppToast.show(context, 'Refund declined');
      }
    } catch (e) {
      if (mounted) AppToast.show(context, _msg(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showMarkPaidModal(BuildContext context, Refund refund) async {
    await showAppModal<void>(
      context: context,
      builder: (modalCtx) => _MarkPaidModal(
        amount: refund.amount,
        onConfirm: (reference, screenshotPath) async {
          Navigator.of(modalCtx).pop();
          await _markPaid(refund, reference, screenshotPath);
        },
        onBack: () => Navigator.of(modalCtx).pop(),
      ),
    );
  }

  Future<void> _markPaid(
    Refund refund,
    String reference,
    String? screenshotPath,
  ) async {
    setState(() => _busy = true);
    try {
      await ref.read(refundActionsProvider).markPaid(
            refundRef: refund.detailKey,
            paymentProofReference: reference,
            screenshotPath: screenshotPath,
            detailKey: _detailKey,
          );
      if (mounted) AppToast.show(context, 'Refund marked Paid');
    } catch (e) {
      if (mounted) AppToast.show(context, _msg(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _msg(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
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

/// Workflow stepper driven by the server `steps[]` payload.
class _WorkflowStepper extends StatelessWidget {
  const _WorkflowStepper({required this.steps});

  final List<RefundStep> steps;

  @override
  Widget build(BuildContext context) {
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
              for (var i = 0; i < steps.length; i++) ...[
                _StepDot(label: steps[i].label, active: steps[i].done),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2.h,
                      margin: EdgeInsets.only(bottom: 18.h),
                      color: steps[i].done
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

/// Booking reference row. Tappable (with a chevron) only when the referenced
/// booking exists in the bookings cache so refunds for archived bookings don't
/// dead-link.
class _BookingRef extends ConsumerWidget {
  const _BookingRef({required this.bookingId, required this.label});

  final String bookingId;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exists =
        ref.watch(bookingByIdProvider(bookingId)).valueOrNull != null;

    final row = Padding(
      padding: EdgeInsets.fromLTRB(0, 12.h, 0, 4.h),
      child: Row(
        children: [
          Icon(AppIcons.cal, size: 17.sp, color: AppColors.fgTertiary),
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
              label,
              style: AppText.figtree(size: 12.5, weight: FontWeight.w600),
            ),
          ),
          if (exists)
            Icon(AppIcons.chevRight, size: 17.sp, color: AppColors.fgTertiary),
        ],
      ),
    );

    if (!exists) return row;
    return GestureDetector(
      onTap: () => context.push(Routes.bookingDetail(bookingId)),
      behavior: HitTestBehavior.opaque,
      child: row,
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
  final void Function(String reference, String? screenshotPath) onConfirm;
  final VoidCallback onBack;

  @override
  State<_MarkPaidModal> createState() => _MarkPaidModalState();
}

class _MarkPaidModalState extends State<_MarkPaidModal> {
  final _ref = TextEditingController();
  String? _screenshotPath;
  bool _picking = false;

  @override
  void dispose() {
    _ref.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file != null && mounted) {
        setState(() => _screenshotPath = file.path);
      }
    } catch (e) {
      if (mounted) AppToast.show(context, 'Could not pick image');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  bool get _hasProof => _ref.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final attached = _screenshotPath != null;
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
          'Process ${Formatters.money(widget.amount)} externally, then log the '
          'payment proof reference here. Proof is required before marking Paid.',
          style: AppText.figtree(
            size: 13.5,
            weight: FontWeight.w400,
            color: AppColors.fgSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: 18.h),
        _LabeledInput(
          label: 'Payment proof reference',
          controller: _ref,
          placeholder: 'e.g. UPI/AXIS/552210034',
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 14.h),
        GestureDetector(
          onTap: _picking ? null : _pickScreenshot,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(13.r),
            decoration: BoxDecoration(
              color: attached ? AppColors.greenBg : AppColors.bgCard,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: attached ? AppColors.greenFg : AppColors.borderDefault,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  attached ? AppIcons.checkCircle : AppIcons.plus,
                  size: 20.sp,
                  color: attached ? AppColors.greenFg : AppColors.fgTertiary,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    attached
                        ? 'Screenshot attached'
                        : 'Attach screenshot (optional)',
                    style: AppText.figtree(
                      size: 13,
                      weight: FontWeight.w600,
                      color:
                          attached ? AppColors.greenFg : AppColors.fgSecondary,
                    ),
                  ),
                ),
                if (_picking)
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
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
                disabled: !_hasProof,
                onPressed: !_hasProof
                    ? null
                    : () => widget.onConfirm(_ref.text.trim(), _screenshotPath),
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
              borderSide:
                  const BorderSide(color: AppColors.fgPrimary, width: 1.5),
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

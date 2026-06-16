import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
import 'package:new_flutter_project/features/shops/application/providers/shops_providers.dart';
import '../../application/providers/payouts_providers.dart';
import '../../domain/entities/payout.dart';

/// Payout detail screen — pushed from PayoutsScreen via Navigator.push.
class PayoutDetailScreen extends ConsumerStatefulWidget {
  const PayoutDetailScreen({required this.payoutId, super.key});

  final String payoutId;

  @override
  ConsumerState<PayoutDetailScreen> createState() => _PayoutDetailScreenState();
}

class _PayoutDetailScreenState extends ConsumerState<PayoutDetailScreen> {
  String? _localStatus;
  List<PayoutBooking>? _localBookings;
  List<PayoutAdjustment>? _localAdjustments;
  int? _overrideNet;
  final Map<String, bool> _open = {};

  List<PayoutBooking> _bookingsFor(Payout p) =>
      _localBookings ?? List<PayoutBooking>.from(p.bookings);

  List<PayoutAdjustment> _adjustmentsFor(Payout p) =>
      _localAdjustments ?? List<PayoutAdjustment>.from(p.adjustments);

  String _statusFor(Payout p) => _localStatus ?? p.status;

  void _toggleSection(String key) =>
      setState(() => _open[key] = !(_open[key] ?? false));

  PayoutCalc _calcFor(Payout p) {
    final bookings = _bookingsFor(p);
    final adjustments = _adjustmentsFor(p);
    final temp = Payout(
      id: p.id,
      shopId: p.shopId,
      period: p.period,
      status: _statusFor(p),
      createdAt: p.createdAt,
      paidAt: p.paidAt,
      utr: p.utr,
      proof: p.proof,
      adjustments: adjustments,
      bookings: bookings,
    );
    return temp.calc;
  }

  void _toggleExclude(int index) {
    setState(() {
      final current = _localBookings ?? <PayoutBooking>[];
      _localBookings = [
        for (var i = 0; i < current.length; i++)
          i == index
              ? current[i].copyWith(excluded: !current[i].excluded)
              : current[i],
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(payoutByIdProvider(widget.payoutId));

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => _Loading(),
          error: (_, __) => _ErrorState(),
          data: (payout) {
            if (payout == null) return _ErrorState();
            // Seed local mutable copies on first build
            _localBookings ??= List<PayoutBooking>.from(payout.bookings);
            _localAdjustments ??=
                List<PayoutAdjustment>.from(payout.adjustments);

            final status = _statusFor(payout);
            final c = _calcFor(payout);
            final netFinal = _overrideNet ?? c.net;
            final editable = status != 'paid';
            final shopAsync = ref.watch(shopByIdProvider(payout.shopId));
            final shopName = shopAsync.valueOrNull?.name ?? payout.shopId;

            return Column(
              children: [
                TopBar(
                  title: 'Payout',
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
                      // Header net amount card
                      AppCard(
                        padding: EdgeInsets.all(18.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StatusBadge(
                                  label: status == 'paid' ? 'Paid' : 'Pending',
                                  tone: status == 'paid'
                                      ? BadgeTone.green
                                      : BadgeTone.amber,
                                ),
                                Text(
                                  payout.id,
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
                              'NET PAYABLE',
                              style: AppText.figtree(
                                size: 10.5,
                                weight: FontWeight.w700,
                                color: AppColors.fgTertiary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              Formatters.money(netFinal),
                              style: AppText.figtree(
                                size: 32,
                                weight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            if (_overrideNet != null) ...[
                              SizedBox(height: 4.h),
                              Text(
                                'Overridden · calculated ${Formatters.money(c.net)}',
                                style: AppText.figtree(
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: AppColors.amberFg,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Shop + period card
                      AppCard(
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 11.h),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36.r,
                                    height: 36.r,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.bgPage,
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Icon(AppIcons.store,
                                        size: 18.sp,
                                        color: AppColors.fgSecondary),
                                  ),
                                  SizedBox(width: 11.w),
                                  Expanded(
                                    child: Text(
                                      shopName,
                                      style: AppText.figtree(
                                        size: 14,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1.h, color: AppColors.borderSoft),
                            Padding(
                              padding: EdgeInsets.only(top: 11.h),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Period',
                                    style: AppText.figtree(
                                      size: 13,
                                      weight: FontWeight.w500,
                                      color: AppColors.fgTertiary,
                                    ),
                                  ),
                                  Text(
                                    payout.period,
                                    style: AppText.figtree(
                                      size: 13.5,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Calculation summary card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CALCULATION',
                              style: AppText.figtree(
                                size: 11,
                                weight: FontWeight.w700,
                                color: AppColors.fgSecondary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            _CalcLine(
                              label: 'Gross (completed bookings)',
                              amount: c.gross,
                              sign: '',
                              isOpen: _open['g'] ?? false,
                              onToggle: () => _toggleSection('g'),
                              child: _GrossDetail(
                                bookings: _bookingsFor(payout),
                                editable: editable,
                                onToggleExclude: editable
                                    ? (i) {
                                        _localBookings ??=
                                            List<PayoutBooking>.from(
                                                payout.bookings);
                                        _toggleExclude(i);
                                      }
                                    : null,
                              ),
                            ),
                            _CalcLine(
                              label: 'Commission',
                              amount: c.commission,
                              sign: '-',
                              isOpen: _open['c'] ?? false,
                              onToggle: () => _toggleSection('c'),
                              child: _CommDetail(
                                bookings: _bookingsFor(payout)
                                    .where((b) => !b.excluded)
                                    .toList(),
                              ),
                            ),
                            if (c.refunds > 0)
                              _CalcLine(
                                label: 'Refunds in period',
                                amount: c.refunds,
                                sign: '-',
                                isOpen: _open['r'] ?? false,
                                onToggle: () => _toggleSection('r'),
                                child: _RefundsDetail(
                                  bookings: _bookingsFor(payout)
                                      .where((b) => !b.excluded && b.refund > 0)
                                      .toList(),
                                ),
                              ),
                            _CalcLine(
                              label: 'Other adjustments',
                              amount: c.adj,
                              sign: c.adj < 0
                                  ? '-'
                                  : c.adj > 0
                                      ? '+'
                                      : '',
                              isOpen: _open['a'] ?? false,
                              onToggle: () => _toggleSection('a'),
                              child: _AdjDetail(
                                adjustments: _adjustmentsFor(payout),
                                editable: editable,
                                onAdd: editable
                                    ? () {
                                        _localAdjustments ??=
                                            List<PayoutAdjustment>.from(
                                                payout.adjustments);
                                        setState(() {
                                          _localAdjustments!.add(
                                            const PayoutAdjustment(
                                              amount: -50,
                                              reason: 'Manual adjustment',
                                              at: 'now',
                                            ),
                                          );
                                        });
                                        AppToast.show(
                                            context, 'Adjustment added');
                                      }
                                    : null,
                              ),
                            ),
                            // Net payable row
                            Padding(
                              padding: EdgeInsets.only(top: 13.h),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Net Payable',
                                    style: AppText.figtree(
                                      size: 14,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        Formatters.money(netFinal),
                                        style: AppText.figtree(
                                          size: 19,
                                          weight: FontWeight.w800,
                                        ),
                                      ),
                                      if (editable) ...[
                                        SizedBox(width: 10.w),
                                        GestureDetector(
                                          onTap: () => _showOverrideModal(
                                              context, c.net),
                                          child: Container(
                                            width: 30.r,
                                            height: 30.r,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: AppColors.bgCard,
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              border: Border.all(
                                                  color:
                                                      AppColors.borderDefault),
                                            ),
                                            child: Icon(AppIcons.edit,
                                                size: 15.sp,
                                                color: AppColors.fgSecondary),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
                            if (payout.utr.isNotEmpty) ...[
                              Text(
                                payout.utr,
                                style: AppText.figtree(
                                  size: 13,
                                  weight: FontWeight.w600,
                                ),
                              ),
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
                        _buildTimestamps(payout),
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
                _buildFooter(context, payout, status, netFinal),
              ],
            );
          },
        ),
      ),
    );
  }

  String _buildTimestamps(Payout p) {
    var s = 'Created ${p.createdAt}';
    if (p.paidAt != null) s += ' · Paid ${p.paidAt}';
    return s;
  }

  Widget _buildFooter(
      BuildContext context, Payout payout, String status, int netFinal) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: status == 'paid'
            ? AppButton(
                label: 'Payout settled',
                full: true,
                kind: AppButtonKind.secondary,
                disabled: true,
                onPressed: null,
              )
            : Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      kind: AppButtonKind.secondary,
                      full: true,
                      onPressed: () {
                        AppToast.show(context, 'Payout cancelled');
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: 'Mark Paid',
                      full: true,
                      onPressed: () =>
                          _showMarkPaidModal(context, payout, netFinal),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _showMarkPaidModal(
      BuildContext context, Payout payout, int amount) async {
    await showAppModal<void>(
      context: context,
      builder: (modalCtx) => _MarkPaidModal(
        amount: amount,
        onConfirm: (utr) {
          Navigator.of(modalCtx).pop();
          setState(() => _localStatus = 'paid');
          AppToast.show(context, 'Payout marked Paid');
        },
        onBack: () => Navigator.of(modalCtx).pop(),
      ),
    );
  }

  Future<void> _showOverrideModal(BuildContext context, int calcNet) async {
    await showAppModal<void>(
      context: context,
      builder: (modalCtx) => _OverrideNetModal(
        calcNet: calcNet,
        onConfirm: (value) {
          Navigator.of(modalCtx).pop();
          setState(() => _overrideNet = value);
          AppToast.show(context, 'Net overridden');
        },
        onBack: () => Navigator.of(modalCtx).pop(),
      ),
    );
  }
}

// ─── Calc expandable line ─────────────────────────────────────────────────────

class _CalcLine extends StatelessWidget {
  const _CalcLine({
    required this.label,
    required this.amount,
    required this.sign,
    required this.isOpen,
    required this.onToggle,
    this.child,
  });

  final String label;
  final int amount;
  final String sign; // '' | '-' | '+'
  final bool isOpen;
  final VoidCallback onToggle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final hasChild = child != null;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: hasChild ? onToggle : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 13.h),
              child: Row(
                children: [
                  if (hasChild)
                    AnimatedRotation(
                      turns: isOpen ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        AppIcons.chevRight,
                        size: 16.sp,
                        color: AppColors.fgTertiary,
                      ),
                    )
                  else
                    SizedBox(width: 16.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      label,
                      style: AppText.figtree(
                        size: 13.5,
                        weight: FontWeight.w500,
                        color: AppColors.fgSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${sign == '-' ? '− ' : sign == '+' ? '+ ' : ''}${Formatters.money(amount.abs())}',
                    style: AppText.figtree(
                      size: 14,
                      weight: FontWeight.w700,
                      color:
                          sign == '-' ? AppColors.redFg : AppColors.fgPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen && child != null)
            Padding(
              padding: EdgeInsets.only(left: 24.w, bottom: 14.h),
              child: child,
            ),
        ],
      ),
    );
  }
}

// ─── Calc detail sub-widgets ──────────────────────────────────────────────────

class _GrossDetail extends StatelessWidget {
  const _GrossDetail({
    required this.bookings,
    required this.editable,
    this.onToggleExclude,
  });

  final List<PayoutBooking> bookings;
  final bool editable;
  final void Function(int index)? onToggleExclude;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4.h),
        for (var i = 0; i < bookings.length; i++) ...[
          Opacity(
            opacity: bookings[i].excluded ? 0.45 : 1.0,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            bookings[i].customer,
                            style: AppText.figtree(
                              size: 12.5,
                              weight: FontWeight.w600,
                            ).copyWith(
                              decoration: bookings[i].excluded
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '· ${bookings[i].date}',
                            style: AppText.figtree(
                              size: 11,
                              weight: FontWeight.w500,
                              color: AppColors.fgTertiary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        bookings[i].id.replaceAll('DD-KL-2026', '#…'),
                        style: AppText.figtree(
                          size: 11,
                          weight: FontWeight.w500,
                          color: AppColors.fgTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.money(bookings[i].gross),
                  style: AppText.figtree(
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 8.w),
                if (editable)
                  GestureDetector(
                    onTap: () => onToggleExclude?.call(i),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(7.r),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Text(
                        bookings[i].excluded ? 'Add' : 'Exclude',
                        style: AppText.figtree(
                          size: 10.5,
                          weight: FontWeight.w600,
                          color: bookings[i].excluded
                              ? AppColors.blueFg
                              : AppColors.fgTertiary,
                          letterSpacing: 0.03,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (i < bookings.length - 1) SizedBox(height: 8.h),
        ],
      ],
    );
  }
}

class _CommDetail extends StatelessWidget {
  const _CommDetail({required this.bookings});

  final List<PayoutBooking> bookings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4.h),
        for (final b in bookings)
          Padding(
            padding: EdgeInsets.only(bottom: 7.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  b.customer,
                  style: AppText.figtree(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.fgSecondary,
                  ),
                ),
                Text(
                  '− ${Formatters.money(b.commission)}',
                  style: AppText.figtree(
                    size: 12,
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

class _RefundsDetail extends StatelessWidget {
  const _RefundsDetail({required this.bookings});

  final List<PayoutBooking> bookings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4.h),
        for (final b in bookings)
          Padding(
            padding: EdgeInsets.only(bottom: 7.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  b.customer,
                  style: AppText.figtree(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.fgSecondary,
                  ),
                ),
                Text(
                  '− ${Formatters.money(b.refund)}',
                  style: AppText.figtree(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.redFg,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AdjDetail extends StatelessWidget {
  const _AdjDetail({
    required this.adjustments,
    required this.editable,
    this.onAdd,
  });

  final List<PayoutAdjustment> adjustments;
  final bool editable;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4.h),
        for (final a in adjustments)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${a.reason} · ${a.at}',
                    style: AppText.figtree(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.fgSecondary,
                    ),
                  ),
                ),
                Text(
                  '${a.amount < 0 ? '− ' : '+ '}${Formatters.money(a.amount.abs())}',
                  style: AppText.figtree(
                    size: 12,
                    weight: FontWeight.w500,
                    color: a.amount < 0 ? AppColors.redFg : AppColors.greenFg,
                  ),
                ),
              ],
            ),
          ),
        if (editable && onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.plus, size: 15.sp, color: AppColors.fgSecondary),
                SizedBox(width: 6.w),
                Text(
                  'Add adjustment',
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w600,
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

// ─── Modals ───────────────────────────────────────────────────────────────────

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
        Text('Mark payout paid',
            style: AppText.figtree(size: 19, weight: FontWeight.w700)),
        SizedBox(height: 6.h),
        Text(
          'Transfer ${Formatters.money(widget.amount)} externally, then log the reference.',
          style: AppText.figtree(
            size: 13.5,
            weight: FontWeight.w400,
            color: AppColors.fgSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: 18.h),
        _InputField(
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
                  color: _proof ? AppColors.greenFg : AppColors.borderDefault),
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
                  _proof
                      ? 'Screenshot attached'
                      : 'Attach screenshot (optional)',
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

class _OverrideNetModal extends StatefulWidget {
  const _OverrideNetModal({
    required this.calcNet,
    required this.onConfirm,
    required this.onBack,
  });

  final int calcNet;
  final void Function(int value) onConfirm;
  final VoidCallback onBack;

  @override
  State<_OverrideNetModal> createState() => _OverrideNetModalState();
}

class _OverrideNetModalState extends State<_OverrideNetModal> {
  late final TextEditingController _val;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _val = TextEditingController(text: widget.calcNet.toString());
  }

  @override
  void dispose() {
    _val.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _val.text.trim().isNotEmpty && _note.text.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Override net payable',
            style: AppText.figtree(size: 19, weight: FontWeight.w700)),
        SizedBox(height: 6.h),
        Text(
          'Calculated net is ${Formatters.money(widget.calcNet)}. A note is required for any override.',
          style: AppText.figtree(
            size: 13.5,
            weight: FontWeight.w400,
            color: AppColors.fgSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: 18.h),
        _InputField(
          label: 'New net amount',
          controller: _val,
          placeholder: '0',
          prefix: '₹',
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 14.h),
        _TextArea(
          label: 'Reason (required)',
          controller: _note,
          placeholder: 'Why is this overridden?',
          onChanged: (_) => setState(() {}),
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
                label: 'Save Override',
                full: true,
                disabled: !canSave,
                onPressed: canSave
                    ? () => widget
                        .onConfirm(int.tryParse(_val.text) ?? widget.calcNet)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Shared input widgets ─────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.prefix,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final String? prefix;
  final TextInputType? keyboardType;
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
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: placeholder,
            prefixText: prefix,
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

class _TextArea extends StatelessWidget {
  const _TextArea({
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
          maxLines: 4,
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
        TopBar(title: 'Payout', onBack: () => Navigator.of(context).pop()),
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
        TopBar(title: 'Payout', onBack: () => Navigator.of(context).pop()),
        Expanded(
          child: Center(
            child: Text(
              'Payout not found.',
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

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import '../components/refund_filter_sheet.dart';

/// Lightweight booking context used to pre-fill the New Refund form when it is
/// opened from a booking's "Refund" action (mirrors `prefill.newRefundFor` in
/// `screen_refunds.jsx`). Kept feature-local so the form stays decoupled from
/// the bookings entity; the orchestrator builds one from a Booking when wiring.
class RefundPrefill {
  const RefundPrefill({
    required this.bookingId,
    required this.customerName,
    required this.total,
    required this.status,
  });

  final String bookingId;
  final String customerName;
  final int total;

  /// Booking status string (e.g. `new`, `assigned`, `washing`, `completed`).
  final String status;
}

/// Suggested refund tier + amount for a booking, by its stage.
/// Mirrors `tierFor` in `screen_refunds.jsx`: post-pickup → 0%, assigned/going
/// → 70%, otherwise → 100%.
({String tier, int amount}) _suggestedTier(RefundPrefill? b) {
  if (b == null) return (tier: '100%', amount: 0);
  const post = [
    'picked',
    'atshop',
    'washing',
    'done',
    'returning',
    'completed'
  ];
  const assigned = ['assigned', 'going'];
  if (post.contains(b.status)) return (tier: '0%', amount: 0);
  if (assigned.contains(b.status)) {
    return (tier: '70%', amount: (b.total * 0.7).round());
  }
  return (tier: '100%', amount: b.total);
}

/// Form to create a new refund request. Standalone, or pre-filled from a
/// booking's Refund button when [booking] is supplied.
class NewRefundScreen extends StatefulWidget {
  const NewRefundScreen({this.booking, super.key});

  /// When non-null, the form is pre-filled from this booking.
  final RefundPrefill? booking;

  @override
  State<NewRefundScreen> createState() => _NewRefundScreenState();
}

class _NewRefundScreenState extends State<NewRefundScreen> {
  late final TextEditingController _refController;
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  late String _tier;
  String _reason = kRefundReasons.first;

  @override
  void initState() {
    super.initState();
    final init = _suggestedTier(widget.booking);
    _refController =
        TextEditingController(text: widget.booking?.bookingId ?? '');
    _amountController =
        TextEditingController(text: init.amount == 0 ? '' : '${init.amount}');
    _tier = init.tier;
  }

  @override
  void dispose() {
    _refController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _valid =>
      _refController.text.trim().isNotEmpty &&
      _amountController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: 'New Refund',
              subtitle: booking != null ? 'From booking' : 'Standalone',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  if (booking != null) ...[
                    _PrefillBanner(
                      customerName: booking.customerName,
                      tier: _suggestedTier(booking).tier,
                    ),
                    SizedBox(height: 14.h),
                  ],
                  // Booking ref card
                  _FormCard(
                    label: 'BOOKING',
                    children: [
                      _LabeledInput(
                        label: 'Booking reference',
                        controller: _refController,
                        placeholder: 'DD-KL-…',
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  // Refund details card
                  _FormCard(
                    label: 'REFUND',
                    children: [
                      // Tier selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tier',
                            style: AppText.figtree(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: AppColors.fgSecondary,
                            ),
                          ),
                          SizedBox(height: 9.h),
                          Row(
                            children: ['100%', '70%', '0%', 'Override']
                                .map((t) => Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _tier = t),
                                        child: Container(
                                          margin: EdgeInsets.only(
                                              right: t != 'Override' ? 8.w : 0),
                                          height: 42.h,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _tier == t
                                                ? AppColors.fgPrimary
                                                : AppColors.bgCard,
                                            borderRadius:
                                                BorderRadius.circular(10.r),
                                            border: Border.all(
                                              color: _tier == t
                                                  ? AppColors.fgPrimary
                                                  : AppColors.borderDefault,
                                            ),
                                          ),
                                          child: Text(
                                            t,
                                            style: AppText.figtree(
                                              size: 12.5,
                                              weight: FontWeight.w700,
                                              color: _tier == t
                                                  ? Colors.white
                                                  : AppColors.fgSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      _LabeledInput(
                        label: 'Amount',
                        controller: _amountController,
                        placeholder: '0',
                        prefix: '₹',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      SizedBox(height: 14.h),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reason',
                            style: AppText.figtree(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: AppColors.fgSecondary,
                            ),
                          ),
                          SizedBox(height: 9.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: kRefundReasons.map((r) {
                              final sel = _reason == r;
                              return GestureDetector(
                                onTap: () => setState(() => _reason = r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.brandYellow
                                        : AppColors.bgCard,
                                    borderRadius: BorderRadius.circular(999.r),
                                    border: Border.all(
                                      color: sel
                                          ? AppColors.brandYellowDeep
                                          : AppColors.borderDefault,
                                    ),
                                  ),
                                  child: Text(
                                    r,
                                    style: AppText.figtree(
                                      size: 12.5,
                                      weight: sel
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      _TextAreaInput(
                        label: 'Notes',
                        controller: _notesController,
                        placeholder: _tier == 'Override'
                            ? 'Override reason (required)'
                            : 'Optional notes…',
                        optional: _tier != 'Override',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border: Border(top: BorderSide(color: AppColors.borderSoft)),
              ),
              child: SafeArea(
                top: false,
                child: AppButton(
                  label: 'Create Refund',
                  full: true,
                  disabled: !_valid,
                  onPressed: _valid
                      ? () {
                          AppToast.show(context, 'Refund created · Requested');
                          Navigator.of(context).pop();
                        }
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blue "pre-filled from booking" banner shown when the form is opened from a
/// booking's Refund action.
class _PrefillBanner extends StatelessWidget {
  const _PrefillBanner({required this.customerName, required this.tier});

  final String customerName;
  final String tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.checkCircle, size: 18.sp, color: AppColors.blueFg),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppText.figtree(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: AppColors.blueFg,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                      text: "Pre-filled from $customerName's booking. "
                          'Suggested tier '),
                  TextSpan(
                    text: tier,
                    style: AppText.figtree(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: AppColors.blueFg,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 14.h),
          ...children,
        ],
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
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

class _TextAreaInput extends StatelessWidget {
  const _TextAreaInput({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.optional = true,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w600,
                color: AppColors.fgSecondary,
              ),
            ),
            if (optional) ...[
              SizedBox(width: 6.w),
              Text(
                '(optional)',
                style: AppText.figtree(
                  size: 12,
                  weight: FontWeight.w400,
                  color: AppColors.fgMuted,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          maxLines: 4,
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

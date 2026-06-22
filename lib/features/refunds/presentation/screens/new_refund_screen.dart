import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/constants/app_options.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import '../../../bookings/application/providers/bookings_providers.dart';

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
class NewRefundScreen extends ConsumerStatefulWidget {
  const NewRefundScreen({this.booking, super.key});

  /// When non-null, the form is pre-filled from this booking.
  final RefundPrefill? booking;

  @override
  ConsumerState<NewRefundScreen> createState() => _NewRefundScreenState();
}

class _NewRefundScreenState extends ConsumerState<NewRefundScreen> {
  late final TextEditingController _refController;
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  late String _tier;
  String _reason = kRefundReasons.first;
  bool _isLoading = false;
  int? _amountPaid;
  int? _totalRefunded;
  int? _remaining;

  @override
  void initState() {
    super.initState();
    final init = _suggestedTier(widget.booking);
    _refController =
        TextEditingController(text: widget.booking?.bookingId ?? '');
    _amountController =
        TextEditingController(text: init.amount == 0 ? '' : '${init.amount}');
    _tier = init.tier;

    // If booking is provided, fetch refund summary
    if (widget.booking != null) {
      _loadRefundSummary();
    }
  }

  @override
  void dispose() {
    _refController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Load refund summary data from API
  Future<void> _loadRefundSummary() async {
    try {
      final bookingId = int.tryParse(widget.booking!.bookingId);
      if (bookingId == null) {
        debugPrint('Failed to parse booking ID: ${widget.booking!.bookingId}');
        return;
      }

      debugPrint('Loading refund summary for booking ID: $bookingId');
      final refundSummary = await ref.read(refundSummaryProvider(bookingId).future);

      debugPrint(
        'Refund summary loaded: amountPaid=${refundSummary.amountPaid}, '
        'totalRefunded=${refundSummary.totalRefunded}, '
        'remaining=${refundSummary.remaining}',
      );

      setState(() {
        _amountPaid = refundSummary.amountPaid;
        _totalRefunded = refundSummary.totalRefunded;
        _remaining = refundSummary.remaining;

        debugPrint(
          'State updated: _amountPaid=$_amountPaid, '
          '_totalRefunded=$_totalRefunded, '
          '_remaining=$_remaining',
        );

        // Pre-fill amount based on tier and remaining balance
        _updateAmountForTier(_tier);
      });
    } catch (e) {
      debugPrint('Error loading refund summary: $e');
    }
  }

  /// Update amount field based on selected tier
  void _updateAmountForTier(String tier) {
    debugPrint('Updating amount for tier: $tier, _amountPaid=$_amountPaid, _remaining=$_remaining');

    if (tier == '100%' && _amountPaid != null) {
      final tierAmount = (_amountPaid! * 100 / 100).round();
      final cappedAmount = (_remaining != null && _remaining! < tierAmount)
          ? _remaining!
          : tierAmount;
      _amountController.text = cappedAmount.toString();
      debugPrint('100% tier: tierAmount=$tierAmount, cappedAmount=$cappedAmount');
    } else if (tier == '70%' && _amountPaid != null) {
      final tierAmount = (_amountPaid! * 70 / 100).round();
      final cappedAmount = (_remaining != null && _remaining! < tierAmount)
          ? _remaining!
          : tierAmount;
      _amountController.text = cappedAmount.toString();
      debugPrint('70% tier: tierAmount=$tierAmount, cappedAmount=$cappedAmount');
    } else if (tier == '0%') {
      _amountController.text = '';
      debugPrint('0% tier: amount cleared');
    } else if (tier == 'Override') {
      // Clear for user to enter custom amount
      _amountController.text = '';
      debugPrint('Override tier: amount cleared for custom entry');
    } else {
      debugPrint('Unknown tier: $tier');
    }
  }

  bool get _valid =>
      _refController.text.trim().isNotEmpty &&
      _amountController.text.trim().isNotEmpty &&
      (_remaining == null || _remaining! > 0); // Allow if null (loading) or if remaining > 0

  /// Parse refund reason to API key format
  String _parseReasonToKey(String displayReason) {
    return switch (displayReason) {
      'Cancellation by customer' => 'cancellation_by_customer',
      'Founder cancellation' => 'founder_cancellation',
      'Service quality issue' => 'service_quality_issue',
      'Damage during wash' => 'damage_during_wash',
      'Duplicate charge' => 'duplicate_charge',
      'Other' => 'other',
      _ => 'other',
    };
  }

  /// Create refund and handle response
  Future<void> _createRefund() async {
    if (!_valid) return;

    setState(() => _isLoading = true);

    try {
      final bookingId = int.parse(_refController.text.trim());
      final amount = int.parse(_amountController.text.trim());

      // Determine percent or amount based on tier
      int? percent;
      int? amountToSend;

      if (_tier == '100%') {
        percent = 100;
      } else if (_tier == '70%') {
        percent = 70;
      } else if (_tier == '0%') {
        percent = 0;
      } else {
        // Override: send actual amount
        amountToSend = amount;
      }

      final reason = _parseReasonToKey(_reason);
      final comment = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      // Call API through repository
      await ref
          .read(bookingsRepositoryProvider)
          .createRefund(
            bookingId,
            percent: percent,
            amount: amountToSend,
            reason: reason,
            comment: comment,
          );

      // Only invalidate the detail provider for the specific booking being refunded
      // This will refresh the detail screen when user pops back to it
      // List will refetch naturally when user navigates back to it
      ref.invalidate(bookingByIdProvider(bookingId.toString()));

      if (mounted) {
        AppToast.show(context, 'Refund created successfully');
        Navigator.of(context).pop();
      }
    } on FormatException {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.show(context, 'Invalid booking ID or amount');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.show(context, 'Error: ${e.toString()}');
      }
    }
  }

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
                  // Refund summary (if data loaded from API)
                  if (_amountPaid != null) ...[
                    _FormCard(
                      label: 'SUMMARY',
                      children: [
                        _SummaryRow(
                          label: 'Amount Paid',
                          amount: _amountPaid ?? 0,
                        ),
                        SizedBox(height: 10.h),
                        _SummaryRow(
                          label: 'Already Refunded',
                          amount: _totalRefunded ?? 0,
                        ),
                        SizedBox(height: 10.h),
                        _SummaryRow(
                          label: 'Remaining',
                          amount: _remaining ?? 0,
                          highlight: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                  ],
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
                                        onTap: (_remaining == null || _remaining! > 0)
                                            ? () {
                                                debugPrint('Tier selected: $t');
                                                setState(() {
                                                  _tier = t;
                                                  _updateAmountForTier(t);
                                                });
                                              }
                                            : null,
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
                  SizedBox(height: 14.h),
                  // Refund history from API
                  if (booking != null) ...[
                    _RefundHistoryWidget(
                      bookingId: int.tryParse(booking.bookingId) ?? 0,
                    ),
                  ],
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
                  disabled: !_valid || _isLoading,
                  onPressed: (_valid && !_isLoading) ? _createRefund : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Summary row showing amount with label
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    this.highlight = false,
  });

  final String label;
  final int amount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w500,
            color: AppColors.fgSecondary,
          ),
        ),
        Text(
          '₹$amount',
          style: AppText.figtree(
            size: 13.5,
            weight: highlight ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? AppColors.fgPrimary : AppColors.fgPrimary,
          ),
        ),
      ],
    );
  }
}

/// Refund history display widget
class _RefundHistoryWidget extends ConsumerWidget {
  const _RefundHistoryWidget({required this.bookingId});

  final int bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(refundSummaryProvider(bookingId)).when(
      data: (summary) {
        if (summary.refunds.isEmpty) {
          return _FormCard(
            label: 'REFUND HISTORY',
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Text(
                    'No refunds yet',
                    style: AppText.figtree(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: AppColors.fgMuted,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return _FormCard(
          label: 'REFUND HISTORY',
          children: [
            ...summary.refunds.map((refund) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.bgPage,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${refund.amount}',
                            style: AppText.figtree(
                              size: 13.5,
                              weight: FontWeight.w700,
                              color: AppColors.fgPrimary,
                            ),
                          ),
                          Text(
                            _formatDate(refund.createdAt),
                            style: AppText.figtree(
                              size: 11,
                              weight: FontWeight.w500,
                              color: AppColors.fgMuted,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        refund.reason,
                        style: AppText.figtree(
                          size: 12,
                          weight: FontWeight.w500,
                          color: AppColors.fgSecondary,
                        ),
                      ),
                      if (refund.comment != null && refund.comment!.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          refund.comment!,
                          style: AppText.figtree(
                            size: 11,
                            weight: FontWeight.w400,
                            color: AppColors.fgMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => _FormCard(
        label: 'REFUND HISTORY',
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: SizedBox(
                height: 20.h,
                width: 20.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => _FormCard(
        label: 'REFUND HISTORY',
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                'Error loading refund history',
                style: AppText.figtree(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: AppColors.fgMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_monthName(date.month)} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
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

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

/// Form to create a new refund request. Standalone (no booking pre-fill in this context).
class NewRefundScreen extends StatefulWidget {
  const NewRefundScreen({super.key});

  @override
  State<NewRefundScreen> createState() => _NewRefundScreenState();
}

class _NewRefundScreenState extends State<NewRefundScreen> {
  final _refController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _tier = '100%';
  String _reason = kRefundReasons.first;

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
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: 'New Refund',
              subtitle: 'Standalone',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
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
                                        onTap: () =>
                                            setState(() => _tier = t),
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
                                    borderRadius:
                                        BorderRadius.circular(999.r),
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

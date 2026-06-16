import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/config/constants.dart';
import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_bottom_sheet.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/avatar.dart';
import 'package:new_flutter_project/features/customers/application/providers/customers_providers.dart';
import 'package:new_flutter_project/features/customers/domain/entities/customer.dart';

/// A selected customer — either an existing one (id not null) or a new entry
/// captured via the quick-add flow (id is null, isNew is true).
class CustomerPick {
  const CustomerPick({
    required this.name,
    required this.phone,
    this.id,
    this.isNew = false,
  });

  final String name;
  final String phone;
  final String? id;
  final bool isNew;
}

/// A customer picker widget: shows the selected value or a "Select customer"
/// button that opens a bottom sheet for searching existing customers or
/// quick-adding a new one (demo OTP: 1234).
///
/// Reused in [NewBookingScreen] and any screen that needs to pick a customer.
class CustomerPicker extends ConsumerWidget {
  const CustomerPicker({
    required this.onChanged,
    this.value,
    super.key,
  });

  final ValueChanged<CustomerPick?> onChanged;
  final CustomerPick? value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (value == null) {
      return Column(
        children: [
          // Search existing
          GestureDetector(
            onTap: () => _openPickerSheet(context, ref),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(11.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  Icon(
                    AppIcons.search,
                    size: 18.sp,
                    color: AppColors.fgTertiary,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Search existing customer…',
                    style: AppText.figtree(
                      size: 13.5,
                      weight: FontWeight.w500,
                      color: AppColors.fgMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // Quick-add new
          GestureDetector(
            onTap: () => _openQuickAddSheet(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(11.r),
                border: Border.all(
                  color: AppColors.borderDefault,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.plus,
                    size: 16.sp,
                    color: AppColors.fgSecondary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Add new customer',
                    style: AppText.figtree(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.fgSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Show selected customer
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.brandYellow,
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: AppColors.brandYellowDeep),
      ),
      child: Row(
        children: [
          Avatar(name: value!.name, size: 36),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      value!.name,
                      style: AppText.figtree(
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                    if (value!.isNew) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amberBg,
                          borderRadius: BorderRadius.circular(99.r),
                        ),
                        child: Text(
                          'New',
                          style: AppText.figtree(
                            size: 10,
                            weight: FontWeight.w700,
                            color: AppColors.amberFg,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  value!.phone,
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: const Color(0xA6000000),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(null),
            child: Icon(
              AppIcons.close,
              size: 18.sp,
              color: const Color(0xA6000000),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPickerSheet(BuildContext context, WidgetRef ref) {
    return showAppBottomSheet<void>(
      context: context,
      title: 'Select customer',
      builder: (_) => _CustomerPickerBody(
        onPick: (pick) {
          onChanged(pick);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _openQuickAddSheet(BuildContext context) {
    return showAppBottomSheet<void>(
      context: context,
      title: 'Add new customer',
      builder: (_) => _QuickAddBody(
        onAdd: (pick) {
          onChanged(pick);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ── Search existing ──────────────────────────────────────────────────────────

class _CustomerPickerBody extends ConsumerStatefulWidget {
  const _CustomerPickerBody({required this.onPick});

  final ValueChanged<CustomerPick> onPick;

  @override
  ConsumerState<_CustomerPickerBody> createState() =>
      _CustomerPickerBodyState();
}

class _CustomerPickerBodyState extends ConsumerState<_CustomerPickerBody> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: AppColors.bgPage,
            borderRadius: BorderRadius.circular(11.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              Icon(
                AppIcons.search,
                size: 17.sp,
                color: AppColors.fgTertiary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Name or phone',
                    hintStyle: AppText.figtree(
                      size: 13.5,
                      weight: FontWeight.w400,
                      color: AppColors.fgMuted,
                    ),
                  ),
                  style: AppText.figtree(size: 13.5, weight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        customersAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (_, __) => const SizedBox.shrink(),
          data: (customers) {
            final q = _query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? customers
                : customers.where((c) {
                    return c.name.toLowerCase().contains(q) ||
                        c.phone.contains(q);
                  }).toList();

            if (filtered.isEmpty) {
              return Center(
                child: Text(
                  'No customers match.',
                  style: AppText.figtree(
                    size: 13,
                    weight: FontWeight.w500,
                    color: AppColors.fgMuted,
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final c in filtered)
                  _CustomerRow(
                    customer: c,
                    onTap: () => widget.onPick(
                      CustomerPick(
                        name: c.name,
                        phone: c.phone,
                        id: c.id,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(13.r),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(11.r),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            Avatar(name: customer.name, size: 38),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: AppText.figtree(
                      size: 14,
                      weight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    customer.phone,
                    style: AppText.figtree(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: AppColors.fgTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.chevRight,
              size: 18.sp,
              color: AppColors.fgMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick-add new customer ────────────────────────────────────────────────────

class _QuickAddBody extends StatefulWidget {
  const _QuickAddBody({required this.onAdd});

  final ValueChanged<CustomerPick> onAdd;

  @override
  State<_QuickAddBody> createState() => _QuickAddBodyState();
}

class _QuickAddBodyState extends State<_QuickAddBody> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _otpSent = false;
  bool _otpVerified = false;
  final _otpCtrl = TextEditingController();
  String _otpError = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(
          label: 'Full name',
          controller: _nameCtrl,
          placeholder: 'e.g. Rajan Pillai',
          enabled: !_otpVerified,
        ),
        SizedBox(height: 12.h),
        _Field(
          label: 'Phone number',
          controller: _phoneCtrl,
          placeholder: '+91 98000 00000',
          keyboardType: TextInputType.phone,
          enabled: !_otpSent,
        ),
        SizedBox(height: 16.h),

        if (!_otpSent) ...[
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Send OTP',
                  full: true,
                  size: AppButtonSize.sm,
                  onPressed: () {
                    if (_nameCtrl.text.trim().isEmpty ||
                        _phoneCtrl.text.trim().isEmpty) {
                      return;
                    }
                    setState(() => _otpSent = true);
                    AppToast.show(
                      context,
                      'OTP sent to ${_phoneCtrl.text.trim()}',
                    );
                  },
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: AppButton(
                  label: 'Add without OTP',
                  kind: AppButtonKind.secondary,
                  full: true,
                  size: AppButtonSize.sm,
                  onPressed: () {
                    if (_nameCtrl.text.trim().isEmpty) return;
                    widget.onAdd(
                      CustomerPick(
                        name: _nameCtrl.text.trim(),
                        phone: _phoneCtrl.text.trim().isEmpty
                            ? '—'
                            : _phoneCtrl.text.trim(),
                        isNew: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ] else if (!_otpVerified) ...[
          _Field(
            label: 'Enter OTP (demo: ${AppConstants.demoOtp})',
            controller: _otpCtrl,
            placeholder: '• • • •',
            keyboardType: TextInputType.number,
            error: _otpError,
          ),
          SizedBox(height: 12.h),
          AppButton(
            label: 'Verify OTP',
            full: true,
            size: AppButtonSize.sm,
            onPressed: () {
              if (_otpCtrl.text.trim() == AppConstants.demoOtp) {
                setState(() {
                  _otpVerified = true;
                  _otpError = '';
                });
              } else {
                setState(() => _otpError = 'Incorrect OTP — try 1234');
              }
            },
          ),
        ] else ...[
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: AppColors.greenBg,
              borderRadius: BorderRadius.circular(11.r),
              border: Border.all(color: AppColors.greenFg),
            ),
            child: Row(
              children: [
                Icon(
                  AppIcons.checkCircle,
                  size: 18.sp,
                  color: AppColors.greenFg,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Phone verified',
                    style: AppText.figtree(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: AppColors.greenFg,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          AppButton(
            label: 'Add Customer',
            full: true,
            onPressed: () => widget.onAdd(
              CustomerPick(
                name: _nameCtrl.text.trim(),
                phone: _phoneCtrl.text.trim(),
                isNew: true,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.enabled = true,
    this.error = '',
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final bool enabled;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.figtree(
            size: 12,
            weight: FontWeight.w600,
            color: AppColors.fgSecondary,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppText.figtree(
              size: 14,
              weight: FontWeight.w400,
              color: AppColors.fgMuted,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.r),
              borderSide:
                  const BorderSide(color: AppColors.brandYellowDeep),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.r),
              borderSide: const BorderSide(color: AppColors.borderSoft),
            ),
            errorText: error.isEmpty ? null : error,
          ),
          style: AppText.figtree(size: 14, weight: FontWeight.w500),
        ),
      ],
    );
  }
}

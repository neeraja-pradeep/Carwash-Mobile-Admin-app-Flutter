import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/config/constants.dart';
import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/utils/phone_number.dart';
import 'package:new_flutter_project/core/widgets/app_bottom_sheet.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/avatar.dart';
import 'package:new_flutter_project/core/widgets/search_field.dart';
import 'package:new_flutter_project/features/customers/application/providers/customers_providers.dart';
import 'package:new_flutter_project/features/customers/domain/entities/customer.dart';

/// A selected customer — either an existing one (id not null) or a new entry
/// captured via the add-new flow (id is null, [isNew] true). [verified] is true
/// when the new customer's number passed the demo OTP (tag shows "New · OTP").
class CustomerPick {
  const CustomerPick({
    required this.name,
    required this.phone,
    this.id,
    this.isNew = false,
    this.verified = false,
  });

  final String name;
  final String phone;
  final String? id;
  final bool isNew;
  final bool verified;
}

/// Shared customer picker (mirrors `CustomerPicker` in `ui.jsx`).
///
/// Unselected → a single dashed "Select or add customer" trigger. Tapping opens
/// one "Customer" bottom sheet with an internal **Search existing | Add new**
/// segmented toggle: search filters existing customers (capped list, blocked
/// badge), add-new captures name + phone then either verifies via demo OTP
/// (1234) or adds without OTP (override). Selected → a yellow card with a
/// "Change" action and a "New" / "New · OTP" tag for newly-added customers.
///
/// Reused by [NewBookingScreen]; the same pattern should back the driver-hire
/// and inspection create flows.
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
      return GestureDetector(
        onTap: () => _openSheet(context),
        child: Container(
          width: double.infinity,
          height: 52.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.borderDefault,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Icon(AppIcons.users, size: 19.sp, color: AppColors.fgTertiary),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Select or add customer',
                  style: AppText.figtree(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.fgSecondary,
                  ),
                ),
              ),
              Icon(AppIcons.chevRight,
                  size: 18.sp, color: AppColors.fgTertiary),
            ],
          ),
        ),
      );
    }

    // Selected customer card.
    return Container(
      padding: EdgeInsets.all(13.r),
      decoration: BoxDecoration(
        color: AppColors.brandYellow,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.brandYellowDeep),
      ),
      child: Row(
        children: [
          Avatar(name: value!.name, size: 38),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value!.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.figtree(
                          size: 14.5,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (value!.isNew) ...[
                      SizedBox(width: 7.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1F000000),
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        child: Text(
                          value!.verified ? 'NEW · OTP' : 'NEW',
                          style: AppText.figtree(
                            size: 9,
                            weight: FontWeight.w700,
                            letterSpacing: 0.4,
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
                    color: const Color(0x99000000),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(null),
            child: Container(
              height: 34.h,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 13.w),
              decoration: BoxDecoration(
                color: const Color(0x66FFFFFF),
                borderRadius: BorderRadius.circular(9.r),
                border: Border.all(color: const Color(0x33000000)),
              ),
              child: Text(
                'Change',
                style: AppText.figtree(size: 12.5, weight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) {
    return showAppBottomSheet<void>(
      context: context,
      title: 'Customer',
      maxHeightFactor: 0.86,
      builder: (_) => _CustomerSheetBody(
        onPick: (pick) {
          onChanged(pick);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ── Sheet body (segmented: Search existing | Add new) ─────────────────────────

class _CustomerSheetBody extends ConsumerStatefulWidget {
  const _CustomerSheetBody({required this.onPick});

  final ValueChanged<CustomerPick> onPick;

  @override
  ConsumerState<_CustomerSheetBody> createState() => _CustomerSheetBodyState();
}

class _CustomerSheetBodyState extends ConsumerState<_CustomerSheetBody> {
  // 'search' | 'new'
  String _mode = 'search';

  // Search tab
  String _query = '';

  // Add-new tab
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  bool get _createOk =>
      _nameCtrl.text.trim().isNotEmpty && PhoneNumber.isValid(_phoneCtrl.text);

  /// The number as the rest of the app should see it: `+919876543210`. The
  /// field itself only ever holds the ten national digits.
  String get _phoneE164 => PhoneNumber.e164(_phoneCtrl.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented toggle inside the sheet.
        Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: AppColors.bgPage,
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Row(
            children: [
              for (final seg in const [
                ('search', 'Search existing'),
                ('new', 'Add new'),
              ])
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = seg.$1),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 38.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _mode == seg.$1
                            ? AppColors.bgCard
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: _mode == seg.$1
                            ? [
                                BoxShadow(
                                  color: const Color(0x1A000000),
                                  blurRadius: 3.r,
                                  offset: Offset(0, 1.h),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        seg.$2,
                        style: AppText.figtree(
                          size: 13,
                          weight: _mode == seg.$1
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: _mode == seg.$1
                              ? AppColors.fgPrimary
                              : AppColors.fgTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        if (_mode == 'search') _buildSearch() else _buildAddNew(),
      ],
    );
  }

  // ── Search existing ──
  Widget _buildSearch() {
    final customersAsync = ref.watch(customersProvider);

    return customersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (_, __) => const SizedBox.shrink(),
      data: (customers) {
        final q = _query.trim().toLowerCase();
        final all = customers;
        final list = (q.isEmpty
                ? all
                : all
                    .where((c) =>
                        c.name.toLowerCase().contains(q) || c.phone.contains(q))
                    .toList())
            .take(8)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchField(
              value: _query,
              hintText: 'Search name or phone',
              onChanged: (v) => setState(() => _query = v),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(2.w, 12.h, 2.w, 8.h),
              child: Text(
                q.isNotEmpty
                    ? '${list.length} match${list.length == 1 ? "" : "es"}'
                    : '${all.length} customers · type to narrow',
                style: AppText.figtree(
                  size: 11.5,
                  weight: FontWeight.w500,
                  color: AppColors.fgTertiary,
                ),
              ),
            ),
            if (list.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Center(
                  child: Text(
                    'No match. Switch to Add new.',
                    style: AppText.figtree(
                      size: 13,
                      weight: FontWeight.w500,
                      color: AppColors.fgMuted,
                    ),
                  ),
                ),
              )
            else
              for (final c in list)
                _CustomerRow(
                  customer: c,
                  onTap: () => widget.onPick(
                    CustomerPick(name: c.name, phone: c.phone, id: c.id),
                  ),
                ),
          ],
        );
      },
    );
  }

  // ── Add new ──
  Widget _buildAddNew() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(
          label: 'Full name',
          controller: _nameCtrl,
          placeholder: 'Customer name',
          enabled: true,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 14.h),
        // +91 is fixed and shown as a static prefix — the field holds the ten
        // national digits, and the picked customer carries the E.164 form.
        _Field(
          label: 'Mobile number',
          controller: _phoneCtrl,
          placeholder: '98765 43210',
          prefixText: PhoneNumber.dialCode,
          keyboardType: TextInputType.phone,
          inputFormatters: const [PhoneNumberInputFormatter()],
          errorText: PhoneNumber.errorFor(_phoneCtrl.text),
          enabled: !_otpSent,
          onChanged: (_) => setState(() => _otpSent = false),
        ),
        SizedBox(height: 14.h),

        if (!_otpSent)
          AppButton(
            label: 'Send OTP to verify',
            full: true,
            disabled: !_createOk,
            onPressed: _createOk ? () => setState(() => _otpSent = true) : null,
          )
        else ...[
          _OtpField(
            controller: _otpCtrl,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 14.h),
          AppButton(
            label: 'Verify & add customer',
            full: true,
            disabled: _otpCtrl.text != AppConstants.demoOtp,
            onPressed: _otpCtrl.text == AppConstants.demoOtp
                ? () => widget.onPick(
                      CustomerPick(
                        name: _nameCtrl.text.trim(),
                        phone: _phoneE164,
                        isNew: true,
                        verified: true,
                      ),
                    )
                : null,
          ),
        ],

        SizedBox(height: 14.h),
        // Override — always available once name + phone are valid.
        Opacity(
          opacity: _createOk ? 1 : 0.5,
          child: GestureDetector(
            onTap: _createOk
                ? () => widget.onPick(
                      CustomerPick(
                        name: _nameCtrl.text.trim(),
                        phone: _phoneE164,
                        isNew: true,
                      ),
                    )
                : null,
            child: Container(
              height: 46.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Text(
                'Add without OTP (override)',
                style: AppText.figtree(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: AppColors.fgSecondary,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          "OTP confirms the number is reachable. Override only if you've "
          'already confirmed by phone.',
          textAlign: TextAlign.center,
          style: AppText.figtree(
            size: 11.5,
            weight: FontWeight.w500,
            color: AppColors.fgMuted,
            height: 1.4,
          ),
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
        padding: EdgeInsets.all(12.r),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12.r),
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
                    overflow: TextOverflow.ellipsis,
                    style: AppText.figtree(size: 14, weight: FontWeight.w700),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    customer.phone,
                    style: AppText.figtree(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.fgTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (customer.blocked)
              Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.redBg,
                  borderRadius: BorderRadius.circular(5.r),
                ),
                child: Text(
                  'BLOCKED',
                  style: AppText.figtree(
                    size: 9,
                    weight: FontWeight.w700,
                    color: AppColors.redFg,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            Icon(AppIcons.chevRight, size: 17.sp, color: AppColors.fgMuted),
          ],
        ),
      ),
    );
  }
}

/// Centered, letter-spaced 4-digit OTP entry.
class _OtpField extends StatelessWidget {
  const _OtpField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Enter OTP',
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w600,
                color: AppColors.fgSecondary,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              '· demo ${AppConstants.demoOtp}',
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w500,
                color: AppColors.fgMuted,
              ),
            ),
          ],
        ),
        SizedBox(height: 7.h),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 4,
          onChanged: onChanged,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppText.figtree(
            size: 22,
            weight: FontWeight.w700,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••',
            hintStyle: AppText.figtree(
              size: 22,
              weight: FontWeight.w700,
              color: AppColors.fgMuted,
              letterSpacing: 8,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 13.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.brandYellowDeep),
            ),
          ),
        ),
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
    this.inputFormatters,
    this.prefixText,
    this.errorText,
    this.enabled = true,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// Fixed, non-editable text ahead of the input — the `+91` dial code.
  final String? prefixText;

  /// Validation message under the field; reddens the border while set.
  final String? errorText;
  final bool enabled;
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
        SizedBox(height: 7.h),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppText.figtree(
              size: 15,
              weight: FontWeight.w500,
              color: AppColors.fgMuted,
            ),
            prefixIcon: prefixText == null
                ? null
                : Padding(
                    padding: EdgeInsets.only(left: 13.w, right: 6.w),
                    child: Text(
                      prefixText!,
                      style: AppText.figtree(
                        size: 15,
                        weight: FontWeight.w600,
                        color: enabled
                            ? AppColors.fgTertiary
                            : AppColors.fgMuted,
                      ),
                    ),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            contentPadding: EdgeInsets.symmetric(
              horizontal: prefixText == null ? 13.w : 0,
              vertical: 14.h,
            ),
            errorText: errorText,
            errorStyle: AppText.figtree(
              size: 11.5,
              weight: FontWeight.w500,
              color: AppColors.redFg,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.brandYellowDeep),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.borderSoft),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.redFg),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.redFg),
            ),
          ),
          style: AppText.figtree(size: 15, weight: FontWeight.w500),
        ),
      ],
    );
  }
}

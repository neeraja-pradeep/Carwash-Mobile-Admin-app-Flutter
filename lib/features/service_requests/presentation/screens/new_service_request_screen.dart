import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/constants/app_options.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/core/widgets/app_dialog.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import 'package:new_flutter_project/features/customers/application/providers/customers_providers.dart';
import 'package:new_flutter_project/features/customers/domain/entities/customer.dart';

import '../../domain/entities/service_request.dart';

/// Full-screen form for creating a new Driver Hire or Inspection request.
///
/// Mirrors `NewServiceReqForm` in `screen_servicereq.jsx`. Fields:
/// customer picker, vehicle make/model + plate (optional), reason for hire
/// (driver only, chip group from [kDriverReasons]), when + duration,
/// location, quoted fee (optional), customer note (optional).
class NewServiceRequestScreen extends ConsumerStatefulWidget {
  const NewServiceRequestScreen({required this.kind, super.key});

  final SrKind kind;

  @override
  ConsumerState<NewServiceRequestScreen> createState() =>
      _NewServiceRequestScreenState();
}

class _NewServiceRequestScreenState
    extends ConsumerState<NewServiceRequestScreen> {
  // Form state.
  Customer? _customer;
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  String? _reason;
  final _whenCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool get _isDriver => widget.kind == SrKind.driver;

  bool get _dirty =>
      _customer != null ||
      _reason != null ||
      _makeCtrl.text.isNotEmpty ||
      _modelCtrl.text.isNotEmpty ||
      _whenCtrl.text.isNotEmpty ||
      _locationCtrl.text.isNotEmpty;

  bool get _isValid {
    return _customer != null &&
        _makeCtrl.text.trim().isNotEmpty &&
        _modelCtrl.text.trim().isNotEmpty &&
        _whenCtrl.text.trim().isNotEmpty &&
        _durationCtrl.text.trim().isNotEmpty &&
        _locationCtrl.text.trim().isNotEmpty &&
        (!_isDriver || _reason != null);
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _whenCtrl.dispose();
    _durationCtrl.dispose();
    _locationCtrl.dispose();
    _feeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_isValid) return;
    AppToast.show(
      context,
      '${_isDriver ? 'Driver hire' : 'Inspection'} request created',
    );
    context.pop();
  }

  Future<void> _onBack(BuildContext context) async {
    if (!_dirty) {
      context.pop();
      return;
    }
    final discard = await showConfirmDialog(
      context: context,
      title: 'Discard this request?',
      body: 'Your entered details will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (discard && context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final discard = await showConfirmDialog(
          context: context,
          title: 'Discard this request?',
          body: 'Your entered details will be lost.',
          confirmLabel: 'Discard',
          destructive: true,
        );
        if (discard && context.mounted) context.pop();
      },
      child: Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: _isDriver ? 'New Driver Hire' : 'New Inspection',
              subtitle: 'Phone-in request',
              onBack: () => _onBack(context),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  // Info banner.
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.blueBg,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(AppIcons.phone,
                            size: 16.sp, color: AppColors.blueFg),
                        SizedBox(width: 9.w),
                        Expanded(
                          child: Text(
                            'Creating a phone-in request on behalf of the customer. '
                            'They will receive a confirmation SMS.',
                            style: AppText.figtree(
                              size: 13,
                              weight: FontWeight.w400,
                              color: AppColors.blueFg,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Customer section.
                  _FormCard(
                    label: 'Customer',
                    child: _InlineCustomerPicker(
                      value: _customer,
                      onChanged: (c) => setState(() => _customer = c),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Vehicle section.
                  _FormCard(
                    label: 'Vehicle',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _FormInput(
                                controller: _makeCtrl,
                                label: 'Make',
                                hint: 'e.g. Toyota',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _FormInput(
                                controller: _modelCtrl,
                                label: 'Model',
                                hint: 'e.g. Fortuner',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        _FormInput(
                          controller: _plateCtrl,
                          label: 'Plate number',
                          hint: 'KL-04-X-XXXX (optional)',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Trip / Inspection section.
                  _FormCard(
                    label: _isDriver ? 'Trip' : 'Inspection',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reason for hire (driver only).
                        if (_isDriver) ...[
                          Text(
                            'Reason for hire',
                            style: AppText.figtree(
                              size: 12,
                              weight: FontWeight.w600,
                              color: AppColors.fgTertiary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              for (final r in kDriverReasons)
                                AppChip(
                                  label: r,
                                  active: _reason == r,
                                  onTap: () =>
                                      setState(() => _reason = r),
                                ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                        ],

                        // When + Duration side by side.
                        Row(
                          children: [
                            Expanded(
                              child: _FormInput(
                                controller: _whenCtrl,
                                label: 'When',
                                hint: '30 May, 7:00 AM',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _FormInput(
                                controller: _durationCtrl,
                                label: 'Duration',
                                hint: '4 hrs',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),

                        // Location.
                        _FormInput(
                          controller: _locationCtrl,
                          label: 'Location',
                          hint: 'Pick-up / inspection address',
                          onChanged: (_) => setState(() {}),
                          prefixIcon: AppIcons.pin,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Fee & notes.
                  _FormCard(
                    label: 'Fee & notes',
                    child: Column(
                      children: [
                        _FormInput(
                          controller: _feeCtrl,
                          label: 'Quoted fee',
                          hint: 'Optional',
                          prefixText: '₹',
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 10.h),
                        _FormTextArea(
                          controller: _noteCtrl,
                          label: 'Customer note',
                          hint: 'Any special instructions or context…',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Submit.
                  AppButton(
                    label: 'Create Request',
                    full: true,
                    disabled: !_isValid,
                    onPressed: _submit,
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ── Form helpers ──────────────────────────────────────────────────────────────

/// Labelled section card wrapping form fields.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 13.h, 16.w, 0),
            child: Text(label, style: AppText.eyebrow),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  const _FormInput({
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixText,
    this.prefixIcon,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? prefixText;
  final IconData? prefixIcon;
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
            size: 12,
            weight: FontWeight.w600,
            color: AppColors.fgTertiary,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: AppText.figtree(size: 14.5, weight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.figtree(
                size: 14.5,
                weight: FontWeight.w400,
                color: AppColors.fgMuted),
            prefixText: prefixText,
            prefixStyle:
                AppText.figtree(size: 14.5, weight: FontWeight.w600),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 16.sp, color: AppColors.fgTertiary)
                : null,
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            filled: true,
            fillColor: AppColors.bgPage,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9.r),
              borderSide:
                  const BorderSide(color: AppColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9.r),
              borderSide:
                  const BorderSide(color: AppColors.borderDefault, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormTextArea extends StatelessWidget {
  const _FormTextArea({
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

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
            color: AppColors.fgTertiary,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          maxLines: 3,
          style: AppText.figtree(size: 14.5, weight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.figtree(
                size: 14.5,
                weight: FontWeight.w400,
                color: AppColors.fgMuted),
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            filled: true,
            fillColor: AppColors.bgPage,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9.r),
              borderSide:
                  const BorderSide(color: AppColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9.r),
              borderSide: const BorderSide(
                  color: AppColors.borderDefault, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline customer picker — searches the customers list and shows a
/// selected-customer chip once picked. Used in place of the shared
/// `CustomerPicker` which resides in the bookings feature (not yet available).
class _InlineCustomerPicker extends ConsumerStatefulWidget {
  const _InlineCustomerPicker({
    required this.value,
    required this.onChanged,
  });

  final Customer? value;
  final ValueChanged<Customer?> onChanged;

  @override
  ConsumerState<_InlineCustomerPicker> createState() =>
      _InlineCustomerPickerState();
}

class _InlineCustomerPickerState
    extends ConsumerState<_InlineCustomerPicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _open = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    if (widget.value != null) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.value!.name,
                  style: AppText.figtree(
                      size: 14.5, weight: FontWeight.w700),
                ),
                Text(
                  widget.value!.phone,
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: AppColors.fgTertiary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              widget.onChanged(null);
              _searchCtrl.clear();
              setState(() => _query = '');
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.bgPage,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Text(
                'Change',
                style: AppText.figtree(
                    size: 13, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    return customersAsync.when(
      loading: () => Text('Loading customers…',
          style: AppText.figtree(
              size: 13, color: AppColors.fgTertiary)),
      error: (e, _) => Text('Error loading customers',
          style: AppText.figtree(size: 13, color: AppColors.danger)),
      data: (customers) {
        final filtered = _query.isEmpty
            ? customers
            : customers.where((c) {
                final q = _query.toLowerCase();
                return c.name.toLowerCase().contains(q) ||
                    c.phone.toLowerCase().contains(q);
              }).toList();

        return Column(
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  setState(() => _query = v),
              onTap: () => setState(() => _open = true),
              style: AppText.figtree(
                  size: 14.5, weight: FontWeight.w400),
              decoration: InputDecoration(
                hintText: 'Search customer name or phone',
                hintStyle: AppText.figtree(
                    size: 14.5,
                    weight: FontWeight.w400,
                    color: AppColors.fgMuted),
                prefixIcon: Icon(AppIcons.search,
                    size: 18.sp, color: AppColors.fgTertiary),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 12.h),
                filled: true,
                fillColor: AppColors.bgPage,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9.r),
                  borderSide:
                      const BorderSide(color: AppColors.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9.r),
                  borderSide: const BorderSide(
                      color: AppColors.borderDefault, width: 1.5),
                ),
              ),
            ),
            if (_open && _query.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(9.r),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                constraints: BoxConstraints(maxHeight: 180.h),
                child: filtered.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(12.r),
                        child: Text('No customers found',
                            style: AppText.figtree(
                                size: 13,
                                color: AppColors.fgTertiary)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderSoft),
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          return GestureDetector(
                            onTap: () {
                              widget.onChanged(c);
                              _searchCtrl.clear();
                              setState(() {
                                _query = '';
                                _open = false;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 10.h),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: AppText.figtree(
                                        size: 14, weight: FontWeight.w600),
                                  ),
                                  Text(
                                    c.phone,
                                    style: AppText.figtree(
                                      size: 12.5,
                                      weight: FontWeight.w400,
                                      color: AppColors.fgTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        );
      },
    );
  }
}

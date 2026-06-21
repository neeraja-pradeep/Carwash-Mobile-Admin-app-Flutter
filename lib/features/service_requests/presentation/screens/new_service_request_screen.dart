import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/constants/app_options.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import 'package:new_flutter_project/features/bookings/presentation/components/customer_picker.dart';

import '../../domain/entities/service_request.dart';
import '../../application/providers/service_requests_providers.dart';

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
  // Form state — mirrors NewServiceReqForm in screen_servicereq.jsx.
  CustomerPick? _customer;
  DateTime? _appointmentDate; // Store the actual date
  final _makeCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  late String _reason = _isDriver ? 'Round Trip' : '';
  final _whenCtrl = TextEditingController();
  late final _durationCtrl =
      TextEditingController(text: _isDriver ? '4 hrs' : '~1 hr');
  final _locationCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  bool get _isDriver => widget.kind == SrKind.driver;

  // Matches the JSX `valid` check: customer + when + location.
  bool get _isValid =>
      _customer != null &&
      _appointmentDate != null &&
      _locationCtrl.text.trim().isNotEmpty;

  /// Map UI reason label to API trip_type value
  String _getTripType(String uiLabel) {
    const mapping = {
      'One Way': 'one_way',
      'Round Trip': 'round_trip',
      'Hourly': 'hourly',
      'Hospital': 'hospital',
    };
    return mapping[uiLabel] ?? 'round_trip';
  }

  /// Open date picker and update appointment date
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _appointmentDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final formatted =
          '${picked.day} ${_getMonthName(picked.month)}, ${picked.year}';
      setState(() {
        _appointmentDate = picked;
        _whenCtrl.text = formatted;
      });
    }
  }

  /// Get month name from month number
  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _plateCtrl.dispose();
    _whenCtrl.dispose();
    _durationCtrl.dispose();
    _locationCtrl.dispose();
    _feeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final customerId = int.tryParse(_customer!.id ?? '');
      if (customerId == null) {
        AppToast.show(context, 'Invalid customer');
        return;
      }

      // Format appointment date as YYYY-MM-DD
      String appointmentDate = '';
      if (_appointmentDate != null) {
        appointmentDate =
            '${_appointmentDate!.year}-${_appointmentDate!.month.toString().padLeft(2, '0')}-${_appointmentDate!.day.toString().padLeft(2, '0')}';
      } else {
        AppToast.show(context, 'Please select appointment date');
        return;
      }

      final params = {
        'customerId': customerId,
        'requestType': _isDriver ? 'driver' : 'inspection',
        'tripType': _isDriver ? _getTripType(_reason) : null,
        'inspectionType': null, // TODO: Add inspection type picker if needed
        'vehicleText': _makeCtrl.text.isNotEmpty
            ? '${_makeCtrl.text}${_plateCtrl.text.isNotEmpty ? ' · ${_plateCtrl.text}' : ''}'
            : null,
        'appointmentDate': appointmentDate,
        'addressText': _locationCtrl.text,
        'quotedFee': _feeCtrl.text.isNotEmpty ? _feeCtrl.text : null,
        'customerNote': _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
      };

      await ref.read(createServiceRequestProvider(params).future);

      if (mounted) {
        final isNew = _customer?.isNew ?? false;
        AppToast.show(
          context,
          '${_isDriver ? 'Driver hire' : 'Inspection'} request created'
          '${isNew ? ' · new customer added' : ''}',
        );
        // Force refresh the requests list to show the new request
        ref.invalidate(serviceRequestsProvider);
        ref.invalidate(filteredServiceRequestsProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: _isDriver ? 'New Driver Hire' : 'New Inspection',
              subtitle: 'Phone-in request',
              onBack: () => context.pop(),
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
                            "Capture the basics now — you'll call the "
                            'customer to confirm fee, timing and assign someone.',
                            style: AppText.figtree(
                              size: 12.5,
                              weight: FontWeight.w500,
                              color: AppColors.blueFg,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Customer section — shared picker (search existing / quick-add).
                  _FormCard(
                    label: 'Customer',
                    child: CustomerPicker(
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
                        _FormInput(
                          controller: _makeCtrl,
                          label: 'Make & model',
                          hint: 'e.g. Maruti Ertiga',
                        ),
                        SizedBox(height: 10.h),
                        _FormInput(
                          controller: _plateCtrl,
                          label: _isDriver ? 'Plate' : 'Plate / pre-purchase',
                          hint: _isDriver
                              ? 'KL-04-… (optional)'
                              : 'KL-04-… or Pre-purchase (optional)',
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
                                  onTap: () => setState(() => _reason = r),
                                ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                        ],

                        // When + Duration side by side.
                        Row(
                          children: [
                            Expanded(
                              child: _DatePickerInput(
                                controller: _whenCtrl,
                                label: 'When',
                                hint: '30 May',
                                onTap: _pickDate,
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
                    disabled: !_isValid || _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
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
                size: 14.5, weight: FontWeight.w400, color: AppColors.fgMuted),
            prefixText: prefixText,
            prefixStyle: AppText.figtree(size: 14.5, weight: FontWeight.w600),
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
              borderSide: const BorderSide(color: AppColors.borderDefault),
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
                size: 14.5, weight: FontWeight.w400, color: AppColors.fgMuted),
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            filled: true,
            fillColor: AppColors.bgPage,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
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

class _DatePickerInput extends StatelessWidget {
  const _DatePickerInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onTap;

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
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.bgPage,
              borderRadius: BorderRadius.circular(9.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? hint : controller.text,
                    style: AppText.figtree(
                      size: 14.5,
                      weight: controller.text.isEmpty
                          ? FontWeight.w400
                          : FontWeight.w500,
                      color: controller.text.isEmpty
                          ? AppColors.fgMuted
                          : AppColors.fgPrimary,
                    ),
                  ),
                ),
                Icon(
                  AppIcons.chevRight,
                  size: 18.sp,
                  color: AppColors.fgTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

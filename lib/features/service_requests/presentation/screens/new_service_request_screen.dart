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
import 'package:new_flutter_project/features/customers/application/providers/customers_providers.dart';
import 'package:new_flutter_project/features/customers/domain/entities/customer.dart';

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

  /// The saved address chosen from the dropdown. Null while nothing is picked
  /// or when the admin switched to typing a one-off address; [_locationCtrl] is
  /// the single source of truth for the text either way.
  SavedAddress? _pickedAddress;

  /// True once the admin picks "Type a different address" — keeps the free-text
  /// field open even though no saved address is selected.
  bool _typingAddress = false;

  bool get _isDriver => widget.kind == SrKind.driver;

  // Matches the JSX `valid` check: customer + when + location.
  bool get _isValid =>
      _customer != null &&
      _appointmentDate != null &&
      _locationCtrl.text.trim().isNotEmpty;

  /// Swapping the customer invalidates anything picked from their address
  /// book, so the location resets to empty rather than carrying the previous
  /// customer's address into the new request.
  void _onCustomerChanged(CustomerPick? customer) {
    setState(() {
      _customer = customer;
      _pickedAddress = null;
      _typingAddress = false;
      _locationCtrl.clear();
    });
  }

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
        // A saved address brings its own pin — forward it so the assigned
        // worker gets coordinates, not just a line of text.
        'latitude': _pickedAddress?.latitude,
        'longitude': _pickedAddress?.longitude,
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

  /// The Location control.
  ///
  /// For an existing customer this is a dropdown over their saved addresses
  /// (fetched from `/api/accounts/v1/addresses/?user_id=…`), so an admin taking
  /// a phone-in request picks the address the customer already saved instead of
  /// re-typing it — which also carries the saved lat/long through to the job.
  /// Falls back to free text for a brand-new customer, for one with no saved
  /// addresses, when the fetch fails, or when the admin explicitly chooses to
  /// type a different address.
  Widget _buildLocationField() {
    final customerId = _customer?.id;
    if (customerId == null) return _locationTextField();

    return ref.watch(customerAddressesProvider(customerId)).when(
          loading: () => const _LocationFieldSkeleton(),
          error: (_, __) => _locationTextField(
            note: "Couldn't load saved addresses — type the address instead.",
            noteColor: AppColors.redFg,
          ),
          data: (addresses) {
            if (addresses.isEmpty) {
              return _locationTextField(
                note: 'No saved addresses for this customer.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SavedAddressDropdown(
                  addresses: addresses,
                  value: _pickedAddress,
                  typingAddress: _typingAddress,
                  onSelected: (address) => setState(() {
                    _pickedAddress = address;
                    _typingAddress = address == null;
                    _locationCtrl.text = address?.text ?? '';
                  }),
                ),
                if (_typingAddress) ...[
                  SizedBox(height: 10.h),
                  _locationTextField(label: 'Address'),
                ],
              ],
            );
          },
        );
  }

  /// Free-text location entry, with an optional explanatory note underneath.
  Widget _locationTextField({
    String label = 'Location',
    String? note,
    Color? noteColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormInput(
          controller: _locationCtrl,
          label: label,
          hint: 'Pick-up / inspection address',
          onChanged: (_) => setState(() {}),
          prefixIcon: AppIcons.pin,
        ),
        if (note != null) ...[
          SizedBox(height: 6.h),
          Text(
            note,
            style: AppText.figtree(
              size: 11.5,
              weight: FontWeight.w500,
              color: noteColor ?? AppColors.fgMuted,
            ),
          ),
        ],
      ],
    );
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
                      onChanged: _onCustomerChanged,
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

                        // Location — saved-address dropdown once a customer
                        // with an id is selected, free text otherwise.
                        _buildLocationField(),
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

// ── Location helpers ──────────────────────────────────────────────────────────

/// Sentinel entry for the "type a different address" row — a saved address the
/// customer will never have, matched by identity (const canonicalisation).
const _typeAddressOption = SavedAddress(label: '', text: '', isDefault: false);

/// Dropdown over a customer's saved addresses, plus an escape hatch for an
/// address that isn't in their address book.
class _SavedAddressDropdown extends StatelessWidget {
  const _SavedAddressDropdown({
    required this.addresses,
    required this.value,
    required this.typingAddress,
    required this.onSelected,
  });

  final List<SavedAddress> addresses;

  /// The selected saved address, or null when nothing is picked yet or the
  /// admin opted to type one instead (see [typingAddress]).
  final SavedAddress? value;
  final bool typingAddress;

  /// Fires with the chosen address, or null for "type a different address".
  final ValueChanged<SavedAddress?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value ?? (typingAddress ? _typeAddressOption : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: AppText.figtree(
            size: 12,
            weight: FontWeight.w600,
            color: AppColors.fgTertiary,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.bgPage,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SavedAddress>(
              value: selected,
              isExpanded: true,
              itemHeight: 58.h,
              borderRadius: BorderRadius.circular(12.r),
              dropdownColor: AppColors.bgCard,
              icon: Icon(
                AppIcons.chevDown,
                size: 20.sp,
                color: AppColors.fgTertiary,
              ),
              hint: Row(
                children: [
                  Icon(AppIcons.pin, size: 16.sp, color: AppColors.fgTertiary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Select saved address',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.figtree(
                        size: 14.5,
                        weight: FontWeight.w400,
                        color: AppColors.fgMuted,
                      ),
                    ),
                  ),
                ],
              ),
              // Collapsed state stays one line — the menu shows the detail.
              selectedItemBuilder: (_) => [
                for (final a in addresses) _collapsedRow(a.text),
                _collapsedRow('Type a different address'),
              ],
              items: [
                for (final a in addresses)
                  DropdownMenuItem<SavedAddress>(
                    value: a,
                    child: _AddressMenuRow(address: a),
                  ),
                DropdownMenuItem<SavedAddress>(
                  value: _typeAddressOption,
                  child: Row(
                    children: [
                      Icon(AppIcons.plus,
                          size: 16.sp, color: AppColors.fgSecondary),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Type a different address',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.figtree(
                            size: 13.5,
                            weight: FontWeight.w600,
                            color: AppColors.fgSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (picked) => onSelected(
                picked == _typeAddressOption ? null : picked,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _collapsedRow(String text) {
    return Row(
      children: [
        Icon(AppIcons.pin, size: 16.sp, color: AppColors.fgTertiary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.figtree(size: 14.5, weight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

/// One saved address inside the open dropdown: label + DEFAULT badge on top,
/// the full address underneath.
class _AddressMenuRow extends StatelessWidget {
  const _AddressMenuRow({required this.address});

  final SavedAddress address;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                address.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.figtree(size: 13, weight: FontWeight.w700),
              ),
            ),
            if (address.isDefault) ...[
              SizedBox(width: 7.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(5.r),
                ),
                child: Text(
                  'DEFAULT',
                  style: AppText.figtree(
                    size: 9,
                    weight: FontWeight.w600,
                    color: AppColors.blueFg,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 3.h),
        Text(
          address.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w500,
            color: AppColors.fgTertiary,
          ),
        ),
      ],
    );
  }
}

/// Placeholder shown while a customer's saved addresses are loading.
class _LocationFieldSkeleton extends StatelessWidget {
  const _LocationFieldSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: AppText.figtree(
            size: 12,
            weight: FontWeight.w600,
            color: AppColors.fgTertiary,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          height: 46.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.bgPage,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 15.sp,
                height: 15.sp,
                child: const CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Loading saved addresses…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.figtree(
                    size: 14,
                    weight: FontWeight.w500,
                    color: AppColors.fgMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

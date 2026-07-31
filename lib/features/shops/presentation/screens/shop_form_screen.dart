import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/router/app_router.dart';
import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/constants/app_options.dart';
import 'package:new_flutter_project/core/utils/phone_number.dart';
import 'package:new_flutter_project/core/widgets/widgets.dart';

import '../../application/providers/shops_providers.dart';
import '../../domain/entities/shop.dart';

/// Add / Edit shop form screen.
/// Mirrors `AddShopForm` in `screen_shopforms.jsx`.
/// [shopId] is null when adding, non-null when editing.
class ShopFormScreen extends ConsumerWidget {
  const ShopFormScreen({this.shopId, super.key});

  final String? shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (shopId == null) {
      return const _ShopFormBody(shop: null);
    }
    // Detail, not `shopByIdProvider`: that one picks the shop out of the *list*
    // response, which carries no owner, phone, address, coordinates, vehicle
    // types, commission or bank details — so the form opened blank.
    final shopAsync = ref.watch(shopDetailProvider(shopId!));
    return shopAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgPage,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(
          child: Column(
            children: [
              TopBar(title: 'Edit Shop', onBack: () => context.pop()),
              Expanded(
                child: ErrorView(
                  onRetry: () => ref.invalidate(shopDetailProvider(shopId!)),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (shop) => _ShopFormBody(shop: shop),
    );
  }
}

class _ShopFormBody extends ConsumerStatefulWidget {
  const _ShopFormBody({required this.shop});
  final Shop? shop;

  @override
  ConsumerState<_ShopFormBody> createState() => _ShopFormBodyState();
}

class _ShopFormBodyState extends ConsumerState<_ShopFormBody> {
  late _FormState _f;
  bool _touched = false;
  bool _saving = false;

  bool get _isEdit => widget.shop != null;

  @override
  void initState() {
    super.initState();
    _f = _isEdit ? _FormState.fromShop(widget.shop!) : const _FormState();
  }

  bool get _dirty => _isEdit
      ? _touched
      : _f.name.isNotEmpty ||
          _f.ownerName.isNotEmpty ||
          _f.address.isNotEmpty ||
          _f.latitude != null;

  /// Shop phone is optional, but a half-typed one still blocks the save —
  /// otherwise it would silently reach the API as an empty string.
  bool get _shopPhoneOk =>
      _f.shopPhone.trim().isEmpty || PhoneNumber.isValid(_f.shopPhone);

  /// Owner phone is only validated when creating: on edit it is read-only and
  /// deliberately not sent, so a shop carrying a legacy number stays saveable.
  bool get _ownerPhoneOk =>
      _isEdit ? true : PhoneNumber.isValid(_f.ownerPhone);

  bool get _valid =>
      _f.name.trim().isNotEmpty && _ownerPhoneOk && _shopPhoneOk;

  /// The API form of a number this form holds. Falls back to the raw value for
  /// a legacy number the edit screen can't fix (owner phone is read-only there)
  /// — blanking it would wipe a real number the shop already has.
  String _outgoing(String raw) {
    final formatted = PhoneNumber.e164(raw);
    return formatted.isEmpty ? raw.trim() : formatted;
  }

  void _set(_FormState updated) => setState(() {
        _f = updated;
        if (_isEdit) _touched = true;
      });

  /// Opens the map picker for the Address field and folds the picked point back
  /// into the form: the exact coordinates go to the backend, the reverse-geocoded
  /// address fills Address and the postal code fills Pincode.
  ///
  /// Anything the geocoder could not resolve is left as the admin typed it —
  /// a picked point never wipes text they already entered.
  Future<void> _pickLocation() async {
    FocusScope.of(context).unfocus();
    final place = await showLocationPicker(context, initial: _f.pickedPlace);
    if (place == null || !mounted) return;

    _set(_f.copyWith(
      latitude: place.latitude,
      longitude: place.longitude,
      address: place.hasAddress ? place.address : _f.address,
      pincode: place.hasPincode ? place.pincode : _f.pincode,
      // The geocoder resolves these alongside the address; there are no inputs
      // for them, so the picked point is the only place they can come from.
      city: place.city.isNotEmpty ? place.city : _f.city,
      state: place.state.isNotEmpty ? place.state : _f.state,
    ));

    if (!place.hasPincode) {
      AppToast.show(context, 'Pincode not found for this point — enter it manually');
    }
  }

  /// Map display vehicle type names to API-compatible lowercase values
  List<String> _mapVehicleTypes(List<String> displayTypes) {
    final mapping = {
      'hatchback': 'hatchback',
      'sedan': 'sedan',
      'compact suv': 'suv',
      'premium suv': 'suv',
      'suv': 'suv',
      'convertible': 'convertible',
      'bike': 'bike',
    };
    return displayTypes
        .map((t) {
          final lower = t.toLowerCase();
          return mapping[lower] ?? lower;
        })
        .toList();
  }

  /// Map commission type to API-compatible values
  String _mapCommissionType(String mode) {
    final mapping = {
      'percentage': 'percentage',
      'flat': 'flat',
      'floor': 'percent_floor', // floor mode is actually percent_floor in API
    };
    return mapping[mode] ?? mode;
  }

  /// Create a new shop via API
  void _handleCreate() async {
    if (!_valid) return;

    AppToast.show(context, 'Creating shop...');

    try {
      final params = (
        name: _f.name.trim(),
        address: _f.address.trim(),
        pincode: _f.pincode.trim(),
        // Resolved by the map picker; empty when no point was picked.
        city: _f.city.trim(),
        state: _f.state.trim(),
        // Both go out as +91XXXXXXXXXX — the field only ever held the ten
        // national digits.
        phone: _f.shopPhone.trim().isEmpty
            ? _outgoing(_f.ownerPhone)
            : _outgoing(_f.shopPhone),
        ownerName: _f.ownerName.trim(),
        ownerPhone: _outgoing(_f.ownerPhone),
        latitude: _f.latitude,
        longitude: _f.longitude,
        dailyBookingCap: int.tryParse(_f.cap),
        supportedVehicleTypes: _f.types.isNotEmpty ? _mapVehicleTypes(_f.types) : null,
        commissionType: _mapCommissionType(_f.mode),
        commissionPercentage: _f.mode == 'percentage' || _f.mode == 'floor' ? _f.pct : null,
        commissionAmount: _f.mode == 'flat' ? _f.flat : null,
        commissionFloor: _f.mode == 'floor' ? _f.floor : null,
        bankAccountName: _f.accName.isEmpty ? null : _f.accName,
        bankAccountNumber: _f.accNo.isEmpty ? null : _f.accNo,
        bankIfsc: _f.ifsc.isEmpty ? null : _f.ifsc,
        upiId: _f.upi.isEmpty ? null : _f.upi,
        gstin: _f.gstin.trim().isEmpty ? null : _f.gstin.trim(),
        // No input for PAN on this form yet.
        pan: null,
      );

      // Trigger the provider to create the shop
      await ref.read(createShopProvider(params).future);
      if (!mounted) return;
      AppToast.show(context, 'Shop created (Inactive) — add a service next');

      context.pop();
      // Shops list will reload naturally when user navigates back
    } catch (e) {
      if (!mounted) return;

      // Extract error message
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }

      // Show error dialog instead of toast for better visibility
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Failed to create shop'),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Saves the edited shop — PATCH /api/shop/v1/shops/{id}/.
  ///
  /// Only the fields this form owns are sent. City and state ride along solely
  /// when the map picker resolved them this session; sending them blank would
  /// wipe whatever the shop already has, since there are no inputs for them.
  void _handleEdit() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);

    try {
      await ref.read(updateShopProvider)(
        widget.shop!.id,
        name: _f.name.trim(),
        address: _f.address.trim(),
        pincode: _f.pincode.trim(),
        city: _f.city.trim().isEmpty ? null : _f.city.trim(),
        state: _f.state.trim().isEmpty ? null : _f.state.trim(),
        phone: _f.shopPhone.trim().isEmpty
            ? _outgoing(_f.ownerPhone)
            : _outgoing(_f.shopPhone),
        // owner_name / owner_phone are deliberately omitted: they are write-only
        // helper fields the *create* view pops to resolve an owner User, and
        // ShopViewSet.perform_update never consumes them. Sending them would be
        // silently dropped — see the note in the Owner fields' helper text.
        latitude: _f.latitude,
        longitude: _f.longitude,
        dailyBookingCap: int.tryParse(_f.cap),
        supportedVehicleTypes:
            _f.types.isNotEmpty ? _mapVehicleTypes(_f.types) : null,
        commissionType: _mapCommissionType(_f.mode),
        commissionPercentage:
            _f.mode == 'percentage' || _f.mode == 'floor' ? _f.pct : null,
        commissionAmount: _f.mode == 'flat' ? _f.flat : null,
        commissionFloor: _f.mode == 'floor' ? _f.floor : null,
        bankAccountName: _f.accName.trim().isEmpty ? null : _f.accName.trim(),
        bankAccountNumber: _f.accNo.trim().isEmpty ? null : _f.accNo.trim(),
        bankIfsc: _f.ifsc.trim().isEmpty ? null : _f.ifsc.trim(),
        upiId: _f.upi.trim().isEmpty ? null : _f.upi.trim(),
        gstin: _f.gstin.trim().isEmpty ? null : _f.gstin.trim(),
      );
      if (!mounted) return;
      AppToast.show(context, 'Shop details saved');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = e.toString().replaceFirst('Exception: ', '');
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Failed to save shop'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Prompts to discard unsaved details before leaving (matches the design's
  /// discard pattern). Pops only when confirmed or when not dirty.
  Future<void> _handleBack() async {
    if (!_dirty) {
      context.pop();
      return;
    }
    final discard = await showConfirmDialog(
      context: context,
      title: _isEdit ? 'Discard changes?' : 'Discard new shop?',
      body: 'Your entered details will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (discard && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        if (_isEdit) setState(() => _touched = true);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              TopBar(
                title: _isEdit ? 'Edit Shop' : 'Add Shop',
                subtitle: _isEdit ? widget.shop!.name : null,
                onBack: _handleBack,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info banner for add mode
                      if (!_isEdit) ...[
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppColors.blueBg,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(AppIcons.alert,
                                  size: 18.sp, color: AppColors.blueFg),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    style: AppText.figtree(
                                      size: 12.5,
                                      weight: FontWeight.w500,
                                      color: AppColors.blueFg,
                                      height: 1.4,
                                    ),
                                    children: const [
                                      TextSpan(text: 'Shop is created '),
                                      TextSpan(
                                        text: 'Inactive',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      TextSpan(
                                        text:
                                            '. Add at least one active service before you can activate it.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),
                      ],

                      // Shop
                      _FCard(
                        label: 'Shop',
                        children: [
                          _FInput(
                            label: 'Shop name',
                            value: _f.name,
                            placeholder: 'e.g. SparkleWash Mullackal',
                            onChanged: (v) => _set(_f.copyWith(name: v)),
                          ),
                          _FInput(
                            label: 'Address',
                            value: _f.address,
                            placeholder: 'Pick on map, or type street & locality',
                            maxLines: 2,
                            onChanged: (v) => _set(_f.copyWith(address: v)),
                            trailing: _MapPinButton(onTap: _pickLocation),
                          ),
                          _LocationHint(
                            place: _f.pickedPlace,
                            onTap: _pickLocation,
                          ),
                          _FInput(
                            label: 'Pincode',
                            value: _f.pincode,
                            placeholder: '688011',
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _set(_f.copyWith(pincode: v)),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Contacts
                      _FCard(
                        label: 'Contacts',
                        children: [
                          _FInput(
                            label: 'Owner name',
                            value: _f.ownerName,
                            placeholder: 'Full name',
                            // The owner is resolved when the shop is created;
                            // the update endpoint has no way to reassign it, so
                            // editing here would look like it saved and not.
                            readOnly: _isEdit,
                            onChanged: (v) => _set(_f.copyWith(ownerName: v)),
                          ),
                          // The country code is fixed at +91 and rendered as a
                          // static prefix, so the field holds the ten national
                          // digits only and the API always gets E.164.
                          _FInput(
                            label: 'Owner phone',
                            value: _f.ownerPhone,
                            placeholder: '98765 43210',
                            prefix: PhoneNumber.dialCode,
                            keyboardType: TextInputType.phone,
                            inputFormatters: const [PhoneNumberInputFormatter()],
                            readOnly: _isEdit,
                            errorText: PhoneNumber.errorFor(_f.ownerPhone),
                            helperText: _isEdit
                                ? 'Owner is set when the shop is created and '
                                    'cannot be changed here.'
                                : null,
                            onChanged: (v) => _set(_f.copyWith(ownerPhone: v)),
                          ),
                          _FInput(
                            label: 'Shop phone',
                            value: _f.shopPhone,
                            placeholder: 'Number drivers see',
                            prefix: PhoneNumber.dialCode,
                            optional: true,
                            keyboardType: TextInputType.phone,
                            inputFormatters: const [PhoneNumberInputFormatter()],
                            errorText: PhoneNumber.errorFor(_f.shopPhone),
                            onChanged: (v) => _set(_f.copyWith(shopPhone: v)),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Operating Hours & Slots
                      _FCard(
                        label: 'Operating Hours & Slots',
                        children: [
                          if (_isEdit)
                            GestureDetector(
                              onTap: () => context
                                  .push(Routes.shopHours(widget.shop!.id)),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38.r,
                                    height: 38.r,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.bgPage,
                                      borderRadius: BorderRadius.circular(11.r),
                                    ),
                                    child: Icon(
                                      AppIcons.clock,
                                      size: 19.sp,
                                      color: AppColors.fgSecondary,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Manage hours & slots',
                                          style: AppText.figtree(
                                            size: 13.5,
                                            weight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          'Weekly schedule, breaks, per-slot capacity & holidays',
                                          style: AppText.figtree(
                                            size: 12,
                                            weight: FontWeight.w400,
                                            color: AppColors.fgTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    AppIcons.chevRight,
                                    size: 18.sp,
                                    color: AppColors.fgTertiary,
                                  ),
                                ],
                              ),
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  AppIcons.clock,
                                  size: 17.sp,
                                  color: AppColors.fgTertiary,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    'You\'ll set the weekly schedule, time slots and breaks on the next step, once the shop is created.',
                                    style: AppText.figtree(
                                      size: 12.5,
                                      weight: FontWeight.w400,
                                      color: AppColors.fgTertiary,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Operational Config
                      _FCard(
                        label: 'Operational Config',
                        children: [
                          _FInput(
                            label: 'Daily booking cap',
                            value: _f.cap,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _set(_f.copyWith(cap: v)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vehicle types supported',
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
                                children: kVehicleTypes.map((t) {
                                  final on = _f.types.contains(t);
                                  return GestureDetector(
                                    onTap: () {
                                      final next = on
                                          ? _f.types
                                              .where((x) => x != t)
                                              .toList()
                                          : [..._f.types, t];
                                      _set(_f.copyWith(types: next));
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 13.w,
                                        vertical: 8.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: on
                                            ? AppColors.brandYellow
                                            : AppColors.bgCard,
                                        borderRadius:
                                            BorderRadius.circular(999.r),
                                        border: Border.all(
                                          color: on
                                              ? AppColors.brandYellowDeep
                                              : AppColors.borderDefault,
                                        ),
                                      ),
                                      child: Text(
                                        t,
                                        style: AppText.figtree(
                                          size: 13,
                                          weight: on
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
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Commission
                      _FCard(
                        label: 'Commission (negotiated)',
                        children: [
                          _CommissionSeg(
                            value: _f.mode,
                            onChange: (v) => _set(_f.copyWith(mode: v)),
                          ),
                          if (_f.mode == 'percentage')
                            _FInput(
                              label: 'Percentage',
                              value: _f.pct,
                              suffix: '%',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onChanged: (v) => _set(_f.copyWith(pct: v)),
                            ),
                          if (_f.mode == 'flat')
                            _FInput(
                              label: 'Flat fee per booking',
                              value: _f.flat,
                              prefix: '₹',
                              keyboardType: TextInputType.number,
                              onChanged: (v) => _set(_f.copyWith(flat: v)),
                            ),
                          if (_f.mode == 'floor')
                            Row(
                              children: [
                                Expanded(
                                  child: _FInput(
                                    label: 'Percentage',
                                    value: _f.pct,
                                    suffix: '%',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    onChanged: (v) => _set(_f.copyWith(pct: v)),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: _FInput(
                                    label: 'Minimum ₹',
                                    value: _f.floor,
                                    prefix: '₹',
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) =>
                                        _set(_f.copyWith(floor: v)),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Bank / UPI
                      _FCard(
                        label: 'Bank / UPI (payout reference)',
                        children: [
                          _FInput(
                            label: 'Account name',
                            value: _f.accName,
                            optional: true,
                            onChanged: (v) => _set(_f.copyWith(accName: v)),
                          ),
                          _FInput(
                            label: 'Account number',
                            value: _f.accNo,
                            optional: true,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _set(_f.copyWith(accNo: v)),
                          ),
                          _FInput(
                            label: 'IFSC',
                            value: _f.ifsc,
                            optional: true,
                            onChanged: (v) => _set(_f.copyWith(ifsc: v)),
                          ),
                          _FInput(
                            label: 'UPI ID',
                            value: _f.upi,
                            optional: true,
                            onChanged: (v) => _set(_f.copyWith(upi: v)),
                          ),
                          _FInput(
                            label: 'GSTIN',
                            value: _f.gstin,
                            optional: true,
                            placeholder: '32ABCFS1234K1Z5',
                            onChanged: (v) => _set(_f.copyWith(gstin: v)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Save bar
              Container(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                decoration: const BoxDecoration(
                  color: AppColors.bgCard,
                  border: Border(top: BorderSide(color: AppColors.borderSoft)),
                ),
                child: AppButton(
                  label: _isEdit ? 'Save Changes' : 'Save Shop',
                  full: true,
                  disabled: !_valid || _saving,
                  onPressed: _isEdit ? _handleEdit : _handleCreate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Form field primitives ────────────────────────────────────────────────────

/// Labelled text field.
///
/// Holds its own [TextEditingController] kept in sync with [value] (same
/// pattern as `SearchField`) so the form can write into a field the admin isn't
/// typing in — the map picker fills Address and Pincode this way.
class _FInput extends StatefulWidget {
  const _FInput({
    required this.label,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.trailing,
    this.optional = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.readOnly = false,
    this.helperText,
    this.errorText,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final String? prefix;
  final String? suffix;

  /// Rendered inside the field, right of the input (e.g. the map-picker pin).
  final Widget? trailing;
  final bool optional;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  /// Shown but not editable — the value is real, this screen just can't change
  /// it. Greyed so the admin isn't invited to type into a field that won't save.
  final bool readOnly;

  /// Muted note under the field explaining a constraint.
  final String? helperText;

  /// Validation message under the field. Takes the place of [helperText] and
  /// reddens the border while the value is wrong.
  final String? errorText;

  @override
  State<_FInput> createState() => _FInputState();
}

class _FInputState extends State<_FInput> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(_FInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiline = widget.maxLines > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w600,
                color: AppColors.fgSecondary,
              ),
            ),
            if (widget.optional) ...[
              SizedBox(width: 6.w),
              Text(
                '· optional',
                style: AppText.figtree(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: AppColors.fgMuted,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 7.h),
        Container(
          constraints: BoxConstraints(minHeight: 50.h),
          decoration: BoxDecoration(
            color: widget.readOnly ? AppColors.bgInput : AppColors.bgCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: widget.errorText != null
                  ? AppColors.redFg
                  : AppColors.borderDefault,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              SizedBox(width: 13.w),
              if (widget.prefix != null) ...[
                Text(
                  widget.prefix!,
                  style: AppText.figtree(
                    size: 15,
                    weight: FontWeight.w600,
                    color: AppColors.fgTertiary,
                  ),
                ),
                SizedBox(width: 6.w),
              ],
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: widget.onChanged,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  readOnly: widget.readOnly,
                  maxLines: widget.maxLines,
                  minLines: 1,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                    isDense: true,
                    hintText: widget.placeholder,
                    hintStyle: AppText.figtree(
                      size: 15,
                      weight: FontWeight.w500,
                      color: AppColors.fgMuted,
                    ),
                  ),
                  style: AppText.figtree(
                    size: 15,
                    weight: FontWeight.w500,
                    color: widget.readOnly
                        ? AppColors.fgTertiary
                        : AppColors.fgPrimary,
                  ),
                ),
              ),
              if (widget.suffix != null) ...[
                SizedBox(width: 6.w),
                Text(
                  widget.suffix!,
                  style: AppText.figtree(
                    size: 13,
                    weight: FontWeight.w500,
                    color: AppColors.fgTertiary,
                  ),
                ),
              ],
              if (widget.trailing != null) ...[
                SizedBox(width: 6.w),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: widget.trailing,
                ),
              ],
              SizedBox(width: 13.w),
            ],
          ),
        ),
        if (widget.errorText != null || widget.helperText != null) ...[
          SizedBox(height: 6.h),
          Text(
            widget.errorText ?? widget.helperText!,
            style: AppText.figtree(
              size: 11.5,
              weight: FontWeight.w500,
              color: widget.errorText != null
                  ? AppColors.redFg
                  : AppColors.fgMuted,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

/// The map affordance that lives inside the Address field.
class _MapPinButton extends StatelessWidget {
  const _MapPinButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: AppColors.brandYellow,
          borderRadius: BorderRadius.circular(9.r),
          border: Border.all(color: AppColors.brandYellowDeep),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.pin, size: 15.sp, color: AppColors.fgOnBrand),
            SizedBox(width: 4.w),
            Text(
              'Map',
              style: AppText.figtree(
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.fgOnBrand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sits under the Address field: nudges the admin to pin the shop when no
/// coordinates are set, and shows the exact ones that will be saved once they
/// are. Tapping either state re-opens the picker.
class _LocationHint extends StatelessWidget {
  const _LocationHint({required this.place, required this.onTap});

  final GeoPlace? place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final located = place != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: located ? AppColors.greenBg : AppColors.blueBg,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Icon(
              located ? AppIcons.checkCircle : AppIcons.pin,
              size: 15.sp,
              color: located ? AppColors.greenFg : AppColors.blueFg,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                located
                    ? 'Location pinned · ${place!.coordsLabel}'
                    : 'Tap Map to pin the exact shop location',
                style: AppText.figtree(
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: located ? AppColors.greenFg : AppColors.blueFg,
                ),
              ),
            ),
            if (located)
              Text(
                'Change',
                style: AppText.figtree(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: AppColors.greenFg,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FCard extends StatelessWidget {
  const _FCard({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 0.1,
            ),
          ),
          SizedBox(height: 14.h),
          ...children.expand((w) => [w, SizedBox(height: 14.h)]).toList()
            ..removeLast(),
        ],
      ),
    );
  }
}

class _CommissionSeg extends StatelessWidget {
  const _CommissionSeg({required this.value, required this.onChange});
  final String value;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    const opts = [
      ('percentage', 'Percentage'),
      ('flat', 'Flat ₹'),
      ('floor', '% + floor'),
    ];
    return Row(
      children: [
        for (final (k, l) in opts) ...[
          if (k != 'percentage') SizedBox(width: 7.w),
          Expanded(
            child: GestureDetector(
              onTap: () => onChange(k),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == k ? AppColors.fgPrimary : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: value == k
                        ? AppColors.fgPrimary
                        : AppColors.borderDefault,
                  ),
                ),
                child: Text(
                  l,
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color:
                        value == k ? AppColors.fgOnDark : AppColors.fgSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Form state ───────────────────────────────────────────────────────────────

class _FormState {
  const _FormState({
    this.name = '',
    this.ownerName = '',
    this.ownerPhone = '',
    this.shopPhone = '',
    this.address = '',
    this.pincode = '',
    this.city = '',
    this.state = '',
    this.latitude,
    this.longitude,
    this.cap = '20',
    this.types = const ['Hatchback', 'Sedan', 'Compact SUV', 'SUV'],
    this.mode = 'percentage',
    this.pct = '15',
    this.flat = '40',
    this.floor = '30',
    this.accName = '',
    this.accNo = '',
    this.ifsc = '',
    this.upi = '',
    this.gstin = '',
  });

  factory _FormState.fromShop(Shop s) {
    final c = s.commission;
    final pincodeMatch = RegExp(r'\b\d{6}\b').firstMatch(s.address);
    // `Shop` defaults unset coordinates to 0/0 rather than null; treat null
    // island as "no location picked yet" so the picker starts from the device.
    final located = s.latitude != 0 || s.longitude != 0;
    return _FormState(
      name: s.name,
      ownerName: s.ownerName,
      // Stored as +91XXXXXXXXXX; the fields hold the ten national digits and
      // the +91 prefix supplies the rest.
      ownerPhone: PhoneNumber.national(s.ownerPhone),
      shopPhone: PhoneNumber.national(s.shopPhone),
      address: s.address,
      // The shop's own column when it has one; the address is only scraped as
      // a fallback for rows that predate it.
      pincode: s.pincode.trim().isNotEmpty
          ? s.pincode.trim()
          : (pincodeMatch?.group(0) ?? ''),
      latitude: located ? s.latitude : null,
      longitude: located ? s.longitude : null,
      cap: '${s.cap}',
      types: [...s.vehicleTypes],
      mode: c.mode.name,
      pct: '${c.pct ?? 15}',
      flat: '${c.flat ?? 40}',
      floor: '${c.floor ?? 30}',
      accName: s.bank.accName,
      accNo: s.bank.accNo,
      ifsc: s.bank.ifsc,
      upi: s.bank.upi,
      gstin: s.bank.gstin,
    );
  }

  final String name;
  final String ownerName;
  final String ownerPhone;
  final String shopPhone;
  final String address;
  final String pincode;

  /// Resolved by the map picker's geocoder — the form has no inputs for these,
  /// so they stay empty until a point is picked.
  final String city;
  final String state;

  /// Coordinates of the point picked on the map — null until the admin picks
  /// one. Sent to the backend verbatim so the shop is placed exactly there.
  final double? latitude;
  final double? longitude;
  final String cap;
  final List<String> types;
  final String mode;
  final String pct;
  final String flat;
  final String floor;
  final String accName;
  final String accNo;
  final String ifsc;
  final String upi;
  final String gstin;

  /// The picked point as a [GeoPlace], or null when nothing is picked yet.
  /// Seeds the map picker so re-opening it starts where the pin was left.
  GeoPlace? get pickedPlace => latitude == null || longitude == null
      ? null
      : GeoPlace(
          latitude: latitude!,
          longitude: longitude!,
          address: address,
          pincode: pincode,
        );

  _FormState copyWith({
    String? name,
    String? ownerName,
    String? ownerPhone,
    String? shopPhone,
    String? address,
    String? pincode,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    String? cap,
    List<String>? types,
    String? mode,
    String? pct,
    String? flat,
    String? floor,
    String? accName,
    String? accNo,
    String? ifsc,
    String? upi,
    String? gstin,
  }) {
    return _FormState(
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      shopPhone: shopPhone ?? this.shopPhone,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cap: cap ?? this.cap,
      types: types ?? this.types,
      mode: mode ?? this.mode,
      pct: pct ?? this.pct,
      flat: flat ?? this.flat,
      floor: floor ?? this.floor,
      accName: accName ?? this.accName,
      accNo: accNo ?? this.accNo,
      ifsc: ifsc ?? this.ifsc,
      upi: upi ?? this.upi,
      gstin: gstin ?? this.gstin,
    );
  }
}

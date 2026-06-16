import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/router/app_router.dart';
import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/constants/app_options.dart';
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
    final shopAsync = ref.watch(shopByIdProvider(shopId!));
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
                  onRetry: () => ref.invalidate(shopByIdProvider(shopId!)),
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

class _ShopFormBody extends StatefulWidget {
  const _ShopFormBody({required this.shop});
  final Shop? shop;

  @override
  State<_ShopFormBody> createState() => _ShopFormBodyState();
}

class _ShopFormBodyState extends State<_ShopFormBody> {
  late _FormState _f;
  bool _touched = false;

  bool get _isEdit => widget.shop != null;

  @override
  void initState() {
    super.initState();
    _f = _isEdit ? _FormState.fromShop(widget.shop!) : const _FormState();
  }

  bool get _dirty => _isEdit
      ? _touched
      : _f.name.isNotEmpty || _f.ownerName.isNotEmpty || _f.address.isNotEmpty;

  bool get _valid =>
      _f.name.trim().isNotEmpty && _f.ownerPhone.trim().isNotEmpty;

  void _set(_FormState updated) => setState(() {
        _f = updated;
        if (_isEdit) _touched = true;
      });

  void _toast(String msg) => AppToast.show(context, msg);

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
                            placeholder: 'Street, locality',
                            onChanged: (v) => _set(_f.copyWith(address: v)),
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
                            onChanged: (v) => _set(_f.copyWith(ownerName: v)),
                          ),
                          _FInput(
                            label: 'Owner phone',
                            value: _f.ownerPhone,
                            placeholder: '+91 …',
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => _set(_f.copyWith(ownerPhone: v)),
                          ),
                          _FInput(
                            label: 'Shop phone',
                            value: _f.shopPhone,
                            placeholder: 'Number drivers see',
                            optional: true,
                            keyboardType: TextInputType.phone,
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
                color: AppColors.bgCard,
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.borderSoft)),
                ),
                child: AppButton(
                  label: _isEdit ? 'Save Changes' : 'Save Shop',
                  full: true,
                  disabled: !_valid,
                  onPressed: () {
                    _toast(
                      _isEdit
                          ? 'Shop details saved'
                          : 'Shop created (Inactive) — add a service next',
                    );
                    context.pop();
                  },
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

class _FInput extends StatelessWidget {
  const _FInput({
    required this.label,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.optional = false,
    this.keyboardType,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final String? prefix;
  final String? suffix;
  final bool optional;
  final TextInputType? keyboardType;

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
          height: 50.h,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              SizedBox(width: 13.w),
              if (prefix != null) ...[
                Text(
                  prefix!,
                  style: AppText.figtree(
                    size: 15,
                    weight: FontWeight.w600,
                    color: AppColors.fgTertiary,
                  ),
                ),
                SizedBox(width: 6.w),
              ],
              Expanded(
                child: TextFormField(
                  initialValue: value,
                  onChanged: onChanged,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: placeholder,
                    hintStyle: AppText.figtree(
                      size: 15,
                      weight: FontWeight.w500,
                      color: AppColors.fgMuted,
                    ),
                  ),
                  style: AppText.figtree(size: 15, weight: FontWeight.w500),
                ),
              ),
              if (suffix != null) ...[
                SizedBox(width: 6.w),
                Text(
                  suffix!,
                  style: AppText.figtree(
                    size: 13,
                    weight: FontWeight.w500,
                    color: AppColors.fgTertiary,
                  ),
                ),
              ],
              SizedBox(width: 13.w),
            ],
          ),
        ),
      ],
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
    return _FormState(
      name: s.name,
      ownerName: s.ownerName,
      ownerPhone: s.ownerPhone,
      shopPhone: s.shopPhone,
      address: s.address,
      pincode: pincodeMatch?.group(0) ?? '',
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

  _FormState copyWith({
    String? name,
    String? ownerName,
    String? ownerPhone,
    String? shopPhone,
    String? address,
    String? pincode,
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

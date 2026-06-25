import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/offers_providers.dart';
import '../../domain/entities/coupon.dart';
import '../../infrastructure/models/coupon_response_model.dart';
import 'form_helpers.dart';

/// Add / Edit coupon form — pushed intra-module via Navigator.
class CouponFormScreen extends ConsumerStatefulWidget {
  const CouponFormScreen({this.coupon, super.key});

  /// Null when creating a new coupon.
  final Coupon? coupon;

  @override
  ConsumerState<CouponFormScreen> createState() => _CouponFormScreenState();
}

class _CouponFormScreenState extends ConsumerState<CouponFormScreen> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _maxDCtrl;
  late final TextEditingController _minOCtrl;
  late final TextEditingController _limitCtrl;
  late final TextEditingController _perUserCtrl;

  late String _type;
  late String _scope;
  late List<int> _scopeShops;
  late bool _active;
  DateTime? _from;
  DateTime? _to;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _codeCtrl = TextEditingController(text: c?.code ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _valueCtrl = TextEditingController(
        text: c != null && c.value != 0 ? '${c.value}' : '');
    _maxDCtrl = TextEditingController(
        text: c?.maxDiscount != null ? '${c!.maxDiscount}' : '');
    _minOCtrl = TextEditingController(
        text: c?.minOrder != null ? '${c!.minOrder}' : '0');
    _limitCtrl =
        TextEditingController(text: c != null ? '${c.limit}' : '');
    _perUserCtrl = TextEditingController(
        text: c?.perUserLimit != null ? '${c!.perUserLimit}' : '1');
    _type = c?.discountType ?? 'percentage';
    _scope = (c != null && !c.appliesToAllShops) ? 'shop' : 'all';
    _scopeShops = List<int>.from(c?.shopIds ?? const []);
    _active = c?.statusActive ?? true;
    _from = c?.startDate;
    _to = c?.endDate;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    _maxDCtrl.dispose();
    _minOCtrl.dispose();
    _limitCtrl.dispose();
    _perUserCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _codeCtrl.text.trim().isNotEmpty && _valueCtrl.text.trim().isNotEmpty;

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}-'
        '${_month(d.month)}-${d.year}';
  }

  static String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = (isFrom ? _from : _to) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        // Start of day for the start date.
        _from = DateTime(picked.year, picked.month, picked.day);
      } else {
        // End of day for the end date.
        _to = DateTime(
            picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  /// Client-side validation mirroring the write serializer rules.
  /// Returns an error message, or null when valid.
  String? _validate() {
    final value = num.tryParse(_valueCtrl.text.trim());
    if (_type == 'percentage') {
      if (value == null || value <= 0) {
        return 'Percentage coupons need a discount percent greater than 0.';
      }
    } else {
      if (value == null || value <= 0) {
        return 'Flat coupons need an amount greater than 0.';
      }
    }
    if (_from == null || _to == null) {
      return 'Please set both validity dates.';
    }
    if (!_to!.isAfter(_from!)) {
      return 'End date must be after start date.';
    }
    if (_scope == 'shop' && _scopeShops.isEmpty) {
      return 'Specific-shop coupons need at least one shop selected.';
    }
    return null;
  }

  Map<String, dynamic> _buildPayload() {
    final value = num.tryParse(_valueCtrl.text.trim()) ?? 0;
    final isPercentage = _type == 'percentage';
    final appliesToAll = _scope == 'all';
    return buildCouponPayload(
      name: _codeCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      discountType: _type,
      discountPercentage: isPercentage ? value : null,
      flatAmount: isPercentage ? null : value,
      maxDiscount: isPercentage
          ? num.tryParse(_maxDCtrl.text.trim())
          : null,
      minOrder: num.tryParse(_minOCtrl.text.trim()),
      appliesToAllShops: appliesToAll,
      shopIds: appliesToAll ? null : _scopeShops,
      limit: int.tryParse(_limitCtrl.text.trim()) ?? 0,
      perUserLimit: int.tryParse(_perUserCtrl.text.trim()),
      startDate: _from?.toUtc().toIso8601String(),
      endDate: _to?.toUtc().toIso8601String(),
      status: _active,
    );
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      AppToast.show(context, error);
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(offersRepositoryProvider);
    final isEdit = widget.coupon != null;
    try {
      final payload = _buildPayload();
      if (isEdit) {
        await repo.updateCoupon(widget.coupon!.id, payload);
      } else {
        await repo.createCoupon(payload);
      }
      ref.invalidate(couponsProvider);
      if (!mounted) return;
      AppToast.show(context, isEdit ? 'Coupon saved' : 'Coupon created');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.show(context, _message(e));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete coupon'),
        content: Text(
          'Delete "${widget.coupon!.code}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.redFg),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await ref.read(offersRepositoryProvider).deleteCoupon(widget.coupon!.id);
      ref.invalidate(couponsProvider);
      if (!mounted) return;
      AppToast.show(context, 'Coupon deleted');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.show(context, _message(e));
    }
  }

  static String _message(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.coupon != null;
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: isEdit ? 'Edit Coupon' : 'Add Coupon',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding:
                    EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  OfferFCard(
                    label: 'Code & Discount',
                    children: [
                      OfferFInput(
                        label: 'Coupon code',
                        controller: _codeCtrl,
                        placeholder: 'e.g. FIRST50',
                        onChanged: (v) {
                          // Force uppercase
                          final upper = v.toUpperCase();
                          if (_codeCtrl.text != upper) {
                            _codeCtrl.value = TextEditingValue(
                              text: upper,
                              selection: TextSelection.collapsed(
                                  offset: upper.length),
                            );
                          }
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 14.h),
                      OfferFInput(
                        label: 'Description',
                        controller: _descCtrl,
                        placeholder: '50% off your first wash',
                        optional: true,
                        onChanged: (_) => setState(() {}),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        'Discount type',
                        style: AppText.figtree(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: AppColors.fgSecondary,
                        ),
                      ),
                      SizedBox(height: 9.h),
                      OfferSegControl(
                        value: _type,
                        options: const [
                          ('percentage', 'Percentage'),
                          ('flat', 'Flat ₹'),
                        ],
                        onChanged: (v) => setState(() => _type = v),
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Expanded(
                            child: OfferFInput(
                              label: _type == 'percentage'
                                  ? 'Percent'
                                  : 'Amount',
                              controller: _valueCtrl,
                              prefix:
                                  _type == 'flat' ? '₹' : '',
                              suffix:
                                  _type == 'percentage' ? '%' : '',
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          if (_type == 'percentage') ...[
                            SizedBox(width: 12.w),
                            Expanded(
                              child: OfferFInput(
                                label: 'Max discount',
                                controller: _maxDCtrl,
                                prefix: '₹',
                                keyboardType: TextInputType.number,
                                optional: true,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 14.h),
                      OfferFInput(
                        label: 'Minimum order',
                        controller: _minOCtrl,
                        prefix: '₹',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  OfferFCard(
                    label: 'Scope & Limits',
                    children: [
                      Text(
                        'Applies to',
                        style: AppText.figtree(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: AppColors.fgSecondary,
                        ),
                      ),
                      SizedBox(height: 9.h),
                      OfferSegControl(
                        value: _scope,
                        options: const [
                          ('all', 'All shops'),
                          ('shop', 'Specific shop'),
                        ],
                        onChanged: (v) =>
                            setState(() => _scope = v),
                      ),
                      if (_scope == 'shop') ...[
                        SizedBox(height: 12.h),
                        ShopScopeChips(
                          selected: _scopeShops,
                          onToggle: (s) => setState(() {
                            if (_scopeShops.contains(s)) {
                              _scopeShops.remove(s);
                            } else {
                              _scopeShops.add(s);
                            }
                          }),
                        ),
                      ],
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Expanded(
                            child: OfferFInput(
                              label: 'Total uses',
                              controller: _limitCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: OfferFInput(
                              label: 'Per user',
                              controller: _perUserCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  OfferFCard(
                    label: 'Validity',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: 'Valid from',
                              value: _fmt(_from),
                              onTap: () => _pickDate(isFrom: true),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _DateField(
                              label: 'Valid to',
                              value: _fmt(_to),
                              onTap: () => _pickDate(isFrom: false),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active now',
                                style: AppText.figtree(
                                  size: 13.5,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                _active
                                    ? 'Customers can redeem'
                                    : 'Hidden / paused',
                                style: AppText.figtree(
                                  size: 12,
                                  color: AppColors.fgTertiary,
                                ),
                              ),
                            ],
                          ),
                          OfferToggle(
                            on: _active,
                            onTap: () =>
                                setState(() => _active = !_active),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isEdit) ...[
                    SizedBox(height: 14.h),
                    AppButton(
                      label: 'Delete Coupon',
                      kind: AppButtonKind.secondary,
                      full: true,
                      disabled: _saving,
                      onPressed: _saving ? null : _confirmDelete,
                    ),
                  ],
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding:
              EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            border:
                Border(top: BorderSide(color: AppColors.borderSoft)),
          ),
          child: AppButton(
            label: isEdit ? 'Save Changes' : 'Create Coupon',
            full: true,
            disabled: !_valid || _saving,
            onPressed: (_valid && !_saving) ? _submit : null,
          ),
        ),
      ),
    );
  }
}

/// A read-only, tappable date field that opens a date picker.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

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
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 46.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(11.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Text(
              value.isEmpty ? 'Pick date' : value,
              style: AppText.figtree(
                size: 14,
                weight: FontWeight.w500,
                color: value.isEmpty
                    ? AppColors.fgMuted
                    : AppColors.fgPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

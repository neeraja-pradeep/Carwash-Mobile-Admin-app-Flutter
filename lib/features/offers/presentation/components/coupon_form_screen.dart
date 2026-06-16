import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/coupon.dart';

/// Add / Edit coupon form — pushed intra-module via Navigator.
class CouponFormScreen extends StatefulWidget {
  const CouponFormScreen({this.coupon, super.key});

  /// Null when creating a new coupon.
  final Coupon? coupon;

  @override
  State<CouponFormScreen> createState() => _CouponFormScreenState();
}

class _CouponFormScreenState extends State<CouponFormScreen> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _maxDCtrl;
  late final TextEditingController _minOCtrl;
  late final TextEditingController _limitCtrl;
  late final TextEditingController _perUserCtrl;
  late final TextEditingController _fromCtrl;
  late final TextEditingController _toCtrl;

  late String _type;
  late String _scope;
  late List<String> _scopeShops;
  late bool _active;

  static const List<String> _availableShops = [
    'SparkleWash Mullackal',
    'AquaShine Thathampally',
    'GleamPro Vazhicherry',
    'BlueWave Komala Rd',
    'ShineHub Iron Bridge',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _codeCtrl = TextEditingController(text: c?.code ?? '');
    _valueCtrl = TextEditingController(text: c != null ? '${c.value}' : '');
    _maxDCtrl = TextEditingController(
        text: c?.maxDiscount != null ? '${c!.maxDiscount}' : '');
    _minOCtrl =
        TextEditingController(text: c != null ? '${c.minOrder}' : '0');
    _limitCtrl =
        TextEditingController(text: c != null ? '${c.usageLimit}' : '');
    _perUserCtrl =
        TextEditingController(text: c != null ? '${c.perUser}' : '1');
    _fromCtrl = TextEditingController(text: c?.validFrom ?? '');
    _toCtrl = TextEditingController(text: c?.validTo ?? '');
    _type = c?.type ?? 'percentage';
    _scope = (c != null && c.scope != 'All shops') ? 'shop' : 'all';
    _scopeShops = List<String>.from(c?.scopeShops ?? []);
    _active = c?.status == 'active';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _maxDCtrl.dispose();
    _minOCtrl.dispose();
    _limitCtrl.dispose();
    _perUserCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _codeCtrl.text.trim().isNotEmpty && _valueCtrl.text.isNotEmpty;

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
                  _FCard(
                    label: 'Code & Discount',
                    children: [
                      _FInput(
                        label: 'Coupon code',
                        controller: _codeCtrl,
                        placeholder: 'e.g. FIRST50',
                        onChanged: (v) {
                          _codeCtrl.value = _codeCtrl.value.copyWith(
                            text: v.toUpperCase(),
                            selection: TextSelection.collapsed(
                                offset: v.length),
                          );
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 14.h),
                      _FieldLabel(text: 'Discount type'),
                      SizedBox(height: 9.h),
                      _SegControl(
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
                            child: _FInput(
                              label: _type == 'percentage'
                                  ? 'Percent'
                                  : 'Amount',
                              controller: _valueCtrl,
                              prefix: _type == 'flat' ? '₹' : '',
                              suffix: _type == 'percentage' ? '%' : '',
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          if (_type == 'percentage') ...[
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _FInput(
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
                      _FInput(
                        label: 'Minimum order',
                        controller: _minOCtrl,
                        prefix: '₹',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  _FCard(
                    label: 'Scope & Limits',
                    children: [
                      _FieldLabel(text: 'Applies to'),
                      SizedBox(height: 9.h),
                      _SegControl(
                        value: _scope,
                        options: const [
                          ('all', 'All shops'),
                          ('shop', 'Specific shop'),
                        ],
                        onChanged: (v) => setState(() => _scope = v),
                      ),
                      if (_scope == 'shop') ...[
                        SizedBox(height: 12.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: _availableShops.map((s) {
                            final active = _scopeShops.contains(s);
                            return AppChip(
                              label: s.split(' ').first,
                              active: active,
                              onTap: () => setState(() {
                                if (active) {
                                  _scopeShops.remove(s);
                                } else {
                                  _scopeShops.add(s);
                                }
                              }),
                            );
                          }).toList(),
                        ),
                      ],
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Expanded(
                            child: _FInput(
                              label: 'Total uses',
                              controller: _limitCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _FInput(
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
                  _FCard(
                    label: 'Validity',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _FInput(
                              label: 'Valid from',
                              controller: _fromCtrl,
                              placeholder: '01-Jun-2026',
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _FInput(
                              label: 'Valid to',
                              controller: _toCtrl,
                              placeholder: '30-Jun-2026',
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
                          _Toggle(
                            on: _active,
                            onTap: () =>
                                setState(() => _active = !_active),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            border: Border(top: BorderSide(color: AppColors.borderSoft)),
          ),
          child: AppButton(
            label: isEdit ? 'Save Changes' : 'Create Coupon',
            full: true,
            disabled: !_valid,
            onPressed: _valid
                ? () {
                    AppToast.show(
                      context,
                      isEdit ? 'Coupon saved' : 'Coupon created',
                    );
                    Navigator.of(context).pop();
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

/// ─── Private helper widgets ───────────────────────────────────────────────

class _FCard extends StatelessWidget {
  const _FCard({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 14.h),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppText.figtree(
        size: 12.5,
        weight: FontWeight.w600,
        color: AppColors.fgSecondary,
      ),
    );
  }
}

class _FInput extends StatelessWidget {
  const _FInput({
    required this.label,
    required this.controller,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.optional = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final String? prefix;
  final String? suffix;
  final TextInputType? keyboardType;
  final bool optional;
  final ValueChanged<String>? onChanged;

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
              SizedBox(width: 4.w),
              Text(
                '(optional)',
                style: AppText.figtree(
                  size: 11,
                  color: AppColors.fgMuted,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 7.h),
        Container(
          height: 46.h,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(11.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              if (prefix != null && prefix!.isNotEmpty) ...[
                SizedBox(width: 12.w),
                Text(
                  prefix!,
                  style: AppText.figtree(
                    size: 14,
                    color: AppColors.fgTertiary,
                  ),
                ),
                SizedBox(width: 4.w),
              ] else
                SizedBox(width: 12.w),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  style: AppText.figtree(size: 14, weight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: AppText.figtree(
                      size: 14,
                      color: AppColors.fgMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (suffix != null && suffix!.isNotEmpty) ...[
                Text(
                  suffix!,
                  style: AppText.figtree(
                    size: 14,
                    color: AppColors.fgTertiary,
                  ),
                ),
                SizedBox(width: 12.w),
              ] else
                SizedBox(width: 12.w),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegControl extends StatelessWidget {
  const _SegControl({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: EdgeInsets.all(3.r),
      child: Row(
        children: options.map((opt) {
          final active = value == opt.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.bgCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: const Color(0x1A000000),
                            blurRadius: 4.r,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  opt.$2,
                  style: AppText.figtree(
                    size: 13.5,
                    weight:
                        active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? AppColors.fgPrimary
                        : AppColors.fgTertiary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46.w,
        height: 26.h,
        decoration: BoxDecoration(
          color: on ? AppColors.brandYellow : AppColors.borderDefault,
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(3.r),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment:
                on ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20.r,
              height: 20.r,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x33000000),
                    blurRadius: 4.r,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

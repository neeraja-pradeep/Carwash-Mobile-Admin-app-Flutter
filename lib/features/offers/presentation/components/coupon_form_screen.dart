import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../domain/entities/coupon.dart';
import 'form_helpers.dart';

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

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _codeCtrl = TextEditingController(text: c?.code ?? '');
    _valueCtrl = TextEditingController(
        text: c != null ? '${c.value}' : '');
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
                            child: OfferFInput(
                              label: 'Valid from',
                              controller: _fromCtrl,
                              placeholder: '01-Jun-2026',
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: OfferFInput(
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
                          OfferToggle(
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

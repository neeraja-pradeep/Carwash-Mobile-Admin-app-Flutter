import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import '../components/payout_filter_sheet.dart';

/// New Payout creation screen — pushed from PayoutsScreen.
class NewPayoutScreen extends StatefulWidget {
  const NewPayoutScreen({super.key});

  @override
  State<NewPayoutScreen> createState() => _NewPayoutScreenState();
}

class _NewPayoutScreenState extends State<NewPayoutScreen> {
  String? _selectedShopId;

  int _fakeNet(String shopId) {
    // Demo: small fixed number per shop for illustration.
    const nets = {'s1': 1876, 's2': 470, 's3': 1108, 's4': 3200, 's5': 2540};
    return nets[shopId] ?? 1200;
  }

  @override
  Widget build(BuildContext context) {
    final fakeNet =
        _selectedShopId != null ? _fakeNet(_selectedShopId!) : 0;
    final shopName = _selectedShopId != null
        ? kDemoShopNames[_selectedShopId!] ?? _selectedShopId!
        : null;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: 'New Payout',
              subtitle: 'Standalone',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SHOP',
                          style: AppText.figtree(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.fgSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Column(
                          children: kDemoShopNames.entries.map((e) {
                            final sel = _selectedShopId == e.key;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedShopId = e.key),
                              child: Container(
                                width: double.infinity,
                                margin: EdgeInsets.only(bottom: 8.h),
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.brandYellow
                                      : AppColors.bgCard,
                                  borderRadius: BorderRadius.circular(11.r),
                                  border: Border.all(
                                    color: sel
                                        ? AppColors.brandYellowDeep
                                        : AppColors.borderSoft,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20.r,
                                      height: 20.r,
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? AppColors.fgPrimary
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: sel
                                            ? null
                                            : Border.all(
                                                color: AppColors.borderStrong,
                                                width: 2),
                                      ),
                                      child: sel
                                          ? Icon(
                                              AppIcons.check,
                                              size: 13.sp,
                                              color: AppColors.brandYellow,
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 11.w),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: AppText.figtree(
                                          size: 13.5,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  if (shopName != null) ...[
                    SizedBox(height: 14.h),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AUTO-CALCULATED',
                            style: AppText.figtree(
                              size: 11,
                              weight: FontWeight.w700,
                              color: AppColors.fgSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Period',
                                style: AppText.figtree(
                                  size: 13,
                                  weight: FontWeight.w500,
                                  color: AppColors.fgTertiary,
                                ),
                              ),
                              Text(
                                'oldest pending – today',
                                style: AppText.figtree(
                                  size: 13.5,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Divider(height: 1.h, color: AppColors.borderSoft),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Net payable',
                                style: AppText.figtree(
                                  size: 14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                Formatters.money(fakeNet),
                                style: AppText.figtree(
                                  size: 18,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Review bookings and adjust on the next screen after saving.',
                            style: AppText.figtree(
                              size: 12,
                              weight: FontWeight.w500,
                              color: AppColors.fgTertiary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border: Border(top: BorderSide(color: AppColors.borderSoft)),
              ),
              child: SafeArea(
                top: false,
                child: AppButton(
                  label: shopName != null
                      ? 'Create Payout · ${Formatters.money(fakeNet)}'
                      : 'Create Payout',
                  full: true,
                  disabled: _selectedShopId == null,
                  onPressed: _selectedShopId == null
                      ? null
                      : () {
                          AppToast.show(context, 'Payout created · Pending');
                          Navigator.of(context).pop();
                        },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

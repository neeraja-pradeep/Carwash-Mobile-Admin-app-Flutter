import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/skeleton_card.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/features/shops/application/providers/shops_providers.dart';
import 'package:new_flutter_project/features/shops/domain/entities/shop.dart';

/// New Payout creation screen — standalone, or pre-filled for a shop when
/// opened from that shop's Settlement tab ("Create Payout for This Shop").
/// Mirrors `prefill.newPayoutFor` in `screen_payouts.jsx`.
class NewPayoutScreen extends ConsumerStatefulWidget {
  const NewPayoutScreen({this.prefillShopId, super.key});

  /// When non-null, this shop is pre-selected and a "pre-filled" banner shows.
  final String? prefillShopId;

  @override
  ConsumerState<NewPayoutScreen> createState() => _NewPayoutScreenState();
}

class _NewPayoutScreenState extends ConsumerState<NewPayoutScreen> {
  String? _selectedShopId;

  @override
  void initState() {
    super.initState();
    _selectedShopId = widget.prefillShopId;
  }

  /// Auto-calculated net preview (matches `fakeNet` in `screen_payouts.jsx`).
  int _fakeNet(Shop shop) =>
      (shop.settlement.lifetimePaid * 0.08 + 1200).round();

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(shopsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: shopsAsync.when(
          loading: () => _Scaffold(
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                const SkeletonCard(),
                SizedBox(height: 14.h),
                const SkeletonCard(),
              ],
            ),
          ),
          error: (_, __) => _Scaffold(
            child: Center(
              child: Text(
                'Could not load shops.',
                style: AppText.figtree(
                  size: 14,
                  weight: FontWeight.w500,
                  color: AppColors.fgMuted,
                ),
              ),
            ),
          ),
          data: (shops) => _buildForm(context, shops),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<Shop> shops) {
    Shop? selected;
    for (final s in shops) {
      if (s.id == _selectedShopId) {
        selected = s;
        break;
      }
    }
    final fakeNet = selected != null ? _fakeNet(selected) : 0;
    final prefilled = widget.prefillShopId != null;

    return Column(
      children: [
        TopBar(
          title: 'New Payout',
          subtitle: prefilled ? 'From shop settlement' : 'Standalone',
          onBack: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            children: [
              if (prefilled && selected != null) ...[
                _PrefillBanner(shopName: selected.name),
                SizedBox(height: 14.h),
              ],
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
                      children: shops.map((s) {
                        final sel = _selectedShopId == s.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedShopId = s.id),
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
                                    s.name,
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
              if (selected != null) ...[
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
              label: selected != null
                  ? 'Create Payout · ${Formatters.money(fakeNet)}'
                  : 'Create Payout',
              full: true,
              disabled: selected == null,
              onPressed: selected == null
                  ? null
                  : () {
                      AppToast.show(context, 'Payout created · Pending');
                      Navigator.of(context).pop();
                    },
            ),
          ),
        ),
      ],
    );
  }
}

/// Blue "pre-filled for shop" banner shown when opened from a shop settlement.
class _PrefillBanner extends StatelessWidget {
  const _PrefillBanner({required this.shopName});

  final String shopName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.checkCircle, size: 18.sp, color: AppColors.blueFg),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppText.figtree(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: AppColors.blueFg,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Pre-filled for '),
                  TextSpan(
                    text: shopName,
                    style: AppText.figtree(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: AppColors.blueFg,
                    ),
                  ),
                  const TextSpan(text: ' · oldest pending → today.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// TopBar + scrollable body scaffold for the loading / error views.
class _Scaffold extends StatelessWidget {
  const _Scaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          title: 'New Payout',
          onBack: () => Navigator.of(context).pop(),
        ),
        Expanded(child: child),
      ],
    );
  }
}

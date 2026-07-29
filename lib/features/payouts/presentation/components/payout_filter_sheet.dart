import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_bottom_sheet.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/features/shops/application/providers/shops_providers.dart';
import '../../application/providers/payouts_providers.dart';

/// Opens the payouts filter bottom sheet.
Future<void> showPayoutFilterSheet(BuildContext context, WidgetRef ref) async {
  await showAppBottomSheet<void>(
    context: context,
    title: 'Filter payouts',
    footer: _FilterFooter(),
    builder: (ctx) => _FilterBody(),
  );
}

class _FilterFooter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(payoutLogFilterProvider.notifier);
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Reset',
            kind: AppButtonKind.secondary,
            full: true,
            onPressed: () {
              controller.reset();
              Navigator.of(context).pop();
            },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: AppButton(
            label: 'Apply filters',
            full: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _FilterBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(payoutLogFilterProvider);
    final controller = ref.read(payoutLogFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATE',
          style: AppText.figtree(
            size: 11,
            weight: FontWeight.w700,
            color: AppColors.fgSecondary,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 9.w,
          runSpacing: 9.h,
          children: [
            for (final d in const [
              ('any', 'All time'),
              ('7', 'Last 7 days'),
              ('30', 'Last 30 days'),
              ('90', 'Last 90 days'),
            ])
              AppChip(
                label: d.$2,
                active: filter.date == d.$1,
                onTap: () => controller.setDate(d.$1),
              ),
          ],
        ),
        SizedBox(height: 22.h),
        Text(
          'STATUS',
          style: AppText.figtree(
            size: 11,
            weight: FontWeight.w700,
            color: AppColors.fgSecondary,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 9.w,
          runSpacing: 9.h,
          children: [
            AppChip(
              label: 'Pending',
              active: filter.status == 'pending',
              onTap: () => controller.apply(
                filter.copyWith(
                    status: filter.status == 'pending' ? null : 'pending'),
              ),
            ),
            AppChip(
              label: 'Paid',
              active: filter.status == 'paid',
              onTap: () => controller.apply(
                filter.copyWith(
                    status: filter.status == 'paid' ? null : 'paid'),
              ),
            ),
          ],
        ),
        SizedBox(height: 22.h),
        Text(
          'SHOP',
          style: AppText.figtree(
            size: 11,
            weight: FontWeight.w700,
            color: AppColors.fgSecondary,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 12.h),
        ref.watch(shopsProvider).when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (shops) => Wrap(
                spacing: 9.w,
                runSpacing: 9.h,
                children: shops.map((s) {
                  final shopIdStr = s.id.toString();
                  final active = filter.shop == shopIdStr;
                  return AppChip(
                    label: s.name.split(' ').first,
                    active: active,
                    onTap: () => controller.apply(
                      filter.copyWith(shop: active ? null : shopIdStr),
                    ),
                  );
                }).toList(),
              ),
            ),
        SizedBox(height: 8.h),
      ],
    );
  }
}

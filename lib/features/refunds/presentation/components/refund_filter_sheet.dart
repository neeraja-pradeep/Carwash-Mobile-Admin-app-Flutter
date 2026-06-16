import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_bottom_sheet.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import '../../application/providers/refunds_providers.dart';
import '../../application/states/refunds_filter_state.dart';

const List<String> kRefundReasons = [
  'Cancellation by customer',
  'Founder cancellation',
  'Service quality issue',
  'Damage during wash',
  'Duplicate charge',
  'Other',
];

const Map<String, String> kRefundStatusLabels = {
  'requested': 'Requested',
  'approved': 'Approved',
  'paid': 'Paid',
  'declined': 'Declined',
};

/// Opens the refunds filter bottom sheet.
Future<void> showRefundFilterSheet(BuildContext context, WidgetRef ref) async {
  await showAppBottomSheet<void>(
    context: context,
    title: 'Filter refunds',
    footer: _FilterFooter(),
    builder: (ctx) => _FilterBody(),
  );
}

class _FilterFooter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(refundsFilterProvider.notifier);
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
    final filter = ref.watch(refundsFilterProvider);
    final controller = ref.read(refundsFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          children: kRefundStatusLabels.entries.map((e) {
            final active = filter.status == e.key;
            return AppChip(
              label: e.value,
              active: active,
              onTap: () => controller.apply(
                filter.copyWith(status: active ? null : e.key),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 22.h),
        Text(
          'REASON',
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
          children: kRefundReasons.map((r) {
            final active = filter.reason == r;
            return AppChip(
              label: r,
              active: active,
              onTap: () => controller.apply(
                filter.copyWith(reason: active ? null : r),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }
}

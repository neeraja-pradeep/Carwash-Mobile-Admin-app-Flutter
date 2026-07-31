import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_bottom_sheet.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/app/theme/colors.dart';

import '../../application/providers/drivers_providers.dart';
import '../../application/states/drivers_filter_state.dart';
import '../../domain/entities/field_driver.dart';

/// Opens the Drivers filter sheet (status only in MVP).
Future<void> showDriversFilterSheet(BuildContext context, WidgetRef ref) {
  ref.read(driversFilterDraftProvider.notifier).state =
      ref.read(driversFilterProvider);
  return showAppBottomSheet<void>(
    context: context,
    title: 'Filter drivers',
    builder: (_) => const _DriversFilterBody(),
    footer: const _DriversFilterFooter(),
    maxHeightFactor: 0.56,
  );
}

class _DriversFilterBody extends ConsumerWidget {
  const _DriversFilterBody();

  static const List<(DriverStatus?, String)> _statuses = [
    (DriverStatus.online, 'Online'),
    (DriverStatus.offline, 'Offline'),
    (DriverStatus.invited, 'Invited'),
    (DriverStatus.suspended, 'Suspended'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(driversFilterDraftProvider);

    void update(DriversFilterState next) =>
        ref.read(driversFilterDraftProvider.notifier).state = next;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATUS',
          style: AppText.figtree(
            size: 11,
            weight: FontWeight.w700,
            color: AppColors.fgSecondary,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 9.w,
          runSpacing: 9.h,
          children: [
            for (final s in _statuses)
              AppChip(
                label: s.$2,
                active: draft.status == s.$1,
                onTap: () => update(
                  DriversFilterState(
                    status: draft.status == s.$1 ? null : s.$1,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DriversFilterFooter extends ConsumerWidget {
  const _DriversFilterFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Reset',
            kind: AppButtonKind.secondary,
            full: true,
            onPressed: () =>
                ref.read(driversFilterDraftProvider.notifier).state =
                    const DriversFilterState(),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: AppButton(
            label: 'Apply filters',
            full: true,
            onPressed: () {
              ref
                  .read(driversFilterProvider.notifier)
                  .apply(ref.read(driversFilterDraftProvider));
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}

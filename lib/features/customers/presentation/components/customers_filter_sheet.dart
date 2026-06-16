import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../application/providers/customers_providers.dart';
import '../../application/states/customers_filter_state.dart';

/// Opens the Customers filter sheet (status / joined / booking count). The
/// draft lives in [customersFilterDraftProvider] so the pinned footer can
/// apply it.
Future<void> showCustomersFilterSheet(BuildContext context, WidgetRef ref) {
  // Seed the draft from the committed filter each time we open.
  ref.read(customersFilterDraftProvider.notifier).state =
      ref.read(customersFilterProvider);
  return showAppBottomSheet<void>(
    context: context,
    title: 'Filter customers',
    builder: (_) => const _CustomersFilterBody(),
    footer: const _CustomersFilterFooter(),
  );
}

class _CustomersFilterBody extends ConsumerWidget {
  const _CustomersFilterBody();

  static const List<(String?, String)> _statuses = [
    ('active', 'Active'),
    ('blocked', 'Blocked'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(customersFilterDraftProvider);

    void update(CustomersFilterState next) =>
        ref.read(customersFilterDraftProvider.notifier).state = next;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Group(
          label: 'Status',
          children: [
            for (final s in _statuses)
              AppChip(
                label: s.$2,
                active: draft.status == s.$1,
                onTap: () => update(
                  draft.copyWith(
                    status: draft.status == s.$1 ? null : s.$1,
                  ),
                ),
              ),
          ],
        ),
        _Group(
          label: 'Joined',
          children: [
            for (final opt in kJoinedOpts)
              AppChip(
                label: opt.$2,
                active: draft.joined == opt.$1,
                onTap: () => update(draft.copyWith(joined: opt.$1)),
              ),
          ],
        ),
        _Group(
          label: 'Booking count',
          children: [
            for (final opt in kVolumeOpts)
              AppChip(
                label: opt.$2,
                active: draft.volume == opt.$1,
                onTap: () => update(draft.copyWith(volume: opt.$1)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 22.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppText.eyebrow),
          SizedBox(height: 12.h),
          Wrap(spacing: 9.w, runSpacing: 9.h, children: children),
        ],
      ),
    );
  }
}

class _CustomersFilterFooter extends ConsumerWidget {
  const _CustomersFilterFooter();

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
                ref.read(customersFilterDraftProvider.notifier).state =
                    const CustomersFilterState(),
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
                  .read(customersFilterProvider.notifier)
                  .apply(ref.read(customersFilterDraftProvider));
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/constants/app_options.dart';
import 'package:new_flutter_project/core/widgets/widgets.dart';

import '../../application/providers/shops_providers.dart';
import '../../application/states/shops_filter_state.dart';

/// Rating options for the filter sheet (matches JSX RATING_OPTS).
const List<(String, String)> kRatingOpts = [
  ('any', 'Any rating'),
  ('4.5', '4.5+'),
  ('4.0', '4.0+'),
  ('3.5', '3.5+'),
];

/// Shows the shops filter bottom sheet. The draft is seeded from the committed
/// filter; Apply commits it; Reset clears to defaults.
void showShopsFilterSheet(BuildContext context, WidgetRef ref) {
  // Seed the draft from the current committed state.
  ref.read(shopsFilterDraftProvider.notifier).state =
      ref.read(shopsFilterProvider);

  showAppBottomSheet<void>(
    context: context,
    title: 'Filter shops',
    footer: _SheetFooter(),
    builder: (_) => _ShopsFilterBody(),
  );
}

class _ShopsFilterBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(shopsFilterDraftProvider);
    final notifier = ref.read(shopsFilterDraftProvider.notifier);

    void setDraft(ShopsFilterState next) => notifier.state = next;
    void toggleType(String t) {
      final types = draft.types.contains(t)
          ? draft.types.where((x) => x != t).toList()
          : [...draft.types, t];
      setDraft(draft.copyWith(types: types));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status
        _FilterGroup(
          label: 'Status',
          child: Row(
            children: [
              for (final (k, l) in [('active', 'Active'), ('inactive', 'Inactive')])
                Padding(
                  padding: EdgeInsets.only(right: 9.w),
                  child: AppChip(
                    label: l,
                    active: draft.status == k,
                    onTap: () => setDraft(
                      draft.copyWith(
                        status: draft.status == k ? null : k,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 22.h),
        // Vehicle types
        _FilterGroup(
          label: 'Vehicle types supported',
          child: Wrap(
            spacing: 9.w,
            runSpacing: 9.h,
            children: [
              for (final t in kVehicleTypes)
                AppChip(
                  label: t,
                  active: draft.types.contains(t),
                  onTap: () => toggleType(t),
                ),
            ],
          ),
        ),
        SizedBox(height: 22.h),
        // Rating
        _FilterGroup(
          label: 'Rating',
          child: Wrap(
            spacing: 9.w,
            runSpacing: 9.h,
            children: [
              for (final (k, l) in kRatingOpts)
                AppChip(
                  label: l,
                  active: draft.rating == k,
                  onTap: () => setDraft(draft.copyWith(rating: k)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetFooter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Reset',
            kind: AppButtonKind.secondary,
            full: true,
            onPressed: () {
              ref.read(shopsFilterDraftProvider.notifier).state =
                  const ShopsFilterState();
            },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: AppButton(
            label: 'Apply filters',
            full: true,
            onPressed: () {
              final draft = ref.read(shopsFilterDraftProvider);
              ref.read(shopsFilterProvider.notifier).apply(draft);
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        SizedBox(height: 12.h),
        child,
      ],
    );
  }
}

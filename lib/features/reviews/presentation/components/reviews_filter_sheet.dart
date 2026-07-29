import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../application/providers/reviews_providers.dart';
import '../../application/states/reviews_filter_state.dart';

/// Opens the Reviews filter sheet (rating / shop / content). The draft
/// lives in [reviewsFilterDraftProvider] so the pinned footer can apply it.
Future<void> showReviewsFilterSheet(BuildContext context, WidgetRef ref) {
  // Seed the draft from the committed filter each time we open.
  ref.read(reviewsFilterDraftProvider.notifier).state =
      ref.read(reviewsFilterProvider);
  return showAppBottomSheet<void>(
    context: context,
    title: 'Filter reviews',
    builder: (_) => const _ReviewsFilterBody(),
    footer: const _ReviewsFilterFooter(),
  );
}

class _ReviewsFilterBody extends ConsumerWidget {
  const _ReviewsFilterBody();

  static const List<(String, String)> _ratings = [
    ('any', 'Any'),
    ('5', '5★ only'),
    ('4', '4★ & up'),
    ('3', '3★ & up'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(reviewsFilterDraftProvider);
    final shops = ref
            .watch(reviewsProvider)
            .value
            ?.reviews
            .map((r) => r.shop)
            .toSet()
            .toList() ??
        const <String>[];

    void update(ReviewsFilterState next) =>
        ref.read(reviewsFilterDraftProvider.notifier).state = next;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Group(
          label: 'Rating',
          children: [
            for (final r in _ratings)
              AppChip(
                label: r.$2,
                active: draft.rating == r.$1,
                onTap: () => update(draft.copyWith(rating: r.$1)),
              ),
          ],
        ),
        _Group(
          label: 'Shop',
          children: [
            for (final shop in shops)
              AppChip(
                label: shop.split(' ').first,
                active: draft.shops.contains(shop),
                onTap: () => update(
                  draft.copyWith(
                    shops: draft.shops.contains(shop)
                        ? (draft.shops.where((s) => s != shop).toList())
                        : [...draft.shops, shop],
                  ),
                ),
              ),
          ],
        ),
        _Group(
          label: 'Content',
          children: [
            AppChip(
              label: 'Has written review',
              active: draft.hasText,
              onTap: () => update(draft.copyWith(hasText: !draft.hasText)),
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

class _ReviewsFilterFooter extends ConsumerWidget {
  const _ReviewsFilterFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Reset',
            kind: AppButtonKind.secondary,
            full: true,
            onPressed: () => ref.read(reviewsFilterDraftProvider.notifier).state =
                const ReviewsFilterState(),
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
                  .read(reviewsFilterProvider.notifier)
                  .apply(ref.read(reviewsFilterDraftProvider));
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}

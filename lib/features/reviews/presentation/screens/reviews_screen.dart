import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/error/error_view.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/list_controls.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/reviews_providers.dart';
import '../components/review_card.dart';
import '../components/reviews_filter_sheet.dart';
import 'review_detail_screen.dart';

/// Reviews list — search, filter sheet, sort and tap-through to detail.
/// Canonical reference for the project's list screens.
class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  static const List<SortOption> sortOptions = [
    ('recent', 'Most recent'),
    ('rating_hi', 'Rating: high → low'),
    ('rating_lo', 'Rating: low → high'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reviewsFilterProvider);
    final controller = ref.read(reviewsFilterProvider.notifier);
    final filtered = ref.watch(filteredReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: 'Reviews',
              // Tracks the selected window — it used to read "Last 7 days"
              // even after the sheet switched to 30 days / all time.
              subtitle: filter.dateLabel,
              onBack: () => context.pop(),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
              ),
              child: SearchField(
                value: filter.query,
                hintText: 'Search customer or shop',
                onChanged: controller.setQuery,
              ),
            ),
            if (filter.activeCount > 0) _ActiveChips(),
            Expanded(
              child: filtered.when(
                loading: () => ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: 4,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, __) => const SkeletonCard(),
                ),
                error: (_, __) => ErrorView(
                  onRetry: () => ref.invalidate(reviewsProvider),
                ),
                data: (reviews) {
                  if (reviews.isEmpty) {
                    // Three different reasons for an empty list, three
                    // different fixes — telling an admin to clear filters they
                    // never set (and offering a reset that restores the same
                    // date window) is a dead end.
                    if (filter.hasUserFilter) {
                      return EmptyState(
                        icon: AppIcons.message,
                        title: 'No reviews match',
                        body: 'Try clearing your search or filters.',
                        actionLabel: 'Reset filters',
                        onAction: controller.reset,
                      );
                    }
                    if (filter.isDateLimited) {
                      return EmptyState(
                        icon: AppIcons.message,
                        title: 'No reviews in the '
                            '${filter.dateLabel.toLowerCase()}',
                        body: 'This list is scoped to the '
                            '${filter.dateLabel.toLowerCase()}. '
                            'Older reviews are still there.',
                        actionLabel: 'Show all time',
                        onAction: () => controller.setDate('any'),
                      );
                    }
                    return EmptyState(
                      icon: AppIcons.message,
                      title: 'No reviews yet',
                      body: 'Customer reviews will show up here once they '
                          'start rating their washes.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(reviewsProvider);
                      await ref.read(reviewsProvider.future);
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(16.r),
                      itemCount: reviews.length + 1,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return ListControls(
                            count: reviews.length,
                            noun: 'review',
                            onFilter: () =>
                                showReviewsFilterSheet(context, ref),
                            filterCount: filter.activeCount,
                            sort: filter.sort,
                            sortOptions: sortOptions,
                            onSort: controller.setSort,
                          );
                        }
                        final review = reviews[index - 1];
                        return ReviewCard(
                          review: review,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ReviewDetailScreen(review: review),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reviewsFilterProvider);
    final controller = ref.read(reviewsFilterProvider.notifier);

    final chips = <Widget>[
      if (filter.rating != 'any')
        AppChip(
          label: filter.rating == '5' ? '5★' : '${filter.rating}★ & up',
          active: true,
          removable: true,
          onRemove: controller.removeRating,
        ),
      for (final shop in filter.shops)
        AppChip(
          label: shop.split(' ').first,
          active: true,
          removable: true,
          onRemove: () => controller.removeShop(shop),
        ),
      if (filter.hasText)
        AppChip(
          label: 'Has text',
          active: true,
          removable: true,
          onRemove: controller.removeHasText,
        ),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.bgPage,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 2.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final chip in chips) ...[chip, SizedBox(width: 8.w)],
            GestureDetector(
              onTap: controller.reset,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Text(
                  'Clear all',
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: AppColors.fgSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

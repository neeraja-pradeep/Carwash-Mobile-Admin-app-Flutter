import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/router/app_router.dart';
import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/core/widgets/widgets.dart';

import '../../application/providers/shops_providers.dart';
import '../components/shop_card.dart';
import '../components/shops_filter_sheet.dart';

/// Shops list screen — search, ListControls filter+sort, FAB add-shop,
/// card tap → shop detail. Mirrors `ShopsScreen` in `screen_shops.jsx`.
class ShopsScreen extends ConsumerWidget {
  const ShopsScreen({super.key});

  static const List<SortOption> _sortOptions = [
    ('name', 'Name A–Z'),
    ('rating', 'Rating: high → low'),
    ('busy', 'Busiest today'),
    ('cap', 'Capacity used'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(shopsFilterProvider);
    final controller = ref.read(shopsFilterProvider.notifier);
    final filtered = ref.watch(filteredShopsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                TopBar(
                  title: 'Shops',
                  onBack: () => context.pop(),
                ),
                // Search bar
                Container(
                  padding:
                      EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
                  decoration: const BoxDecoration(
                    color: AppColors.bgCard,
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderSoft),
                    ),
                  ),
                  child: SearchField(
                    value: filter.query,
                    hintText: 'Search shop name or area',
                    onChanged: controller.setQuery,
                  ),
                ),
                // Active filter chips
                if (filter.activeCount > 0) _ActiveChips(),
                Expanded(
                  child: filtered.when(
                    loading: () => ListView.separated(
                      padding: EdgeInsets.all(16.r),
                      itemCount: 3,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (_, __) => const SkeletonCard(),
                    ),
                    error: (_, __) => ErrorView(
                      onRetry: () => ref.invalidate(shopsProvider),
                    ),
                    data: (shops) {
                      if (shops.isEmpty) {
                        return EmptyState(
                          icon: AppIcons.store,
                          title: 'No shops match',
                          body: 'Try clearing your search or filters.',
                          actionLabel: 'Reset filters',
                          onAction: controller.reset,
                        );
                      }
                      return ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          16.w, 16.h, 16.w, 96.h,
                        ),
                        itemCount: shops.length + 1,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (ctx, index) {
                          if (index == 0) {
                            return ListControls(
                              count: shops.length,
                              noun: 'shop',
                              onFilter: () =>
                                  showShopsFilterSheet(ctx, ref),
                              filterCount: filter.activeCount,
                              sort: filter.sort,
                              sortOptions: _sortOptions,
                              onSort: controller.setSort,
                            );
                          }
                          final shop = shops[index - 1];
                          return ShopCard(
                            shop: shop,
                            onTap: () => context
                                .push(Routes.shopDetail(shop.id)),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            // FAB
            Positioned(
              right: 18.w,
              bottom: 24.h,
              child: AppFab(
                onPressed: () => context.push(Routes.addShop),
                icon: AppIcons.plus,
                semanticLabel: 'Add shop',
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
    final filter = ref.watch(shopsFilterProvider);
    final controller = ref.read(shopsFilterProvider.notifier);

    final chips = <Widget>[
      if (filter.status != null)
        AppChip(
          label: filter.status == 'active' ? 'Active' : 'Inactive',
          active: true,
          removable: true,
          onRemove: controller.removeStatus,
        ),
      for (final t in filter.types)
        AppChip(
          label: t,
          active: true,
          removable: true,
          onRemove: () => controller.removeType(t),
        ),
      if (filter.rating != 'any')
        AppChip(
          label: '${filter.rating}+',
          active: true,
          removable: true,
          onRemove: controller.removeRating,
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
              onTap: () {
                controller.reset();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Text(
                  'Clear all',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
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

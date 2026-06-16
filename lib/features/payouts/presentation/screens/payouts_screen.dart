import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/core/widgets/app_fab.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/empty_state.dart';
import 'package:new_flutter_project/core/widgets/list_controls.dart';
import 'package:new_flutter_project/core/widgets/search_field.dart';
import 'package:new_flutter_project/core/widgets/skeleton_card.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import '../../application/providers/payouts_providers.dart';
import '../../application/states/payouts_filter_state.dart';
import '../../domain/entities/payout.dart';
import '../components/payout_card.dart';
import '../components/payout_filter_sheet.dart';
import 'payout_detail_screen.dart';
import 'new_payout_screen.dart';

/// Payout Log list screen — module entry-point.
class PayoutsScreen extends ConsumerWidget {
  const PayoutsScreen({super.key});

  static const List<SortOption> _sortOptions = [
    ('recent', 'Most recent'),
    ('net_hi', 'Net: high → low'),
    ('net_lo', 'Net: low → high'),
    ('shop', 'Shop A–Z'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(payoutsFilterProvider);
    final controller = ref.read(payoutsFilterProvider.notifier);
    final payoutsAsync = ref.watch(payoutsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                TopBar(
                  title: 'Payout Log',
                  subtitle: 'Last 90 days',
                  onBack: () => context.pop(),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
                  decoration: const BoxDecoration(
                    color: AppColors.bgCard,
                    border: Border(
                        bottom: BorderSide(color: AppColors.borderSoft)),
                  ),
                  child: SearchField(
                    value: filter.query,
                    hintText: 'Search shop or UTR',
                    onChanged: controller.setQuery,
                  ),
                ),
                if (filter.activeCount > 0) _ActiveChips(),
                Expanded(
                  child: payoutsAsync.when(
                    loading: () => ListView.separated(
                      padding: EdgeInsets.all(16.r),
                      itemCount: 3,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (_, __) => const SkeletonCard(),
                    ),
                    error: (_, __) => EmptyState(
                      icon: AppIcons.wallet,
                      title: 'Could not load payouts',
                      body: 'Please try again.',
                      actionLabel: 'Retry',
                      onAction: () => ref.invalidate(payoutsProvider),
                    ),
                    data: (allPayouts) {
                      final payouts = _applyFilter(allPayouts, filter);
                      if (payouts.isEmpty) {
                        return EmptyState(
                          icon: AppIcons.wallet,
                          title: 'No payouts match',
                          body:
                              'Try clearing your search or filters.',
                          actionLabel: 'Reset filters',
                          onAction: controller.reset,
                        );
                      }
                      return ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                            16.w, 16.h, 16.w, 100.h),
                        itemCount: payouts.length + 1,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (ctx, index) {
                          if (index == 0) {
                            return ListControls(
                              count: payouts.length,
                              noun: 'payout',
                              onFilter: () =>
                                  showPayoutFilterSheet(ctx, ref),
                              filterCount: filter.activeCount,
                              sort: filter.sort,
                              sortOptions: _sortOptions,
                              onSort: controller.setSort,
                            );
                          }
                          final p = payouts[index - 1];
                          return PayoutCard(
                            payout: p,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PayoutDetailScreen(
                                    payoutId: p.id),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              right: 18.w,
              bottom: 24.h,
              child: AppFab(
                semanticLabel: 'New payout',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NewPayoutScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Payout> _applyFilter(List<Payout> all, PayoutsFilterState f) {
    final shopNameFn = (String id) => kDemoShopNames[id] ?? id;
    return applyPayoutFilter(all, f, shopName: shopNameFn);
  }
}

class _ActiveChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(payoutsFilterProvider);
    final controller = ref.read(payoutsFilterProvider.notifier);

    return Container(
      width: double.infinity,
      color: AppColors.bgPage,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 2.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (filter.status != null) ...[
              AppChip(
                label: filter.status == 'paid' ? 'Paid' : 'Pending',
                active: true,
                removable: true,
                onRemove: controller.removeStatus,
              ),
              SizedBox(width: 8.w),
            ],
            if (filter.shopId != null) ...[
              AppChip(
                label: (kDemoShopNames[filter.shopId!] ?? filter.shopId!)
                    .split(' ')
                    .first,
                active: true,
                removable: true,
                onRemove: controller.removeShop,
              ),
              SizedBox(width: 8.w),
            ],
          ],
        ),
      ),
    );
  }
}

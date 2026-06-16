import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
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
import '../../application/providers/customers_providers.dart';
import '../../application/states/customers_filter_state.dart';
import '../components/customer_card.dart';
import '../components/customers_filter_sheet.dart';

/// Customers list screen — search, filter sheet, sort, card tap → detail.
///
/// This is a bottom-nav tab; the [TopBar] has no back button.
class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(customersFilterProvider);
    final controller = ref.read(customersFilterProvider.notifier);
    final filtered = ref.watch(filteredCustomersProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar (no back — bottom-nav tab) ─────────────────────────
            const TopBar(title: 'Customers'),

            // ── Search bar ─────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSoft),
                ),
              ),
              child: SearchField(
                value: filter.query,
                hintText: 'Search name or phone',
                onChanged: controller.setQuery,
              ),
            ),

            // ── Active filter chips ────────────────────────────────────────
            if (filter.activeCount > 0) _ActiveChips(),

            // ── List / skeleton / empty ────────────────────────────────────
            Expanded(
              child: filtered.when(
                loading: () => ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: 4,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, __) => const SkeletonCard(),
                ),
                error: (_, __) => ErrorView(
                  onRetry: () => ref.invalidate(customersProvider),
                ),
                data: (customers) {
                  if (customers.isEmpty) {
                    return EmptyState(
                      icon: AppIcons.users,
                      title: 'No customers match',
                      body: 'Try clearing your search or filters.',
                      actionLabel: 'Reset filters',
                      onAction: () {
                        controller.reset();
                      },
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.all(16.r),
                    itemCount: customers.length + 2,
                    separatorBuilder: (_, index) =>
                        index == 0 ? const SizedBox.shrink() : SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListControls(
                          count: customers.length,
                          noun: 'customer',
                          onFilter: () =>
                              showCustomersFilterSheet(context, ref),
                          filterCount: filter.activeCount,
                          sort: filter.sort,
                          sortOptions: kCustomerSortOpts,
                          onSort: controller.setSort,
                        );
                      }
                      if (index == customers.length + 1) {
                        return SizedBox(height: 8.h);
                      }
                      final customer = customers[index - 1];
                      return CustomerCard(
                        customer: customer,
                        onTap: () =>
                            context.push(Routes.customerDetail(customer.id)),
                      );
                    },
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
    final filter = ref.watch(customersFilterProvider);
    final controller = ref.read(customersFilterProvider.notifier);

    final chips = <Widget>[
      if (filter.status != null)
        AppChip(
          label: filter.status == 'active' ? 'Active' : 'Blocked',
          active: true,
          removable: true,
          onRemove: controller.removeStatus,
        ),
      if (filter.joined != 'any')
        AppChip(
          label: kJoinedOpts
              .firstWhere((o) => o.$1 == filter.joined)
              .$2,
          active: true,
          removable: true,
          onRemove: controller.removeJoined,
        ),
      if (filter.volume != 'any')
        AppChip(
          label: '${kVolumeOpts.firstWhere((o) => o.$1 == filter.volume).$2}'
              ' bookings',
          active: true,
          removable: true,
          onRemove: controller.removeVolume,
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

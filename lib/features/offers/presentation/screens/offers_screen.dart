import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/error/error_view.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_fab.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/list_controls.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/providers/offers_providers.dart';
import '../../application/states/offers_filter_state.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/entities/offer_banner.dart';
import '../components/banner_card.dart';
import '../components/banner_form_screen.dart';
import '../components/coupon_card.dart';
import '../components/coupon_form_screen.dart';

/// Offers module — Coupons / Banners tab screen.
///
/// Navigation: TopBar back → context.pop (go_router).
/// Intra-module forms pushed via [Navigator.of(context).push].
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  static const List<SortOption> _sortOptions = [
    ('recent', 'Most recent'),
    ('az', 'A–Z'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(offersTabProvider);
    final filter = ref.watch(offersFilterProvider);
    final controller = ref.read(offersFilterProvider.notifier);
    final tabNotifier = ref.read(offersTabProvider.notifier);

    final couponsAsync = ref.watch(couponsProvider);
    final bannersAsync = ref.watch(bannersProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar
                TopBar(
                  title: 'Offers',
                  onBack: () => context.pop(),
                ),
                // Tab toggle — Coupons | Banners
                _TabBar(
                  current: tab,
                  onSelect: (t) {
                    tabNotifier.state = t;
                    controller.reset();
                  },
                ),
                // Search bar
                Container(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
                  decoration: const BoxDecoration(
                    color: AppColors.bgCard,
                    border:
                        Border(bottom: BorderSide(color: AppColors.borderSoft)),
                  ),
                  child: SearchField(
                    value: filter.query,
                    hintText: tab == 'coupons'
                        ? 'Search code or description'
                        : 'Search banner title',
                    onChanged: controller.setQuery,
                  ),
                ),
                // List area
                Expanded(
                  child: tab == 'coupons'
                      ? _CouponsList(
                          async: couponsAsync,
                          filter: filter,
                          controller: controller,
                          sortOptions: _sortOptions,
                        )
                      : _BannersList(
                          async: bannersAsync,
                          filter: filter,
                          controller: controller,
                          sortOptions: _sortOptions,
                        ),
                ),
              ],
            ),
            // FAB
            Positioned(
              right: 18.w,
              bottom: 24.h,
              child: AppFab(
                semanticLabel: tab == 'coupons' ? 'New Coupon' : 'New Banner',
                onPressed: () {
                  if (tab == 'coupons') {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CouponFormScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BannerFormScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab bar ─────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onSelect});

  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          for (final (key, label) in [
            ('coupons', 'Coupons'),
            ('banners', 'Banners'),
          ])
            _TabItem(
              label: label,
              active: current == key,
              onTap: () => onSelect(key),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0, 13.h, 0, 13.h),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.figtree(
                  size: 14,
                  weight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? AppColors.fgPrimary : AppColors.fgTertiary,
                ),
              ),
            ),
            if (active)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.4,
                    child: Container(
                      height: 2.5.h,
                      decoration: BoxDecoration(
                        color: AppColors.brandYellowDeep,
                        borderRadius: BorderRadius.circular(99.r),
                      ),
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

// ─── Coupons list ─────────────────────────────────────────────────────────────

class _CouponsList extends ConsumerWidget {
  const _CouponsList({
    required this.async,
    required this.filter,
    required this.controller,
    required this.sortOptions,
  });

  final AsyncValue<List<Coupon>> async;
  final OffersFilterState filter;
  final OffersFilterController controller;
  final List<SortOption> sortOptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      loading: () => ListView.separated(
        padding: EdgeInsets.all(16.r),
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, __) => const SkeletonCard(),
      ),
      error: (_, __) => ErrorView(
        onRetry: () => ref.invalidate(couponsProvider),
      ),
      data: (coupons) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(couponsProvider);
            await ref.read(couponsProvider.future);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
            itemCount: coupons.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    ListControls(
                      count: coupons.length,
                      noun: 'coupon',
                      onFilter: () => _showFilterSheet(context),
                      filterCount: filter.activeFilterCount,
                      sort: filter.sort,
                      sortOptions: sortOptions,
                      onSort: controller.setSort,
                    ),
                    if (coupons.isEmpty)
                      EmptyState(
                        icon: AppIcons.tag,
                        title: 'No coupons',
                        body: 'Create your first coupon.',
                      ),
                  ],
                );
              }
              final c = coupons[index - 1];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: CouponCard(
                  coupon: c,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CouponFormScreen(coupon: c),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Filter coupons',
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Reset',
              kind: AppButtonKind.secondary,
              full: true,
              onPressed: controller.reset,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Apply filters',
              full: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      builder: (_) => _StatusFilter(
        statuses: const {
          'active': 'Active',
          'scheduled': 'Scheduled',
          'paused': 'Paused',
          'expired': 'Expired',
        },
        current: filter.status,
        onChanged: controller.setStatus,
      ),
    );
  }
}

// ─── Banners list ─────────────────────────────────────────────────────────────

class _BannersList extends ConsumerWidget {
  const _BannersList({
    required this.async,
    required this.filter,
    required this.controller,
    required this.sortOptions,
  });

  final AsyncValue<List<OfferBanner>> async;
  final OffersFilterState filter;
  final OffersFilterController controller;
  final List<SortOption> sortOptions;

  /// Search, status and order are applied by `/promotions/` itself — filtering
  /// again here would only ever narrow the page already fetched. Kept as a
  /// pass-through so the list body below reads the same as the coupons tab.
  List<OfferBanner> _apply(List<OfferBanner> all) => all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      loading: () => ListView.separated(
        padding: EdgeInsets.all(16.r),
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, __) => const SkeletonCard(),
      ),
      error: (_, __) => ErrorView(
        onRetry: () => ref.invalidate(bannersProvider),
      ),
      data: (all) {
        final banners = _apply(all);
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(bannersProvider);
            await ref.read(bannersProvider.future);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
            itemCount: banners.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    ListControls(
                      count: banners.length,
                      noun: 'banner',
                      onFilter: () => _showFilterSheet(context),
                      filterCount: filter.activeFilterCount,
                      sort: filter.sort,
                      sortOptions: sortOptions,
                      onSort: controller.setSort,
                    ),
                    if (banners.isEmpty)
                      EmptyState(
                        icon: AppIcons.tag,
                        title: 'No banners',
                        body: 'Create your first banner.',
                      ),
                  ],
                );
              }
              final b = banners[index - 1];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: BannerCard(
                  banner: b,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BannerFormScreen(banner: b),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Filter banners',
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Reset',
              kind: AppButtonKind.secondary,
              full: true,
              onPressed: controller.reset,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Apply filters',
              full: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      builder: (_) => _StatusFilter(
        statuses: const {
          'active': 'Active',
          'scheduled': 'Scheduled',
          'inactive': 'Inactive',
        },
        current: filter.status,
        onChanged: controller.setStatus,
      ),
    );
  }
}

// ─── Shared filter sheet body ─────────────────────────────────────────────────

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.statuses,
    required this.current,
    required this.onChanged,
  });

  final Map<String, String> statuses;
  final String? current;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
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
          children: statuses.entries.map((e) {
            final active = current == e.key;
            return AppChip(
              label: e.value,
              active: active,
              onTap: () => onChanged(active ? null : e.key),
            );
          }).toList(),
        ),
      ],
    );
  }
}

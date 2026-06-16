import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/status/booking_status.dart';
import 'package:new_flutter_project/core/widgets/app_bottom_sheet.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/features/shops/application/providers/shops_providers.dart';

import '../../application/providers/bookings_providers.dart';
import '../../application/states/bookings_filter_state.dart';

/// Opens the Bookings filter sheet (date range / daypart / status / shop /
/// assignment). The draft lives in [bookingsFilterDraftProvider].
Future<void> showBookingsFilterSheet(BuildContext context, WidgetRef ref) {
  // Seed the draft from the committed filter each time we open.
  ref.read(bookingsFilterDraftProvider.notifier).state =
      ref.read(bookingsFilterProvider);
  return showAppBottomSheet<void>(
    context: context,
    title: 'Filter bookings',
    builder: (_) => const _BookingsFilterBody(),
    footer: const _BookingsFilterFooter(),
  );
}

class _BookingsFilterBody extends ConsumerWidget {
  const _BookingsFilterBody();

  static const List<(String, String)> _dates = [
    ('today', 'Today'),
    ('yesterday', 'Yesterday'),
    ('last7', 'Last 7 days'),
    ('month', 'This Month'),
    ('custom', 'Custom'),
  ];

  static const List<(String, String, String)> _dayparts = [
    ('morning', 'Morning', '5a–12p'),
    ('afternoon', 'Afternoon', '12–5p'),
    ('evening', 'Evening', '5–9p'),
  ];

  static const List<(String, String)> _assignments = [
    ('me', 'Assigned to me'),
    ('cofounder', 'Co-founder'),
    ('unassigned', 'Unassigned'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(bookingsFilterDraftProvider);
    final shopsAsync = ref.watch(shopsProvider);

    void update(BookingsFilterState next) =>
        ref.read(bookingsFilterDraftProvider.notifier).state = next;

    void toggleStatus(String key) {
      final next = draft.statuses.contains(key)
          ? draft.statuses.where((s) => s != key).toList()
          : [...draft.statuses, key];
      update(draft.copyWith(statuses: next));
    }

    void toggleShop(String shopId) {
      final next = draft.shops.contains(shopId)
          ? draft.shops.where((s) => s != shopId).toList()
          : [...draft.shops, shopId];
      update(draft.copyWith(shops: next));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date range
        _Group(
          label: 'Date range',
          children: [
            for (final d in _dates)
              AppChip(
                label: d.$2,
                active: draft.date == d.$1,
                onTap: () => update(draft.copyWith(date: d.$1)),
              ),
          ],
        ),

        // Time of day
        _Group(
          label: 'Time of day',
          children: [
            for (final dp in _dayparts)
              AppChip(
                label: '${dp.$2}  ${dp.$3}',
                active: draft.daypart == dp.$1,
                onTap: () => update(
                  draft.copyWith(
                    daypart: draft.daypart == dp.$1 ? null : dp.$1,
                  ),
                ),
              ),
          ],
        ),

        // Status multi-select
        _Group(
          label: 'Status',
          children: [
            for (final s in kBookingStatusOrder)
              AppChip(
                label: s.label,
                active: draft.statuses.contains(s.key),
                onTap: () => toggleStatus(s.key),
              ),
          ],
        ),

        // Shop multi-select
        _Group(
          label: 'Shop',
          children: [
            ...shopsAsync.when(
              loading: () => const <Widget>[],
              error: (_, __) => const <Widget>[],
              data: (shops) => [
                for (final shop in shops)
                  AppChip(
                    label: shop.name.split(' ').first,
                    active: draft.shops.contains(shop.id),
                    onTap: () => toggleShop(shop.id),
                  ),
              ],
            ),
          ],
        ),

        // Assignment
        _Group(
          label: 'Assignment',
          children: [
            for (final a in _assignments)
              AppChip(
                label: a.$2,
                active: draft.assign == a.$1,
                onTap: () => update(
                  draft.copyWith(
                    assign: draft.assign == a.$1 ? null : a.$1,
                  ),
                ),
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

class _BookingsFilterFooter extends ConsumerWidget {
  const _BookingsFilterFooter();

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
                ref.read(bookingsFilterDraftProvider.notifier).state =
                    const BookingsFilterState(),
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
                  .read(bookingsFilterProvider.notifier)
                  .apply(ref.read(bookingsFilterDraftProvider));
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}


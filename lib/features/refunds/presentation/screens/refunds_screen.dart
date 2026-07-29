import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/core/error/error_view.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/core/widgets/app_fab.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/empty_state.dart';
import 'package:new_flutter_project/core/widgets/list_controls.dart';
import 'package:new_flutter_project/core/widgets/search_field.dart';
import 'package:new_flutter_project/core/widgets/skeleton_card.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import '../../application/providers/refunds_providers.dart';
import '../components/refund_card.dart';
import '../components/refund_filter_sheet.dart';
import 'refund_detail_screen.dart';
import 'new_refund_screen.dart';

/// Refund Log list screen — module entry-point.
///
/// When [prefillBooking] is supplied (e.g. opened from a booking's "Refund"
/// action), the New Refund form is shown immediately, pre-filled from that
/// booking — mirrors `prefill.newRefundFor` in `screen_refunds.jsx`.
class RefundsScreen extends ConsumerStatefulWidget {
  const RefundsScreen({this.prefillBooking, super.key});

  final RefundPrefill? prefillBooking;

  @override
  ConsumerState<RefundsScreen> createState() => _RefundsScreenState();
}

class _RefundsScreenState extends ConsumerState<RefundsScreen> {
  @override
  void initState() {
    super.initState();
    final prefill = widget.prefillBooking;
    if (prefill != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NewRefundScreen(booking: prefill),
          ),
        );
      });
    }
  }

  static const List<SortOption> _sortOptions = [
    ('recent', 'Most recent'),
    ('amount_hi', 'Amount: high → low'),
    ('amount_lo', 'Amount: low → high'),
    ('status', 'By status'),
  ];

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(refundsFilterProvider);
    final controller = ref.read(refundsFilterProvider.notifier);
    final filtered = ref.watch(filteredRefundsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                TopBar(
                  title: 'Refund Log',
                  subtitle: filter.dateLabel,
                  onBack: () => context.pop(),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
                  decoration: const BoxDecoration(
                    color: AppColors.bgCard,
                    border:
                        Border(bottom: BorderSide(color: AppColors.borderSoft)),
                  ),
                  child: SearchField(
                    value: filter.query,
                    hintText: 'Search booking ID, name, phone',
                    onChanged: controller.setQuery,
                  ),
                ),
                if (filter.activeCount > 0) _ActiveChips(),
                Expanded(
                  child: filtered.when(
                    loading: () => ListView.separated(
                      padding: EdgeInsets.all(16.r),
                      itemCount: 3,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (_, __) => const SkeletonCard(),
                    ),
                    error: (err, __) {
                      // Only show "No internet" for genuine connectivity
                      // failures; surface the real message otherwise.
                      final msg =
                          err.toString().replaceFirst('Exception: ', '');
                      final lower = msg.toLowerCase();
                      final isConnectivity = lower.contains('internet') ||
                          lower.contains('connection') ||
                          lower.contains('timeout') ||
                          lower.contains('socket');
                      return ErrorView(
                        kind: isConnectivity
                            ? ErrorKind.network
                            : ErrorKind.server,
                        message: isConnectivity ? null : msg,
                        onRetry: () => ref.invalidate(refundsProvider),
                      );
                    },
                    data: (refunds) {
                      if (refunds.isEmpty) {
                        // Only blame filters when the admin actually set one —
                        // the list itself is unscoped, so otherwise there
                        // simply are no refunds.
                        if (filter.hasUserFilter) {
                          return EmptyState(
                            icon: AppIcons.receipt,
                            title: 'No refunds match',
                            body: 'Try clearing your search or filters.',
                            actionLabel: 'Reset filters',
                            onAction: controller.reset,
                          );
                        }
                        return const EmptyState(
                          icon: AppIcons.receipt,
                          title: 'No refunds yet',
                          body: 'Refunds raised against bookings will show up '
                              'here.',
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(refundsProvider);
                          await ref.read(refundsProvider.future);
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                          itemCount: refunds.length + 1,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (ctx, index) {
                            if (index == 0) {
                              return ListControls(
                                count: refunds.length,
                                noun: 'refund',
                                onFilter: () => showRefundFilterSheet(ctx, ref),
                                filterCount: filter.activeCount,
                                sort: filter.sort,
                                sortOptions: _sortOptions,
                                onSort: controller.setSort,
                              );
                            }
                            final r = refunds[index - 1];
                            return RefundCard(
                              refund: r,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      RefundDetailScreen(refundId: r.detailKey),
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
            Positioned(
              right: 18.w,
              bottom: 24.h,
              child: AppFab(
                semanticLabel: 'New refund',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NewRefundScreen(),
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

class _ActiveChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(refundsFilterProvider);
    final controller = ref.read(refundsFilterProvider.notifier);

    return Container(
      width: double.infinity,
      color: AppColors.bgPage,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 2.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (filter.date != 'any') ...[
              AppChip(
                label: filter.dateLabel,
                active: true,
                removable: true,
                onRemove: controller.removeDate,
              ),
              SizedBox(width: 8.w),
            ],
            if (filter.status != null) ...[
              AppChip(
                label: kRefundStatusLabels[filter.status] ?? filter.status!,
                active: true,
                removable: true,
                onRemove: controller.removeStatus,
              ),
              SizedBox(width: 8.w),
            ],
            if (filter.reason != null) ...[
              AppChip(
                label: filter.reason!,
                active: true,
                removable: true,
                onRemove: controller.removeReason,
              ),
              SizedBox(width: 8.w),
            ],
          ],
        ),
      ),
    );
  }
}

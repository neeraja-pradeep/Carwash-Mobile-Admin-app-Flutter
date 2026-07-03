import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../application/providers/reports_providers.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/repositories/reports_repository.dart';
import 'metric_tile.dart';
import 'row_list.dart';

/// Eyebrow section label.
class _Lbl extends StatelessWidget {
  const _Lbl(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 2.h),
      child: Text(
        text.toUpperCase(),
        style: AppText.figtree(
          size: 11,
          weight: FontWeight.w700,
          color: AppColors.fgSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// Picks the matching per-report provider for [reportId], fetches it for the
/// selected [query], and renders the typed body (with loading / error states).
class ReportBody extends ConsumerWidget {
  const ReportBody({required this.reportId, required this.query, super.key});

  final String reportId;
  final ReportQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (reportId) {
      'revenue' => _async(ref.watch(revenueReportProvider(query)),
          (d) => _RevenueBody(r: d)),
      'drivers' => _async(ref.watch(driversReportProvider(query)),
          (d) => _DriversBody(r: d)),
      'shops' => _async(ref.watch(shopPerformanceReportProvider(query)),
          (d) => _ShopsBody(r: d)),
      'commission' => _async(ref.watch(commissionReportProvider(query)),
          (d) => _CommissionBody(r: d)),
      'cancellation' => _async(ref.watch(cancellationsReportProvider(query)),
          (d) => _CancellationBody(r: d)),
      'inspection' => _async(ref.watch(inspectionsReportProvider(query)),
          (d) => _InspectionBody(r: d)),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _async<T>(AsyncValue<T> value, Widget Function(T) data) {
    return value.when(
      data: data,
      loading: () => Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            const SkeletonCard(),
            SizedBox(height: 12.h),
          ],
        ],
      ),
      error: (e, _) => Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Text(
          'Could not load this report.\n${e.toString().replaceFirst('Exception: ', '')}',
          textAlign: TextAlign.center,
          style: AppText.figtree(
            size: 13,
            weight: FontWeight.w500,
            color: AppColors.fgTertiary,
          ),
        ),
      ),
    );
  }
}

/// Indian-rupee rating/percent helper — trims a trailing `.0`.
String _trimNum(num v) =>
    v % 1 == 0 ? v.toInt().toString() : v.toString();

// ─── Revenue ──────────────────────────────────────────────────────────────────

class _RevenueBody extends StatelessWidget {
  const _RevenueBody({required this.r});

  final RevenueReport r;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(tiles: [
          MetricTile(
            label: 'Net revenue',
            value: Formatters.money(r.kpis.net),
          ),
          MetricTile(
            label: 'Gross',
            value: Formatters.money(r.kpis.gross),
          ),
          MetricTile(
            label: 'Commission',
            value: Formatters.money(r.kpis.commission),
            color: AppColors.amberFg,
          ),
          MetricTile(
            label: 'Refunds',
            value: Formatters.money(r.kpis.refunds),
            color: AppColors.redFg,
          ),
        ]),
        SizedBox(height: 10.h),
        const _Lbl('By service'),
        SizedBox(height: 6.h),
        RowList(
          rows: r.byService
              .map((s) => RowItem(
                    name: s.name,
                    sub: '${s.count}×',
                    value: Formatters.money(s.revenue),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Drivers & Inspectors ─────────────────────────────────────────────────────

class _DriversBody extends StatelessWidget {
  const _DriversBody({required this.r});

  final DriversReport r;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(tiles: [
          MetricTile(
            label: 'Active drivers',
            value: '${r.activeDrivers}',
          ),
          MetricTile(
            label: 'Hire jobs',
            value: '${r.hireJobs}',
          ),
          MetricTile(
            label: 'Driver payout',
            value: Formatters.money(r.driverPayout),
          ),
          MetricTile(
            label: 'Inspector payout',
            value: Formatters.money(r.inspectorPayout),
          ),
        ]),
        SizedBox(height: 10.h),
        const _Lbl('Driver performance'),
        SizedBox(height: 6.h),
        RowList(
          rows: r.drivers
              .map((p) => RowItem(
                    name: p.name,
                    sub:
                        '${p.wash} wash · ${p.hire} hire${p.rating != null ? " · ★ ${_trimNum(p.rating!)}" : ""}',
                    value: Formatters.money(p.earnings),
                  ))
              .toList(),
        ),
        SizedBox(height: 10.h),
        const _Lbl('Inspector performance'),
        SizedBox(height: 6.h),
        RowList(
          rows: r.inspectors
              .map((p) => RowItem(
                    name: p.name,
                    sub:
                        '${p.inspections} inspection${p.inspections == 1 ? "" : "s"}${p.rating != null ? " · ★ ${_trimNum(p.rating!)}" : ""}',
                    value: Formatters.money(p.payout),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Shop Performance ─────────────────────────────────────────────────────────

class _ShopsBody extends StatelessWidget {
  const _ShopsBody({required this.r});

  final ShopPerformanceReport r;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(tiles: [
          MetricTile(
            label: 'Shops active',
            value: '${r.shopsActive}',
          ),
          MetricTile(
            label: 'Total bookings',
            value: '${r.totalBookings}',
          ),
          MetricTile(
            label: 'Total revenue',
            value: Formatters.money(r.totalRevenue),
          ),
        ]),
        SizedBox(height: 10.h),
        const _Lbl('Revenue by shop'),
        SizedBox(height: 6.h),
        RowList(
          rows: r.byShop
              .map((s) => RowItem(
                    name: s.shop,
                    sub: '${s.bookings} bookings',
                    value: Formatters.money(s.revenue),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Commission / Settlement ──────────────────────────────────────────────────

class _CommissionBody extends StatelessWidget {
  const _CommissionBody({required this.r});

  final CommissionReport r;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(tiles: [
          MetricTile(
            label: 'Platform commission',
            value: Formatters.money(r.platformCommission),
            color: AppColors.amberFg,
          ),
          MetricTile(
            label: 'Shop earnings',
            value: Formatters.money(r.shopEarnings),
          ),
          MetricTile(
            label: 'Refunds deducted',
            value: Formatters.money(r.refundsDeducted),
            color: AppColors.redFg,
          ),
          MetricTile(
            label: 'Net settled',
            value: Formatters.money(r.netSettled),
          ),
        ]),
        SizedBox(height: 10.h),
        const _Lbl('Commission by shop'),
        SizedBox(height: 6.h),
        RowList(
          rows: r.byShop
              .map((s) => RowItem(
                    name: s.shop,
                    sub: '${Formatters.money(s.gross)} gross',
                    value: Formatters.money(s.commission),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Cancellations ────────────────────────────────────────────────────────────

class _CancellationBody extends StatelessWidget {
  const _CancellationBody({required this.r});

  final CancellationsReport r;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(tiles: [
          MetricTile(
            label: 'Cancelled',
            value: '${r.cancelled}',
            color: AppColors.redFg,
          ),
          MetricTile(
            label: 'Cancel rate',
            value: '${_trimNum(r.cancelRatePercent)}%',
          ),
          MetricTile(
            label: 'Refunds issued',
            value: Formatters.money(r.refundsIssued),
            color: AppColors.redFg,
          ),
          MetricTile(
            label: 'Total bookings',
            value: '${r.totalBookings}',
          ),
        ]),
        SizedBox(height: 10.h),
        const _Lbl('Reasons'),
        SizedBox(height: 6.h),
        if (r.reasons.isEmpty)
          _EmptyRows(text: 'No cancellations in this period.')
        else
          RowList(
            rows: r.reasons
                .map((x) => RowItem(name: x.reason, value: '${x.count}'))
                .toList(),
          ),
      ],
    );
  }
}

// ─── Inspections ──────────────────────────────────────────────────────────────

class _InspectionBody extends StatelessWidget {
  const _InspectionBody({required this.r});

  final InspectionsReport r;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(tiles: [
          MetricTile(
            label: 'Inspections',
            value: '${r.inspections}',
          ),
          MetricTile(
            label: 'Inspector payout',
            value: Formatters.money(r.inspectorPayout),
          ),
          MetricTile(
            label: 'Avg fee',
            value: Formatters.money(r.avgFee),
          ),
          MetricTile(
            label: 'Active inspectors',
            value: '${r.activeInspectors}',
          ),
        ]),
        SizedBox(height: 10.h),
        const _Lbl('By inspector'),
        SizedBox(height: 6.h),
        RowList(
          rows: r.rows
              .map((p) => RowItem(
                    name: p.name,
                    sub:
                        '${p.inspections} inspection${p.inspections == 1 ? "" : "s"}',
                    value: Formatters.money(p.payout),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class _EmptyRows extends StatelessWidget {
  const _EmptyRows({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        text,
        style: AppText.figtree(
          size: 13,
          weight: FontWeight.w500,
          color: AppColors.fgMuted,
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.tiles});

  final List<MetricTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: tiles
          .map(
            (t) => SizedBox(
              width: (MediaQuery.of(context).size.width - 32.w - 10.w) / 2,
              child: t,
            ),
          )
          .toList(),
    );
  }
}

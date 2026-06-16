import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/daily_summary.dart';
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

/// The 6 per-report metric layouts sourced from [DailySummary].
/// Mirrors `ReportBody` in `screen_reports.jsx`.
class ReportBody extends StatelessWidget {
  const ReportBody({required this.reportId, required this.summary, super.key});

  final String reportId;
  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    return switch (reportId) {
      'revenue' => _RevenueBody(d: summary),
      'drivers' => _DriversBody(d: summary),
      'shops' => _ShopsBody(d: summary),
      'commission' => _CommissionBody(d: summary),
      'cancellation' => _CancellationBody(d: summary),
      'inspection' => _InspectionBody(d: summary),
      _ => const SizedBox.shrink(),
    };
  }
}

// ─── Revenue ──────────────────────────────────────────────────────────────────

class _RevenueBody extends StatelessWidget {
  const _RevenueBody({required this.d});

  final DailySummary d;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(tiles: [
          MetricTile(
            label: 'Net revenue',
            value: Formatters.money(d.revenue.net),
          ),
          MetricTile(
            label: 'Gross',
            value: Formatters.money(d.revenue.gross),
          ),
          MetricTile(
            label: 'Commission',
            value: Formatters.money(d.revenue.commission),
            color: AppColors.amberFg,
          ),
          MetricTile(
            label: 'Refunds',
            value: Formatters.money(d.revenue.refunds),
            color: AppColors.redFg,
          ),
        ]),
        SizedBox(height: 10.h),
        const _Lbl('By service'),
        SizedBox(height: 6.h),
        RowList(
          rows: d.byService
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
  const _DriversBody({required this.d});

  final DailySummary d;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(tiles: [
          MetricTile(
            label: 'Active drivers',
            value: '${d.teamTotals.activeDrivers}',
          ),
          MetricTile(
            label: 'Hire jobs',
            value: '${d.teamTotals.hireJobs}',
          ),
          MetricTile(
            label: 'Driver payout',
            value: Formatters.money(d.teamTotals.driverPayout),
          ),
          MetricTile(
            label: 'Inspector payout',
            value: Formatters.money(d.teamTotals.inspectorPayout),
          ),
        ]),
        SizedBox(height: 10.h),
        const _Lbl('Driver performance'),
        SizedBox(height: 6.h),
        RowList(
          rows: d.byDriver
              .map((p) => RowItem(
                    name: p.name,
                    sub:
                        '${p.jobs} wash · ${p.hireJobs} hire${p.rating != null ? " · ★ ${p.rating}" : ""}',
                    value: Formatters.money(p.earnings),
                  ))
              .toList(),
        ),
        SizedBox(height: 10.h),
        const _Lbl('Inspector performance'),
        SizedBox(height: 6.h),
        RowList(
          rows: d.byInspector
              .map((p) => RowItem(
                    name: p.name,
                    sub:
                        '${p.inspections} inspection${p.inspections == 1 ? "" : "s"}${p.rating != null ? " · ★ ${p.rating}" : ""}',
                    value: Formatters.money(p.earnings),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Shop Performance ─────────────────────────────────────────────────────────

class _ShopsBody extends StatelessWidget {
  const _ShopsBody({required this.d});

  final DailySummary d;

  @override
  Widget build(BuildContext context) {
    final activeShops = d.byShop.where((s) => s.bookings > 0).length;
    final totalBookings =
        d.byShop.fold(0, (sum, s) => sum + s.bookings);
    final totalRevenue =
        d.byShop.fold<num>(0, (sum, s) => sum + s.revenue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(tiles: [
          MetricTile(
            label: 'Shops active',
            value: '$activeShops',
          ),
          MetricTile(
            label: 'Total bookings',
            value: '$totalBookings',
          ),
          MetricTile(
            label: 'Total revenue',
            value: Formatters.money(totalRevenue),
          ),
        ]),
        SizedBox(height: 10.h),
        const _Lbl('Revenue by shop'),
        SizedBox(height: 6.h),
        RowList(
          rows: d.byShop
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
  const _CommissionBody({required this.d});

  final DailySummary d;

  @override
  Widget build(BuildContext context) {
    final comm = d.revenue.commission;
    final net = d.revenue.net;
    final shopShare =
        d.revenue.gross - comm - d.revenue.refunds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(tiles: [
          MetricTile(
            label: 'Platform commission',
            value: Formatters.money(comm),
            color: AppColors.amberFg,
          ),
          MetricTile(
            label: 'Shop earnings',
            value: Formatters.money(shopShare),
          ),
          MetricTile(
            label: 'Refunds deducted',
            value: Formatters.money(d.revenue.refunds),
            color: AppColors.redFg,
          ),
          MetricTile(
            label: 'Net settled',
            value: Formatters.money(net),
          ),
        ]),
        SizedBox(height: 10.h),
        const _Lbl('Commission by shop'),
        SizedBox(height: 6.h),
        RowList(
          rows: d.byShop
              .where((s) => s.revenue > 0)
              .map((s) => RowItem(
                    name: s.shop,
                    sub: '${Formatters.money(s.revenue)} gross',
                    value: Formatters.money(
                        (s.revenue * 0.15).round()),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Cancellations ────────────────────────────────────────────────────────────

class _CancellationBody extends StatelessWidget {
  const _CancellationBody({required this.d});

  final DailySummary d;

  @override
  Widget build(BuildContext context) {
    final c = d.bookings;
    final rate = c.total == 0
        ? 0
        : (c.cancelled / c.total * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(tiles: [
          MetricTile(
            label: 'Cancelled',
            value: '${c.cancelled}',
            color: AppColors.redFg,
          ),
          MetricTile(
            label: 'Cancel rate',
            value: '$rate%',
          ),
          MetricTile(
            label: 'Refunds issued',
            value: Formatters.money(d.revenue.refunds),
            color: AppColors.redFg,
          ),
          MetricTile(
            label: 'Total bookings',
            value: '${c.total}',
          ),
        ]),
        SizedBox(height: 10.h),
        const _Lbl('Reasons'),
        SizedBox(height: 6.h),
        const RowList(
          rows: [
            RowItem(
              name: 'Cancelled by customer',
              sub: 'before assignment',
              value: '1',
            ),
            RowItem(name: 'Damage during wash', value: '0'),
            RowItem(name: 'No driver available', value: '0'),
          ],
        ),
      ],
    );
  }
}

// ─── Inspections ──────────────────────────────────────────────────────────────

class _InspectionBody extends StatelessWidget {
  const _InspectionBody({required this.d});

  final DailySummary d;

  @override
  Widget build(BuildContext context) {
    final activeInspectors =
        d.byInspector.where((p) => p.online).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(tiles: [
          MetricTile(
            label: 'Inspections',
            value: '${d.teamTotals.inspections}',
          ),
          MetricTile(
            label: 'Inspector payout',
            value: Formatters.money(d.teamTotals.inspectorPayout),
          ),
          MetricTile(
            label: 'Avg fee',
            value: Formatters.money(800),
          ),
          MetricTile(
            label: 'Active inspectors',
            value: '$activeInspectors',
          ),
        ]),
        SizedBox(height: 10.h),
        const _Lbl('By inspector'),
        SizedBox(height: 6.h),
        RowList(
          rows: d.byInspector
              .map((p) => RowItem(
                    name: p.name,
                    sub:
                        '${p.inspections} inspection${p.inspections == 1 ? "" : "s"}',
                    value: Formatters.money(p.earnings),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Shared metric grid ───────────────────────────────────────────────────────

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

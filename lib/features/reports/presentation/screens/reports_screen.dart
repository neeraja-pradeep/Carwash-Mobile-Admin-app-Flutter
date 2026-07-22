import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/reports_providers.dart';
import '../../domain/entities/report_kind.dart';
import '../../domain/repositories/reports_repository.dart';
import '../components/report_body.dart';

/// Reports module screen — pick a report, choose a period, see metrics, export.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(selectedReportProvider);
    if (sel != null) {
      return _ReportDetail(reportId: sel);
    }
    return _ReportPicker();
  }
}

// ─── Report picker ────────────────────────────────────────────────────────────

class _ReportPicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: 'Reports',
              subtitle: 'Analytics',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
                children: [
                  Text(
                    'Pick a report, choose a period, export.',
                    style: AppText.figtree(
                      size: 12.5,
                      color: AppColors.fgTertiary,
                      weight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  for (final kind in ReportKind.values)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _ReportTile(kind: kind),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends ConsumerWidget {
  const _ReportTile({required this.kind});

  final ReportKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(selectedReportProvider.notifier).state = kind.name,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A14141E),
              offset: Offset(0, 1.h),
              blurRadius: 2.r,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bgPage,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                _iconFor(kind),
                size: 21.sp,
                color: AppColors.fgPrimary,
              ),
            ),
            SizedBox(width: 13.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind.label,
                    style: AppText.figtree(
                      size: 14.5,
                      weight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    kind.description,
                    style: AppText.figtree(
                      size: 12,
                      color: AppColors.fgTertiary,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              AppIcons.chevRight,
              size: 18.sp,
              color: AppColors.fgTertiary,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ReportKind kind) => switch (kind) {
        ReportKind.revenue => AppIcons.rupee,
        ReportKind.drivers => AppIcons.car,
        ReportKind.shops => AppIcons.store,
        ReportKind.commission => AppIcons.wallet,
        ReportKind.cancellation => AppIcons.close,
        ReportKind.inspection => AppIcons.search,
      };
}

// ─── Report detail ────────────────────────────────────────────────────────────

/// Period constants: (key, label) pairs.
const List<(String, String)> _kPeriods = [
  ('today', 'Today'),
  ('7', 'Last 7 days'),
  ('30', 'Last 30 days'),
  ('month', 'This month'),
  ('custom', 'Custom range'),
];

class _ReportDetail extends ConsumerStatefulWidget {
  const _ReportDetail({required this.reportId});

  final String reportId;

  @override
  ConsumerState<_ReportDetail> createState() => _ReportDetailState();
}

class _ReportDetailState extends ConsumerState<_ReportDetail> {
  String _period = 'today';
  String _customFrom = '2026-05-01';
  String _customTo = '2026-05-29';
  bool _exporting = false;

  String get _periodLabel {
    if (_period == 'custom') return '$_customFrom → $_customTo';
    return _kPeriods.firstWhere((p) => p.$1 == _period).$2;
  }

  ReportKind get _kind =>
      ReportKind.values.firstWhere((k) => k.name == widget.reportId);

  /// The selected window translated to API params.
  ReportQuery get _query => switch (_period) {
        '7' => const ReportQuery(period: 'last_7'),
        '30' => const ReportQuery(period: 'last_30'),
        'month' => const ReportQuery(period: 'this_month'),
        'custom' => ReportQuery(from: _customFrom, to: _customTo),
        _ => const ReportQuery(period: 'today'),
      };

  /// UI report id → backend report slug.
  String get _reportSlug => switch (widget.reportId) {
        'drivers' => 'drivers-inspectors',
        'shops' => 'shop-performance',
        'cancellation' => 'cancellations',
        'inspection' => 'inspections',
        _ => widget.reportId, // revenue, commission
      };

  /// Invalidates and re-awaits the report provider for the current window.
  Future<void> _refreshReport() async {
    final query = _query;
    switch (widget.reportId) {
      case 'revenue':
        ref.invalidate(revenueReportProvider(query));
        await ref.read(revenueReportProvider(query).future);
      case 'drivers':
        ref.invalidate(driversReportProvider(query));
        await ref.read(driversReportProvider(query).future);
      case 'shops':
        ref.invalidate(shopPerformanceReportProvider(query));
        await ref.read(shopPerformanceReportProvider(query).future);
      case 'commission':
        ref.invalidate(commissionReportProvider(query));
        await ref.read(commissionReportProvider(query).future);
      case 'cancellation':
        ref.invalidate(cancellationsReportProvider(query));
        await ref.read(cancellationsReportProvider(query).future);
      case 'inspection':
        ref.invalidate(inspectionsReportProvider(query));
        await ref.read(inspectionsReportProvider(query).future);
    }
  }

  Future<void> _exportCsv() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final export = await ref
          .read(reportsRepositoryProvider)
          .exportCsv(_reportSlug, _query);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${export.filename}');
      await file.writeAsBytes(export.bytes);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: '${_kind.label} report · $_periodLabel',
      );
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          'Export failed: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: _kind.label,
              subtitle: 'Report',
              onBack: () =>
                  ref.read(selectedReportProvider.notifier).state = null,
              actions: [
                AppIconButton(
                  icon: AppIcons.share,
                  semanticLabel: 'Export',
                  onTap: _exporting ? null : _exportCsv,
                ),
              ],
            ),
            // Period selector chips
            Container(
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    for (final (key, label) in _kPeriods) ...[
                      AppChip(
                        label: label,
                        active: _period == key,
                        onTap: () => setState(() => _period = key),
                      ),
                      SizedBox(width: 8.w),
                    ],
                  ],
                ),
              ),
            ),
            // Custom date range inputs
            if (_period == 'custom')
              Container(
                color: AppColors.bgPage,
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _DateInput(
                        value: _customFrom,
                        onChanged: (v) => setState(() => _customFrom = v),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _DateInput(
                        value: _customTo,
                        onChanged: (v) => setState(() => _customTo = v),
                      ),
                    ),
                  ],
                ),
              ),
            // Scrollable body — each report manages its own loading/error.
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshReport,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
                  children: [
                    Text(
                      _periodLabel,
                      style: AppText.figtree(
                        size: 12,
                        color: AppColors.fgTertiary,
                        weight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    ReportBody(reportId: widget.reportId, query: _query),
                    SizedBox(height: 14.h),
                    AppButton(
                      label: _exporting ? 'Exporting…' : 'Export this report',
                      kind: AppButtonKind.secondary,
                      full: true,
                      icon: AppIcons.share,
                      onPressed: _exporting ? null : _exportCsv,
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date input ───────────────────────────────────────────────────────────────

/// A tappable date field that opens the native date picker and emits a
/// `YYYY-MM-DD` string.
class _DateInput extends StatelessWidget {
  const _DateInput({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  Future<void> _pick(BuildContext context) async {
    final initial = DateTime.tryParse(value) ?? DateTime(2026);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      onChanged('${picked.year}-$m-$d');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(11.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Row(
          children: [
            Icon(AppIcons.calendar, size: 15.sp, color: AppColors.fgTertiary),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                value,
                style: AppText.figtree(size: 13, weight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

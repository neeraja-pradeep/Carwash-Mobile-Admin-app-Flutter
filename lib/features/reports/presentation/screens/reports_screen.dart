import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/reports_providers.dart';
import '../../domain/entities/daily_summary.dart';
import '../../domain/entities/report_kind.dart';
import '../components/report_body.dart';

/// Reports module screen — pick a report, choose a period, see metrics, export.
/// Mirrors `ReportsScreen` + `ReportDetail` in `screen_reports.jsx`.
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
    final summaryAsync = ref.watch(dailySummaryProvider);
    final date = summaryAsync.maybeWhen(
      data: (d) => d.date,
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: 'Reports',
              subtitle: date,
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
      onTap: () =>
          ref.read(selectedReportProvider.notifier).state = kind.name,
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
  bool _exportOpen = false;

  String get _periodLabel {
    if (_period == 'custom') return '$_customFrom → $_customTo';
    return _kPeriods.firstWhere((p) => p.$1 == _period).$2;
  }

  ReportKind get _kind =>
      ReportKind.values.firstWhere((k) => k.name == widget.reportId);

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dailySummaryProvider);

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
                  onTap: () => setState(() => _exportOpen = true),
                ),
              ],
            ),
            // Period selector chips
            Container(
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border: Border(
                    bottom: BorderSide(color: AppColors.borderSoft)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    for (final (key, label) in _kPeriods) ...[
                      AppChip(
                        label: label,
                        active: _period == key,
                        onTap: () =>
                            setState(() => _period = key),
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
                        onChanged: (v) =>
                            setState(() => _customFrom = v),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _DateInput(
                        value: _customTo,
                        onChanged: (v) =>
                            setState(() => _customTo = v),
                      ),
                    ),
                  ],
                ),
              ),
            // Scrollable body
            Expanded(
              child: summaryAsync.when(
                loading: () => ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: 4,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, __) => const SkeletonCard(),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (summary) => _buildBody(context, summary),
              ),
            ),
          ],
        ),
      ),
      // Export modal overlay
      floatingActionButton: null,
    );
  }

  Widget _buildBody(BuildContext context, DailySummary summary) {
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
          children: [
            Text(
              '$_periodLabel · ${summary.date}',
              style: AppText.figtree(
                size: 12,
                color: AppColors.fgTertiary,
                weight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 14.h),
            ReportBody(reportId: widget.reportId, summary: summary),
            SizedBox(height: 14.h),
            AppButton(
              label: 'Export this report',
              kind: AppButtonKind.secondary,
              full: true,
              icon: AppIcons.share,
              onPressed: () => setState(() => _exportOpen = true),
            ),
            SizedBox(height: 20.h),
          ],
        ),
        if (_exportOpen) _ExportModal(
          reportName: _kind.label,
          onClose: () => setState(() => _exportOpen = false),
          onExport: (fmt) {
            setState(() => _exportOpen = false);
            AppToast.show(
              context,
              'Exporting ${_kind.label} · $fmt…',
            );
          },
        ),
      ],
    );
  }
}

// ─── Export modal ─────────────────────────────────────────────────────────────

class _ExportModal extends StatelessWidget {
  const _ExportModal({
    required this.reportName,
    required this.onClose,
    required this.onExport,
  });

  final String reportName;
  final VoidCallback onClose;
  final ValueChanged<String> onExport;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: AppColors.bgOverlay,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent tap-through
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 28.w),
              padding: EdgeInsets.all(22.r),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export $reportName',
                    style: AppText.figtree(
                      size: 19,
                      weight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Download as PDF or CSV for the selected period.',
                    style: AppText.figtree(
                      size: 13,
                      color: AppColors.fgSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      for (final (fmt, icon) in [
                        ('PDF', AppIcons.note),
                        ('CSV', AppIcons.receipt),
                      ]) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onExport(fmt),
                            child: Container(
                              height: 54.h,
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius:
                                    BorderRadius.circular(12.r),
                                border: Border.all(
                                    color: AppColors.borderDefault),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(icon, size: 17.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    fmt,
                                    style: AppText.figtree(
                                      size: 14,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (fmt == 'PDF') SizedBox(width: 10.w),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Date input ───────────────────────────────────────────────────────────────

class _DateInput extends StatefulWidget {
  const _DateInput({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_DateInput> createState() => _DateInputState();
}

class _DateInputState extends State<_DateInput> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_DateInput old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.datetime,
        onChanged: widget.onChanged,
        style: AppText.figtree(
          size: 13,
          weight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

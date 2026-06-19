import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/status/badge_tone.dart';
import 'package:new_flutter_project/core/status/service_request_status.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/core/widgets/app_bottom_sheet.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_icon_button.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/avatar.dart';
import 'package:new_flutter_project/core/widgets/skeleton_card.dart';
import 'package:new_flutter_project/core/widgets/status_badge.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import 'package:new_flutter_project/features/drivers/application/providers/drivers_providers.dart';
import 'package:new_flutter_project/features/drivers/domain/entities/field_driver.dart'
    show LiveLocation;

import '../../application/providers/service_requests_providers.dart';
import '../../domain/entities/service_request.dart';
import '../components/sr_assign_sheet.dart';
import '../components/sr_otp_modal.dart';
import '../components/sr_summary_card.dart';

/// Full-screen detail for a single service request.
///
/// Mirrors `SrDetail` in `screen_servicereq.jsx`. Handles status transitions
/// (New → Contacted → Assigned → In Progress → Completed / Cancelled), OTP
/// verification, assignee picking, and displays the live location card and
/// completion summary when applicable.
class ServiceRequestDetailScreen extends ConsumerStatefulWidget {
  const ServiceRequestDetailScreen({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<ServiceRequestDetailScreen> createState() =>
      _ServiceRequestDetailScreenState();
}

class _ServiceRequestDetailScreenState
    extends ConsumerState<ServiceRequestDetailScreen> {
  ServiceRequestStatus? _statusOverride;
  String? _assigneeIdOverride;
  List<SrTimelineEntry>? _timelineOverride;
  SrSummary? _summaryOverride;
  String _opsNote = '';
  bool _menuOpen = false;

  String get _nowStamp {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final min = now.minute.toString().padLeft(2, '0');
    final period = now.hour < 12 ? 'AM' : 'PM';
    return '29 May, $hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync =
        ref.watch(serviceRequestByIdProvider(widget.requestId));

    return requestAsync.when(
      loading: () => _buildShell(
        context,
        title: 'Request',
        body: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            const SkeletonCard(),
            SizedBox(height: 14.h),
            const SkeletonCard(),
            SizedBox(height: 14.h),
            const SkeletonCard(),
          ],
        ),
      ),
      error: (e, _) => _buildShell(
        context,
        title: 'Request',
        body: Center(
          child: Text('Could not load request',
              style: AppText.figtree(size: 14, color: AppColors.danger)),
        ),
      ),
      data: (request) {
        if (request == null) {
          return _buildShell(
            context,
            title: 'Request',
            body: Center(
              child: Text('Request not found',
                  style: AppText.figtree(size: 14)),
            ),
          );
        }
        final status = _statusOverride ?? request.status;
        final assigneeId = _assigneeIdOverride ?? request.assigneeId;
        final timeline = _timelineOverride ?? request.timeline;
        final summary = _summaryOverride ?? request.summary;

        return _DetailBody(
          request: request,
          status: status,
          assigneeId: assigneeId,
          timeline: timeline,
          summary: summary,
          opsNote: _opsNote,
          menuOpen: _menuOpen,
          nowStamp: _nowStamp,
          onMenuToggle: () => setState(() => _menuOpen = !_menuOpen),
          onMenuClose: () => setState(() => _menuOpen = false),
          onStatusChange: (s) => setState(() {
            _statusOverride = s;
            _menuOpen = false;
          }),
          onAssigneeChange: (id) => setState(() => _assigneeIdOverride = id),
          onTimelineAdd: (e) => setState(
              () => _timelineOverride = [...timeline, e]),
          onSummarySet: (s) => setState(() => _summaryOverride = s),
          onNoteChange: (n) => setState(() => _opsNote = n),
        );
      },
    );
  }

  Widget _buildShell(BuildContext context,
      {required String title, required Widget body}) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(title: title, onBack: () => context.pop()),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.request,
    required this.status,
    required this.assigneeId,
    required this.timeline,
    required this.summary,
    required this.opsNote,
    required this.menuOpen,
    required this.nowStamp,
    required this.onMenuToggle,
    required this.onMenuClose,
    required this.onStatusChange,
    required this.onAssigneeChange,
    required this.onTimelineAdd,
    required this.onSummarySet,
    required this.onNoteChange,
  });

  final ServiceRequest request;
  final ServiceRequestStatus status;
  final String? assigneeId;
  final List<SrTimelineEntry> timeline;
  final SrSummary? summary;
  final String opsNote;
  final bool menuOpen;
  final String nowStamp;
  final VoidCallback onMenuToggle;
  final VoidCallback onMenuClose;
  final ValueChanged<ServiceRequestStatus> onStatusChange;
  final ValueChanged<String> onAssigneeChange;
  final ValueChanged<SrTimelineEntry> onTimelineAdd;
  final ValueChanged<SrSummary> onSummarySet;
  final ValueChanged<String> onNoteChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assigneeAsync = assigneeId != null
        ? ref.watch(assigneeByIdProvider(assigneeId!))
        : const AsyncValue<({String name, String phone, String role})?>
            .data(null);
    final assignee = assigneeAsync.valueOrNull;

    // Next action (mirrors nextStep in JSX).
    _NextStep? nextStep;
    if (status == ServiceRequestStatus.created) {
      nextStep = _NextStep(
        label: 'Mark Contacted',
        action: () {
          onStatusChange(ServiceRequestStatus.contacted);
          onTimelineAdd(SrTimelineEntry(
            status: ServiceRequestStatus.contacted,
            at: nowStamp,
            by: 'Anand',
          ));
          AppToast.show(context, 'Marked Contacted');
        },
      );
    } else if ((status == ServiceRequestStatus.contacted ||
            status == ServiceRequestStatus.assigned) &&
        assigneeId != null) {
      nextStep = _NextStep(
        label: 'Start Job',
        action: () => _showOtp(context, 'start', assignee),
      );
    } else if (status == ServiceRequestStatus.inProgress) {
      nextStep = _NextStep(
        label: 'End Job',
        action: () => _showOtp(context, 'end', assignee),
      );
    }

    final isDone = status == ServiceRequestStatus.completed ||
        status == ServiceRequestStatus.cancelled;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              request: request,
              menuOpen: menuOpen,
              onMenuToggle: onMenuToggle,
              onMenuClose: onMenuClose,
              onAddNote: () => _showNoteModal(context),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  _HeaderCard(request: request, status: status),
                  SizedBox(height: 14.h),
                  if (status == ServiceRequestStatus.inProgress &&
                      request.live != null) ...[
                    _LiveCard(live: request.live!),
                    SizedBox(height: 14.h),
                  ],
                  _DetailsCard(request: request),
                  SizedBox(height: 14.h),
                  if (request.note.isNotEmpty) ...[
                    _NoteCard(
                      label: 'Customer note',
                      icon: AppIcons.message,
                      text: request.note,
                    ),
                    SizedBox(height: 14.h),
                  ],
                  if (opsNote.isNotEmpty) ...[
                    _NoteCard(
                      label: 'Founder note',
                      icon: AppIcons.note,
                      text: opsNote,
                    ),
                    SizedBox(height: 14.h),
                  ],
                  if (status == ServiceRequestStatus.completed &&
                      summary != null) ...[
                    SrSummaryCard(summary: summary!),
                    SizedBox(height: 14.h),
                  ],
                  _AssignCard(
                    request: request,
                    status: status,
                    assigneeId: assigneeId,
                    assignee: assignee,
                    onAssign: () => _openAssignSheet(context, ref),
                  ),
                  SizedBox(height: 14.h),
                  _TimelineCard(timeline: timeline),
                ],
              ),
            ),
            // Sticky footer.
            Container(
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border:
                    Border(top: BorderSide(color: AppColors.borderSoft)),
              ),
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 24.h),
              child: isDone
                  ? AppButton(
                      label: status == ServiceRequestStatus.completed
                          ? 'Request completed'
                          : 'Request cancelled',
                      full: true,
                      disabled: true,
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Cancel',
                            kind: AppButtonKind.secondary,
                            full: true,
                            onPressed: () => _confirmCancel(context),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: AppButton(
                            label: nextStep?.label ?? 'Assign first',
                            full: true,
                            disabled: nextStep == null,
                            onPressed: nextStep?.action,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOtp(
    BuildContext context,
    String mode,
    ({String name, String phone, String role})? assignee,
  ) async {
    if (request.otp.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => SrOtpModal(
        mode: mode,
        expectedOtp: request.otp,
        onVerify: () {
          Navigator.of(context).pop();
          if (mode == 'start') {
            onStatusChange(ServiceRequestStatus.inProgress);
            onTimelineAdd(SrTimelineEntry(
              status: ServiceRequestStatus.inProgress,
              at: nowStamp,
              by: assignee?.name ?? 'Anand',
              location:
                  request.startLoc ?? request.location,
            ));
            AppToast.show(context, 'Job started · location captured');
          } else {
            onStatusChange(ServiceRequestStatus.completed);
            onTimelineAdd(SrTimelineEntry(
              status: ServiceRequestStatus.completed,
              at: nowStamp,
              by: assignee?.name ?? 'Anand',
              location: request.endLoc ??
                  request.startLoc ??
                  request.location,
            ));
            onSummarySet(SrSummary(
              plannedHours: 0,
              actualHours: 0,
              extraKm: 0,
              baseFee: request.fee ?? 0,
              extraCharge: 0,
              extraReason: 'Completed as planned — no extra charge',
              total: request.fee ?? 0,
              paid: false,
            ));
            AppToast.show(context, 'Job completed · summary ready');
          }
        },
      ),
    );
  }

  Future<void> _openAssignSheet(BuildContext context, WidgetRef ref) async {
    await showAppBottomSheet<void>(
      context: context,
      title: request.kind == SrKind.driver
          ? 'Assign driver'
          : 'Assign inspector',
      maxHeightFactor: 0.64,
      builder: (sheetCtx) => SrAssignSheet(
        kind: request.kind,
        currentRequestId: request.id,
        currentAssigneeId: assigneeId,
        sheetContext: sheetCtx,
        onPick: (id) {
          onAssigneeChange(id);
          if (status == ServiceRequestStatus.created ||
              status == ServiceRequestStatus.contacted) {
            onStatusChange(ServiceRequestStatus.assigned);
            onTimelineAdd(SrTimelineEntry(
              status: ServiceRequestStatus.assigned,
              at: nowStamp,
              by: 'Anand',
            ));
          }
          AppToast.show(context, 'Assignee updated');
        },
      ),
    );
  }

  Future<void> _showNoteModal(BuildContext context) async {
    String draft = opsNote;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          20.h,
          20.w,
          MediaQuery.of(ctx).viewInsets.bottom + 24.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add founder note',
                style:
                    AppText.figtree(size: 17, weight: FontWeight.w700)),
            SizedBox(height: 14.h),
            StatefulBuilder(builder: (_, set) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller:
                        TextEditingController(text: draft),
                    maxLines: 4,
                    onChanged: (v) => draft = v,
                    decoration: InputDecoration(
                      hintText:
                          'Internal note visible to ops…',
                      hintStyle: AppText.figtree(
                          size: 14, color: AppColors.fgMuted),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10.r),
                        borderSide: const BorderSide(
                            color: AppColors.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10.r),
                        borderSide: const BorderSide(
                            color: AppColors.borderDefault),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  AppButton(
                    label: 'Save note',
                    full: true,
                    onPressed: () {
                      onNoteChange(draft);
                      Navigator.of(ctx).pop();
                      AppToast.show(context, 'Note saved');
                    },
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r)),
        title: Text('Cancel request?',
            style:
                AppText.figtree(size: 17, weight: FontWeight.w700)),
        content: Text(
          'This will mark the request as cancelled. This cannot be undone.',
          style: AppText.figtree(
              size: 14,
              color: AppColors.fgSecondary,
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep',
                style: AppText.figtree(
                    size: 14, weight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Cancel request',
                style: AppText.figtree(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      onStatusChange(ServiceRequestStatus.cancelled);
      onTimelineAdd(SrTimelineEntry(
        status: ServiceRequestStatus.cancelled,
        at: nowStamp,
        by: 'Anand',
      ));
      AppToast.show(context, 'Request cancelled');
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _NextStep {
  const _NextStep({required this.label, required this.action});
  final String label;
  final VoidCallback action;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.request,
    required this.menuOpen,
    required this.onMenuToggle,
    required this.onMenuClose,
    required this.onAddNote,
  });

  final ServiceRequest request;
  final bool menuOpen;
  final VoidCallback onMenuToggle;
  final VoidCallback onMenuClose;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    return TopBar(
      title: '${request.kind.label} Request',
      subtitle: request.id,
      onBack: () => context.pop(),
      actions: [
        AppIconButton(
          icon: AppIcons.phone,
          iconSize: 20,
          semanticLabel: 'Call customer',
          onTap: () =>
              AppToast.show(context, 'Calling ${request.customer.name}…'),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            AppIconButton(
              icon: AppIcons.more,
              iconSize: 22,
              semanticLabel: 'More actions',
              onTap: onMenuToggle,
            ),
            if (menuOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: onMenuClose,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              Positioned(
                right: 0,
                top: 44.h,
                child: _DropdownMenu(
                  onAddNote: onAddNote,
                  onClose: onMenuClose,
                  requestId: request.id,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DropdownMenu extends StatelessWidget {
  const _DropdownMenu({
    required this.onAddNote,
    required this.onClose,
    required this.requestId,
  });

  final VoidCallback onAddNote;
  final VoidCallback onClose;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final items = [
      (AppIcons.share, 'Share request'),
      (AppIcons.copy, 'Copy request ID'),
      (AppIcons.note, 'Add note'),
    ];
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 190.w,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: AppCard.shadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++)
              GestureDetector(
                onTap: () {
                  onClose();
                  if (items[i].$2 == 'Add note') {
                    onAddNote();
                  } else if (items[i].$2 == 'Copy request ID') {
                    AppToast.show(context, 'Copied $requestId');
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 13.h),
                  decoration: BoxDecoration(
                    border: i < items.length - 1
                        ? const Border(
                            bottom: BorderSide(
                                color: AppColors.borderSoft))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(items[i].$1,
                          size: 16.sp, color: AppColors.fgSecondary),
                      SizedBox(width: 10.w),
                      Text(
                        items[i].$2,
                        style: AppText.figtree(
                            size: 14, weight: FontWeight.w500),
                      ),
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.request, required this.status});

  final ServiceRequest request;
  final ServiceRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.bgPage,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      request.kind == SrKind.driver
                          ? AppIcons.car
                          : AppIcons.search,
                      size: 14.sp,
                      color: AppColors.fgSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      request.kind.label.toUpperCase(),
                      style: AppText.figtree(
                        size: 11,
                        weight: FontWeight.w700,
                        letterSpacing: 0.04 * 11,
                        color: AppColors.fgSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              StatusBadge(label: status.label, tone: status.tone),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            request.customer.name,
            style: AppText.figtree(size: 20, weight: FontWeight.w800),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(AppIcons.phone,
                  size: 14.sp, color: AppColors.fgTertiary),
              SizedBox(width: 6.w),
              Text(
                request.customer.phone,
                style: AppText.figtree(
                  size: 13.5,
                  weight: FontWeight.w500,
                  color: AppColors.fgSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.live});

  final LiveLocation live;

  @override
  Widget build(BuildContext context) {
    final moving = live.moving;
    final label = live.label;
    final lastUpdate = live.lastUpdate;

    return AppCard(
      accent: AppColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Live Location',
                  style:
                      AppText.figtree(size: 13, weight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: moving ? AppColors.blueBg : AppColors.greyBg,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  moving ? 'Moving' : 'Static',
                  style: AppText.figtree(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: moving ? AppColors.blueFg : AppColors.greyFg,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Map placeholder.
          Container(
            height: 100.h,
            decoration: BoxDecoration(
              color: AppColors.bgPage,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.borderSoft),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.pin,
                    size: 24.sp, color: AppColors.fgTertiary),
                SizedBox(height: 4.h),
                Text(
                  'Map view — coming soon',
                  style: AppText.figtree(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.fgMuted),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(AppIcons.pin,
                  size: 14.sp, color: AppColors.fgTertiary),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  label,
                  style:
                      AppText.figtree(size: 13, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Updated $lastUpdate',
            style: AppText.figtree(
                size: 12,
                weight: FontWeight.w400,
                color: AppColors.fgTertiary),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padded: false,
      child: Column(
        children: [
          _DetailRow(
            icon: AppIcons.car,
            label: 'Vehicle',
            value:
                '${request.vehicle.title} · ${request.vehicle.type}',
            sub: request.vehicle.plate,
          ),
          if (request.kind == SrKind.driver &&
              request.reason != null)
            _DetailRow(
              icon: AppIcons.note,
              label: 'Reason for hire',
              value: request.reason!,
            ),
          _DetailRow(
            icon: AppIcons.clock,
            label: 'When',
            value: '${request.when} · ${request.duration}',
          ),
          _DetailRow(
            icon: AppIcons.pin,
            label: 'Location',
            value: request.location,
            hasNav: true,
          ),
          _DetailRow(
            icon: AppIcons.rupee,
            label: 'Quoted fee',
            value: request.fee != null
                ? Formatters.money(request.fee!)
                : 'TBD',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.hasNav = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final bool hasNav;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 11.h, 16.w, 11.h),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(icon, size: 16.sp, color: AppColors.fgTertiary),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.figtree(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: AppColors.fgTertiary,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  style: AppText.figtree(
                      size: 13.5,
                      weight: FontWeight.w600,
                      height: 1.4),
                ),
                if (sub != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    sub!,
                    style: AppText.figtree(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.fgTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasNav)
            GestureDetector(
              onTap: () =>
                  AppToast.show(context, 'Opening navigation…'),
              child: Container(
                width: 34.r,
                height: 34.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(9.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Icon(AppIcons.nav,
                    size: 16.sp, color: AppColors.fgPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.label,
    required this.icon,
    required this.text,
  });

  final String label;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15.sp, color: AppColors.fgTertiary),
              SizedBox(width: 7.w),
              Text(label, style: AppText.eyebrow),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            text,
            style: AppText.figtree(
              size: 14,
              weight: FontWeight.w400,
              color: AppColors.fgSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignCard extends StatelessWidget {
  const _AssignCard({
    required this.request,
    required this.status,
    required this.assigneeId,
    required this.assignee,
    required this.onAssign,
  });

  final ServiceRequest request;
  final ServiceRequestStatus status;
  final String? assigneeId;
  final ({String name, String phone, String role})? assignee;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final canAssign = status != ServiceRequestStatus.completed &&
        status != ServiceRequestStatus.cancelled;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.kind == SrKind.driver
                ? 'Assigned Driver'
                : 'Assigned Inspector',
            style: AppText.figtree(size: 13.5, weight: FontWeight.w700),
          ),
          SizedBox(height: 12.h),
          if (assignee != null)
            Row(
              children: [
                Avatar(name: assignee!.name, size: 38),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignee!.name,
                        style: AppText.figtree(
                            size: 14.5, weight: FontWeight.w700),
                      ),
                      Text(
                        assignee!.role,
                        style: AppText.figtree(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: AppColors.fgTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canAssign)
                  AppButton(
                    label: 'Change',
                    kind: AppButtonKind.secondary,
                    size: AppButtonSize.sm,
                    onPressed: onAssign,
                  ),
              ],
            )
          else if (canAssign)
            AppButton(
              label: request.kind == SrKind.driver
                  ? 'Assign driver'
                  : 'Assign inspector',
              full: true,
              kind: AppButtonKind.secondary,
              icon: AppIcons.users,
              onPressed: onAssign,
            )
          else
            Text(
              'No assignee',
              style: AppText.figtree(
                size: 13.5,
                weight: FontWeight.w500,
                color: AppColors.fgMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.timeline});

  final List<SrTimelineEntry> timeline;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeline',
              style:
                  AppText.figtree(size: 13.5, weight: FontWeight.w700)),
          SizedBox(height: 12.h),
          for (var i = 0; i < timeline.length; i++)
            _TimelineRow(
              entry: timeline[i],
              isLast: i == timeline.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.isLast});

  final SrTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20.w,
            child: Column(
              children: [
                Container(
                  width: 10.r,
                  height: 10.r,
                  decoration: BoxDecoration(
                    color: entry.status.tone.foreground,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5.w,
                      color: AppColors.borderSoft,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge(
                      label: entry.status.label,
                      tone: entry.status.tone),
                  SizedBox(height: 3.h),
                  Text(
                    '${entry.at} · ${entry.by}',
                    style: AppText.figtree(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.fgTertiary,
                    ),
                  ),
                  if (entry.location != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      entry.location!,
                      style: AppText.figtree(
                        size: 12,
                        weight: FontWeight.w400,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

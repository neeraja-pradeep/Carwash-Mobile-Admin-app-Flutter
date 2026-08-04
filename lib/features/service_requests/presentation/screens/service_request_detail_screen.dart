import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/status/service_request_status.dart';
import 'package:new_flutter_project/core/widgets/app_bottom_sheet.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_dialog.dart';
import 'package:new_flutter_project/core/widgets/app_icon_button.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/avatar.dart';
import 'package:new_flutter_project/core/widgets/skeleton_card.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';

import '../../application/providers/service_requests_providers.dart';
import '../../infrastructure/models/driver_inspection_detail_response_model.dart';
import '../components/sr_assign_sheet.dart';

/// Full-screen detail for a single service request.
class ServiceRequestDetailScreen extends ConsumerStatefulWidget {
  const ServiceRequestDetailScreen({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<ServiceRequestDetailScreen> createState() =>
      _ServiceRequestDetailScreenState();
}

/// Strips Dart's default `Exception: ` prefix so toasts show the raw server
/// message (e.g. `Incorrect code.` instead of `Exception: otp: Incorrect
/// code.`).
String _msg(Object e) {
  final s = e.toString();
  return s.startsWith('Exception: ') ? s.substring(11) : s;
}

class _ServiceRequestDetailScreenState
    extends ConsumerState<ServiceRequestDetailScreen> {
  String _opsNote = '';
  bool _menuOpen = false;

  String get _nowStamp {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final min = now.minute.toString().padLeft(2, '0');
    final period = now.hour < 12 ? 'AM' : 'PM';
    return '${now.day} ${_getMonth(now.month)}, $hour:$min $period';
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    // Parse request ID - handle both numeric strings and references
    int? parsedId;
    try {
      parsedId = int.parse(widget.requestId.toString());
    } catch (e) {
      debugPrint('⚠️ Failed to parse requestId: ${widget.requestId}');
    }

    if (parsedId == null || parsedId <= 0) {
      return _buildShell(
        context,
        title: 'Request',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Invalid Request ID',
                  style: AppText.figtree(
                      size: 14,
                      color: AppColors.danger,
                      weight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Text('Received: "${widget.requestId}"',
                  style:
                      AppText.figtree(size: 12, color: AppColors.fgTertiary)),
              SizedBox(height: 4.h),
              Text('Expected: numeric ID (e.g., "77")',
                  style:
                      AppText.figtree(size: 11, color: AppColors.fgTertiary)),
              SizedBox(height: 16.h),
              AppButton(
                label: 'Go Back',
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      );
    }

    final requestId = parsedId;
    final detailAsync = ref.watch(serviceRequestDetailProvider(requestId));

    return detailAsync.when(
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
      error: (e, st) => _buildShell(
        context,
        title: 'Request',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Could not load request',
                  style: AppText.figtree(size: 14, color: AppColors.danger)),
              SizedBox(height: 8.h),
              Text(_msg(e),
                  style: AppText.figtree(size: 12, color: AppColors.fgTertiary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (detail) {
        return _DetailBody(
          requestId: requestId,
          detail: detail,
          opsNote: _opsNote,
          menuOpen: _menuOpen,
          nowStamp: _nowStamp,
          onMenuToggle: () => setState(() => _menuOpen = !_menuOpen),
          onMenuClose: () => setState(() => _menuOpen = false),
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
    required this.requestId,
    required this.detail,
    required this.opsNote,
    required this.menuOpen,
    required this.nowStamp,
    required this.onMenuToggle,
    required this.onMenuClose,
    required this.onNoteChange,
  });

  final int requestId;
  final DriverInspectionDetailResponse detail;
  final String opsNote;
  final bool menuOpen;
  final String nowStamp;
  final VoidCallback onMenuToggle;
  final VoidCallback onMenuClose;
  final ValueChanged<String> onNoteChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(detailActionProvider);
    final status = _parseStatus(detail.status);
    final hasWorker = detail.worker != null;
    final isPaid = detail.isPaid;

    _NextStep? nextStep;
    if (status == ServiceRequestStatus.created) {
      nextStep = _NextStep(
        label: 'Mark Contacted',
        action: actionState.isLoading
            ? null
            : () async {
                try {
                  await ref.read(detailActionProvider.notifier).updateStatus(
                        id: requestId,
                        status: 'contacted',
                      );
                  if (context.mounted) {
                    AppToast.show(context, 'Marked Contacted');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppToast.show(context, _msg(e));
                  }
                }
              },
      );
    } else if ((status == ServiceRequestStatus.contacted ||
            status == ServiceRequestStatus.assigned) &&
        hasWorker) {
      if (!isPaid) {
        nextStep = _NextStep(label: 'Awaiting Payment', action: null);
      } else {
        nextStep = _NextStep(
          label: 'Start Job',
          action: actionState.isLoading
              ? null
              : () async {
                  try {
                    await ref
                        .read(detailActionProvider.notifier)
                        .markArrived(requestId);
                    if (context.mounted) {
                      AppToast.show(context, 'Marked Arrived');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppToast.show(context, _msg(e));
                    }
                  }
                },
        );
      }
    } else if (status == ServiceRequestStatus.arrived && hasWorker) {
      nextStep = _NextStep(
        label: 'Start Job',
        action: actionState.isLoading
            ? null
            : () => _showOtpModal(context, ref, 'start'),
      );
    } else if (status == ServiceRequestStatus.inProgress) {
      nextStep = _NextStep(
        label: 'End Job',
        action: actionState.isLoading
            ? null
            : () => _showOtpModal(context, ref, 'end'),
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
              detail: detail,
              menuOpen: menuOpen,
              onMenuToggle: onMenuToggle,
              onMenuClose: onMenuClose,
              onAddNote: () => _showNoteModal(context),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(serviceRequestDetailProvider(requestId));
                  await ref
                      .read(serviceRequestDetailProvider(requestId).future);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                  children: [
                    _HeaderCard(detail: detail, status: status),
                    SizedBox(height: 14.h),
                    _DetailsCard(detail: detail),
                    SizedBox(height: 14.h),
                    if (detail.customerNote != null &&
                        detail.customerNote!.isNotEmpty) ...[
                      _NoteCard(
                        label: 'CUSTOMER NOTE',
                        icon: AppIcons.message,
                        text: detail.customerNote!,
                      ),
                      SizedBox(height: 14.h),
                    ],
                    if (opsNote.isNotEmpty) ...[
                      _NoteCard(
                        label: 'FOUNDER NOTE',
                        icon: AppIcons.note,
                        text: opsNote,
                        onEdit: () => _showNoteModal(context),
                      ),
                      SizedBox(height: 14.h),
                    ],
                    _AssignCard(
                      detail: detail,
                      status: status,
                      onAssign: () => _openAssignSheet(context, ref),
                    ),
                    SizedBox(height: 14.h),
                    _TimelineCard(detail: detail),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border: Border(top: BorderSide(color: AppColors.borderSoft)),
              ),
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
              child: SafeArea(
                top: false,
                child: isDone
                    ? AppButton(
                        label: status == ServiceRequestStatus.completed
                            ? 'Request completed'
                            : 'Request cancelled',
                        kind: AppButtonKind.secondary,
                        full: true,
                        disabled: true,
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _CancelButton(
                              isLoading: actionState.isLoading,
                              onTap: () => _confirmCancel(context, ref),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            flex: 2,
                            child: AppButton(
                              label: nextStep?.label ?? 'Assign first',
                              full: true,
                              disabled:
                                  nextStep == null || actionState.isLoading,
                              onPressed: nextStep?.action,
                            ),
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

  ServiceRequestStatus _parseStatus(String status) {
    switch (status) {
      case 'new':
      case 'created':
        return ServiceRequestStatus.created;
      case 'contacted':
        return ServiceRequestStatus.contacted;
      case 'assigned':
        return ServiceRequestStatus.assigned;
      case 'arrived':
        return ServiceRequestStatus.arrived;
      case 'in_progress':
        return ServiceRequestStatus.inProgress;
      case 'completed':
        return ServiceRequestStatus.completed;
      case 'cancelled':
        return ServiceRequestStatus.cancelled;
      default:
        return ServiceRequestStatus.created;
    }
  }

  void _showOtpModal(BuildContext context, WidgetRef ref, String mode) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20.w, 20.h, 20.w, MediaQuery.of(_).viewInsets.bottom + 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter ${mode == 'start' ? 'start' : 'end'} OTP',
                style: AppText.figtree(size: 18, weight: FontWeight.w700)),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'OTP',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            AppButton(
              label: 'Verify',
              full: true,
              onPressed: () async {
                final otp = controller.text.trim();
                try {
                  if (mode == 'start') {
                    await ref
                        .read(detailActionProvider.notifier)
                        .verifyStartOtp(
                          id: requestId,
                          otp: otp,
                        );
                  } else {
                    await ref.read(detailActionProvider.notifier).verifyEndOtp(
                          id: requestId,
                          otp: otp,
                        );
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    AppToast.show(context,
                        mode == 'start' ? 'Job started' : 'Job completed');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppToast.show(context, _msg(e));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAssignSheet(BuildContext context, WidgetRef ref) async {
    final isInspection = detail.requestType == 'inspection';
    await showAppBottomSheet<void>(
      context: context,
      title: isInspection ? 'Assign inspector' : 'Assign driver',
      maxHeightFactor: 0.64,
      builder: (sheetCtx) => SrAssignSheet(
        requestId: requestId,
        currentAssigneeId: detail.worker?.id.toString(),
        sheetContext: sheetCtx,
        onPick: (id, name) async {
          try {
            const slotId = 1;
            final workerType = isInspection ? 'inspector_id' : 'driver_id';
            await ref.read(detailActionProvider.notifier).assignWorker(
                  id: requestId,
                  workerId: int.parse(id),
                  slotId: slotId,
                  workerType: workerType,
                );
            if (context.mounted) {
              AppToast.show(context, 'Assigned to $name');
            }
          } catch (e) {
            if (context.mounted) {
              AppToast.show(context, _msg(e));
            }
          }
        },
      ),
    );
  }

  Future<void> _showNoteModal(BuildContext context) async {
    final controller = TextEditingController(text: opsNote);
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
            Text(opsNote.isEmpty ? 'Add note' : 'Edit note',
                style: AppText.figtree(size: 19, weight: FontWeight.w700)),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type a note…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    kind: AppButtonKind.secondary,
                    full: true,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: AppButton(
                    label: 'Save',
                    full: true,
                    onPressed: () {
                      onNoteChange(controller.text.trim());
                      Navigator.of(ctx).pop();
                      AppToast.show(
                        context,
                        controller.text.isEmpty ? 'Note cleared' : 'Note saved',
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Cancel this request?',
      body: 'The customer will be notified.',
      confirmLabel: 'Yes, cancel',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      try {
        await ref.read(detailActionProvider.notifier).cancelRequest(requestId);
        if (context.mounted) {
          AppToast.show(context, 'Request cancelled');
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.show(context, _msg(e));
        }
      }
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _NextStep {
  const _NextStep({required this.label, required this.action});
  final String label;
  final VoidCallback? action;
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onTap, this.isLoading = false});

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          height: 50.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.redBg,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.redFg),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20.h,
                  height: 20.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'Cancel',
                  style: AppText.figtree(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.redFg),
                ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.detail,
    required this.menuOpen,
    required this.onMenuToggle,
    required this.onMenuClose,
    required this.onAddNote,
  });

  final DriverInspectionDetailResponse detail;
  final bool menuOpen;
  final VoidCallback onMenuToggle;
  final VoidCallback onMenuClose;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final typeLabel =
        detail.requestType == 'inspection' ? 'Inspection' : 'Driver';
    return TopBar(
      title: '$typeLabel Request',
      subtitle: detail.reference,
      onBack: () => context.pop(),
      actions: [
        AppIconButton(
          icon: AppIcons.phone,
          iconSize: 20,
          semanticLabel: 'Call customer',
          onTap: () async {
            if (detail.customerPhone == null || detail.customerPhone!.isEmpty) {
              AppToast.show(context, 'No phone number available');
              return;
            }
            try {
              final uri = Uri(scheme: 'tel', path: detail.customerPhone);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                if (context.mounted) {
                  AppToast.show(context, 'Could not open dialer');
                }
              }
            } catch (e) {
              if (context.mounted) {
                AppToast.show(context, _msg(e));
              }
            }
          },
        ),
      ],
    );
  }
}

// ── Card components ──────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.detail, required this.status});

  final DriverInspectionDetailResponse detail;
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
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  detail.requestType == 'inspection' ? 'INSPECTION' : 'DRIVER',
                  style: AppText.figtree(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.fgSecondary),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.brandYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  status.label,
                  style: AppText.figtree(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.brandYellowDeep,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(detail.title,
              style: AppText.figtree(size: 15, weight: FontWeight.w700)),
          SizedBox(height: 4.h),
          Text(detail.reference,
              style: AppText.figtree(size: 12, color: AppColors.fgTertiary)),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.detail});

  final DriverInspectionDetailResponse detail;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
              label: 'Vehicle',
              value: detail.carLabel ?? detail.vehicleText ?? 'N/A'),
          _DetailRow(
            label: 'When',
            value:
                '${detail.appointmentDate} ${detail.startTime} · ${detail.durationLabel}',
          ),
          _DetailRow(label: 'Location', value: detail.addressText),
          _DetailRow(
              label: 'Fee',
              value: '₹${detail.quotedFee ?? detail.estimatedFee ?? '0'}'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.figtree(
                  size: 11,
                  color: AppColors.fgTertiary,
                  weight: FontWeight.w600)),
          SizedBox(height: 4.h),
          Text(value, style: AppText.figtree(size: 13)),
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
    this.onEdit,
  });

  final String label;
  final IconData icon;
  final String text;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.fgTertiary),
              SizedBox(width: 8.w),
              Text(label,
                  style: AppText.figtree(
                      size: 11,
                      color: AppColors.fgTertiary,
                      weight: FontWeight.w600)),
              const Spacer(),
              if (onEdit != null)
                GestureDetector(
                    onTap: onEdit,
                    child: Icon(AppIcons.edit,
                        size: 16, color: AppColors.fgTertiary)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(text, style: AppText.figtree(size: 13, height: 1.5)),
        ],
      ),
    );
  }
}

class _AssignCard extends StatelessWidget {
  const _AssignCard({
    required this.detail,
    required this.status,
    required this.onAssign,
  });

  final DriverInspectionDetailResponse detail;
  final ServiceRequestStatus status;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final worker = detail.worker;
    final needsAssignee = detail.worker == null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ASSIGNMENT',
              style: AppText.figtree(
                  size: 11,
                  color: AppColors.fgTertiary,
                  weight: FontWeight.w600)),
          SizedBox(height: 12.h),
          if (needsAssignee)
            AppButton(
              label:
                  '+ Assign ${detail.requestType == 'inspection' ? 'Inspector' : 'Driver'}',
              full: true,
              onPressed: onAssign,
            )
          else if (worker != null)
            Row(
              children: [
                Avatar(name: worker.name, size: 32),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker.name,
                          style: AppText.figtree(
                              size: 13, weight: FontWeight.w600)),
                      Text('★ ${worker.rating?.toStringAsFixed(1) ?? 'N/A'}',
                          style: AppText.figtree(
                              size: 11, color: AppColors.fgTertiary)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onAssign,
                  child: Text('Change',
                      style: AppText.figtree(
                          size: 12,
                          color: AppColors.fgPrimary,
                          weight: FontWeight.w600)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.detail});

  final DriverInspectionDetailResponse detail;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIMELINE',
              style: AppText.figtree(
                  size: 11,
                  color: AppColors.fgTertiary,
                  weight: FontWeight.w600)),
          SizedBox(height: 12.h),
          if (detail.timeline.isEmpty)
            Text('No timeline entries',
                style: AppText.figtree(size: 13, color: AppColors.fgTertiary))
          else
            Column(
              children: [
                for (final entry in detail.timeline)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(entry.status,
                                style: AppText.figtree(
                                    size: 12, weight: FontWeight.w600)),
                            const Spacer(),
                            Text(entry.createdAt,
                                style: AppText.figtree(
                                    size: 11, color: AppColors.fgTertiary)),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text('by ${entry.actorName}',
                            style: AppText.figtree(
                                size: 11, color: AppColors.fgTertiary)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

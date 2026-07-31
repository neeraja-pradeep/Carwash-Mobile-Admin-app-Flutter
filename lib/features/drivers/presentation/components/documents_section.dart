import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_bottom_sheet.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/core/widgets/app_dialog.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/constants/app_options.dart';

import '../../application/providers/drivers_providers.dart';
import '../../domain/entities/field_driver.dart';
import '../../infrastructure/models/driver_response_model.dart';

/// The Documents card with inline list, add / edit / delete flow.
///
/// Two modes:
/// * **Local (add)** — [workerId] is null (the Hire form before the worker
///   exists). Front/Back are simple toggles; mutations are kept in memory and
///   surfaced via [onChanged].
/// * **Remote (detail / edit)** — [workerId] set. Picking a side uploads the
///   file (multipart), verify toggles PATCH, delete DELETEs; the provider
///   refreshes the underlying driver afterwards.
class DocumentsSection extends ConsumerStatefulWidget {
  const DocumentsSection({
    required this.documents,
    required this.onChanged,
    this.workerId,
    this.isInspector = false,
    super.key,
  });

  final List<DriverDocument> documents;
  final ValueChanged<List<DriverDocument>> onChanged;

  /// When set, document actions hit the API for this worker.
  final String? workerId;
  final bool isInspector;

  @override
  ConsumerState<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends ConsumerState<DocumentsSection> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  bool get _remote => widget.workerId != null;

  /// Resolve a possibly-relative document URL to an absolute one using the
  /// configured API base host.
  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = dotenv.env['API_BASE_URL'] ?? '';
    if (base.isEmpty) return url;
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final u = url.startsWith('/') ? url : '/$url';
    return '$b$u';
  }

  /// Open a full-screen in-app preview of a document's uploaded sides.
  void _openDocPreview(BuildContext context, DriverDocument doc) {
    final sides = <({String label, String url})>[];
    final front = doc.frontFileUrl;
    final back = doc.backFileUrl;
    if (front != null && front.trim().isNotEmpty) {
      sides.add((label: 'Front', url: _resolveUrl(front)));
    }
    if (back != null && back.trim().isNotEmpty) {
      sides.add((label: 'Back', url: _resolveUrl(back)));
    }
    if (sides.isEmpty) {
      AppToast.show(context, 'No file uploaded for ${doc.type}');
      return;
    }
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (_) => _DocPreviewDialog(title: doc.type, sides: sides),
    );
  }

  // ── Remote helpers ───────────────────────────────────────────────────────

  Future<String?> _pickFile() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      return x?.path;
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Could not open gallery');
      }
      return null;
    }
  }

  Future<void> _uploadSide({
    required String kind,
    required String side,
    String? name,
  }) async {
    final path = await _pickFile();
    if (path == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(driverMutationsProvider).uploadDocument(
            widget.workerId!,
            isInspector: widget.isInspector,
            filePath: path,
            kind: kind,
            side: side,
            name: name,
          );
      if (mounted) AppToast.show(context, 'Document uploaded');
    } catch (e) {
      if (mounted) {
        AppToast.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleVerify(DriverDocument doc, {required bool front}) async {
    setState(() => _busy = true);
    try {
      await ref.read(driverMutationsProvider).patchDocument(
            widget.workerId!,
            doc.id,
            isInspector: widget.isInspector,
            frontVerified: front ? !doc.frontVerified : null,
            backVerified: front ? null : !doc.backVerified,
          );
      if (mounted) AppToast.show(context, 'Verification updated');
    } catch (e) {
      if (mounted) {
        AppToast.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteRemote(DriverDocument doc) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete this document?',
      body: "The uploaded photos will be removed. This can't be undone.",
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(driverMutationsProvider).deleteDocument(
            widget.workerId!,
            doc.id,
            isInspector: widget.isInspector,
          );
      if (mounted) AppToast.show(context, 'Document removed');
    } catch (e) {
      if (mounted) {
        AppToast.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Remote add sheet (pick type, then upload front/back) ───────────────────

  Future<void> _openRemoteSheet(
    BuildContext context,
    DriverDocument? existingDoc,
  ) {
    String type = existingDoc != null
        ? existingDoc.type
        : kDocTypes.first;
    String customTitle = existingDoc?.name ?? '';

    return showAppBottomSheet<void>(
      context: context,
      title: existingDoc != null ? 'Edit document' : 'Add document',
      maxHeightFactor: 0.85,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final isOther = type == 'Other';
          final kind = existingDoc?.kind ?? docKindFromLabel(type);
          final name = isOther
              ? (customTitle.trim().isEmpty ? null : customTitle.trim())
              : existingDoc?.name;

          Future<void> doUpload(String side) async {
            Navigator.of(sheetCtx).pop();
            await _uploadSide(kind: kind, side: side, name: name);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DOCUMENT TYPE',
                style: AppText.figtree(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.fgSecondary,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 11.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final t in kDocTypes)
                    AppChip(
                      label: t,
                      active: type == t,
                      onTap: existingDoc != null
                          ? () {}
                          : () => setSheet(() => type = t),
                    ),
                ],
              ),
              if (isOther && existingDoc == null) ...[
                SizedBox(height: 12.h),
                _SheetTextField(
                  label: 'Document name',
                  value: customTitle,
                  placeholder: 'e.g. Bank passbook',
                  onChanged: (t) => setSheet(() => customTitle = t),
                ),
              ],
              SizedBox(height: 20.h),
              Text(
                'UPLOAD PHOTOS',
                style: AppText.figtree(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.fgSecondary,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 11.h),
              Row(
                children: [
                  Expanded(
                    child: _UploadTile(
                      label: 'Front',
                      on: existingDoc?.front ?? false,
                      onTap: () => doUpload('front'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _UploadTile(
                      label: 'Back',
                      on: existingDoc?.back ?? false,
                      onTap: () => doUpload('back'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                'Tap a side to pick a photo and upload it. Front is required; add back only if the document has two sides.',
                style: AppText.figtree(
                  size: 11.5,
                  weight: FontWeight.w500,
                  color: AppColors.fgMuted,
                  height: 1.4,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Local add sheet (add mode — no worker id yet) ──────────────────────────

  Future<void> _openLocalSheet(BuildContext context, DriverDocument? existingDoc) {
    String type = existingDoc?.type ?? kDocTypes.first;
    String customTitle = existingDoc?.name ?? '';
    // The picked file paths, held until the worker exists and can own them.
    final frontNotifier = ValueNotifier<String?>(existingDoc?.localFrontPath);
    String? backPath = existingDoc?.localBackPath;

    void doSave(BuildContext sheetCtx) {
      final isOther = type == 'Other';
      final finalType = isOther
          ? (customTitle.trim().isEmpty ? 'Other' : customTitle.trim())
          : type;
      final id =
          existingDoc?.id ?? 'dc_${DateTime.now().millisecondsSinceEpoch}';
      final updated = DriverDocument(
        id: id,
        type: finalType,
        front: frontNotifier.value != null,
        back: backPath != null,
        kind: docKindFromLabel(finalType),
        // Custom names ride along so the upload names the document the same
        // way the remote sheet would.
        name: isOther && customTitle.trim().isNotEmpty
            ? customTitle.trim()
            : existingDoc?.name,
        localFrontPath: frontNotifier.value,
        localBackPath: backPath,
      );
      final docs = List<DriverDocument>.from(widget.documents);
      final idx = docs.indexWhere((d) => d.id == id);
      if (idx >= 0) {
        docs[idx] = updated;
        AppToast.show(context, 'Document updated');
      } else {
        docs.add(updated);
        AppToast.show(context, 'Document added');
      }
      widget.onChanged(docs);
      Navigator.of(sheetCtx).pop();
    }

    return showAppBottomSheet<void>(
      context: context,
      title: existingDoc != null ? 'Edit document' : 'Add document',
      maxHeightFactor: 0.85,
      footer: ValueListenableBuilder<String?>(
        valueListenable: frontNotifier,
        builder: (ctx, frontVal, _) => _DocSheetFooter(
          canSave: frontVal != null,
          hasDelete: existingDoc != null,
          onSave: () => doSave(ctx),
          onDeleteRequest: existingDoc != null
              ? () async {
                  final sheetNavigator = Navigator.of(ctx);
                  final confirmed = await showConfirmDialog(
                    context: context,
                    title: 'Delete this document?',
                    body:
                        "The uploaded photos will be removed. This can't be undone.",
                    confirmLabel: 'Delete',
                    destructive: true,
                  );
                  if (confirmed && context.mounted) {
                    final docs = widget.documents
                        .where((d) => d.id != existingDoc.id)
                        .toList();
                    widget.onChanged(docs);
                    sheetNavigator.pop();
                    AppToast.show(context, 'Document removed');
                  }
                }
              : null,
        ),
      ),
      builder: (ctx) => ValueListenableBuilder<String?>(
        valueListenable: frontNotifier,
        builder: (ctx2, frontVal, _) => StatefulBuilder(
          builder: (ctx3, setSheet) => _DocSheetBody(
            type: type,
            customTitle: customTitle,
            front: frontVal != null,
            back: backPath != null,
            onTypeChanged: (t) => setSheet(() => type = t),
            onTitleChanged: (t) => setSheet(() => customTitle = t),
            // Same picker the remote sheet uses — the file is held here and
            // uploaded once the hire call hands back a worker id.
            onFrontToggle: () async {
              final path = await _pickFile();
              if (path != null) frontNotifier.value = path;
            },
            onBackToggle: () async {
              final path = await _pickFile();
              if (path != null) setSheet(() => backPath = path);
            },
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, DriverDocument? existingDoc) {
    if (_remote) {
      _openRemoteSheet(context, existingDoc);
    } else {
      _openLocalSheet(context, existingDoc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = widget.documents;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DOCUMENTS',
                style: AppText.figtree(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.fgSecondary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${docs.length}',
                style: AppText.figtree(
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: AppColors.fgTertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Empty state
          if (docs.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Text(
                'No documents yet — add license, Aadhaar, police verification, etc.',
                style: AppText.figtree(
                  size: 13,
                  weight: FontWeight.w500,
                  color: AppColors.fgMuted,
                ),
              ),
            ),

          // Document rows
          if (docs.isNotEmpty)
            Column(
              children: [
                for (var i = 0; i < docs.length; i++) ...[
                  if (i > 0) Divider(height: 1.h, color: AppColors.borderSoft),
                  _DocRow(
                    doc: docs[i],
                    remote: _remote,
                    onView: () => _openDocPreview(context, docs[i]),
                    onEdit: () => _openSheet(context, docs[i]),
                    onVerifyFront:
                        _remote ? () => _toggleVerify(docs[i], front: true) : null,
                    onVerifyBack: _remote
                        ? () => _toggleVerify(docs[i], front: false)
                        : null,
                    onDelete: _remote ? () => _deleteRemote(docs[i]) : null,
                  ),
                ],
              ],
            ),

          // Add document button
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: _busy ? null : () => _openSheet(context, null),
            child: Container(
              width: double.infinity,
              height: 44.h,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(11.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.plus,
                    size: 16.sp,
                    color: AppColors.fgSecondary,
                  ),
                  SizedBox(width: 7.w),
                  Text(
                    _busy ? 'Working…' : 'Add document',
                    style: AppText.figtree(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.fgSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Doc row ───────────────────────────────────────────────────────────────────

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.doc,
    required this.remote,
    required this.onView,
    required this.onEdit,
    this.onVerifyFront,
    this.onVerifyBack,
    this.onDelete,
  });

  final DriverDocument doc;
  final bool remote;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback? onVerifyFront;
  final VoidCallback? onVerifyBack;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 11.h),
      child: Row(
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: AppColors.bgPage,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              AppIcons.note,
              size: 18.sp,
              color: AppColors.fgSecondary,
            ),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.figtree(
                    size: 13.5,
                    weight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    // Badges reflect whether each side has been uploaded.
                    // In remote mode they also act as verify toggles (onTap).
                    _SideBadge(
                      label: 'Front',
                      on: doc.front,
                      verified: doc.frontVerified,
                      onTap: onVerifyFront,
                    ),
                    SizedBox(width: 6.w),
                    _SideBadge(
                      label: 'Back',
                      on: doc.back,
                      verified: doc.backVerified,
                      onTap: onVerifyBack,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _IconAction(
            icon: AppIcons.search,
            onTap: onView,
            semanticLabel: 'View',
          ),
          SizedBox(width: 6.w),
          _IconAction(
            icon: AppIcons.edit,
            onTap: onEdit,
            semanticLabel: 'Edit',
          ),
          if (remote && onDelete != null) ...[
            SizedBox(width: 6.w),
            _IconAction(
              icon: AppIcons.trash,
              onTap: onDelete!,
              semanticLabel: 'Delete',
            ),
          ],
        ],
      ),
    );
  }
}

class _SideBadge extends StatelessWidget {
  const _SideBadge({
    required this.label,
    required this.on,
    this.verified = false,
    this.onTap,
  });

  final String label;

  /// Whether the side has been uploaded.
  final bool on;

  /// Whether the uploaded side has also been verified/approved.
  final bool verified;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Three states: verified (green ✓), uploaded-not-verified (neutral •),
    // and missing (muted —).
    final Color bg;
    final Color fg;
    final String suffix;
    if (on && verified) {
      bg = AppColors.greenBg;
      fg = AppColors.greenFg;
      suffix = '✓';
    } else if (on) {
      bg = AppColors.bgPage;
      fg = AppColors.fgSecondary;
      suffix = '•';
    } else {
      bg = AppColors.bgPage;
      fg = AppColors.fgMuted;
      suffix = '—';
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Text(
          '$label $suffix',
          style: AppText.figtree(
            size: 10,
            weight: FontWeight.w600,
            color: fg,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32.r,
          height: 32.r,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Icon(icon, size: 15.sp, color: AppColors.fgSecondary),
        ),
      ),
    );
  }
}

// ── Doc Sheet body (local mode) ───────────────────────────────────────────────

class _DocSheetBody extends StatelessWidget {
  const _DocSheetBody({
    required this.type,
    required this.customTitle,
    required this.front,
    required this.back,
    required this.onTypeChanged,
    required this.onTitleChanged,
    required this.onFrontToggle,
    required this.onBackToggle,
  });

  final String type;
  final String customTitle;
  final bool front;
  final bool back;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onTitleChanged;

  /// Open the picker for that side. Named "toggle" historically, when the tiles
  /// only flipped a flag and no file was ever attached.
  final VoidCallback onFrontToggle;
  final VoidCallback onBackToggle;

  bool get _isOther => type == 'Other';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DOCUMENT TYPE',
          style: AppText.figtree(
            size: 11,
            weight: FontWeight.w700,
            color: AppColors.fgSecondary,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 11.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final t in kDocTypes)
              AppChip(
                label: t,
                active: type == t,
                onTap: () => onTypeChanged(t),
              ),
          ],
        ),
        if (_isOther) ...[
          SizedBox(height: 12.h),
          _SheetTextField(
            label: 'Document name',
            value: customTitle,
            placeholder: 'e.g. Bank passbook',
            onChanged: onTitleChanged,
          ),
        ],
        SizedBox(height: _isOther ? 8.h : 20.h),
        Text(
          'UPLOAD PHOTOS',
          style: AppText.figtree(
            size: 11,
            weight: FontWeight.w700,
            color: AppColors.fgSecondary,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 11.h),
        Row(
          children: [
            Expanded(
              child: _UploadTile(
                label: 'Front',
                on: front,
                onTap: onFrontToggle,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _UploadTile(
                label: 'Back',
                on: back,
                onTap: onBackToggle,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Text(
          'Tap a side to pick a photo. Front is required; add back only if the '
          'document has two sides. Photos upload when the driver is saved.',
          style: AppText.figtree(
            size: 11.5,
            weight: FontWeight.w500,
            color: AppColors.fgMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ── Doc sheet footer (local mode) ──────────────────────────────────────────────

class _DocSheetFooter extends StatelessWidget {
  const _DocSheetFooter({
    required this.canSave,
    required this.hasDelete,
    required this.onSave,
    required this.onDeleteRequest,
  });

  final bool canSave;
  final bool hasDelete;
  final VoidCallback onSave;
  final VoidCallback? onDeleteRequest;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (hasDelete) ...[
          Expanded(
            child: AppButton(
              label: 'Delete',
              kind: AppButtonKind.secondary,
              full: true,
              onPressed: onDeleteRequest,
            ),
          ),
          SizedBox(width: 10.w),
        ],
        Expanded(
          flex: hasDelete ? 2 : 1,
          child: AppButton(
            label: 'Save document',
            full: true,
            disabled: !canSave,
            onPressed: canSave ? onSave : null,
          ),
        ),
      ],
    );
  }
}

// ── Upload tile ───────────────────────────────────────────────────────────────

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 92.h,
        decoration: BoxDecoration(
          color: on ? const Color(0x24FAD93A) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: on ? AppColors.brandYellowDeep : AppColors.borderDefault,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              on ? AppIcons.checkCircle : AppIcons.plus,
              size: on ? 22.sp : 20.sp,
              color: on ? AppColors.fgPrimary : AppColors.fgTertiary,
            ),
            SizedBox(height: 6.h),
            Text(
              on ? '$label ✓' : label,
              style: AppText.figtree(
                size: 12,
                weight: FontWeight.w600,
                color: on ? AppColors.fgPrimary : AppColors.fgTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet text field ──────────────────────────────────────────────────────────

class _SheetTextField extends StatefulWidget {
  const _SheetTextField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  State<_SheetTextField> createState() => _SheetTextFieldState();
}

class _SheetTextFieldState extends State<_SheetTextField> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.value);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w600,
            color: AppColors.fgSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: TextField(
            controller: _ctrl,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: widget.placeholder,
              hintStyle: AppText.figtree(
                size: 14.5,
                weight: FontWeight.w400,
                color: AppColors.fgMuted,
              ),
            ),
            style: AppText.figtree(size: 14.5, weight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}

/// Full-screen in-app preview of a document's uploaded sides (front/back).
class _DocPreviewDialog extends StatelessWidget {
  const _DocPreviewDialog({required this.title, required this.sides});

  final String title;
  final List<({String label, String url})> sides;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SafeArea(
        child: Column(
          children: [
            // Header with title + close.
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.figtree(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(AppIcons.close, color: Colors.white, size: 22.sp),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                itemCount: sides.length,
                separatorBuilder: (_, __) => SizedBox(height: 16.h),
                itemBuilder: (_, i) {
                  final side = sides[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        side.label,
                        style: AppText.figtree(
                          size: 12,
                          weight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Image.network(
                            side.url,
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return SizedBox(
                                height: 220.h,
                                child: const Center(
                                  child: CircularProgressIndicator.adaptive(),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              height: 160.h,
                              alignment: Alignment.center,
                              color: Colors.white10,
                              child: Text(
                                'Could not load image',
                                style: AppText.figtree(
                                  size: 13,
                                  weight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

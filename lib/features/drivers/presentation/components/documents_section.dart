import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

import '../../domain/entities/field_driver.dart';

/// The Documents card with inline list, add / edit / delete flow.
///
/// Mirrors `DocumentsCard` + `DocSheet` in `screen_drivers.jsx`.
/// Uses [StatefulWidget] because the doc list is locally mutable.
class DocumentsSection extends StatefulWidget {
  const DocumentsSection({
    required this.documents,
    required this.onChanged,
    super.key,
  });

  final List<DriverDocument> documents;
  final ValueChanged<List<DriverDocument>> onChanged;

  @override
  State<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends State<DocumentsSection> {
  /// Opens the add/edit bottom sheet for [existingDoc] (null = add new).
  Future<void> _openSheet(BuildContext context, DriverDocument? existingDoc) {
    // Mutable state for the sheet (boxed so body+footer share state)
    String type = existingDoc?.type ?? kDocTypes.first;
    String customTitle = '';
    // ValueNotifier lets body and footer share the same `front` value reactively.
    final frontNotifier = ValueNotifier<bool>(existingDoc?.front ?? false);
    bool back = existingDoc?.back ?? false;

    void doSave(BuildContext sheetCtx) {
      final finalType = type == 'Other'
          ? (customTitle.trim().isEmpty ? 'Other' : customTitle.trim())
          : type;
      final id = existingDoc?.id ??
          'dc_${DateTime.now().millisecondsSinceEpoch}';
      final updated = DriverDocument(
        id: id,
        type: finalType,
        front: frontNotifier.value,
        back: back,
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
      footer: ValueListenableBuilder<bool>(
        valueListenable: frontNotifier,
        builder: (ctx, frontVal, _) => _DocSheetFooter(
          canSave: frontVal,
          hasDelete: existingDoc != null,
          onSave: () => doSave(ctx),
          onDeleteRequest: existingDoc != null
              ? () async {
                  // Capture context-dependent objects before the await gap.
                  final messenger = ScaffoldMessenger.of(context);
                  final confirmed = await showConfirmDialog(
                    context: context,
                    title: 'Delete this document?',
                    body:
                        "The uploaded photos will be removed. This can't be undone.",
                    confirmLabel: 'Delete',
                    destructive: true,
                  );
                  if (confirmed) {
                    final docs = widget.documents
                        .where((d) => d.id != existingDoc.id)
                        .toList();
                    widget.onChanged(docs);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Document removed')),
                    );
                  }
                }
              : null,
        ),
      ),
      builder: (ctx) => ValueListenableBuilder<bool>(
        valueListenable: frontNotifier,
        builder: (ctx2, frontVal, _) => StatefulBuilder(
          builder: (ctx3, setSheet) => _DocSheetBody(
            type: type,
            customTitle: customTitle,
            front: frontVal,
            back: back,
            onTypeChanged: (t) => setSheet(() => type = t),
            onTitleChanged: (t) => setSheet(() => customTitle = t),
            onFrontToggle: () {
              frontNotifier.value = !frontNotifier.value;
            },
            onBackToggle: () => setSheet(() => back = !back),
          ),
        ),
      ),
    );
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
                  if (i > 0)
                    Divider(height: 1.h, color: AppColors.borderSoft),
                  _DocRow(
                    doc: docs[i],
                    onView: () =>
                        AppToast.show(context, 'Viewing ${docs[i].type}'),
                    onEdit: () => _openSheet(context, docs[i]),
                  ),
                ],
              ],
            ),

          // Add document button
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () => _openSheet(context, null),
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
                    'Add document',
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
    required this.onView,
    required this.onEdit,
  });

  final DriverDocument doc;
  final VoidCallback onView;
  final VoidCallback onEdit;

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
                    _SideBadge(label: 'Front', on: doc.front),
                    SizedBox(width: 6.w),
                    _SideBadge(label: 'Back', on: doc.back),
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
        ],
      ),
    );
  }
}

class _SideBadge extends StatelessWidget {
  const _SideBadge({required this.label, required this.on});

  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: on ? AppColors.greenBg : AppColors.bgPage,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Text(
        on ? '$label ✓' : '$label —',
        style: AppText.figtree(
          size: 10,
          weight: FontWeight.w600,
          color: on ? AppColors.greenFg : AppColors.fgMuted,
          letterSpacing: 0.3,
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

// ── Doc Sheet body ────────────────────────────────────────────────────────────

/// Body of the add/edit document bottom sheet.
/// Mirrors `DocSheet` in `screen_drivers.jsx`.
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
          'Front is required. Add back only if the document has two sides.',
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

// ── Doc sheet footer ──────────────────────────────────────────────────────────

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

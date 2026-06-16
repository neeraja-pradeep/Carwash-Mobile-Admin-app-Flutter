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
/// Uses [StatefulWidget] because the doc list and sheet state are purely visual.
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
  // null = closed; empty object = add new; {doc: x} = edit existing
  DriverDocument? _sheetDoc; // existing doc being edited
  bool _sheetOpen = false;

  void _openAdd() => setState(() {
        _sheetDoc = null;
        _sheetOpen = true;
      });

  void _openEdit(DriverDocument doc) => setState(() {
        _sheetDoc = doc;
        _sheetOpen = true;
      });

  void _closeSheet() => setState(() => _sheetOpen = false);

  void _save(DriverDocument updated) {
    final docs = List<DriverDocument>.from(widget.documents);
    final idx = docs.indexWhere((d) => d.id == updated.id);
    if (idx >= 0) {
      docs[idx] = updated;
      AppToast.show(context, 'Document updated');
    } else {
      docs.add(updated);
      AppToast.show(context, 'Document added');
    }
    widget.onChanged(docs);
    _closeSheet();
  }

  void _delete(String id) {
    final docs = widget.documents.where((d) => d.id != id).toList();
    widget.onChanged(docs);
    _closeSheet();
    AppToast.show(context, 'Document removed');
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
                    onEdit: () => _openEdit(docs[i]),
                  ),
                ],
              ],
            ),

          // Add button
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: _openAdd,
            child: Container(
              width: double.infinity,
              height: 44.h,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(11.r),
                border: Border.all(
                  color: AppColors.borderDefault,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.plus, size: 16.sp, color: AppColors.fgSecondary),
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

          // Doc sheet
          if (_sheetOpen)
            _DocSheet(
              existingDoc: _sheetDoc,
              onClose: _closeSheet,
              onSave: _save,
              onDelete: _sheetDoc != null ? () => _delete(_sheetDoc!.id) : null,
            ),
        ],
      ),
    );
  }
}

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
          // Note icon tile
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

          // Type + side badges
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

          // View button
          _IconAction(icon: AppIcons.search, onTap: onView, semanticLabel: 'View'),
          SizedBox(width: 6.w),
          // Edit button
          _IconAction(icon: AppIcons.edit, onTap: onEdit, semanticLabel: 'Edit'),
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

// ── Doc Sheet (add / edit) ────────────────────────────────────────────────────

/// Bottom sheet for adding or editing a document.
/// Mirrors `DocSheet` in `screen_drivers.jsx`.
class _DocSheet extends StatefulWidget {
  const _DocSheet({
    required this.existingDoc,
    required this.onClose,
    required this.onSave,
    required this.onDelete,
  });

  final DriverDocument? existingDoc;
  final VoidCallback onClose;
  final ValueChanged<DriverDocument> onSave;
  final VoidCallback? onDelete;

  @override
  State<_DocSheet> createState() => _DocSheetState();
}

class _DocSheetState extends State<_DocSheet> {
  late String _type;
  late String _customTitle;
  late bool _front;
  late bool _back;

  @override
  void initState() {
    super.initState();
    final ex = widget.existingDoc;
    _type = ex?.type ?? kDocTypes.first;
    _customTitle = '';
    _front = ex?.front ?? false;
    _back = ex?.back ?? false;

    // Show sheet immediately
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  void _show() {
    showAppBottomSheet<void>(
      context: context,
      title: widget.existingDoc != null ? 'Edit document' : 'Add document',
      builder: (_) => _DocSheetBody(
        type: _type,
        customTitle: _customTitle,
        front: _front,
        back: _back,
        onTypeChanged: (t) => setState(() => _type = t),
        onTitleChanged: (t) => setState(() => _customTitle = t),
        onFrontToggle: () => setState(() => _front = !_front),
        onBackToggle: () => setState(() => _back = !_back),
        onDeleteRequest: widget.onDelete != null
            ? () async {
                final confirmed = await showConfirmDialog(
                  context: context,
                  title: 'Delete this document?',
                  body:
                      "The uploaded photos will be removed. This can't be undone.",
                  confirmLabel: 'Delete',
                  destructive: true,
                );
                if (confirmed) {
                  widget.onDelete!();
                }
              }
            : null,
      ),
      footer: _DocSheetFooter(
        canSave: _front,
        hasDelete: widget.onDelete != null,
        onSave: () {
          final finalType =
              _type == 'Other' ? (_customTitle.trim().isEmpty ? 'Other' : _customTitle.trim()) : _type;
          final id = widget.existingDoc?.id ??
              'dc_${DateTime.now().millisecondsSinceEpoch}';
          widget.onSave(
            DriverDocument(
              id: id,
              type: finalType,
              front: _front,
              back: _back,
            ),
          );
          Navigator.of(context).pop();
        },
        onDeleteRequest: widget.onDelete != null
            ? () async {
                final confirmed = await showConfirmDialog(
                  context: context,
                  title: 'Delete this document?',
                  body:
                      "The uploaded photos will be removed. This can't be undone.",
                  confirmLabel: 'Delete',
                  destructive: true,
                );
                if (confirmed) {
                  widget.onDelete!();
                  Navigator.of(context).pop();
                }
              }
            : null,
      ),
      maxHeightFactor: 0.85,
    ).then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

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
    this.onDeleteRequest,
  });

  final String type;
  final String customTitle;
  final bool front;
  final bool back;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback onFrontToggle;
  final VoidCallback onBackToggle;
  final VoidCallback? onDeleteRequest;

  bool get _isOther => type == 'Other';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type section
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

        // Custom name field for "Other"
        if (_isOther) ...[
          SizedBox(height: 12.h),
          _TextField(
            label: 'Document name',
            value: customTitle,
            placeholder: 'e.g. Bank passbook',
            onChanged: onTitleChanged,
          ),
        ],
        SizedBox(height: _isOther ? 8.h : 20.h),

        // Upload photos
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
              child: _UploadTile(label: 'Front', on: front, onTap: onFrontToggle),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _UploadTile(label: 'Back', on: back, onTap: onBackToggle),
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
          color: on
              ? const Color(0x24FAD93A) // rgba(250,217,58,0.14)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                on ? AppColors.brandYellowDeep : AppColors.borderDefault,
            style: on ? BorderStyle.solid : BorderStyle.solid,
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

class _TextField extends StatefulWidget {
  const _TextField({
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
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
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

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/typography.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_button.dart';

/// Generic single-field edit sheet, or an info-only sheet (no input).
///
/// Mirrors `BottomSheet open={!!edit}` in `screen_settings.jsx`. When [info]
/// is non-null it renders an info paragraph. When [label] is non-null it
/// renders a text/numeric input.
///
/// [onSaved] receives the entered value and should perform the persistence
/// (PATCH) — it may throw to keep the sheet open (the caller shows the error
/// toast). The sheet closes only on success.
Future<void> showEditFieldSheet(
  BuildContext context, {
  required String title,
  String? label,
  String? initialValue,
  String? info,
  bool numeric = false,
  String? suffix,
  Future<void> Function(String value)? onSaved,
}) {
  final controller = TextEditingController(text: initialValue ?? '');
  return showAppBottomSheet<void>(
    context: context,
    title: title,
    maxHeightFactor: 0.6,
    footer: label != null && onSaved != null
        ? _EditFooter(controller: controller, onSaved: onSaved)
        : const _InfoFooter(),
    builder: (ctx) => _EditBody(
      controller: controller,
      info: info,
      label: label,
      numeric: numeric,
      suffix: suffix,
    ),
  ).whenComplete(controller.dispose);
}

// ── Footer variants ────────────────────────────────────────────────────────────

class _EditFooter extends StatefulWidget {
  const _EditFooter({required this.controller, required this.onSaved});

  final TextEditingController controller;
  final Future<void> Function(String value) onSaved;

  @override
  State<_EditFooter> createState() => _EditFooterState();
}

class _EditFooterState extends State<_EditFooter> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSaved(widget.controller.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // Caller surfaces the error toast; keep the sheet open to retry.
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Cancel',
            kind: AppButtonKind.secondary,
            full: true,
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: AppButton(
            label: _saving ? 'Saving…' : 'Save',
            full: true,
            disabled: _saving,
            onPressed: _saving ? null : _save,
          ),
        ),
      ],
    );
  }
}

class _InfoFooter extends StatelessWidget {
  const _InfoFooter();

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Got it',
      full: true,
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _EditBody extends StatelessWidget {
  const _EditBody({
    required this.controller,
    this.info,
    this.label,
    this.numeric = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String? info;
  final String? label;
  final bool numeric;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (info != null)
          Padding(
            padding: EdgeInsets.only(bottom: label != null ? 16.h : 0),
            child: Text(
              info!,
              style: AppText.figtree(
                size: 13.5,
                weight: FontWeight.w400,
                color: AppColors.fgSecondary,
                height: 1.55,
              ),
            ),
          ),
        if (label != null) ...[
          Text(
            label!,
            style: AppText.figtree(
              size: 12.5,
              weight: FontWeight.w600,
              color: AppColors.fgSecondary,
            ),
          ),
          SizedBox(height: 7.h),
          Container(
            height: 50.h,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType:
                        numeric ? TextInputType.number : TextInputType.text,
                    style: AppText.figtree(size: 14, weight: FontWeight.w500),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
                      isDense: true,
                      suffixText: suffix,
                      suffixStyle: AppText.figtree(
                        size: 13,
                        weight: FontWeight.w500,
                        color: AppColors.fgSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

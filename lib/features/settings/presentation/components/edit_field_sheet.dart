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
/// renders a text/numeric input. Both can coexist (refund tiers: info only).
Future<void> showEditFieldSheet(
  BuildContext context, {
  required String title,
  String? label,
  String? initialValue,
  String? info,
  bool numeric = false,
  String? suffix,
  required VoidCallback onSaved,
}) {
  return showAppBottomSheet<void>(
    context: context,
    title: title,
    maxHeightFactor: 0.6,
    footer: label != null
        ? _EditFooter(onSaved: onSaved)
        : const _InfoFooter(),
    builder: (ctx) => _EditBody(
      info: info,
      label: label,
      initialValue: initialValue,
      numeric: numeric,
      suffix: suffix,
    ),
  );
}

// ── Footer variants ────────────────────────────────────────────────────────────

class _EditFooter extends StatelessWidget {
  const _EditFooter({required this.onSaved});

  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Cancel',
            kind: AppButtonKind.secondary,
            full: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: AppButton(
            label: 'Save',
            full: true,
            onPressed: () {
              Navigator.of(context).pop();
              onSaved();
            },
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

class _EditBody extends StatefulWidget {
  const _EditBody({
    this.info,
    this.label,
    this.initialValue,
    this.numeric = false,
    this.suffix,
  });

  final String? info;
  final String? label;
  final String? initialValue;
  final bool numeric;
  final String? suffix;

  @override
  State<_EditBody> createState() => _EditBodyState();
}

class _EditBodyState extends State<_EditBody> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.info != null)
          Padding(
            padding: EdgeInsets.only(bottom: widget.label != null ? 16.h : 0),
            child: Text(
              widget.info!,
              style: AppText.figtree(
                size: 13.5,
                weight: FontWeight.w400,
                color: AppColors.fgSecondary,
                height: 1.55,
              ),
            ),
          ),
        if (widget.label != null) ...[
          Text(
            widget.label!,
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
                    controller: _ctrl,
                    keyboardType: widget.numeric
                        ? TextInputType.number
                        : TextInputType.text,
                    style: AppText.figtree(size: 14, weight: FontWeight.w500),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
                      isDense: true,
                      suffixText: widget.suffix,
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

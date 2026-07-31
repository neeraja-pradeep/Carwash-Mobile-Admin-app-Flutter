import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/typography.dart';
import '../../../../../core/utils/phone_number.dart';
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
///
/// With [phone] true the field becomes an Indian mobile input: a fixed `+91`
/// prefix, ten digits in the field, and [onSaved] receives the E.164 form.
Future<void> showEditFieldSheet(
  BuildContext context, {
  required String title,
  String? label,
  String? initialValue,
  String? info,
  bool numeric = false,
  bool phone = false,
  String? suffix,
  Future<void> Function(String value)? onSaved,
}) {
  final controller = TextEditingController(
    // A stored `+91 98765 43210` unpacks to the ten digits the field owns.
    text: phone
        ? PhoneNumber.national(initialValue ?? '')
        : (initialValue ?? ''),
  );
  return showAppBottomSheet<void>(
    context: context,
    title: title,
    maxHeightFactor: 0.6,
    footer: label != null && onSaved != null
        ? _EditFooter(controller: controller, onSaved: onSaved, phone: phone)
        : const _InfoFooter(),
    builder: (ctx) => _EditBody(
      controller: controller,
      info: info,
      label: label,
      numeric: numeric,
      phone: phone,
      suffix: suffix,
    ),
  );
  // Disposal belongs to _EditBody, not to this future: the future completes
  // the moment the route pops, while the sheet is still animating out and its
  // subtree still rebuilding against the controller.
}

// ── Footer variants ────────────────────────────────────────────────────────────

class _EditFooter extends StatefulWidget {
  const _EditFooter({
    required this.controller,
    required this.onSaved,
    this.phone = false,
  });

  final TextEditingController controller;
  final Future<void> Function(String value) onSaved;
  final bool phone;

  @override
  State<_EditFooter> createState() => _EditFooterState();
}

class _EditFooterState extends State<_EditFooter> {
  bool _saving = false;

  /// Half-typed numbers can't be saved — `e164` would hand the API an empty
  /// string and silently clear the setting.
  bool get _canSave =>
      !widget.phone || PhoneNumber.isValid(widget.controller.text);

  @override
  void initState() {
    super.initState();
    // Save stays disabled until the ten digits are in.
    if (widget.phone) widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    if (widget.phone) widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _save() async {
    if (_saving || !_canSave) return;
    setState(() => _saving = true);
    try {
      await widget.onSaved(
        widget.phone
            ? PhoneNumber.e164(widget.controller.text)
            : widget.controller.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // Caller surfaces the error toast; keep the sheet open to retry.
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _saving || !_canSave;
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
            disabled: blocked,
            onPressed: blocked ? null : _save,
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

/// Owns the sheet's controller: it is disposed when this element leaves the
/// tree, which is after the exit transition has finished — disposing it the
/// moment the route pops would pull it out from under the animating sheet.
class _EditBody extends StatefulWidget {
  const _EditBody({
    required this.controller,
    this.info,
    this.label,
    this.numeric = false,
    this.phone = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String? info;
  final String? label;
  final bool numeric;
  final bool phone;
  final String? suffix;

  @override
  State<_EditBody> createState() => _EditBodyState();
}

class _EditBodyState extends State<_EditBody> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final info = widget.info;
    final label = widget.label;
    final numeric = widget.numeric;
    final phone = widget.phone;
    final suffix = widget.suffix;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (info != null)
          Padding(
            padding: EdgeInsets.only(bottom: label != null ? 16.h : 0),
            child: Text(
              info,
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
            label,
            style: AppText.figtree(
              size: 12.5,
              weight: FontWeight.w600,
              color: AppColors.fgSecondary,
            ),
          ),
          SizedBox(height: 7.h),
          // The phone variant rebuilds as you type so the validation line
          // under the field tracks the value.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final error = phone ? PhoneNumber.errorFor(value.text) : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: error != null
                            ? AppColors.redFg
                            : AppColors.borderDefault,
                      ),
                    ),
                    child: Row(
                      children: [
                        // +91 is fixed — the field holds the ten digits only.
                        if (phone) ...[
                          SizedBox(width: 12.w),
                          Text(
                            PhoneNumber.dialCode,
                            style: AppText.figtree(
                              size: 14,
                              weight: FontWeight.w600,
                              color: AppColors.fgTertiary,
                            ),
                          ),
                        ],
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: phone
                                ? TextInputType.phone
                                : numeric
                                    ? TextInputType.number
                                    : TextInputType.text,
                            inputFormatters: phone
                                ? const [PhoneNumberInputFormatter()]
                                : null,
                            style: AppText.figtree(
                              size: 14,
                              weight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: phone ? 6.w : 12.w,
                                vertical: 0,
                              ),
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
                  if (error != null) ...[
                    SizedBox(height: 6.h),
                    Text(
                      error,
                      style: AppText.figtree(
                        size: 11.5,
                        weight: FontWeight.w500,
                        color: AppColors.redFg,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';

/// Damage types from the JSX prototype (`DMG_TYPES`).
const List<String> kDamageTypes = [
  'Minor scratch',
  'Major scratch',
  'Dent',
  'Glass crack',
  'Paint chip',
  'Interior stain',
  'Other',
];

/// Damage panel locations from the JSX prototype (`DMG_PANELS`).
const List<String> kDamagePanels = [
  'Front bumper',
  'Rear bumper',
  'Front-left door',
  'Front-right door',
  'Rear-left door',
  'Rear-right door',
  'Bonnet',
  'Boot',
  'Roof',
  'Windshield',
  'Interior',
  'Other',
];

/// Result returned by the damage check sheet when saved.
class DamageCheckResult {
  const DamageCheckResult({
    required this.checked,
    required this.issues,
    required this.types,
    required this.panels,
    required this.note,
  });

  final bool checked;
  final bool issues;
  final List<String> types;
  final List<String> panels;
  final String note;
}

/// Opens a damage-check bottom sheet for [phase] (`'pickup'` or `'drop'`).
/// Calls [onSave] with the result when the user taps "Save & Continue".
Future<void> showDamageCheckSheet({
  required BuildContext context,
  required String phase,
  required void Function(DamageCheckResult result) onSave,
}) async {
  final result = await showModalBottomSheet<DamageCheckResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x80000000),
    builder: (sheetCtx) => _DamageSheet(phase: phase),
  );
  if (result != null) {
    onSave(result);
  }
}

/// Full self-contained damage check bottom sheet.
class _DamageSheet extends StatefulWidget {
  const _DamageSheet({required this.phase});

  final String phase;

  @override
  State<_DamageSheet> createState() => _DamageSheetState();
}

class _DamageSheetState extends State<_DamageSheet> {
  bool _checked = false;
  bool _issues = false;
  List<String> _types = [];
  List<String> _panels = [];
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _toggle<T>(List<T> arr, T val, void Function(List<T>) update) {
    setState(() {
      update(arr.contains(val)
          ? arr.where((x) => x != val).toList()
          : [...arr, val]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title =
        'Damage Check · ${widget.phase == 'pickup' ? 'Pickup' : 'Drop'}';
    final maxH = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: EdgeInsets.only(top: 10.h, bottom: 2.h),
            child: Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
            ),
          ),

          // Title row
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 12.h),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style:
                        AppText.figtree(size: 17, weight: FontWeight.w700),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    AppIcons.close,
                    size: 20.sp,
                    color: AppColors.fgSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photos stay on your phone — log only what\'s needed here.',
                    style: AppText.figtree(
                      size: 13,
                      weight: FontWeight.w400,
                      color: AppColors.fgTertiary,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Mandatory check toggle
                  GestureDetector(
                    onTap: () => setState(() => _checked = !_checked),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: _checked
                            ? AppColors.brandYellow
                            : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: _checked
                              ? AppColors.brandYellowDeep
                              : AppColors.borderDefault,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24.r,
                            height: 24.r,
                            decoration: BoxDecoration(
                              color: _checked
                                  ? AppColors.fgPrimary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(7.r),
                              border: _checked
                                  ? null
                                  : Border.all(
                                      color: AppColors.borderStrong,
                                      width: 2,
                                    ),
                            ),
                            child: _checked
                                ? Icon(
                                    AppIcons.check,
                                    size: 16.sp,
                                    color: AppColors.brandYellow,
                                  )
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'I have checked the vehicle for damages',
                              style: AppText.figtree(
                                size: 14,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Issues found?
                  Text('ISSUES FOUND?', style: AppText.eyebrow),
                  SizedBox(height: 11.h),
                  Row(
                    children: [
                      Expanded(
                        child: _IssueButton(
                          label: 'No, all clear',
                          selected: !_issues,
                          danger: false,
                          onTap: () => setState(() => _issues = false),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _IssueButton(
                          label: 'Yes, issues',
                          selected: _issues,
                          danger: true,
                          onTap: () => setState(() => _issues = true),
                        ),
                      ),
                    ],
                  ),

                  if (_issues) ...[
                    SizedBox(height: 20.h),

                    // Damage types
                    Text('DAMAGE TYPE', style: AppText.eyebrow),
                    SizedBox(height: 11.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        for (final t in kDamageTypes)
                          _Pill(
                            label: t,
                            active: _types.contains(t),
                            onTap: () =>
                                _toggle(_types, t, (v) => _types = v),
                          ),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    // Panel / location
                    Text('PANEL / LOCATION', style: AppText.eyebrow),
                    SizedBox(height: 11.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        for (final p in kDamagePanels)
                          _Pill(
                            label: p,
                            active: _panels.contains(p),
                            onTap: () =>
                                _toggle(_panels, p, (v) => _panels = v),
                          ),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    // Notes
                    Text('NOTES', style: AppText.eyebrow),
                    SizedBox(height: 11.h),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe the issue…',
                        hintStyle: AppText.figtree(
                          size: 14,
                          weight: FontWeight.w400,
                          color: AppColors.fgMuted,
                        ),
                        contentPadding: EdgeInsets.all(12.r),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                              color: AppColors.borderDefault),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                              color: AppColors.borderDefault),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                              color: AppColors.brandYellowDeep),
                        ),
                      ),
                      style:
                          AppText.figtree(size: 14, weight: FontWeight.w400),
                    ),

                    SizedBox(height: 18.h),

                    // Voice note placeholder
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: double.infinity,
                        height: 46.h,
                        decoration: BoxDecoration(
                          color: AppColors.bgPage,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppIcons.play,
                              size: 16.sp,
                              color: AppColors.fgSecondary,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Add voice note (max 60s)',
                              style: AppText.figtree(
                                size: 13.5,
                                weight: FontWeight.w600,
                                color: AppColors.fgSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSoft)),
            ),
            child: _SaveButton(
              enabled: _checked,
              onTap: () => Navigator.of(context).pop(
                DamageCheckResult(
                  checked: _checked,
                  issues: _issues,
                  types: List.from(_types),
                  panels: List.from(_panels),
                  note: _noteCtrl.text.trim(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 54.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.brandYellow : AppColors.borderSoft,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          'Save & Continue',
          style: AppText.figtree(
            size: 16,
            weight: FontWeight.w700,
            color: enabled ? AppColors.fgPrimary : AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}

class _IssueButton extends StatelessWidget {
  const _IssueButton({
    required this.label,
    required this.selected,
    required this.danger,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color fg;
    if (selected) {
      if (danger) {
        bg = AppColors.redBg;
        border = AppColors.redFg;
        fg = AppColors.redFg;
      } else {
        bg = AppColors.fgPrimary;
        border = AppColors.fgPrimary;
        fg = AppColors.fgOnDark;
      }
    } else {
      bg = AppColors.bgCard;
      border = AppColors.borderDefault;
      fg = AppColors.fgPrimary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: AppText.figtree(
            size: 14,
            weight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: active ? AppColors.brandYellow : AppColors.bgCard,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color:
                active ? AppColors.brandYellowDeep : AppColors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: AppText.figtree(
            size: 12.5,
            weight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

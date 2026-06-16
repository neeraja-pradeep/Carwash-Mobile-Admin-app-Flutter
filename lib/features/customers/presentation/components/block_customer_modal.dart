import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_options.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';

/// Opens the Block Customer modal. Resolves with the selected block reason
/// when the user confirms, or `null` when they cancel.
Future<String?> showBlockCustomerModal(BuildContext context) {
  return showAppModal<String?>(
    context: context,
    builder: (dialogContext) => _BlockModalBody(dialogContext: dialogContext),
  );
}

class _BlockModalBody extends StatefulWidget {
  const _BlockModalBody({required this.dialogContext});

  final BuildContext dialogContext;

  @override
  State<_BlockModalBody> createState() => _BlockModalBodyState();
}

class _BlockModalBodyState extends State<_BlockModalBody> {
  String _reason = kBlockReasons.first;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Block this customer?',
          style: AppText.figtree(size: 19, weight: FontWeight.w700),
        ),
        SizedBox(height: 6.h),
        Text(
          "They won't be able to make new bookings. In-flight bookings continue.",
          style: AppText.figtree(
            size: 13.5,
            weight: FontWeight.w400,
            color: AppColors.fgSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: 18.h),
        Text(
          'REASON',
          style: AppText.eyebrow,
        ),
        SizedBox(height: 9.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final r in kBlockReasons)
              GestureDetector(
                onTap: () => setState(() => _reason = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999.r),
                    border: Border.all(
                      color: _reason == r
                          ? AppColors.redFg
                          : AppColors.borderDefault,
                    ),
                    color: _reason == r ? AppColors.redBg : AppColors.bgCard,
                  ),
                  child: Text(
                    r,
                    style: AppText.figtree(
                      size: 12.5,
                      weight: _reason == r ? FontWeight.w700 : FontWeight.w500,
                      color: _reason == r ? AppColors.redFg : AppColors.fgPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: TextField(
            controller: _noteCtrl,
            maxLines: 2,
            style: AppText.figtree(size: 14, weight: FontWeight.w400),
            decoration: InputDecoration(
              hintText: 'Optional notes…',
              hintStyle: AppText.figtree(
                size: 14,
                weight: FontWeight.w400,
                color: AppColors.fgMuted,
              ),
              contentPadding: EdgeInsets.all(12.r),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Back',
                kind: AppButtonKind.secondary,
                full: true,
                onPressed: () =>
                    Navigator.of(widget.dialogContext).pop(null),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    Navigator.of(widget.dialogContext).pop(_reason),
                child: Container(
                  height: 54.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Block',
                    style: AppText.figtree(
                      size: 15,
                      weight: FontWeight.w700,
                      color: AppColors.fgOnDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

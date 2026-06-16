import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import 'app_button.dart';

/// Presents a centred modal with a scale-in transition. [builder] returns the
/// modal body; the surrounding white card + scrim are provided.
Future<T?> showAppModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: AppColors.bgOverlay,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, _, __) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(28.w),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(22.r),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: builder(dialogContext),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// A confirmation dialog with a neutral "Back" and an accent/destructive
/// confirm action. Resolves to `true` when confirmed. Mirrors `ConfirmDialog`.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String body,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showAppModal<bool>(
    context: context,
    builder: (dialogContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.figtree(size: 19, weight: FontWeight.w700)),
        SizedBox(height: 8.h),
        Text(
          body,
          style: AppText.figtree(
            size: 14.5,
            weight: FontWeight.w400,
            color: AppColors.fgSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: 22.h),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Back',
                kind: AppButtonKind.secondary,
                full: true,
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: destructive
                  ? _SolidConfirmButton(
                      label: confirmLabel,
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    )
                  : AppButton(
                      label: confirmLabel,
                      full: true,
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Solid-red confirm button used only for destructive confirmations.
class _SolidConfirmButton extends StatelessWidget {
  const _SolidConfirmButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          label,
          style: AppText.figtree(
            size: 15,
            weight: FontWeight.w700,
            color: AppColors.fgOnDark,
          ),
        ),
      ),
    );
  }
}

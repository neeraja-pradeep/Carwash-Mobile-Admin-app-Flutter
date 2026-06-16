import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import 'app_icons.dart';

/// Presents the standard rounded bottom sheet: drag handle, optional titled
/// header with a close button, a scrollable body and an optional pinned footer.
/// Mirrors `BottomSheet` in `ui.jsx`.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  Widget? footer,
  double maxHeightFactor = 0.82,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.bgOverlay,
    builder: (sheetContext) {
      final maxHeight =
          MediaQuery.of(sheetContext).size.height * maxHeightFactor;
      return _SheetShell(
        title: title,
        footer: footer,
        maxHeight: maxHeight,
        child: builder(sheetContext),
      );
    },
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.child,
    required this.maxHeight,
    this.title,
    this.footer,
  });

  final Widget child;
  final double maxHeight;
  final String? title;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          if (title != null)
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 12.h),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: AppColors.borderSoft)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: AppText.figtree(size: 17, weight: FontWeight.w700),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 30.r,
                      height: 30.r,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.bgPage,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.close,
                        size: 18.sp,
                        color: AppColors.fgSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20.w,
                16.h,
                20.w,
                16.h + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: child,
            ),
          ),
          if (footer != null)
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderSoft)),
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

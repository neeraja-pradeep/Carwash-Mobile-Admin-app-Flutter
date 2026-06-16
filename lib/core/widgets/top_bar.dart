import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import 'app_icons.dart';

/// The standard screen app bar: optional back button, title + optional subtitle,
/// and a trailing action cluster. Used as a column child (not a Scaffold
/// appBar) to match the prototype's `TopBar`.
class TopBar extends StatelessWidget {
  const TopBar({
    required this.title,
    this.subtitle,
    this.onBack,
    this.leading,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 54.h),
          child: Row(
            children: [
              if (onBack != null)
                _BackButton(onBack: onBack!)
              else if (leading != null)
                leading!,
              if (onBack != null && leading != null) leading!,
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.titleBar,
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.figtree(
                            size: 12,
                            weight: FontWeight.w500,
                            color: AppColors.fgTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (actions.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 4.w),
      child: GestureDetector(
        onTap: onBack,
        behavior: HitTestBehavior.opaque,
        child: Semantics(
          button: true,
          label: 'Back',
          child: Padding(
            padding: EdgeInsets.all(6.r),
            child: Icon(AppIcons.back, size: 26.sp, color: AppColors.fgPrimary),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import 'app_card.dart';
import 'app_icons.dart';

/// A card with an expandable body — used for the detail-screen reference
/// sections (Timeline, Damage Check, Notes). The open/closed state is purely
/// visual, so a [StatefulWidget] is the correct tool here.
class Collapsible extends StatefulWidget {
  const Collapsible({
    required this.title,
    required this.child,
    this.summary,
    this.leading,
    this.initiallyOpen = false,
    super.key,
  });

  final String title;
  final Widget child;
  final String? summary;
  final Widget? leading;
  final bool initiallyOpen;

  @override
  State<Collapsible> createState() => _CollapsibleState();
}

class _CollapsibleState extends State<Collapsible> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  if (widget.leading != null) ...[
                    IconTheme(
                      data: const IconThemeData(color: AppColors.fgSecondary),
                      child: widget.leading!,
                    ),
                    SizedBox(width: 12.w),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppText.figtree(
                            size: 14,
                            weight: FontWeight.w700,
                          ),
                        ),
                        if (!_open && widget.summary != null)
                          Padding(
                            padding: EdgeInsets.only(top: 3.h),
                            child: Text(
                              widget.summary!,
                              style: AppText.figtree(
                                size: 12.5,
                                weight: FontWeight.w400,
                                color: AppColors.fgTertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      AppIcons.chevDown,
                      size: 20.sp,
                      color: AppColors.fgTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: EdgeInsets.fromLTRB(16.r, 0, 16.r, 16.r),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

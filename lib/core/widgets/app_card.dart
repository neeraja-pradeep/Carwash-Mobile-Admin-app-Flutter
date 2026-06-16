import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';

/// The base surface card used throughout the app.
///
/// White surface, 14px radius, hairline border and the soft, spread shadow
/// from the visual-polish pass (so cards read as elevated, not stroked). Pass
/// [onTap] to make the whole card tappable, [accent] for a coloured left edge.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padded = true,
    this.padding,
    this.accent,
    this.margin,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool padded;
  final EdgeInsetsGeometry? padding;
  final Color? accent;
  final EdgeInsetsGeometry? margin;

  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: const Color(0x0A14141E),
          offset: Offset(0, 1.h),
          blurRadius: 2.r,
        ),
        BoxShadow(
          color: const Color(0x1A14141E),
          offset: Offset(0, 6.h),
          blurRadius: 16.r,
          spreadRadius: -6.r,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      margin: margin,
      padding: padded ? (padding ?? EdgeInsets.all(16.r)) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: shadow,
      ),
      child: child,
    );

    if (accent != null) {
      // A coloured left edge layered over the rounded card.
      final accented = Stack(
        children: [
          content,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3.w,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14.r),
                  bottomLeft: Radius.circular(14.r),
                ),
              ),
            ),
          ),
        ],
      );
      return onTap == null
          ? accented
          : _tappable(accented);
    }

    return onTap == null ? content : _tappable(content);
  }

  Widget _tappable(Widget child) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: child,
      ),
    );
  }
}

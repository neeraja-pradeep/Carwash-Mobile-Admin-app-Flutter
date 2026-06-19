import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';

/// Button visual variants (mirrors the `Btn` kinds in `ui.jsx`).
enum AppButtonKind { primary, secondary, ghost, danger }

/// Button sizes — large (54px) for primary CTAs, small (44px) inline.
enum AppButtonSize { lg, sm }

/// The shared button. Primary uses the brand-yellow vertical gradient with a
/// soft glow; secondary is a bordered white pill; danger uses the red soft fill.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.kind = AppButtonKind.primary,
    this.size = AppButtonSize.lg,
    this.full = false,
    this.icon,
    this.disabled = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final AppButtonSize size;
  final bool full;
  final IconData? icon;
  final bool disabled;

  /// The brand-yellow gradient shared by the primary button and the FAB.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.brandYellowLight,
      AppColors.brandYellow,
      AppColors.brandYellowDeep,
    ],
    stops: [0, 0.55, 1],
  );

  @override
  Widget build(BuildContext context) {
    final h = (size == AppButtonSize.lg ? 54.0 : 44.0).h;
    final fontSize = size == AppButtonSize.lg ? 16.0 : 14.0;

    Color textColor;
    Color? solidColor;
    BoxBorder? border;
    Gradient? gradient;
    List<BoxShadow>? shadow;

    if (disabled) {
      solidColor = AppColors.borderSoft;
      textColor = AppColors.fgMuted;
    } else {
      switch (kind) {
        case AppButtonKind.primary:
          gradient = brandGradient;
          textColor = AppColors.fgPrimary;
          shadow = [
            BoxShadow(
              color: const Color(0x8CD6B112),
              offset: Offset(0, 2.h),
              blurRadius: 8.r,
              spreadRadius: -2.r,
            ),
          ];
        case AppButtonKind.secondary:
          solidColor = AppColors.bgCard;
          textColor = AppColors.fgPrimary;
          border = Border.all(color: AppColors.borderDefault);
        case AppButtonKind.ghost:
          solidColor = Colors.transparent;
          textColor = AppColors.fgSecondary;
        case AppButtonKind.danger:
          solidColor = AppColors.redBg;
          textColor = AppColors.redFg;
      }
    }

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: Container(
          height: h,
          width: full ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: solidColor,
            gradient: gradient,
            border: border,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: shadow,
          ),
          child: Row(
            mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: (fontSize + 3).sp, color: textColor),
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.figtree(
                    size: fontSize,
                    weight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

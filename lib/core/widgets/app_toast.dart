import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';

/// A non-blocking toast: a dark pill above the bottom nav with an optional
/// UNDO-style action, auto-dismissing after ~2.8s. Mirrors `Toast` in `ui.jsx`.
class AppToast {
  const AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  /// Shows [message] (replacing any visible toast). Triggered from UI callbacks
  /// only — never from providers/notifiers.
  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismiss();

    final entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        actionLabel: actionLabel,
        onAction: () {
          onAction?.call();
          _dismiss();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(milliseconds: 2800), _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 92.h,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            builder: (_, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 12.h),
                child: child,
              ),
            ),
            child: Container(
              constraints: BoxConstraints(minWidth: 240.w, maxWidth: 320.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
              decoration: BoxDecoration(
                color: AppColors.toastBg,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x66000000),
                    offset: Offset(0, 10.h),
                    blurRadius: 30.r,
                    spreadRadius: -6.r,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: AppText.figtree(
                        size: 14,
                        weight: FontWeight.w500,
                        color: AppColors.fgOnDark,
                      ),
                    ),
                  ),
                  if (actionLabel != null)
                    GestureDetector(
                      onTap: onAction,
                      child: Padding(
                        padding: EdgeInsets.only(left: 14.w),
                        child: Text(
                          actionLabel!.toUpperCase(),
                          style: AppText.figtree(
                            size: 13,
                            weight: FontWeight.w700,
                            color: AppColors.brandYellow,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

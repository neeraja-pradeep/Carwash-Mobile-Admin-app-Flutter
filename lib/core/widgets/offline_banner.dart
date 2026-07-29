import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../network/connectivity.dart';
import 'app_icons.dart';

/// Wraps the whole app with a persistent offline strip.
///
/// Deliberately **not** a full-screen takeover: whatever a screen has already
/// loaded stays readable and every control keeps working, because most of this
/// app is useful read-only. Losing signal mid-session should cost a thin bar,
/// not the page you were reading. Screens that genuinely cannot load fall back
/// to their own `ErrorView(kind: network)` as before.
///
/// Mounted once in `app.dart` around the router, so no screen needs changing.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);

    return Column(
      // Stretch, not the default `center`: a centred Column hands its children
      // loose width constraints, so the strip would size to its text's natural
      // width and overflow the screen instead of filling it.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: online ? const SizedBox(width: double.infinity) : const _Strip(),
        ),
        // The strip has absorbed the status-bar inset, so the routes below must
        // not pad for it a second time — their own SafeArea would push every
        // screen down by the notch height while the strip is up.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: !online,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.toastBg,
      child: Padding(
        padding: EdgeInsets.only(
          // Paint behind the status bar rather than leaving a pale gap above.
          top: MediaQuery.paddingOf(context).top,
        ),
        child: SizedBox(
          height: 30.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.cloudOff, size: 14.sp, color: AppColors.fgOnDark),
              SizedBox(width: 7.w),
              // Flexible so a narrow phone or a longer translation ellipsizes
              // rather than overflowing the strip.
              Flexible(
                child: Text(
                  'No internet — showing last loaded data',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.figtree(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: AppColors.fgOnDark,
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

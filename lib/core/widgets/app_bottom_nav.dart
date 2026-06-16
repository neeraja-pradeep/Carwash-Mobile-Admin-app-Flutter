import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';

/// A bottom-nav tab definition.
typedef NavItem = ({IconData icon, String label});

/// The shared 4-tab bottom navigation. The active tab fills its icon chip with
/// brand yellow; labels sit below. Used by both the admin shell and the scoped
/// driver app. Mirrors `BottomNav` in `ui.jsx`.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
        boxShadow: [
          BoxShadow(color: Color(0x0D000000), offset: Offset(0, -2), blurRadius: 16),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6.w, 8.h, 6.w, 6.h),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavTab(
                    item: items[i],
                    active: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.item, required this.active, required this.onTap});

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 46.w,
            height: 30.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.brandYellow : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(0x99D6B112),
                        offset: Offset(0, 2.h),
                        blurRadius: 6.r,
                        spreadRadius: -2.r,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              item.icon,
              size: 22.sp,
              color: active ? AppColors.fgPrimary : AppColors.fgTertiary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            item.label,
            style: AppText.figtree(
              size: 10.5,
              weight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.fgPrimary : AppColors.fgTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

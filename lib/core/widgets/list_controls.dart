import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../utils/formatters.dart';
import 'app_bottom_sheet.dart';
import 'app_icons.dart';

/// A sort option: `(value, label)`.
typedef SortOption = (String value, String label);

/// Filter pill — turns yellow and shows the active filter count when > 0.
class FilterButton extends StatelessWidget {
  const FilterButton({required this.onTap, this.count = 0, super.key});

  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return _Pill(
      onTap: onTap,
      active: active,
      icon: AppIcons.sliders,
      label: active ? 'Filter · $count' : 'Filter',
    );
  }
}

/// Sort pill — opens a "Sort by" bottom sheet of [options].
class SortControl extends StatelessWidget {
  const SortControl({
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String value;
  final List<SortOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = options.firstWhere(
      (o) => o.$1 == value,
      orElse: () => options.first,
    );
    return _Pill(
      onTap: () => _open(context),
      active: false,
      icon: AppIcons.sort,
      label: current.$2,
    );
  }

  Future<void> _open(BuildContext context) async {
    await showAppBottomSheet<void>(
      context: context,
      title: 'Sort by',
      maxHeightFactor: 0.6,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            GestureDetector(
              onTap: () {
                onChanged(option.$1);
                Navigator.of(sheetContext).pop();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
                decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: AppColors.borderSoft)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      option.$2,
                      style: AppText.figtree(
                        size: 14.5,
                        weight: option.$1 == value
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (option.$1 == value)
                      Icon(
                        AppIcons.check,
                        size: 19.sp,
                        color: AppColors.brandYellowDeep,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Unified list control row: result count on the left, Filter + Sort on the
/// right (one line). Mirrors `ListControls` in `ui.jsx`.
class ListControls extends StatelessWidget {
  const ListControls({
    required this.count,
    required this.noun,
    this.onFilter,
    this.filterCount = 0,
    this.sort,
    this.sortOptions,
    this.onSort,
    super.key,
  });

  final int count;
  final String noun;
  final VoidCallback? onFilter;
  final int filterCount;
  final String? sort;
  final List<SortOption>? sortOptions;
  final ValueChanged<String>? onSort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2.w, 0, 2.w, 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              Formatters.count(count, noun),
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w600,
                color: AppColors.fgTertiary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onFilter != null)
                FilterButton(onTap: onFilter!, count: filterCount),
              if (onFilter != null && onSort != null) SizedBox(width: 8.w),
              if (onSort != null && sortOptions != null && sort != null)
                SortControl(
                  value: sort!,
                  options: sortOptions!,
                  onChanged: onSort!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.onTap,
    required this.active,
    required this.icon,
    required this.label,
  });

  final VoidCallback onTap;
  final bool active;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: active ? AppColors.brandYellow : AppColors.bgCard,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: active ? AppColors.brandYellowDeep : AppColors.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15.sp, color: AppColors.fgPrimary),
            SizedBox(width: 6.w),
            Text(
              label,
              style: AppText.figtree(size: 12.5, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

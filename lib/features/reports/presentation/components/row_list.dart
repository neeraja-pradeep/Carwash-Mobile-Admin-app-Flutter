import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';

/// A labelled row data item used inside [RowList].
class RowItem {
  const RowItem({required this.name, this.sub, required this.value, this.color});

  final String name;
  final String? sub;
  final String value;
  final Color? color;
}

/// A card of divider-separated labelled rows with right-aligned values.
/// Mirrors `RowList` in `screen_reports.jsx`.
class RowList extends StatelessWidget {
  const RowList({required this.rows, super.key});

  final List<RowItem> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1.h, color: AppColors.borderSoft),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 16.w, vertical: 13.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].name,
                          style: AppText.figtree(
                            size: 13.5,
                            weight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (rows[i].sub != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            rows[i].sub!,
                            style: AppText.figtree(
                              size: 11.5,
                              color: AppColors.fgTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    rows[i].value,
                    style: AppText.figtree(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: rows[i].color ?? AppColors.fgPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

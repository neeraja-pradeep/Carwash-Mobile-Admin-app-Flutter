import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import 'app_icons.dart';

/// Inline list search bar: leading magnifier, text input and a clear button
/// that appears once there is a value. Mirrors `SearchField` in `ui.jsx`.
///
/// Holds its own [TextEditingController] kept in sync with [value] so callers
/// can drive it from a Riverpod `StateProvider` and still get the clear button.
class SearchField extends StatefulWidget {
  const SearchField({
    required this.value,
    required this.onChanged,
    this.hintText = 'Search',
    this.autofocus = false,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Icon(AppIcons.search, size: 19.sp, color: AppColors.fgTertiary),
          SizedBox(width: 9.w),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              cursorColor: AppColors.fgPrimary,
              style: AppText.figtree(size: 15, weight: FontWeight.w400),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: AppText.figtree(
                  size: 15,
                  weight: FontWeight.w400,
                  color: AppColors.fgMuted,
                ),
              ),
            ),
          ),
          if (widget.value.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onChanged('');
              },
              behavior: HitTestBehavior.opaque,
              child: Icon(
                AppIcons.close,
                size: 18.sp,
                color: AppColors.fgTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

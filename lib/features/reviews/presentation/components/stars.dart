import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/app_icons.dart';

/// A 5-star rating row (gold filled up to [rating], outline for the rest).
class Stars extends StatelessWidget {
  const Stars({required this.rating, this.size = 14, super.key});

  final int rating;
  final double size;

  static const Color _gold = Color(0xFFFEC319);
  static const Color _empty = Color(0xFFD7D7D7);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: EdgeInsets.only(right: i < 5 ? 2.w : 0),
            child: Icon(
              i <= rating ? AppIcons.star : AppIcons.starOutline,
              size: size.sp,
              color: i <= rating ? _gold : _empty,
            ),
          ),
      ],
    );
  }
}

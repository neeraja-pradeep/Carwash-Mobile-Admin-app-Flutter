import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_card.dart';

/// A single shimmering rounded box used to compose skeleton loaders.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 6,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius.r),
              gradient: LinearGradient(
                begin: Alignment(-1 - 2 * (1 - t), 0),
                end: Alignment(1 + 2 * t, 0),
                colors: const [
                  Color(0xFFE8E9EB),
                  Color(0xFFF3F3F5),
                  Color(0xFFE8E9EB),
                ],
                stops: const [0.3, 0.5, 0.7],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A list-card skeleton placeholder (badge + lines + footer). Mirrors
/// `SkeletonCard` in `ui.jsx`.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 78.w, height: 22.h, radius: 999),
              ShimmerBox(width: 120.w, height: 14.h),
            ],
          ),
          SizedBox(height: 14.h),
          ShimmerBox(width: 0.6.sw, height: 16.h),
          SizedBox(height: 14.h),
          ShimmerBox(width: 0.85.sw, height: 12.h),
          SizedBox(height: 8.h),
          ShimmerBox(width: 0.7.sw, height: 12.h),
          SizedBox(height: 16.h),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          SizedBox(height: 12.h),
          ShimmerBox(width: 100.w, height: 14.h),
        ],
      ),
    );
  }
}

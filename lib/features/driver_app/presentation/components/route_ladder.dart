import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';

/// The pickup → drop route ladder used on driver job cards and the job detail.
///
/// Mirrors the marker column in `screen_driver_app.jsx`: a filled brand-yellow
/// pickup dot, a dotted connector, and a hollow white drop dot with a strong
/// border. In [dense] (card) mode the two stops are plain text; otherwise each
/// stop carries an uppercase label ("Pickup" / [dropLabel]) above the value.
class RouteLadder extends StatelessWidget {
  const RouteLadder({
    required this.pickup,
    required this.drop,
    this.dropLabel = 'Drop',
    this.dense = false,
    super.key,
  });

  final String pickup;
  final String drop;

  /// Heading shown above the drop value when not [dense] — "Drop" (carwash) or
  /// "Trip" (driver hire).
  final String dropLabel;

  /// Card variant: no labels, single-line ellipsised stops.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    // `IntrinsicHeight` gives the Row a bounded height (driven by the taller
    // stops column) so `crossAxisAlignment.stretch` and the `Expanded`
    // connector can resolve. Without it the Row inherits the unbounded height
    // of the surrounding scroll view and `stretch` forces an infinite height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Marker column
          Padding(
          padding: EdgeInsets.only(top: 3.h),
          child: Column(
            children: [
              _Dot(
                color: AppColors.brandYellowDeep,
                border: false,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.h),
                  child: _DottedConnector(),
                ),
              ),
              _Dot(color: AppColors.bgCard, border: true),
            ],
          ),
        ),
        SizedBox(width: 11.w),
        // Stops
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Stop(
                label: dense ? null : 'Pickup',
                value: pickup,
                valueColor: AppColors.fgPrimary,
                dense: dense,
              ),
              SizedBox(height: dense ? 9.h : 11.h),
              _Stop(
                label: dense ? null : dropLabel,
                value: drop,
                valueColor: AppColors.fgSecondary,
                dense: dense,
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.dense,
  });

  final String? label;
  final String value;
  final Color valueColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: AppText.figtree(
              size: 9.5,
              weight: FontWeight.w700,
              color: AppColors.fgTertiary,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: 2.h),
        ],
        Text(
          value,
          maxLines: dense ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.border});

  final Color color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9.r,
      height: 9.r,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border:
            border ? Border.all(color: AppColors.borderStrong, width: 2) : null,
      ),
    );
  }
}

class _DottedConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2.w,
      // The connector fills the height the parent `Expanded` allots at layout
      // time. It must NOT claim an infinite intrinsic height, or the enclosing
      // `IntrinsicHeight` measurement blows up — so the child is zero-sized and
      // CustomPaint simply paints into the tight constraints it is handed.
      child: CustomPaint(
        painter: _DottedLinePainter(),
        child: const SizedBox(width: 2),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderDefault
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashH = 2.0;
    const gap = 3.0;
    var y = 0.0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(
          Offset(x, y), Offset(x, (y + dashH).clamp(0, size.height)), paint);
      y += dashH + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

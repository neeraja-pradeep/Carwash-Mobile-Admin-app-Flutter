import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../utils/formatters.dart';

/// Circular avatar showing up-to-two-letter initials, or an [imageAsset] when
/// provided. Mirrors `Avatar` in `ui.jsx`.
class Avatar extends StatelessWidget {
  const Avatar({required this.name, this.size = 38, this.imageAsset, super.key});

  final String name;
  final double size;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final dimension = size.r;
    if (imageAsset != null) {
      return Container(
        width: dimension,
        height: dimension,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.avatarBg,
          image: DecorationImage(
            image: AssetImage(imageAsset!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: dimension,
      height: dimension,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.avatarBg,
      ),
      child: Text(
        Formatters.initials(name),
        style: AppText.figtree(
          size: size * 0.38,
          weight: FontWeight.w700,
          color: AppColors.fgSecondary,
        ),
      ),
    );
  }
}

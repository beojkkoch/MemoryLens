import 'package:flutter/material.dart';

import 'package:memorylens/theme/app_theme.dart';

/// Violet circle with the camera aperture, the Memory Lens logo.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.camera_outlined,
        color: AppColors.primaryForeground,
        size: size * 0.45,
      ),
    );
  }
}

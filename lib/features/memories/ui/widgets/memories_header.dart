import 'package:flutter/material.dart';

import 'package:memorylens/theme/app_theme.dart';

/// Strip under the app bar: whether the gallery is connected and how many
/// photos Memory Lens already has.
class MemoriesHeader extends StatelessWidget {
  final bool connected;
  final int photoCount;

  const MemoriesHeader({
    super.key,
    required this.connected,
    required this.photoCount,
  });

  String get _countLabel => photoCount == 1 ? '1 foto' : '$photoCount fotos';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: connected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            connected ? 'Galería conectada' : 'Sin conectar',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _countLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

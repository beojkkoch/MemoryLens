import 'package:flutter/material.dart';

import 'package:memorylens/theme/app_theme.dart';

/// Strip that says the new photos of the device are being analyzed (HU-11).
class NewPhotosProgress extends StatelessWidget {
  final int count;

  const NewPhotosProgress({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: AppColors.background,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                count == 1
                    ? 'Analizando 1 foto nueva…'
                    : 'Analizando $count fotos nuevas…',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// «N nuevas fotos analizadas. Revisar etiquetas» (HU-11, CA3).
class NewPhotosNotice extends StatelessWidget {
  final int count;
  final VoidCallback onReview;
  final VoidCallback onDismiss;

  const NewPhotosNotice({
    super.key,
    required this.count,
    required this.onReview,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 18,
              color: AppColors.secondaryForeground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                count == 1
                    ? '1 nueva foto analizada.'
                    : '$count nuevas fotos analizadas.',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryForeground,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryForeground,
              ),
              onPressed: onReview,
              child: const Text('Revisar etiquetas'),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.secondaryForeground,
              tooltip: 'Cerrar aviso',
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

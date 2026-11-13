import 'package:flutter/material.dart';

import 'package:memorylens/theme/app_theme.dart';

/// The app's own question before the system one. It pops `true` for
/// «Permitir» and `false` for «No permitir»; closing it any other way gives
/// `null`, which counts as «No permitir».
class GalleryConsentDialog extends StatelessWidget {
  const GalleryConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Memory Lens quiere acceder a tus fotos',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: const Text(
        'Se usarán para analizarlas y organizarlas por ti',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No permitir'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Permitir',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

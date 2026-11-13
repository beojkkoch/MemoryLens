import 'package:flutter/material.dart';

import 'package:memorylens/theme/app_theme.dart';

/// Explains why nothing happens after the system said no to the photos.
/// When the permission is blocked it also offers «Abrir ajustes», because the
/// system will not ask again.
class AccessDeniedNotice extends StatelessWidget {
  final bool blocked;
  final Function() onOpenSettings;

  const AccessDeniedNotice({
    super.key,
    required this.blocked,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sin acceso a tus fotos no hay recuerdos para analizar.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            blocked
                ? 'El permiso quedó bloqueado. Actívalo desde los ajustes del '
                      'dispositivo para continuar.'
                : 'Puedes volver a intentarlo cuando quieras.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (blocked) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => onOpenSettings(),
                child: const Text(
                  'Abrir ajustes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

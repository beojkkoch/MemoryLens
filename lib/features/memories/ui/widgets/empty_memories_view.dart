import 'package:flutter/material.dart';

import 'package:memorylens/theme/app_theme.dart';

/// What Recuerdos shows while there is no photo yet.
class EmptyMemoriesView extends StatelessWidget {
  const EmptyMemoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.secondary,
          child: Icon(
            Icons.photo_library_outlined,
            size: 32,
            color: AppColors.secondaryForeground,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Aún no tienes recuerdos',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          'Conecta tu galería para que Memory Lens empiece a recordarlo todo '
          'por ti',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

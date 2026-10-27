import 'package:flutter/material.dart';

import 'package:memorylens/components/memory_lens_app_bar.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Placeholder for the profile summary, built in another task of the sprint.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MemoryLensAppBar(title: 'Mi perfil'),
      body: Center(
        child: Text(
          'Próximamente',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

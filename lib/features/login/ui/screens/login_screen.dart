import 'package:flutter/material.dart';

import 'package:memorylens/components/memory_lens_app_bar.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Placeholder for the sign in screen, built in another task of the sprint.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MemoryLensAppBar(title: 'Iniciar sesión'),
      body: Center(
        child: Text(
          'Próximamente',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

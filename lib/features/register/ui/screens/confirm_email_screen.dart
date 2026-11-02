import 'package:flutter/material.dart';

import 'package:memorylens/components/memory_lens_app_bar.dart';
import 'package:memorylens/components/primary_button.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Shown after signing up: the account works once the email is confirmed.
class ConfirmEmailScreen extends StatelessWidget {
  const ConfirmEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      appBar: const MemoryLensAppBar(title: 'Confirma tu correo'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Revisa tu correo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Enviamos un enlace de confirmación a ${email ?? 'tu correo'}. '
                'Ábrelo y luego inicia sesión para ver tu perfil.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: PrimaryButton(
            label: 'Ir a iniciar sesión',
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ),
      ),
    );
  }
}

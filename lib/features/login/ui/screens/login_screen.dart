import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:memorylens/components/error_message.dart';
import 'package:memorylens/components/labeled_text_field.dart';
import 'package:memorylens/components/memory_lens_app_bar.dart';
import 'package:memorylens/components/primary_button.dart';
import 'package:memorylens/features/login/ui/bloc/login_bloc.dart';
import 'package:memorylens/features/login/ui/bloc/login_event.dart';
import 'package:memorylens/features/login/ui/bloc/login_state.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Sign in form: email and password. Needs a LoginBloc above it.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() {
    return _LoginScreenState();
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _formError = 'Completa todos los campos');
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _formError = 'Escribe un correo válido');
      return;
    }
    setState(() => _formError = null);
    FocusScope.of(context).unfocus();
    context.read<LoginBloc>().add(
      LoginSubmitted(email: email, password: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) =>
          current.status == LoginStatus.success &&
          previous.status != LoginStatus.success,
      listener: (context, state) {
        Navigator.pushNamedAndRemoveUntil(context, '/recuerdos', (_) => false);
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          final error =
              _formError ??
              (state.status == LoginStatus.failure ? state.errorMessage : null);
          return Scaffold(
            appBar: const MemoryLensAppBar(title: 'Iniciar sesión'),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bienvenido de nuevo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ingresa con tu correo y contraseña para ver tu perfil.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LabeledTextField(
                      label: 'Correo electrónico',
                      controller: _emailController,
                      hint: 'hola@memorylens.ai',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    LabeledTextField(
                      label: 'Contraseña',
                      controller: _passwordController,
                      hint: '••••••••',
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: () => _submit(),
                    ),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes cuenta?',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/register',
                            ),
                            child: const Text(
                              'Regístrate',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null) ...[
                      ErrorMessage(message: error),
                      const SizedBox(height: 12),
                    ],
                    PrimaryButton(
                      label: 'Entrar',
                      isLoading: state.status == LoginStatus.loading,
                      onPressed: () => _submit(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

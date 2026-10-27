import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:memorylens/components/error_message.dart';
import 'package:memorylens/components/interest_chip.dart';
import 'package:memorylens/components/memory_lens_app_bar.dart';
import 'package:memorylens/components/primary_button.dart';
import 'package:memorylens/features/register/ui/bloc/register_bloc.dart';
import 'package:memorylens/features/register/ui/bloc/register_event.dart';
import 'package:memorylens/features/register/ui/bloc/register_state.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Sign up form: account data first, then the characterization (onboarding).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() {
    return _RegisterScreenState();
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();
  final _professionController = TextEditingController();
  final Set<int> _selectedInterestIds = {};
  final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  String? _formError;

  @override
  void initState() {
    super.initState();
    context.read<RegisterBloc>().add(RegisterInterestsRequested());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  void _toggleInterest(int id) {
    setState(() {
      if (!_selectedInterestIds.remove(id)) _selectedInterestIds.add(id);
    });
  }

  void _submit() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final city = _cityController.text.trim();
    final profession = _professionController.text.trim();
    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        city.isEmpty ||
        profession.isEmpty) {
      setState(() => _formError = 'Completa todos los campos');
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _formError = 'Escribe un correo válido');
      return;
    }
    if (password.length < 6) {
      setState(
        () => _formError = 'La contraseña debe tener al menos 6 caracteres',
      );
      return;
    }
    if (password != _confirmPasswordController.text) {
      setState(() => _formError = 'Las contraseñas no coinciden');
      return;
    }
    if (_selectedInterestIds.isEmpty) {
      setState(() => _formError = 'Elige al menos un interés');
      return;
    }
    setState(() => _formError = null);
    final bloc = context.read<RegisterBloc>();
    bloc.add(
      RegisterSubmitted(
        fullName: fullName,
        email: email,
        password: password,
        city: city,
        profession: profession,
        interests: bloc.state.interests
            .where((i) => _selectedInterestIds.contains(i.id))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state.status == RegisterStatus.success) {
          Navigator.pushNamedAndRemoveUntil(context, '/profile', (_) => false);
        }
      },
      child: BlocBuilder<RegisterBloc, RegisterState>(
        builder: (context, state) {
          final error =
              _formError ??
              (state.status == RegisterStatus.failure
                  ? state.errorMessage
                  : null);
          return Scaffold(
            appBar: const MemoryLensAppBar(title: 'Crear cuenta'),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StepProgress(),
                    const SizedBox(height: 20),
                    const _SectionTitle('Tus datos'),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Nombre completo',
                      controller: _fullNameController,
                      hint: 'Tu nombre',
                      textCapitalization: TextCapitalization.words,
                    ),
                    _Field(
                      label: 'Correo electrónico',
                      controller: _emailController,
                      hint: 'hola@memorylens.ai',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _Field(
                      label: 'Contraseña',
                      controller: _passwordController,
                      hint: '••••••••',
                      obscureText: true,
                    ),
                    _Field(
                      label: 'Confirmar contraseña',
                      controller: _confirmPasswordController,
                      hint: '••••••••',
                      obscureText: true,
                    ),
                    _Field(
                      label: 'Ciudad',
                      controller: _cityController,
                      hint: 'Bogotá',
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'CARACTERIZACIÓN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _SectionTitle(
                      'Cuéntanos de ti para que Memory Lens te dé mejores '
                      'recuerdos y recomendaciones',
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Profesión u ocupación',
                      controller: _professionController,
                      hint: 'Diseñadora de producto',
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const _FieldLabel('Intereses'),
                    const SizedBox(height: 8),
                    _buildInterests(state),
                    const SizedBox(height: 24),
                    if (error != null) ErrorMessage(message: error),
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
                  label: 'Comenzar',
                  isLoading: state.status == RegisterStatus.loading,
                  onPressed: () => _submit(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInterests(RegisterState state) {
    if (state.interestsStatus == InterestsStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (state.interestsStatus == InterestsStatus.failure) {
      return Row(
        children: [
          const Expanded(
            child: Text(
              'No pudimos cargar los intereses',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => context.read<RegisterBloc>().add(
              RegisterInterestsRequested(),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final interest in state.interests)
          InterestChip(
            label: interest.name,
            selected: _selectedInterestIds.contains(interest.id),
            onTap: () => _toggleInterest(interest.id),
          ),
      ],
    );
  }
}

/// Two filled bars that say the form covers steps 1 and 2.
class _StepProgress extends StatelessWidget {
  const _StepProgress();

  @override
  Widget build(BuildContext context) {
    Widget bar() {
      return Expanded(
        child: Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
    }

    return Row(
      children: [
        bar(),
        const SizedBox(width: 8),
        bar(),
        const SizedBox(width: 8),
        const Text(
          'Paso 1 y 2',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
    );
  }
}

/// Small label above a text field, as in the prototype.
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            autocorrect: !obscureText && keyboardType == null,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}

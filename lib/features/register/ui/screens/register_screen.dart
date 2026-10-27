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

/// Sign up form in two pages: account data first, then the characterization.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() {
    return _RegisterScreenState();
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _maxInterestLength = 40;

  final _pageController = PageController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();
  final _professionController = TextEditingController();
  final _newInterestController = TextEditingController();
  final Set<int> _selectedInterestIds = {};
  final List<String> _newInterests = [];
  final Set<String> _selectedNewInterests = {};
  final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  int _step = 0;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  String? _formError;

  @override
  void initState() {
    super.initState();
    context.read<RegisterBloc>().add(RegisterInterestsRequested());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    _professionController.dispose();
    _newInterestController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _formError = null;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_step == 1) {
      _goToStep(0);
    } else {
      Navigator.pop(context);
    }
  }

  String? _accountError() {
    final password = _passwordController.text;
    if (_fullNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        password.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _cityController.text.trim().isEmpty) {
      return 'Completa todos los campos';
    }
    if (!_emailPattern.hasMatch(_emailController.text.trim())) {
      return 'Escribe un correo válido';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (password != _confirmPasswordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  void _continue() {
    final error = _accountError();
    if (error != null) {
      setState(() => _formError = error);
      return;
    }
    _goToStep(1);
  }

  void _toggleInterest(int id) {
    setState(() {
      if (!_selectedInterestIds.remove(id)) _selectedInterestIds.add(id);
    });
  }

  void _toggleNewInterest(String name) {
    setState(() {
      if (!_selectedNewInterests.remove(name)) _selectedNewInterests.add(name);
    });
  }

  /// Adds the typed interest; if it already exists it only gets selected.
  void _addInterest() {
    final typed = _newInterestController.text.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (typed.isEmpty) return;
    if (typed.length > _maxInterestLength) {
      setState(
        () => _formError =
            'El interés debe tener máximo $_maxInterestLength caracteres',
      );
      return;
    }
    final name = typed[0].toUpperCase() + typed.substring(1);
    final key = name.toLowerCase();
    final interests = context.read<RegisterBloc>().state.interests;
    setState(() {
      _formError = null;
      _newInterestController.clear();
      for (final interest in interests) {
        if (interest.name.toLowerCase() == key) {
          _selectedInterestIds.add(interest.id);
          return;
        }
      }
      for (final existing in _newInterests) {
        if (existing.toLowerCase() == key) {
          _selectedNewInterests.add(existing);
          return;
        }
      }
      _newInterests.add(name);
      _selectedNewInterests.add(name);
    });
  }

  void _submit() {
    final profession = _professionController.text.trim();
    if (profession.isEmpty) {
      setState(() => _formError = 'Escribe tu profesión u ocupación');
      return;
    }
    if (_selectedInterestIds.isEmpty && _selectedNewInterests.isEmpty) {
      setState(() => _formError = 'Elige al menos un interés');
      return;
    }
    setState(() => _formError = null);
    final bloc = context.read<RegisterBloc>();
    bloc.add(
      RegisterSubmitted(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        city: _cityController.text.trim(),
        profession: profession,
        interests: bloc.state.interests
            .where((i) => _selectedInterestIds.contains(i.id))
            .toList(),
        newInterestNames: _newInterests
            .where((name) => _selectedNewInterests.contains(name))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state.status == RegisterStatus.success) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/profile',
              (_) => false,
            );
          }
        },
        child: BlocBuilder<RegisterBloc, RegisterState>(
          builder: (context, state) {
            final error =
                _formError ??
                (_step == 1 && state.status == RegisterStatus.failure
                    ? state.errorMessage
                    : null);
            return Scaffold(
              appBar: MemoryLensAppBar(
                title: 'Crear cuenta',
                onBack: () => _back(),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _StepProgress(step: _step),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildAccountStep(),
                          _buildCharacterizationStep(state),
                        ],
                      ),
                    ),
                  ],
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
                      _step == 0
                          ? PrimaryButton(
                              label: 'Continuar',
                              onPressed: () => _continue(),
                            )
                          : PrimaryButton(
                              label: 'Comenzar',
                              isLoading: state.status == RegisterStatus.loading,
                              onPressed: () => _submit(),
                            ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            obscureText: _hidePassword,
            trailing: _VisibilityToggle(
              hidden: _hidePassword,
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
          _Field(
            label: 'Confirmar contraseña',
            controller: _confirmPasswordController,
            hint: '••••••••',
            obscureText: _hideConfirmPassword,
            trailing: _VisibilityToggle(
              hidden: _hideConfirmPassword,
              onPressed: () =>
                  setState(() => _hideConfirmPassword = !_hideConfirmPassword),
            ),
          ),
          _Field(
            label: 'Ciudad',
            controller: _cityController,
            hint: 'Bogotá',
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterizationStep(RegisterState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
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
          const SizedBox(height: 6),
          TextField(
            controller: _newInterestController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            maxLength: _maxInterestLength,
            onSubmitted: (_) => _addInterest(),
            decoration: InputDecoration(
              hintText: 'Agrega otro interés',
              counterText: '',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add, color: AppColors.primary),
                tooltip: 'Agregar interés',
                onPressed: () => _addInterest(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInterests(state),
        ],
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
            onPressed: () =>
                context.read<RegisterBloc>().add(RegisterInterestsRequested()),
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
        for (final name in _newInterests)
          InterestChip(
            label: name,
            selected: _selectedNewInterests.contains(name),
            onTap: () => _toggleNewInterest(name),
          ),
      ],
    );
  }
}

/// One bar per step: violet when the step is reached, gray when it is not.
class _StepProgress extends StatelessWidget {
  final int step;

  const _StepProgress({required this.step});

  @override
  Widget build(BuildContext context) {
    Widget bar(int index) {
      return Expanded(
        child: AnimatedContainer(
          key: Key('step-bar-$index'),
          duration: const Duration(milliseconds: 250),
          height: 6,
          decoration: BoxDecoration(
            color: index <= step ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
    }

    return Row(
      children: [
        bar(0),
        const SizedBox(width: 8),
        bar(1),
        const SizedBox(width: 8),
        Text(
          'Paso ${step + 1} de 2',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Eye button that shows or hides a password field.
class _VisibilityToggle extends StatelessWidget {
  final bool hidden;
  final Function() onPressed;

  const _VisibilityToggle({required this.hidden, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.textSecondary,
      ),
      tooltip: hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
      onPressed: () => onPressed(),
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
  final Widget? trailing;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isPassword = trailing != null;
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
            autocorrect: !isPassword && keyboardType == null,
            enableSuggestions: !isPassword,
            decoration: InputDecoration(hintText: hint, suffixIcon: trailing),
          ),
        ],
      ),
    );
  }
}

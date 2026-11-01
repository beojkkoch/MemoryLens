import 'package:flutter/material.dart';

import 'package:memorylens/theme/app_theme.dart';

/// Text field with a small label above it, as in the prototype.
/// With [isPassword] it hides the text and shows the eye button.
class LabeledTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Function()? onSubmitted;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<LabeledTextField> createState() {
    return _LabeledTextFieldState();
  }
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: widget.controller,
            obscureText: widget.isPassword && _hidden,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autocorrect: !widget.isPassword && widget.keyboardType == null,
            enableSuggestions: !widget.isPassword,
            onSubmitted: (_) => widget.onSubmitted?.call(),
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: _hidden
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      onPressed: () => setState(() => _hidden = !_hidden),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

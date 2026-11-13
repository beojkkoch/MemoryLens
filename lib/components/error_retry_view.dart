import 'package:flutter/material.dart';

import 'package:memorylens/components/error_message.dart';
import 'package:memorylens/components/primary_button.dart';

/// Centered view for a screen that could not load: the reason in plain
/// Spanish and a «Reintentar» button.
class ErrorRetryView extends StatelessWidget {
  final String message;
  final Function() onRetry;

  /// Extra actions below the retry button, like a sign out link.
  final List<Widget> actions;

  const ErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorMessage(message: message),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Reintentar', onPressed: () => onRetry()),
            ...actions,
          ],
        ),
      ),
    );
  }
}

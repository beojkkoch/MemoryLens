import 'package:flutter/material.dart';

import 'package:memorylens/theme/app_theme.dart';

/// Replaces a widget that threw while building, so the rest of the screen
/// keeps working instead of showing the red error screen.
class ErrorFallback extends StatelessWidget {
  const ErrorFallback({super.key});

  @override
  Widget build(BuildContext context) {
    // It can be built outside of a Scaffold, so it brings its own direction.
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 32),
              SizedBox(height: 8),
              Text(
                'Algo salió mal en esta sección',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

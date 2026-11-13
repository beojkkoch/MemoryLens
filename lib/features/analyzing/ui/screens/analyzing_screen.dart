import 'package:flutter/material.dart';

import 'package:memorylens/components/memory_lens_app_bar.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Where the import and the analysis of the photos will show their progress.
/// For now it only confirms that both permissions were given; the import and
/// the analysis come in their own stories.
class AnalyzingScreen extends StatelessWidget {
  const AnalyzingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MemoryLensAppBar(title: 'Analizando'),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                'Estamos preparando tus fotos',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Memory Lens empezará a organizarlas por ti.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

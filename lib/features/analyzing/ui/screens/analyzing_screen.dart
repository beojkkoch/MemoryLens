import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:memorylens/components/error_retry_view.dart';
import 'package:memorylens/components/memory_lens_app_bar.dart';
import 'package:memorylens/components/primary_button.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_bloc.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_event.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_state.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Where the photos are imported once both permissions were given. Needs a
/// GalleryImportBloc above it.
///
/// It only says how the import is going. The progress bar with the numbers
/// comes with its own story, and the analysis of the photos with another.
class AnalyzingScreen extends StatelessWidget {
  const AnalyzingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MemoryLensAppBar(title: 'Analizando'),
      body: BlocBuilder<GalleryImportBloc, GalleryImportState>(
        builder: (context, state) {
          switch (state.status) {
            case GalleryImportStatus.failure:
              return ErrorRetryView(
                message:
                    state.errorMessage ?? 'No se pudieron importar tus fotos',
                onRetry: () => context.read<GalleryImportBloc>().add(
                  GalleryImportRetried(),
                ),
              );
            case GalleryImportStatus.completed:
              return const _Done();
            case GalleryImportStatus.waitingConnection:
              return const _Working(
                title: 'Esperando conexión',
                detail: 'Seguiremos donde quedamos en cuanto vuelva internet.',
              );
            case GalleryImportStatus.idle:
            case GalleryImportStatus.importing:
              return const _Working(
                title: 'Estamos preparando tus fotos',
                detail: 'Memory Lens empezará a organizarlas por ti.',
              );
          }
        },
      ),
    );
  }
}

class _Working extends StatelessWidget {
  final String title;
  final String detail;

  const _Working({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Listo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tus fotos ya están en Memory Lens.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Ver recuerdos',
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/recuerdos'),
            ),
          ],
        ),
      ),
    );
  }
}

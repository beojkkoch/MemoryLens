import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:memorylens/components/error_retry_view.dart';
import 'package:memorylens/components/memory_lens_app_bar.dart';
import 'package:memorylens/components/primary_button.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_bloc.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_event.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_state.dart';
import 'package:memorylens/features/photo_analysis/ui/bloc/photo_analysis_bloc.dart';
import 'package:memorylens/features/photo_analysis/ui/bloc/photo_analysis_event.dart';
import 'package:memorylens/features/photo_analysis/ui/bloc/photo_analysis_state.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Where the photos are imported and then described by the AI, once both
/// permissions were given. Needs a GalleryImportBloc and a PhotoAnalysisBloc
/// above it.
///
/// It only says how things are going. The progress bar with the numbers comes
/// with its own story.
class AnalyzingScreen extends StatelessWidget {
  const AnalyzingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MemoryLensAppBar(title: 'Analizando'),
      body: BlocListener<GalleryImportBloc, GalleryImportState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == GalleryImportStatus.completed,
        listener: (context, _) =>
            context.read<PhotoAnalysisBloc>().add(PhotoAnalysisStarted()),
        child: BlocBuilder<GalleryImportBloc, GalleryImportState>(
          builder: (context, import) {
            if (import.status == GalleryImportStatus.completed) {
              return const _AnalysisView();
            }
            return _ImportView(state: import);
          },
        ),
      ),
    );
  }
}

class _ImportView extends StatelessWidget {
  final GalleryImportState state;

  const _ImportView({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case GalleryImportStatus.failure:
        return ErrorRetryView(
          message: state.errorMessage ?? 'No se pudieron importar tus fotos',
          onRetry: () =>
              context.read<GalleryImportBloc>().add(GalleryImportRetried()),
        );
      case GalleryImportStatus.waitingConnection:
        return const _Working(
          title: 'Esperando conexión',
          detail: 'Seguiremos donde quedamos en cuanto vuelva internet.',
        );
      case GalleryImportStatus.idle:
      case GalleryImportStatus.importing:
      case GalleryImportStatus.completed:
        return const _Working(
          title: 'Estamos preparando tus fotos',
          detail: 'Memory Lens empezará a organizarlas por ti.',
        );
    }
  }
}

class _AnalysisView extends StatelessWidget {
  const _AnalysisView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhotoAnalysisBloc, PhotoAnalysisState>(
      builder: (context, state) {
        switch (state.status) {
          case PhotoAnalysisStatus.failure:
            return ErrorRetryView(
              message:
                  state.errorMessage ?? 'No se pudieron analizar tus fotos',
              onRetry: () =>
                  context.read<PhotoAnalysisBloc>().add(PhotoAnalysisRetried()),
            );
          case PhotoAnalysisStatus.completed:
            return _Done(failed: state.failed);
          case PhotoAnalysisStatus.waitingConnection:
            return const _Working(
              title: 'Esperando conexión',
              detail: 'Seguiremos donde quedamos en cuanto vuelva internet.',
            );
          case PhotoAnalysisStatus.idle:
          case PhotoAnalysisStatus.analyzing:
            return const _Working(
              title: 'Estamos organizando tus recuerdos',
              detail:
                  'Le ponemos a cada foto un título, una categoría y '
                  'etiquetas.',
            );
        }
      },
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
  /// Photos the AI could not describe.
  final int failed;

  const _Done({required this.failed});

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
            Text(
              switch (failed) {
                0 => 'Tus fotos ya están organizadas en Memory Lens.',
                1 =>
                  'Tus fotos ya están en Memory Lens. Una no se pudo '
                      'analizar.',
                _ =>
                  'Tus fotos ya están en Memory Lens. $failed no se '
                      'pudieron analizar.',
              },
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
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

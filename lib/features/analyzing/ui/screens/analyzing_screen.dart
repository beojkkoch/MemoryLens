import 'dart:async';

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
/// The ring and the numbers come from the photos really processed (HU-10):
/// they change every time a call to the AI ends, and after a restart they
/// start from what is saved. At 100 % it opens Recuerdos by itself, unless
/// some photo could not be analyzed: then it waits on «Reintentar», which
/// sends only those photos again, or «Ver mis recuerdos».
class AnalyzingScreen extends StatefulWidget {
  /// How long 100 % stays on screen before Recuerdos opens, so the person
  /// sees that it finished and how many photos failed.
  final Duration exitDelay;

  const AnalyzingScreen({
    super.key,
    this.exitDelay = const Duration(milliseconds: 1500),
  });

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  /// Opens Recuerdos. Cancelled if the screen goes away first.
  Timer? _exit;

  @override
  void dispose() {
    _exit?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MemoryLensAppBar(title: 'Analizando'),
      body: MultiBlocListener(
        listeners: [
          BlocListener<GalleryImportBloc, GalleryImportState>(
            listenWhen: (previous, current) =>
                previous.status != current.status &&
                current.status == GalleryImportStatus.completed,
            listener: (context, _) =>
                context.read<PhotoAnalysisBloc>().add(PhotoAnalysisStarted()),
          ),
          BlocListener<PhotoAnalysisBloc, PhotoAnalysisState>(
            listenWhen: (previous, current) =>
                previous.status != current.status &&
                current.status == PhotoAnalysisStatus.completed &&
                current.failed == 0,
            listener: (context, _) => _openRecuerdosSoon(),
          ),
        ],
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

  void _openRecuerdosSoon() {
    _exit?.cancel();
    _exit = Timer(widget.exitDelay, () {
      if (mounted) Navigator.pushReplacementNamed(context, '/recuerdos');
    });
  }
}

class _ImportView extends StatelessWidget {
  final GalleryImportState state;

  const _ImportView({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == GalleryImportStatus.failure) {
      return ErrorRetryView(
        message: state.errorMessage ?? 'No se pudieron importar tus fotos',
        onRetry: () =>
            context.read<GalleryImportBloc>().add(GalleryImportRetried()),
      );
    }
    final waiting = state.status == GalleryImportStatus.waitingConnection;
    return _Progress(
      // Before the photos are counted there is nothing real to show yet.
      known: state.total > 0,
      done: state.imported + state.skipped,
      total: state.total,
      title: waiting ? 'Esperando conexión' : 'Preparando tus fotos…',
      count: 'Preparadas ${state.imported} de ${state.total} fotos',
      detail: waiting
          ? 'Seguiremos donde quedamos en cuanto vuelva internet.'
          : 'Memory Lens empezará a organizarlas por ti.',
    );
  }
}

class _AnalysisView extends StatelessWidget {
  const _AnalysisView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhotoAnalysisBloc, PhotoAnalysisState>(
      builder: (context, state) {
        if (state.status == PhotoAnalysisStatus.failure) {
          return ErrorRetryView(
            message: state.errorMessage ?? 'No se pudieron analizar tus fotos',
            onRetry: () =>
                context.read<PhotoAnalysisBloc>().add(PhotoAnalysisRetried()),
          );
        }
        final waiting = state.status == PhotoAnalysisStatus.waitingConnection;
        final completed = state.status == PhotoAnalysisStatus.completed;
        final canRetryFailed = completed && state.failed > 0;
        return _Progress(
          known: completed || state.total > 0,
          done: state.analyzed + state.failed,
          total: state.total,
          title: waiting
              ? 'Esperando conexión'
              : completed
              ? '¡Listo!'
              : 'Analizando tu galería…',
          count: 'Analizadas ${state.analyzed} de ${state.total} fotos',
          failed: state.failed,
          detail: waiting
              ? 'Seguiremos donde quedamos en cuanto vuelva internet.'
              : canRetryFailed
              ? 'Puedes intentarlo otra vez solo con las fotos que fallaron.'
              : 'Le ponemos a cada foto un título, una categoría y etiquetas.',
          actions: canRetryFailed ? const _RetryFailedActions() : null,
        );
      },
    );
  }
}

/// HU-10, CA8: analyze again only the photos «No analizada», or move on.
class _RetryFailedActions extends StatelessWidget {
  const _RetryFailedActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PrimaryButton(
          label: 'Reintentar',
          onPressed: () => context.read<PhotoAnalysisBloc>().add(
            PhotoAnalysisFailedPhotosRetried(),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/recuerdos'),
          child: const Text('Ver mis recuerdos'),
        ),
      ],
    );
  }
}

/// The ring with the percentage in the middle and the numbers under it.
class _Progress extends StatelessWidget {
  /// False while the total is not known: the ring spins without a value.
  final bool known;

  /// Photos processed, including the ones that failed.
  final int done;
  final int total;
  final String title;
  final String count;
  final String detail;

  /// Photos «No analizada» (HU-10, CA7).
  final int failed;

  /// Buttons under the numbers, if any.
  final Widget? actions;

  const _Progress({
    required this.known,
    required this.done,
    required this.total,
    required this.title,
    required this.count,
    required this.detail,
    this.failed = 0,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // Floor, so 100 % only shows when every photo was processed. Nothing to
    // process is already done.
    final percent = total == 0 ? 100 : (done.clamp(0, total) * 100) ~/ total;
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Semantics(
                    label: 'Progreso del análisis',
                    value: known ? '$percent %' : null,
                    child: CircularProgressIndicator(
                      value: known ? percent / 100 : null,
                      strokeWidth: 10,
                      color: primary,
                      backgroundColor: AppColors.secondary,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  if (known)
                    Center(
                      child: Text(
                        '$percent %',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            if (known) ...[
              const SizedBox(height: 8),
              Text(
                count,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            if (failed > 0) ...[
              const SizedBox(height: 4),
              Text(
                failed == 1
                    ? '1 foto no analizada'
                    : '$failed fotos no analizadas',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (actions != null) ...[const SizedBox(height: 24), actions!],
          ],
        ),
      ),
    );
  }
}

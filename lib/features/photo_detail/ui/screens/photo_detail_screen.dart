import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:memorylens/components/error_retry_view.dart';
import 'package:memorylens/components/primary_button.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_edit.dart';
import 'package:memorylens/features/photo_detail/ui/bloc/photo_detail_bloc.dart';
import 'package:memorylens/features/photo_detail/ui/bloc/photo_detail_event.dart';
import 'package:memorylens/features/photo_detail/ui/bloc/photo_detail_state.dart';
import 'package:memorylens/features/photo_detail/ui/widgets/photo_analysis_panel.dart';
import 'package:memorylens/theme/app_theme.dart';

/// A photo in large with its AI analysis and the data found in it (HU-28).
/// Opened from Recuerdos or the chat with the id of the photo. «Hecho» saves
/// the corrections and opens the home (HU-30). Needs a PhotoDetailBloc above
/// it.
class PhotoDetailScreen extends StatelessWidget {
  final String photoId;

  const PhotoDetailScreen({super.key, required this.photoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<PhotoDetailBloc, PhotoDetailState>(
        listenWhen: (previous, current) =>
            previous.saveStatus != current.saveStatus &&
            current.saveStatus == PhotoSaveStatus.saved,
        listener: (context, _) => _openHome(context),
        builder: (context, state) {
          switch (state.status) {
            case PhotoDetailStatus.loading:
              return const _WithBackButton(
                child: Center(child: CircularProgressIndicator()),
              );
            case PhotoDetailStatus.failure:
              return _WithBackButton(
                child: ErrorRetryView(
                  message: state.errorMessage ?? 'No se pudo cargar esta foto',
                  onRetry: () => context.read<PhotoDetailBloc>().add(
                    PhotoDetailRequested(photoId),
                  ),
                ),
              );
            case PhotoDetailStatus.notFound:
              return const _NotFound();
            case PhotoDetailStatus.ready:
              return _WithBackButton(
                child: _Detail(
                  state: state,
                  onDone: (edit) => context.read<PhotoDetailBloc>().add(
                    PhotoEditSubmitted(photoId, edit),
                  ),
                ),
              );
          }
        },
      ),
    );
  }

  /// Back to Recuerdos, which may be under the chat. If it is not in the
  /// stack at all, it replaces whatever is first.
  static void _openHome(BuildContext context) {
    final navigator = Navigator.of(context);
    var home = false;
    navigator.popUntil((route) {
      home = route.settings.name == homeRoute;
      return home || route.isFirst;
    });
    if (!home) navigator.pushReplacementNamed(homeRoute);
  }

  static const homeRoute = '/recuerdos';
}

/// The photo on top, about 70 % of the screen (CA1), and the panel below.
///
/// Not a lazy list: the panel must never be thrown away while scrolling, or
/// what the person typed would be lost.
class _Detail extends StatelessWidget {
  final PhotoDetailState state;
  final ValueChanged<PhotoEdit> onDone;

  const _Detail({required this.state, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final detail = state.detail!;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: constraints.maxHeight * 0.7,
                child: _LargePhoto(detail: detail),
              ),
              PhotoAnalysisPanel(
                detail: detail,
                categories: state.categories,
                saving: state.saveStatus == PhotoSaveStatus.saving,
                saveError: state.saveError,
                onDone: onDone,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The large copy, never the thumbnail (CA4), whole, with a gradient that
/// joins it to the panel (CA1).
class _LargePhoto extends StatelessWidget {
  final PhotoDetail detail;

  const _LargePhoto({required this.detail});

  @override
  Widget build(BuildContext context) {
    final url = detail.imageUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: AppColors.textPrimary,
          child: url == null
              ? const _ImageMissing()
              : Image.network(
                  url,
                  fit: BoxFit.contain,
                  semanticLabel: detail.title,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, _, _) => const _ImageMissing(),
                ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 96,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00FFFFFF), AppColors.background],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageMissing extends StatelessWidget {
  const _ImageMissing();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// «Foto no encontrada» with a way back (CA5).
class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Foto no encontrada',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Volver',
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The back button on the top left, over whatever is below (CA3).
class _WithBackButton extends StatelessWidget {
  final Widget child;

  const _WithBackButton({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filledTonal(
                icon: const BackButtonIcon(),
                tooltip: 'Volver',
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:memorylens/components/error_message.dart';
import 'package:memorylens/components/error_retry_view.dart';
import 'package:memorylens/components/memory_lens_app_bar.dart';
import 'package:memorylens/components/primary_button.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_bloc.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_event.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_state.dart';
import 'package:memorylens/features/memories/ui/widgets/access_denied_notice.dart';
import 'package:memorylens/features/memories/ui/widgets/empty_memories_view.dart';
import 'package:memorylens/features/memories/ui/widgets/gallery_consent_dialog.dart';
import 'package:memorylens/features/memories/ui/widgets/memories_header.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Home of the app. While the gallery is not connected it invites the person
/// to connect it. Needs a MemoriesBloc above it.
class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() {
    return _MemoriesScreenState();
  }
}

class _MemoriesScreenState extends State<MemoriesScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The person may come back from the system settings with the permission on.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<MemoriesBloc>().add(MemoriesResumed());
    }
  }

  Future<void> _askConsent() async {
    final bloc = context.read<MemoriesBloc>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => const GalleryConsentDialog(),
    );
    if (bloc.isClosed) return;
    bloc.add(
      accepted == true ? GalleryConsentAccepted() : GalleryConsentDeclined(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MemoriesBloc, MemoriesState>(
      listenWhen: (previous, current) => previous.access != current.access,
      listener: (context, state) {
        if (state.access == GalleryAccess.consent) {
          _askConsent();
        } else if (state.access == GalleryAccess.granted) {
          Navigator.pushReplacementNamed(context, '/analizando');
        }
      },
      child: BlocBuilder<MemoriesBloc, MemoriesState>(
        builder: (context, state) {
          final showConnect =
              state.status == MemoriesStatus.ready && !state.hasPhotos;
          return Scaffold(
            backgroundColor: AppColors.canvas,
            appBar: MemoryLensAppBar(
              title: 'Recuerdos',
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  tooltip: 'Mi perfil',
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                ),
              ],
            ),
            body: _body(context, state),
            bottomNavigationBar: showConnect
                ? _ConnectBar(
                    isLoading: state.access == GalleryAccess.requesting,
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, MemoriesState state) {
    switch (state.status) {
      case MemoriesStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case MemoriesStatus.failure:
        return ErrorRetryView(
          message: state.errorMessage ?? 'No se pudieron cargar tus recuerdos',
          onRetry: () => context.read<MemoriesBloc>().add(MemoriesStarted()),
        );
      case MemoriesStatus.ready:
        return Column(
          children: [
            MemoriesHeader(
              connected: state.hasPhotos,
              photoCount: state.photoCount,
            ),
            Expanded(
              child: state.hasPhotos
                  ? const _PhotosPlaceholder()
                  : _EmptyBody(state: state),
            ),
          ],
        );
    }
  }
}

/// Empty gallery, plus the reason when the system said no.
class _EmptyBody extends StatelessWidget {
  final MemoriesState state;

  const _EmptyBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final denied =
        state.access == GalleryAccess.denied ||
        state.access == GalleryAccess.blocked;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        const EmptyMemoriesView(),
        if (denied) ...[
          const SizedBox(height: 24),
          AccessDeniedNotice(
            blocked: state.access == GalleryAccess.blocked,
            onOpenSettings: () =>
                context.read<MemoriesBloc>().add(GallerySettingsRequested()),
          ),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: 16),
          ErrorMessage(message: state.errorMessage!),
        ],
      ],
    );
  }
}

/// Stands in for the photo grid until it is built.
class _PhotosPlaceholder extends StatelessWidget {
  const _PhotosPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Tus recuerdos aparecerán aquí',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

/// Sticky bottom bar with the main action, like the forms of the app.
class _ConnectBar extends StatelessWidget {
  final bool isLoading;

  const _ConnectBar({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: 'Permitir acceso a la galería',
          isLoading: isLoading,
          onPressed: () =>
              context.read<MemoriesBloc>().add(GalleryAccessTapped()),
        ),
      ),
    );
  }
}

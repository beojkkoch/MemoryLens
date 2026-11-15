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
import 'package:memorylens/features/memories/ui/widgets/memories_grid.dart';
import 'package:memorylens/features/memories/ui/widgets/memories_header.dart';
import 'package:memorylens/features/memories/ui/widgets/memory_dates.dart';
import 'package:memorylens/features/memories/ui/widgets/new_photos_notice.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Home of the app. While the gallery is not connected it invites the person
/// to connect it; then it shows the analyzed photos grouped by date (HU-12).
/// Needs a MemoriesBloc above it.
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
          final newest = state.newestTakenAt;
          return Scaffold(
            backgroundColor: AppColors.canvas,
            appBar: MemoryLensAppBar(
              title: 'Recuerdos',
              subtitle: newest == null ? null : MemoryDates.monthLabel(newest),
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
        return const MemoriesGridPlaceholder();
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
              photoCount: state.analyzedCount,
            ),
            if (state.newPhotos > 0) NewPhotosProgress(count: state.newPhotos),
            if (state.newPhotosAnalyzed > 0)
              NewPhotosNotice(
                count: state.newPhotosAnalyzed,
                // The review of the tags has no screen yet: for now it only
                // closes the notice.
                onReview: () => context.read<MemoriesBloc>().add(
                  NewPhotosNoticeDismissed(),
                ),
                onDismiss: () => context.read<MemoriesBloc>().add(
                  NewPhotosNoticeDismissed(),
                ),
              ),
            // With no analyzed photo there is no empty grid, only the empty
            // gallery (CA10).
            Expanded(
              child: state.groups.isEmpty
                  ? _EmptyBody(state: state)
                  : MemoriesGrid(
                      groups: state.groups,
                      loadingMore: state.loadingMore,
                      onNearEnd: () => context.read<MemoriesBloc>().add(
                        MoreMemoriesRequested(),
                      ),
                      // Pushed on top, so Recuerdos and its scroll stay
                      // below (CA7).
                      onOpen: (photo) => Navigator.pushNamed(
                        context,
                        '/foto',
                        arguments: photo,
                      ),
                    ),
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

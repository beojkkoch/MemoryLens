import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/check_gallery_access_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/open_gallery_settings_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/request_gallery_access_usecase.dart';
import 'package:memorylens/features/gallery_import/domain/usecases/count_new_photos_usecase.dart';
import 'package:memorylens/features/gallery_import/domain/usecases/has_pending_import_usecase.dart';
import 'package:memorylens/features/gallery_import/domain/usecases/import_new_photos_usecase.dart';
import 'package:memorylens/features/memories/domain/entities/memory_timeline.dart';
import 'package:memorylens/features/memories/domain/usecases/count_analyzed_photos_usecase.dart';
import 'package:memorylens/features/memories/domain/usecases/count_photos_usecase.dart';
import 'package:memorylens/features/memories/domain/usecases/get_memories_usecase.dart';
import 'package:memorylens/features/photo_analysis/domain/usecases/has_pending_analysis_usecase.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_event.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_state.dart';
import 'package:memorylens/injection_container.dart';

/// Decides what Recuerdos shows and walks the person through connecting the
/// gallery: the app's own dialog first, then the system permission.
///
/// The bloc never asks the system on its own: it only does it after
/// [GalleryConsentAccepted], and «No permitir» leaves things as they were.
///
/// Once the gallery is connected, every time Recuerdos opens or the app comes
/// back to the foreground the new photos of the device are imported and
/// analyzed by themselves (HU-11).
class MemoriesBloc extends Bloc<MemoriesEvent, MemoriesState> {
  final CountPhotosUseCase _countPhotos = sl();
  final GetMemoriesUseCase _getMemories = sl();
  final CountAnalyzedPhotosUseCase _countAnalyzed = sl();
  final RequestGalleryAccessUseCase _requestAccess = sl();
  final CheckGalleryAccessUseCase _checkAccess = sl();
  final OpenGallerySettingsUseCase _openSettings = sl();
  final HasPendingImportUseCase _hasPendingImport = sl();
  final HasPendingAnalysisUseCase _hasPendingAnalysis = sl();
  final CountNewPhotosUseCase _countNewPhotos = sl();
  final ImportNewPhotosUseCase _importNewPhotos = sl();

  /// Set while new photos are looked for, so two openings in a row do not
  /// import the same photos twice.
  bool _lookingForNewPhotos = false;

  MemoriesBloc() : super(const MemoriesState()) {
    on<MemoriesStarted>(_onStarted);
    on<GalleryAccessTapped>(_onAccessTapped);
    on<GalleryConsentAccepted>(_onConsentAccepted);
    on<GalleryConsentDeclined>(_onConsentDeclined);
    on<GallerySettingsRequested>(_onSettingsRequested);
    on<MemoriesResumed>(_onResumed);
    on<NewPhotosNoticeDismissed>(_onNoticeDismissed);
    on<MoreMemoriesRequested>(_onMoreRequested);
  }

  Future<void> _onStarted(
    MemoriesStarted event,
    Emitter<MemoriesState> emit,
  ) async {
    emit(state.copyWith(status: MemoriesStatus.loading));
    try {
      // At the same time, so the first page shows fast (HU-15, CA5).
      final results = await Future.wait<Object>([
        _countPhotos(),
        _countAnalyzed(),
        _getMemories(),
      ]);
      emit(
        state.copyWith(
          status: MemoriesStatus.ready,
          photoCount: results[0] as int,
          analyzedCount: results[1] as int,
          timeline: results[2] as MemoryTimeline,
          loadingMore: false,
        ),
      );
    } catch (e, stack) {
      addError(e, stack);
      emit(
        state.copyWith(
          status: MemoriesStatus.failure,
          errorMessage: AppException.messageFor(e),
        ),
      );
      return;
    }
    await _resumeImportIfPending(emit);
    if (state.access != GalleryAccess.granted) await _analyzeNewPhotos(emit);
  }

  /// HU-11: imports and analyzes, without leaving Recuerdos, the photos added
  /// to the device since the last time. Only for a gallery already connected,
  /// and only while the system permission is still on (CA5). With no new
  /// photos nothing shows (CA4).
  Future<void> _analyzeNewPhotos(Emitter<MemoriesState> emit) async {
    if (_lookingForNewPhotos ||
        state.status != MemoriesStatus.ready ||
        !state.hasPhotos) {
      return;
    }
    _lookingForNewPhotos = true;
    try {
      final found = await _countNewPhotos();
      if (found == 0 || emit.isDone) return;
      emit(state.copyWith(newPhotos: found, errorMessage: state.errorMessage));

      final startedAt = DateTime.now();
      final analyzed = await _importNewPhotos();
      final count = await _countPhotos();
      // The timeline and its total follow the analysis (HU-12, CA6).
      final analyzedCount = await _countAnalyzed();
      final timeline = await _getMemories.refresh(
        state.timeline,
        since: startedAt,
      );
      if (emit.isDone) return;
      emit(
        state.copyWith(
          photoCount: count,
          analyzedCount: analyzedCount,
          timeline: timeline,
          newPhotos: 0,
          newPhotosAnalyzed: state.newPhotosAnalyzed + analyzed,
          errorMessage: state.errorMessage,
        ),
      );
    } catch (e, stack) {
      // Nothing for the person to fix: what was done is kept and the next
      // opening goes on. A lost connection is not worth reporting.
      if (!_isConnectionProblem(e)) addError(e, stack);
      if (!emit.isDone) {
        emit(state.copyWith(newPhotos: 0, errorMessage: state.errorMessage));
      }
    } finally {
      _lookingForNewPhotos = false;
    }
  }

  /// HU-15: the next page of the timeline, one at a time. A failure only
  /// stops the indicator: the next scroll tries again.
  Future<void> _onMoreRequested(
    MoreMemoriesRequested event,
    Emitter<MemoriesState> emit,
  ) async {
    if (state.status != MemoriesStatus.ready ||
        state.loadingMore ||
        !state.timeline.hasMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true, errorMessage: state.errorMessage));
    try {
      final timeline = await _getMemories.next(state.timeline);
      emit(
        state.copyWith(
          timeline: timeline,
          loadingMore: false,
          errorMessage: state.errorMessage,
        ),
      );
    } catch (e, stack) {
      if (!_isConnectionProblem(e)) addError(e, stack);
      emit(
        state.copyWith(loadingMore: false, errorMessage: state.errorMessage),
      );
    }
  }

  void _onNoticeDismissed(
    NewPhotosNoticeDismissed event,
    Emitter<MemoriesState> emit,
  ) {
    emit(
      state.copyWith(newPhotosAnalyzed: 0, errorMessage: state.errorMessage),
    );
  }

  /// An import or an analysis cut short (the app was closed in the middle of
  /// it) has to go on, but once the first photo is in, the button that leads
  /// to Analizando is gone. So when either is pending and the permission is
  /// still on, the flow moves on to Analizando by itself, as if the person had
  /// just allowed the access.
  Future<void> _resumeImportIfPending(Emitter<MemoriesState> emit) async {
    try {
      if (!await _hasPendingImport() && !await _hasPendingAnalysis()) return;
      final status = await _checkAccess();
      if (status != GalleryPermissionStatus.granted || emit.isDone) return;
      emit(state.copyWith(access: GalleryAccess.granted));
    } catch (e, stack) {
      // Nothing for the person to fix: Recuerdos works the same without it.
      addError(e, stack);
    }
  }

  void _onAccessTapped(GalleryAccessTapped event, Emitter<MemoriesState> emit) {
    if (state.access == GalleryAccess.requesting) return;
    emit(state.copyWith(access: GalleryAccess.consent));
  }

  Future<void> _onConsentAccepted(
    GalleryConsentAccepted event,
    Emitter<MemoriesState> emit,
  ) async {
    emit(state.copyWith(access: GalleryAccess.requesting));
    try {
      final status = await _requestAccess(userConsented: true);
      emit(state.copyWith(access: _accessFor(status)));
    } catch (e, stack) {
      addError(e, stack);
      emit(
        state.copyWith(
          access: GalleryAccess.idle,
          errorMessage: AppException.messageFor(e),
        ),
      );
    }
  }

  void _onConsentDeclined(
    GalleryConsentDeclined event,
    Emitter<MemoriesState> emit,
  ) {
    emit(state.copyWith(access: GalleryAccess.idle));
  }

  Future<void> _onSettingsRequested(
    GallerySettingsRequested event,
    Emitter<MemoriesState> emit,
  ) async {
    try {
      await _openSettings();
    } catch (e, stack) {
      addError(e, stack);
      emit(state.copyWith(errorMessage: AppException.messageFor(e)));
    }
  }

  /// Back from the settings: if the person turned the permission on there,
  /// both permissions are given and the flow goes on. With the gallery
  /// already connected, the person may have taken new photos meanwhile.
  Future<void> _onResumed(
    MemoriesResumed event,
    Emitter<MemoriesState> emit,
  ) async {
    if (state.access != GalleryAccess.blocked) {
      if (state.access != GalleryAccess.granted) await _analyzeNewPhotos(emit);
      return;
    }
    try {
      final status = await _checkAccess();
      if (status == GalleryPermissionStatus.granted) {
        emit(state.copyWith(access: GalleryAccess.granted));
      }
    } catch (e, stack) {
      // Nothing for the person to fix: they can still press the buttons.
      addError(e, stack);
    }
  }

  bool _isConnectionProblem(Object error) {
    return error is AppException &&
        (error.kind == AppErrorKind.network ||
            error.kind == AppErrorKind.timeout);
  }

  GalleryAccess _accessFor(GalleryPermissionStatus status) {
    switch (status) {
      case GalleryPermissionStatus.granted:
        return GalleryAccess.granted;
      case GalleryPermissionStatus.denied:
        return GalleryAccess.denied;
      case GalleryPermissionStatus.blocked:
        return GalleryAccess.blocked;
    }
  }
}

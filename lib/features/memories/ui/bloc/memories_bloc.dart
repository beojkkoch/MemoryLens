import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/check_gallery_access_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/open_gallery_settings_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/request_gallery_access_usecase.dart';
import 'package:memorylens/features/memories/domain/usecases/count_photos_usecase.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_event.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_state.dart';
import 'package:memorylens/injection_container.dart';

/// Decides what Recuerdos shows and walks the person through connecting the
/// gallery: the app's own dialog first, then the system permission.
///
/// The bloc never asks the system on its own: it only does it after
/// [GalleryConsentAccepted], and «No permitir» leaves things as they were.
class MemoriesBloc extends Bloc<MemoriesEvent, MemoriesState> {
  final CountPhotosUseCase _countPhotos = sl();
  final RequestGalleryAccessUseCase _requestAccess = sl();
  final CheckGalleryAccessUseCase _checkAccess = sl();
  final OpenGallerySettingsUseCase _openSettings = sl();

  MemoriesBloc() : super(const MemoriesState()) {
    on<MemoriesStarted>(_onStarted);
    on<GalleryAccessTapped>(_onAccessTapped);
    on<GalleryConsentAccepted>(_onConsentAccepted);
    on<GalleryConsentDeclined>(_onConsentDeclined);
    on<GallerySettingsRequested>(_onSettingsRequested);
    on<MemoriesResumed>(_onResumed);
  }

  Future<void> _onStarted(
    MemoriesStarted event,
    Emitter<MemoriesState> emit,
  ) async {
    emit(state.copyWith(status: MemoriesStatus.loading));
    try {
      final count = await _countPhotos();
      emit(state.copyWith(status: MemoriesStatus.ready, photoCount: count));
    } catch (e, stack) {
      addError(e, stack);
      emit(
        state.copyWith(
          status: MemoriesStatus.failure,
          errorMessage: AppException.messageFor(e),
        ),
      );
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
  /// both permissions are given and the flow goes on. Only a blocked
  /// permission can change this way, so any other moment is ignored.
  Future<void> _onResumed(
    MemoriesResumed event,
    Emitter<MemoriesState> emit,
  ) async {
    if (state.access != GalleryAccess.blocked) return;
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

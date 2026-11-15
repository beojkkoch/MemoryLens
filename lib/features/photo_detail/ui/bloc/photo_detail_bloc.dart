import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/photo_detail/domain/usecases/get_photo_detail_usecase.dart';
import 'package:memorylens/features/photo_detail/ui/bloc/photo_detail_event.dart';
import 'package:memorylens/features/photo_detail/ui/bloc/photo_detail_state.dart';
import 'package:memorylens/injection_container.dart';

/// Loads one photo with its AI analysis for its detail (HU-28).
class PhotoDetailBloc extends Bloc<PhotoDetailEvent, PhotoDetailState> {
  final GetPhotoDetailUseCase _getDetail = sl();

  PhotoDetailBloc() : super(const PhotoDetailState()) {
    on<PhotoDetailRequested>(_onRequested);
  }

  Future<void> _onRequested(
    PhotoDetailRequested event,
    Emitter<PhotoDetailState> emit,
  ) async {
    emit(const PhotoDetailState());
    try {
      final detail = await _getDetail(event.photoId);
      emit(
        PhotoDetailState(
          status: detail == null
              ? PhotoDetailStatus.notFound
              : PhotoDetailStatus.ready,
          detail: detail,
        ),
      );
    } catch (e, stack) {
      addError(e, stack);
      emit(
        PhotoDetailState(
          status: PhotoDetailStatus.failure,
          errorMessage: AppException.messageFor(e),
        ),
      );
    }
  }
}

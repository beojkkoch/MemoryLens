import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';
import 'package:memorylens/features/photo_detail/domain/usecases/get_categories_usecase.dart';
import 'package:memorylens/features/photo_detail/domain/usecases/get_photo_detail_usecase.dart';
import 'package:memorylens/features/photo_detail/domain/usecases/save_photo_edit_usecase.dart';
import 'package:memorylens/features/photo_detail/ui/bloc/photo_detail_event.dart';
import 'package:memorylens/features/photo_detail/ui/bloc/photo_detail_state.dart';
import 'package:memorylens/injection_container.dart';

/// Loads one photo with its AI analysis for its detail (HU-28) and saves the
/// corrections of the person (HU-30).
class PhotoDetailBloc extends Bloc<PhotoDetailEvent, PhotoDetailState> {
  final GetPhotoDetailUseCase _getDetail = sl();
  final GetCategoriesUseCase _getCategories = sl();
  final SavePhotoEditUseCase _save = sl();

  PhotoDetailBloc() : super(const PhotoDetailState()) {
    on<PhotoDetailRequested>(_onRequested);
    on<PhotoEditSubmitted>(_onSubmitted);
  }

  Future<void> _onRequested(
    PhotoDetailRequested event,
    Emitter<PhotoDetailState> emit,
  ) async {
    emit(const PhotoDetailState());
    try {
      final results = await Future.wait<Object?>([
        _getDetail(event.photoId),
        _getCategories(),
      ]);
      final detail = results[0] as PhotoDetail?;
      emit(
        PhotoDetailState(
          status: detail == null
              ? PhotoDetailStatus.notFound
              : PhotoDetailStatus.ready,
          detail: detail,
          categories: results[1] as List<String>,
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

  Future<void> _onSubmitted(
    PhotoEditSubmitted event,
    Emitter<PhotoDetailState> emit,
  ) async {
    if (state.saveStatus == PhotoSaveStatus.saving) return;
    emit(state.copyWith(saveStatus: PhotoSaveStatus.saving));
    try {
      await _save(event.photoId, event.edit);
      emit(state.copyWith(saveStatus: PhotoSaveStatus.saved));
    } catch (e, stack) {
      // A rule the person can fix is not worth reporting.
      if (e is! AppException || e.technical) addError(e, stack);
      emit(
        state.copyWith(
          saveStatus: PhotoSaveStatus.failure,
          saveError: AppException.messageFor(e),
        ),
      );
    }
  }
}

import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';

/// How the load of the photo went.
enum PhotoDetailStatus {
  loading,
  ready,

  /// The photo does not exist or is not the person's (HU-28, CA5).
  notFound,

  failure,
}

/// Where saving the corrections stands (HU-30).
enum PhotoSaveStatus { idle, saving, saved, failure }

/// Single state of the detail of a photo.
///
/// The fields the person is typing in live in the screen, not here, so a
/// failed save never takes them away (HU-30, CA8).
class PhotoDetailState {
  final PhotoDetailStatus status;
  final PhotoDetail? detail;

  /// The categories of the system to choose from (HU-30, CA5).
  final List<String> categories;

  final String? errorMessage;

  final PhotoSaveStatus saveStatus;
  final String? saveError;

  const PhotoDetailState({
    this.status = PhotoDetailStatus.loading,
    this.detail,
    this.categories = const [],
    this.errorMessage,
    this.saveStatus = PhotoSaveStatus.idle,
    this.saveError,
  });

  /// saveError is not carried over: every copy clears it unless given.
  PhotoDetailState copyWith({PhotoSaveStatus? saveStatus, String? saveError}) {
    return PhotoDetailState(
      status: status,
      detail: detail,
      categories: categories,
      errorMessage: errorMessage,
      saveStatus: saveStatus ?? this.saveStatus,
      saveError: saveError,
    );
  }

  @override
  String toString() {
    return 'PhotoDetailState(status: ${status.name}, detail: $detail, '
        'error: $errorMessage, save: ${saveStatus.name}, '
        'saveError: $saveError)';
  }
}

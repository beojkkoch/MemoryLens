import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';

/// How the load of the photo went.
enum PhotoDetailStatus {
  loading,
  ready,

  /// The photo does not exist or is not the person's (HU-28, CA5).
  notFound,

  failure,
}

/// Single state of the detail of a photo.
class PhotoDetailState {
  final PhotoDetailStatus status;
  final PhotoDetail? detail;
  final String? errorMessage;

  const PhotoDetailState({
    this.status = PhotoDetailStatus.loading,
    this.detail,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'PhotoDetailState(status: ${status.name}, detail: $detail, '
        'error: $errorMessage)';
  }
}

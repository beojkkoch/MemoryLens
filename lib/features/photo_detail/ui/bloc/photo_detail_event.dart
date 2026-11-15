import 'package:memorylens/features/photo_detail/domain/entities/photo_edit.dart';

/// Something the detail of a photo asks the PhotoDetailBloc to do.
abstract class PhotoDetailEvent {}

/// The detail opened, or the person pressed «Reintentar».
class PhotoDetailRequested extends PhotoDetailEvent {
  final String photoId;

  PhotoDetailRequested(this.photoId);

  @override
  String toString() {
    return 'PhotoDetailRequested($photoId)';
  }
}

/// The person pressed «Hecho» (HU-30, CA7).
class PhotoEditSubmitted extends PhotoDetailEvent {
  final String photoId;
  final PhotoEdit edit;

  PhotoEditSubmitted(this.photoId, this.edit);

  @override
  String toString() {
    return 'PhotoEditSubmitted($photoId, $edit)';
  }
}

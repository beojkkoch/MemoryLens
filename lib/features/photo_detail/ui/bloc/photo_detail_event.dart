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

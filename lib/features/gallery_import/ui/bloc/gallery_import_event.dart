/// Something the Analizando screen asks the GalleryImportBloc to do.
abstract class GalleryImportEvent {}

/// The screen opened: import the photos of the gallery.
class GalleryImportStarted extends GalleryImportEvent {
  @override
  String toString() {
    return 'GalleryImportStarted()';
  }
}

/// The person pressed «Reintentar» after the import failed.
class GalleryImportRetried extends GalleryImportEvent {
  @override
  String toString() {
    return 'GalleryImportRetried()';
  }
}

/// Something the Recuerdos screen asks the MemoriesBloc to do.
abstract class MemoriesEvent {}

/// The screen opened, or the person pressed «Reintentar».
class MemoriesStarted extends MemoriesEvent {
  @override
  String toString() {
    return 'MemoriesStarted()';
  }
}

/// The person pressed «Permitir acceso a la galería».
class GalleryAccessTapped extends MemoriesEvent {
  @override
  String toString() {
    return 'GalleryAccessTapped()';
  }
}

/// The person pressed «Permitir» in the app's own dialog.
class GalleryConsentAccepted extends MemoriesEvent {
  @override
  String toString() {
    return 'GalleryConsentAccepted()';
  }
}

/// The person pressed «No permitir» or closed the app's own dialog.
class GalleryConsentDeclined extends MemoriesEvent {
  @override
  String toString() {
    return 'GalleryConsentDeclined()';
  }
}

/// The person pressed «Abrir ajustes».
class GallerySettingsRequested extends MemoriesEvent {
  @override
  String toString() {
    return 'GallerySettingsRequested()';
  }
}

/// The app came back to the foreground, maybe from the system settings.
class MemoriesResumed extends MemoriesEvent {
  @override
  String toString() {
    return 'MemoriesResumed()';
  }
}

/// The person scrolled close to the end of the timeline (HU-15, CA2).
class MoreMemoriesRequested extends MemoriesEvent {
  @override
  String toString() {
    return 'MoreMemoriesRequested()';
  }
}

/// The person closed «N nuevas fotos analizadas» or pressed «Revisar
/// etiquetas».
class NewPhotosNoticeDismissed extends MemoriesEvent {
  @override
  String toString() {
    return 'NewPhotosNoticeDismissed()';
  }
}

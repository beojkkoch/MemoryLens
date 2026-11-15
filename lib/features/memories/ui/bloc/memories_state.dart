/// How the load of the photo count went.
enum MemoriesStatus { loading, ready, failure }

/// Where the connect-your-gallery flow stands.
enum GalleryAccess {
  /// Nothing asked yet, or the person said «No permitir».
  idle,

  /// The app's own dialog is open.
  consent,

  /// Waiting for the system permission dialog.
  requesting,

  /// Both permissions given: the screen moves on to «Analizando».
  granted,

  /// The system said no, but it can be asked again.
  denied,

  /// The system said no and will not ask again: only the settings help.
  blocked,
}

/// Single state of the Recuerdos screen.
class MemoriesState {
  final MemoriesStatus status;
  final int photoCount;
  final GalleryAccess access;
  final String? errorMessage;

  /// New photos of the device being imported and analyzed right now
  /// (HU-11). 0 when nothing is running.
  final int newPhotos;

  /// New photos analyzed, for «N nuevas fotos analizadas» (HU-11, CA3). 0
  /// hides the notice.
  final int newPhotosAnalyzed;

  const MemoriesState({
    this.status = MemoriesStatus.loading,
    this.photoCount = 0,
    this.access = GalleryAccess.idle,
    this.errorMessage,
    this.newPhotos = 0,
    this.newPhotosAnalyzed = 0,
  });

  bool get hasPhotos => photoCount > 0;

  /// errorMessage is not carried over: every copy clears it unless given.
  MemoriesState copyWith({
    MemoriesStatus? status,
    int? photoCount,
    GalleryAccess? access,
    String? errorMessage,
    int? newPhotos,
    int? newPhotosAnalyzed,
  }) {
    return MemoriesState(
      status: status ?? this.status,
      photoCount: photoCount ?? this.photoCount,
      access: access ?? this.access,
      errorMessage: errorMessage,
      newPhotos: newPhotos ?? this.newPhotos,
      newPhotosAnalyzed: newPhotosAnalyzed ?? this.newPhotosAnalyzed,
    );
  }

  @override
  String toString() {
    return 'MemoriesState(status: ${status.name}, photos: $photoCount, '
        'access: ${access.name}, error: $errorMessage, '
        'newPhotos: $newPhotos, newPhotosAnalyzed: $newPhotosAnalyzed)';
  }
}

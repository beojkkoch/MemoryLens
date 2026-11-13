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

  const MemoriesState({
    this.status = MemoriesStatus.loading,
    this.photoCount = 0,
    this.access = GalleryAccess.idle,
    this.errorMessage,
  });

  bool get hasPhotos => photoCount > 0;

  /// errorMessage is not carried over: every copy clears it unless given.
  MemoriesState copyWith({
    MemoriesStatus? status,
    int? photoCount,
    GalleryAccess? access,
    String? errorMessage,
  }) {
    return MemoriesState(
      status: status ?? this.status,
      photoCount: photoCount ?? this.photoCount,
      access: access ?? this.access,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'MemoriesState(status: ${status.name}, photos: $photoCount, '
        'access: ${access.name}, error: $errorMessage)';
  }
}

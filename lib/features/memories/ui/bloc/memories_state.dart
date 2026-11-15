import 'package:memorylens/features/memories/domain/entities/memory_group.dart';

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

  /// The analyzed photos, grouped by the day they were taken (HU-12).
  final List<MemoryGroup> groups;

  const MemoriesState({
    this.status = MemoriesStatus.loading,
    this.photoCount = 0,
    this.access = GalleryAccess.idle,
    this.errorMessage,
    this.newPhotos = 0,
    this.newPhotosAnalyzed = 0,
    this.groups = const [],
  });

  bool get hasPhotos => photoCount > 0;

  /// For «128 fotos» (HU-12, CA6).
  int get analyzedCount {
    return groups.fold(0, (total, group) => total + group.photos.length);
  }

  /// When the newest photo was taken, for «Junio 2024» (HU-12, CA5).
  DateTime? get newestTakenAt {
    return groups.isEmpty ? null : groups.first.photos.first.takenAt;
  }

  /// errorMessage is not carried over: every copy clears it unless given.
  MemoriesState copyWith({
    MemoriesStatus? status,
    int? photoCount,
    GalleryAccess? access,
    String? errorMessage,
    int? newPhotos,
    int? newPhotosAnalyzed,
    List<MemoryGroup>? groups,
  }) {
    return MemoriesState(
      status: status ?? this.status,
      photoCount: photoCount ?? this.photoCount,
      access: access ?? this.access,
      errorMessage: errorMessage,
      newPhotos: newPhotos ?? this.newPhotos,
      newPhotosAnalyzed: newPhotosAnalyzed ?? this.newPhotosAnalyzed,
      groups: groups ?? this.groups,
    );
  }

  @override
  String toString() {
    return 'MemoriesState(status: ${status.name}, photos: $photoCount, '
        'access: ${access.name}, error: $errorMessage, '
        'newPhotos: $newPhotos, newPhotosAnalyzed: $newPhotosAnalyzed, '
        'analyzed: $analyzedCount)';
  }
}

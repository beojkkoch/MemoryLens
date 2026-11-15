/// Where the analysis of the photos stands.
enum PhotoAnalysisStatus {
  /// Waiting for the import to finish.
  idle,

  /// Sending the photos to the AI.
  analyzing,

  /// The connection dropped: the analysis goes on by itself when it is back.
  waitingConnection,

  /// Every photo was handled.
  completed,

  /// Something that waiting does not fix. «Reintentar» tries again.
  failure,
}

class PhotoAnalysisState {
  final PhotoAnalysisStatus status;

  /// Imported photos.
  final int total;

  /// Photos that already have their title, category and tags.
  final int analyzed;

  /// Photos the AI could not describe.
  final int failed;

  final String? errorMessage;

  const PhotoAnalysisState({
    this.status = PhotoAnalysisStatus.idle,
    this.total = 0,
    this.analyzed = 0,
    this.failed = 0,
    this.errorMessage,
  });

  /// errorMessage is not carried over: every copy clears it unless given.
  PhotoAnalysisState copyWith({
    PhotoAnalysisStatus? status,
    int? total,
    int? analyzed,
    int? failed,
    String? errorMessage,
  }) {
    return PhotoAnalysisState(
      status: status ?? this.status,
      total: total ?? this.total,
      analyzed: analyzed ?? this.analyzed,
      failed: failed ?? this.failed,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'PhotoAnalysisState(status: ${status.name}, total: $total, '
        'analyzed: $analyzed, failed: $failed, error: $errorMessage)';
  }
}

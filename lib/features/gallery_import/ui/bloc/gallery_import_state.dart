/// Where the import of the gallery stands.
enum GalleryImportStatus {
  /// Nothing started yet.
  idle,

  /// Reading and uploading the photos.
  importing,

  /// The connection dropped: the import goes on by itself when it is back.
  waitingConnection,

  /// Every photo was handled.
  completed,

  /// Something that waiting does not fix. «Reintentar» tries again.
  failure,
}

/// Single state of the Analizando screen.
class GalleryImportState {
  final GalleryImportStatus status;

  /// Photos found on the device.
  final int total;

  /// Photos already in the person's storage.
  final int imported;

  /// Photos that could not be read and were left out.
  final int skipped;

  final String? errorMessage;

  const GalleryImportState({
    this.status = GalleryImportStatus.idle,
    this.total = 0,
    this.imported = 0,
    this.skipped = 0,
    this.errorMessage,
  });

  /// errorMessage is not carried over: every copy clears it unless given.
  GalleryImportState copyWith({
    GalleryImportStatus? status,
    int? total,
    int? imported,
    int? skipped,
    String? errorMessage,
  }) {
    return GalleryImportState(
      status: status ?? this.status,
      total: total ?? this.total,
      imported: imported ?? this.imported,
      skipped: skipped ?? this.skipped,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'GalleryImportState(status: ${status.name}, total: $total, '
        'imported: $imported, skipped: $skipped, error: $errorMessage)';
  }
}

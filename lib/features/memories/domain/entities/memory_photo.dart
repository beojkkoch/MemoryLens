/// An analyzed photo as Recuerdos shows it (HU-12).
class MemoryPhoto {
  final String id;

  /// Written by the AI (HU-08).
  final String? title;

  /// When the photo was taken, in local time. Null when the device did not
  /// know it.
  final DateTime? takenAt;

  /// Signed URLs of the private fotos bucket. Null when the file could not be
  /// signed, for example because it is no longer in the bucket.
  final String? thumbnailUrl;
  final String? imageUrl;

  const MemoryPhoto({
    required this.id,
    this.title,
    this.takenAt,
    this.thumbnailUrl,
    this.imageUrl,
  });

  @override
  String toString() => 'MemoryPhoto($id, $title, $takenAt)';
}

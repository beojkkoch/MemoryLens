import 'package:memorylens/features/photo_analysis/domain/entities/money.dart';

/// A photo with what the AI wrote about it and the data it found (HU-28).
/// Every field but the id can be missing, and the screen shows «—» for it.
class PhotoDetail {
  final String id;

  /// Signed URL of the large copy, never the thumbnail (CA4). Null when the
  /// file could not be signed.
  final String? imageUrl;

  final String? title;

  /// The short description the AI wrote (foto.texto_alt).
  final String? description;

  /// When the photo was taken, in local time.
  final DateTime? takenAt;

  /// The name of the category, as in the categoria table.
  final String? category;

  /// For example «Cafetería», only for an invoice.
  final String? purchaseType;

  /// Only for an invoice.
  final Money? total;

  const PhotoDetail({
    required this.id,
    this.imageUrl,
    this.title,
    this.description,
    this.takenAt,
    this.category,
    this.purchaseType,
    this.total,
  });

  @override
  String toString() => 'PhotoDetail($id, $title, $category)';
}

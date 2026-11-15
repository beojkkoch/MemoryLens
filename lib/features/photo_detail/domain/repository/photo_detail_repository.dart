import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';

abstract class PhotoDetailRepository {
  /// The photo [id] of the signed in person, or null when it does not exist
  /// or belongs to someone else (HU-28, CA5).
  Future<PhotoDetail?> find(String id);
}

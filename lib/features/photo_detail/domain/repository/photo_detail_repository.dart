import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_edit.dart';

abstract class PhotoDetailRepository {
  /// The photo [id] of the signed in person, or null when it does not exist
  /// or belongs to someone else (HU-28, CA5).
  Future<PhotoDetail?> find(String id);

  /// The names of the categories of the system, to choose from (HU-30, CA5).
  Future<List<String>> categories();

  /// Saves the corrections of the person to the photo [id] (HU-30, CA7).
  Future<void> save(String id, PhotoEdit edit);
}

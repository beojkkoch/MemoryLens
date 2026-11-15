import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';

abstract class PhotoRepository {
  /// How many photos of the signed in person the app already has.
  Future<int> count();

  /// How many photos the AI already described (HU-12, CA6).
  Future<int> countAnalyzed();

  /// Up to [limit] of the photos the AI already described, newest first,
  /// leaving out the first [offset] (HU-15).
  Future<List<MemoryPhoto>> analyzed({required int offset, required int limit});
}

import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';

abstract class PhotoRepository {
  /// How many photos of the signed in person the app already has.
  Future<int> count();

  /// The photos the AI already described, newest first (HU-12).
  Future<List<MemoryPhoto>> analyzed();
}

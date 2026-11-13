abstract class PhotoRepository {
  /// How many photos of the signed in person the app already has.
  Future<int> count();
}

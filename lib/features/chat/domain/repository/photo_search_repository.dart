import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';

/// Finds the photos of the person that match a question written in their own
/// words. The chat only knows this port, so the semantic search (HU-21) takes
/// the place of the word search without changing the chat.
abstract class PhotoSearchRepository {
  /// Up to 12 photos of the person, the most relevant first. Empty when
  /// nothing matches.
  Future<List<MemoryPhoto>> search(String question);
}

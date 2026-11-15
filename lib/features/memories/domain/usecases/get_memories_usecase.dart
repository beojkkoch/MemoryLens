import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:memorylens/features/memories/domain/entities/memory_timeline.dart';
import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';
import 'package:memorylens/injection_container.dart';

/// The analyzed photos of the person, grouped by the day they were taken, for
/// the timeline of Recuerdos (HU-12). They come in pages, so the timeline
/// stays fast with thousands of photos (HU-15).
class GetMemoriesUseCase {
  /// Photos of each page (HU-15, CA1).
  static const pageSize = 60;

  final PhotoRepository _photos = sl();

  /// The newest page (CA1).
  Future<MemoryTimeline> call() {
    return next(MemoryTimeline.empty);
  }

  /// [current] plus the page that follows it (CA2).
  Future<MemoryTimeline> next(MemoryTimeline current) async {
    final page = await _photos.analyzed(
      offset: current.photos.length,
      limit: pageSize,
    );
    return MemoryTimeline(
      photos: _merge(current.photos, page),
      hasMore: page.length == pageSize,
    );
  }

  /// The newest page again, after an analysis, keeping what [current] had
  /// loaded so the grid does not jump back to the top.
  Future<MemoryTimeline> refresh(MemoryTimeline current) async {
    final page = await _photos.analyzed(offset: 0, limit: pageSize);
    return MemoryTimeline(
      photos: _merge(page, current.photos),
      hasMore: current.hasMore || page.length == pageSize,
    );
  }

  /// [first] and then the photos of [second] it does not have yet. A photo
  /// can show up twice when the list changed between two pages.
  static List<MemoryPhoto> _merge(
    List<MemoryPhoto> first,
    List<MemoryPhoto> second,
  ) {
    final ids = {for (final photo in first) photo.id};
    return [...first, ...second.where((photo) => ids.add(photo.id))];
  }
}

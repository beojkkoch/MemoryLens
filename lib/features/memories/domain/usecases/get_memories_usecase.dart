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

  /// The time of the analysis is the server's and [refresh] gets the
  /// phone's, so it looks a bit further back. What repeats is left out.
  static const clockMargin = Duration(hours: 1);

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

  /// Adds to [current] the photos analyzed after [since] that belong to the
  /// part already loaded, each under its own day, even when it was taken
  /// long ago. Nothing loaded is dropped, so the grid does not jump.
  ///
  /// The ones taken before the oldest loaded photo are left for the next
  /// pages: added now, they would make the next page skip as many photos.
  Future<MemoryTimeline> refresh(
    MemoryTimeline current, {
    required DateTime since,
  }) async {
    final oldest = current.groups.isEmpty
        ? null
        : current.groups.last.photos.last.takenAt;
    final recent = await _photos.analyzedSince(
      since: since.subtract(clockMargin),
      takenAfter: current.hasMore ? oldest : null,
    );
    return MemoryTimeline(
      photos: _merge(current.photos, recent),
      hasMore: current.hasMore,
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

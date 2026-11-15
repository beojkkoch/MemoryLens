import 'package:memorylens/features/memories/domain/entities/memory_group.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';

/// The part of the timeline loaded so far (HU-15): the photos, already
/// grouped by day, and whether the account has more to load.
class MemoryTimeline {
  /// Every photo loaded, with no repeats.
  final List<MemoryPhoto> photos;

  final List<MemoryGroup> groups;

  final bool hasMore;

  const MemoryTimeline._(this.photos, this.groups, this.hasMore);

  static const empty = MemoryTimeline._([], [], false);

  factory MemoryTimeline({
    required List<MemoryPhoto> photos,
    required bool hasMore,
  }) {
    return MemoryTimeline._(photos, MemoryGroup.byDay(photos), hasMore);
  }

  @override
  String toString() =>
      'MemoryTimeline(${photos.length} photos, '
      'hasMore: $hasMore)';
}

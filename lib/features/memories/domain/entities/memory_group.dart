import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';

/// The photos taken on the same day, under one title of the timeline
/// (HU-12).
class MemoryGroup {
  /// Midnight of the day, in local time. Null for the photos with no capture
  /// date, which go last.
  final DateTime? day;

  /// Newest first.
  final List<MemoryPhoto> photos;

  const MemoryGroup({required this.day, required this.photos});

  /// Groups the photos by the day they were taken, not the day they were
  /// imported (CA3). Newest day first (CA2), and newest photo first inside
  /// each day (CA4).
  static List<MemoryGroup> byDay(List<MemoryPhoto> photos) {
    final sorted = [...photos]..sort(_newestFirst);
    final groups = <MemoryGroup>[];
    for (final photo in sorted) {
      final day = _dayOf(photo.takenAt);
      if (groups.isEmpty || groups.last.day != day) {
        groups.add(MemoryGroup(day: day, photos: [photo]));
      } else {
        groups.last.photos.add(photo);
      }
    }
    return groups;
  }

  static int _newestFirst(MemoryPhoto a, MemoryPhoto b) {
    final x = a.takenAt;
    final y = b.takenAt;
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return y.compareTo(x);
  }

  static DateTime? _dayOf(DateTime? date) {
    if (date == null) return null;
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  @override
  String toString() => 'MemoryGroup($day, ${photos.length} photos)';
}

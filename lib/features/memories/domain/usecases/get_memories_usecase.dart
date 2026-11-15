import 'package:memorylens/features/memories/domain/entities/memory_group.dart';
import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';
import 'package:memorylens/injection_container.dart';

/// The analyzed photos of the person, grouped by the day they were taken, for
/// the timeline of Recuerdos (HU-12).
class GetMemoriesUseCase {
  final PhotoRepository _photos = sl();

  Future<List<MemoryGroup>> call() async {
    return MemoryGroup.byDay(await _photos.analyzed());
  }
}

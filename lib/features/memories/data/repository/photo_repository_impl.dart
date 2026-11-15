import 'package:memorylens/features/memories/data/source/supabase_photo_data_source.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';
import 'package:memorylens/injection_container.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  final SupabasePhotoDataSource _dataSource = sl();

  @override
  Future<int> count() {
    return _dataSource.count();
  }

  @override
  Future<int> countAnalyzed() {
    return _dataSource.countAnalyzed();
  }

  @override
  Future<List<MemoryPhoto>> analyzed({
    required int offset,
    required int limit,
  }) {
    return _dataSource.analyzed(offset: offset, limit: limit);
  }

  @override
  Future<List<MemoryPhoto>> analyzedSince({
    required DateTime since,
    DateTime? takenAfter,
  }) {
    return _dataSource.analyzedSince(since: since, takenAfter: takenAfter);
  }
}

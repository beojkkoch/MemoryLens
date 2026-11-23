import 'package:memorylens/features/chat/data/source/supabase_photo_search_data_source.dart';
import 'package:memorylens/features/chat/domain/repository/photo_search_repository.dart';
import 'package:memorylens/features/memories/data/source/supabase_photo_data_source.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:memorylens/injection_container.dart';

/// The provisional search by words. The semantic one (HU-21) is another
/// implementation of the same port.
class PhotoSearchRepositoryImpl implements PhotoSearchRepository {
  final SupabasePhotoSearchDataSource _search = sl();
  final SupabasePhotoDataSource _photos = sl();

  @override
  Future<List<MemoryPhoto>> search(String question) async {
    final terms = SupabasePhotoSearchDataSource.termsFrom(question);
    if (terms.isEmpty) return const [];
    return _photos.byIds(await _search.photoIds(terms));
  }
}

import 'package:memorylens/features/memories/data/source/supabase_photo_data_source.dart';
import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';
import 'package:memorylens/injection_container.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  final SupabasePhotoDataSource _dataSource = sl();

  @override
  Future<int> count() {
    return _dataSource.count();
  }
}

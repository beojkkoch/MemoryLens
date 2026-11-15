import 'package:memorylens/features/photo_detail/data/source/supabase_photo_detail_data_source.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';
import 'package:memorylens/features/photo_detail/domain/repository/photo_detail_repository.dart';
import 'package:memorylens/injection_container.dart';

class PhotoDetailRepositoryImpl implements PhotoDetailRepository {
  final SupabasePhotoDetailDataSource _dataSource = sl();

  @override
  Future<PhotoDetail?> find(String id) {
    return _dataSource.find(id);
  }
}

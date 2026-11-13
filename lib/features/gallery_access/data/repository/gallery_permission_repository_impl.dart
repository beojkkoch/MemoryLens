import 'package:memorylens/features/gallery_access/data/source/gallery_permission_data_source.dart';
import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';
import 'package:memorylens/features/gallery_access/domain/repository/gallery_permission_repository.dart';
import 'package:memorylens/injection_container.dart';

class GalleryPermissionRepositoryImpl implements GalleryPermissionRepository {
  final GalleryPermissionDataSource _dataSource = sl();

  @override
  Future<GalleryPermissionStatus> check() {
    return _dataSource.check();
  }

  @override
  Future<GalleryPermissionStatus> request() {
    return _dataSource.request();
  }

  @override
  Future<void> openSettings() {
    return _dataSource.openSettings();
  }
}

import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';
import 'package:memorylens/features/gallery_access/domain/repository/gallery_permission_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Reads the current device permission without asking for it.
class CheckGalleryAccessUseCase {
  final GalleryPermissionRepository _permission = sl();

  Future<GalleryPermissionStatus> call() {
    return _permission.check();
  }
}

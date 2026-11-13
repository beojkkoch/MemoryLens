import 'package:memorylens/features/gallery_access/domain/repository/gallery_permission_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Takes the person to the system settings of the app, where a blocked
/// photo permission can be turned on.
class OpenGallerySettingsUseCase {
  final GalleryPermissionRepository _permission = sl();

  Future<void> call() {
    return _permission.openSettings();
  }
}

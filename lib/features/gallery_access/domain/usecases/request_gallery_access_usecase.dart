import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';
import 'package:memorylens/features/gallery_access/domain/repository/gallery_permission_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Asks the device for access to the photos, but only after the person agreed
/// in the app's own dialog. Without both permissions no photo is read.
class RequestGalleryAccessUseCase {
  final GalleryPermissionRepository _permission = sl();

  Future<GalleryPermissionStatus> call({required bool userConsented}) {
    if (!userConsented) {
      return Future.value(GalleryPermissionStatus.denied);
    }
    return _permission.request();
  }
}

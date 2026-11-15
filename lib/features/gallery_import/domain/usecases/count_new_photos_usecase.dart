import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';
import 'package:memorylens/features/gallery_access/domain/repository/gallery_permission_repository.dart';
import 'package:memorylens/features/gallery_import/domain/repository/device_gallery_repository.dart';
import 'package:memorylens/features/gallery_import/domain/repository/photo_import_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Photos on the device that Memory Lens does not have yet (HU-11, CA1).
///
/// "Since the last time" is what is on the device and not in the storage, so
/// a photo is never counted twice and nothing is lost if the app was closed
/// halfway through.
class CountNewPhotosUseCase {
  final GalleryPermissionRepository _permission = sl();
  final DeviceGalleryRepository _gallery = sl();
  final PhotoImportRepository _photos = sl();

  /// 0 when the person took the permission away in the system (HU-11, CA5):
  /// then the gallery is not even read, and no dialog is shown.
  Future<int> call() async {
    if (await _permission.check() != GalleryPermissionStatus.granted) return 0;
    final onDevice = await _gallery.listPhotos();
    if (onDevice.isEmpty) return 0;
    final stored = await _photos.importedAssetIds();
    return onDevice.where((photo) => !stored.contains(photo.assetId)).length;
  }
}

import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';

abstract class GalleryPermissionRepository {
  /// Current permission, without showing any device dialog.
  Future<GalleryPermissionStatus> check();

  /// Asks the device for the permission. It shows the system dialog unless
  /// the answer is already known.
  Future<GalleryPermissionStatus> request();

  /// Opens the settings page of the app.
  Future<void> openSettings();
}

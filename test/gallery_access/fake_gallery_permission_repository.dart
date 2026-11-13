import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';
import 'package:memorylens/features/gallery_access/domain/repository/gallery_permission_repository.dart';

/// Answers like the device would, without any system dialog.
class FakeGalleryPermissionRepository implements GalleryPermissionRepository {
  /// What [check] answers.
  GalleryPermissionStatus checkResult = GalleryPermissionStatus.denied;

  /// What [request] answers.
  GalleryPermissionStatus requestResult = GalleryPermissionStatus.granted;

  /// Thrown by every call when set.
  Object? error;

  int checkCalls = 0;
  int requestCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<GalleryPermissionStatus> check() async {
    checkCalls++;
    if (error != null) throw error!;
    return checkResult;
  }

  @override
  Future<GalleryPermissionStatus> request() async {
    requestCalls++;
    if (error != null) throw error!;
    return requestResult;
  }

  @override
  Future<void> openSettings() async {
    openSettingsCalls++;
    if (error != null) throw error!;
  }
}

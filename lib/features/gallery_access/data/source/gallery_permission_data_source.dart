import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';
import 'package:permission_handler/permission_handler.dart';

/// The only file that uses permission_handler and device_info_plus.
///
/// It avoids dart:io so the app still builds for web, where the photo
/// permission does not exist and a friendly message is shown instead.
class GalleryPermissionDataSource {
  static const _unsupportedMessage =
      'La galería solo está disponible en la app móvil.';

  /// First Android version where photos have their own permission
  /// (READ_MEDIA_IMAGES, Android 13). Before it the storage one is used.
  static const _androidImagesSdk = 33;

  Future<GalleryPermissionStatus> check() async {
    try {
      final permission = await _permission();
      return toDomain(await permission.status);
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// On Android only the result of a request can say "blocked", so the flow
  /// always asks through here.
  Future<GalleryPermissionStatus> request() async {
    try {
      final permission = await _permission();
      return toDomain(await permission.request());
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  Future<Permission> _permission() async {
    if (kIsWeb) throw const AppException(_unsupportedMessage);
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
        return sdk >= _androidImagesSdk
            ? Permission.photos
            : Permission.storage;
      case TargetPlatform.iOS:
        return Permission.photos;
      default:
        throw const AppException(_unsupportedMessage);
    }
  }

  /// "Limited" is the iOS 14+ answer when the person picked only some photos;
  /// the app can read those, so it counts as granted. "Restricted" (parental
  /// controls) cannot be fixed in the settings, so it is a plain denial.
  static GalleryPermissionStatus toDomain(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return GalleryPermissionStatus.granted;
      case PermissionStatus.permanentlyDenied:
        return GalleryPermissionStatus.blocked;
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
      case PermissionStatus.provisional:
        return GalleryPermissionStatus.denied;
    }
  }
}

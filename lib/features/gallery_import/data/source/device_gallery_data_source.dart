import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/gallery_import/domain/entities/device_gallery_photo.dart';
import 'package:photo_manager/photo_manager.dart';

/// The only file that uses photo_manager.
///
/// It only reads: nothing here edits, moves or deletes a photo of the person.
/// It avoids dart:io so the app still builds for web, where the gallery does
/// not exist and a friendly message is shown instead.
class DeviceGalleryDataSource {
  static const _unsupportedMessage =
      'La galería solo está disponible en la app móvil.';
  static const _noAccessMessage =
      'Memory Lens no tiene acceso a tus fotos. Actívalo en los ajustes e '
      'inténtalo de nuevo.';

  /// Photos asked from the device at once.
  static const pageSize = 500;

  /// Longest side of the copy that gets uploaded, and its JPEG quality.
  static const imageMaxSide = 2560;
  static const imageQuality = 85;

  /// Longest side of the thumbnail for the grid, and its JPEG quality.
  static const thumbnailMaxSide = 400;
  static const thumbnailQuality = 75;

  Future<List<DeviceGalleryPhoto>> listPhotos() async {
    try {
      _ensureSupported();
      await _ensureAccess();

      final albums = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
        // Newest first: createDate and descending are the defaults.
        filterOption: FilterOptionGroup(orders: [const OrderOption()]),
      );
      if (albums.isEmpty) return const [];

      final all = albums.first;
      final count = await all.assetCountAsync;
      final photos = <DeviceGalleryPhoto>[];
      for (var start = 0; start < count; start += pageSize) {
        final page = await all.getAssetListRange(
          start: start,
          end: min(start + pageSize, count),
        );
        // Only the id and the date are kept, never the AssetEntity.
        photos.addAll(
          page.map(
            (asset) => DeviceGalleryPhoto(
              assetId: asset.id,
              takenAt: takenAtFromSeconds(asset.createDateSecond),
            ),
          ),
        );
      }
      return photos;
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  Future<Uint8List?> readImage(String assetId) {
    return _read(assetId, imageMaxSide, imageQuality);
  }

  Future<Uint8List?> readThumbnail(String assetId) {
    return _read(assetId, thumbnailMaxSide, thumbnailQuality);
  }

  /// Null when the photo was deleted after the list was made, or when the
  /// device cannot give it right now (a photo kept only in the cloud).
  Future<Uint8List?> _read(String assetId, int maxSide, int quality) async {
    try {
      _ensureSupported();
      final asset = await AssetEntity.fromId(assetId);
      if (asset == null) return null;
      return await asset.thumbnailDataWithSize(
        fitSize(asset.orientatedWidth, asset.orientatedHeight, maxSide),
        quality: quality,
      );
    } on PlatformException {
      return null;
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// The permission was already asked by the gallery access flow, so this only
  /// checks it: it shows no dialog. "Limited" gives access to the photos the
  /// person picked, and those are the ones imported.
  Future<void> _ensureAccess() async {
    final state = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      ),
    );
    final hasAccess =
        state == PermissionState.authorized || state == PermissionState.limited;
    if (!hasAccess) throw const AppException(_noAccessMessage);
  }

  void _ensureSupported() {
    if (kIsWeb) throw const AppException(_unsupportedMessage);
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return;
      default:
        throw const AppException(_unsupportedMessage);
    }
  }

  /// The date of the photo, or null when the device has none. A missing date
  /// reads as 0, which would be 1970, so it is never turned into a date.
  static DateTime? takenAtFromSeconds(int? seconds) {
    if (seconds == null || seconds == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  /// Size that fits [maxSide] on the longest side, keeps the proportion and
  /// never enlarges the photo.
  static ThumbnailSize fitSize(int width, int height, int maxSide) {
    if (width <= 0 || height <= 0) return ThumbnailSize.square(maxSide);
    final longest = max(width, height);
    if (longest <= maxSide) return ThumbnailSize(width, height);
    final scale = maxSide / longest;
    return ThumbnailSize(
      max(1, (width * scale).round()),
      max(1, (height * scale).round()),
    );
  }
}

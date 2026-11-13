import 'dart:typed_data';

import 'package:memorylens/features/gallery_import/domain/entities/device_gallery_photo.dart';

/// Reads the photos of the device. It is read-only on purpose: nothing here
/// can modify or delete a photo of the person.
abstract class DeviceGalleryRepository {
  /// Every image on the device with its capture date, newest first.
  Future<List<DeviceGalleryPhoto>> listPhotos();

  /// A JPEG copy of the photo, scaled down to a reasonable size. Null when the
  /// photo is gone or cannot be read right now.
  Future<Uint8List?> readImage(String assetId);

  /// A small JPEG for the grid. Null when the photo is gone or cannot be read.
  Future<Uint8List?> readThumbnail(String assetId);
}

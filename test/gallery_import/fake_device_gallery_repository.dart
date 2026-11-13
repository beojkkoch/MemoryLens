import 'dart:typed_data';

import 'package:memorylens/features/gallery_import/domain/entities/device_gallery_photo.dart';
import 'package:memorylens/features/gallery_import/domain/repository/device_gallery_repository.dart';

/// Serves the photos a device would have.
class FakeDeviceGalleryRepository implements DeviceGalleryRepository {
  List<DeviceGalleryPhoto> photos = [];

  /// Ids that cannot be read, like a photo deleted after the list was made.
  final Set<String> unreadable = {};

  /// Thrown by [listPhotos] when set.
  Object? listError;

  @override
  Future<List<DeviceGalleryPhoto>> listPhotos() async {
    if (listError != null) throw listError!;
    return List.of(photos);
  }

  @override
  Future<Uint8List?> readImage(String assetId) async {
    if (unreadable.contains(assetId)) return null;
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<Uint8List?> readThumbnail(String assetId) async {
    if (unreadable.contains(assetId)) return null;
    return Uint8List.fromList([1]);
  }
}

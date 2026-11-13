import 'dart:typed_data';

import 'package:memorylens/features/gallery_import/domain/entities/device_gallery_photo.dart';
import 'package:memorylens/features/gallery_import/domain/entities/stored_photo.dart';

/// Keeps the imported photos in the person's storage.
abstract class PhotoImportRepository {
  /// Device ids of every photo already imported, so they are not uploaded
  /// again.
  Future<Set<String>> importedAssetIds();

  /// Uploads the photo and its thumbnail. The paths only depend on [assetId],
  /// so uploading the same photo twice replaces the files instead of
  /// duplicating them.
  Future<StoredPhoto> upload({
    required String assetId,
    required Uint8List image,
    required Uint8List thumbnail,
  });

  /// Records the photo as imported. It is the last step on purpose: a photo
  /// counts as imported only when its files are already stored.
  Future<void> register({
    required DeviceGalleryPhoto photo,
    required StoredPhoto stored,
  });
}

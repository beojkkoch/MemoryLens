import 'dart:async';
import 'dart:typed_data';

import 'package:memorylens/features/gallery_import/domain/entities/device_gallery_photo.dart';
import 'package:memorylens/features/gallery_import/domain/entities/stored_photo.dart';
import 'package:memorylens/features/gallery_import/domain/repository/photo_import_repository.dart';

/// Behaves like the storage and the foto table: a photo counts as imported
/// once it is registered.
class FakePhotoImportRepository implements PhotoImportRepository {
  FakePhotoImportRepository({List<String>? log}) : log = log ?? [];

  /// Everything that happened, in order, to check what came first.
  final List<String> log;

  /// Device ids already imported.
  final Set<String> imported = {};

  final List<DeviceGalleryPhoto> registered = [];

  /// How many times each photo was uploaded.
  final Map<String, int> uploadCounts = {};

  /// Thrown when that photo is uploaded.
  final Map<String, Object> uploadErrors = {};

  /// Thrown by [importedAssetIds] when set.
  Object? importedIdsError;

  /// While set, every upload waits for it. Keeps an import half done.
  Completer<void>? gate;

  @override
  Future<Set<String>> importedAssetIds() async {
    log.add('imported-ids');
    if (importedIdsError != null) throw importedIdsError!;
    return {...imported};
  }

  @override
  Future<StoredPhoto> upload({
    required String assetId,
    required Uint8List image,
    required Uint8List thumbnail,
  }) async {
    log.add('upload:$assetId');
    uploadCounts[assetId] = (uploadCounts[assetId] ?? 0) + 1;
    await gate?.future;
    final error = uploadErrors[assetId];
    if (error != null) throw error;
    return StoredPhoto(
      imagePath: 'user/$assetId.jpg',
      thumbnailPath: 'user/thumbs/$assetId.jpg',
    );
  }

  @override
  Future<void> register({
    required DeviceGalleryPhoto photo,
    required StoredPhoto stored,
  }) async {
    log.add('register:${photo.assetId}');
    registered.add(photo);
    imported.add(photo.assetId);
  }
}

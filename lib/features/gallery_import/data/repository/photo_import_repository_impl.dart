import 'dart:typed_data';

import 'package:memorylens/features/gallery_import/data/source/supabase_imported_photo_data_source.dart';
import 'package:memorylens/features/gallery_import/data/source/supabase_photo_storage_data_source.dart';
import 'package:memorylens/features/gallery_import/domain/entities/device_gallery_photo.dart';
import 'package:memorylens/features/gallery_import/domain/entities/stored_photo.dart';
import 'package:memorylens/features/gallery_import/domain/repository/photo_import_repository.dart';
import 'package:memorylens/injection_container.dart';

class PhotoImportRepositoryImpl implements PhotoImportRepository {
  final SupabasePhotoStorageDataSource _storage = sl();
  final SupabaseImportedPhotoDataSource _photos = sl();

  @override
  Future<Set<String>> importedAssetIds() {
    return _photos.importedAssetIds();
  }

  @override
  Future<StoredPhoto> upload({
    required String assetId,
    required Uint8List image,
    required Uint8List thumbnail,
  }) {
    return _storage.upload(
      assetId: assetId,
      image: image,
      thumbnail: thumbnail,
    );
  }

  @override
  Future<void> register({
    required DeviceGalleryPhoto photo,
    required StoredPhoto stored,
  }) {
    return _photos.register(photo: photo, stored: stored);
  }
}

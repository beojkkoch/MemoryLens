import 'dart:typed_data';

import 'package:memorylens/features/gallery_import/data/source/device_gallery_data_source.dart';
import 'package:memorylens/features/gallery_import/domain/entities/device_gallery_photo.dart';
import 'package:memorylens/features/gallery_import/domain/repository/device_gallery_repository.dart';
import 'package:memorylens/injection_container.dart';

class DeviceGalleryRepositoryImpl implements DeviceGalleryRepository {
  final DeviceGalleryDataSource _dataSource = sl();

  @override
  Future<List<DeviceGalleryPhoto>> listPhotos() {
    return _dataSource.listPhotos();
  }

  @override
  Future<Uint8List?> readImage(String assetId) {
    return _dataSource.readImage(assetId);
  }

  @override
  Future<Uint8List?> readThumbnail(String assetId) {
    return _dataSource.readThumbnail(assetId);
  }
}

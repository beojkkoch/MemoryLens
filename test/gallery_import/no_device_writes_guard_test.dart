import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CA6: the photos of the device are never modified or deleted. The import
/// only reads, so no code of the feature may call what writes to the gallery.
void main() {
  const featureDir = 'lib/features/gallery_import';
  const dataSource = 'device_gallery_data_source.dart';

  const forbidden = [
    'PhotoManager.editor',
    'deleteWithIds',
    'deleteWithAssets',
    'moveAssetToPath',
    'copyAssetToPath',
    'removeInAlbum',
    'saveImage',
    'saveImageWithPath',
    'saveVideo',
    'saveLivePhoto',
    'createAlbum',
    'createFolder',
    'removeAsset',
  ];

  List<File> featureFiles() {
    return Directory(featureDir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
  }

  test('the import feature has files to check', () {
    expect(featureFiles(), isNotEmpty);
  });

  test('nothing in the import can write to the gallery of the device', () {
    for (final file in featureFiles()) {
      final code = file.readAsStringSync();
      for (final call in forbidden) {
        expect(
          code,
          isNot(contains(call)),
          reason: '${file.path} uses $call, which writes to the gallery',
        );
      }
    }
  });

  test('only the device gallery data source touches photo_manager', () {
    final importers = featureFiles()
        .where(
          (file) => file.readAsStringSync().contains('package:photo_manager'),
        )
        .map((file) => file.uri.pathSegments.last)
        .toList();

    expect(importers, [dataSource]);
  });
}

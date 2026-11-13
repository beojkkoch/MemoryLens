import 'dart:convert';
import 'dart:typed_data';

import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/gallery_import/data/source/signed_in_user.dart';
import 'package:memorylens/features/gallery_import/domain/entities/stored_photo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that writes to the fotos bucket.
///
/// The paths only depend on the person and the photo, never on chance, so
/// uploading a photo again replaces its files instead of duplicating them.
class SupabasePhotoStorageDataSource {
  static const bucket = 'fotos';

  /// The storage client has no timeout of its own, and an upload that hangs
  /// would freeze the whole import.
  static const _uploadTimeout = Duration(seconds: 60);

  final SupabaseClient _client = Supabase.instance.client;

  Future<StoredPhoto> upload({
    required String assetId,
    required Uint8List image,
    required Uint8List thumbnail,
  }) async {
    try {
      final userId = signedInUserId(_client);
      final imagePath = pathForImage(userId, assetId);
      final thumbnailPath = pathForThumbnail(userId, assetId);
      await _put(imagePath, image);
      await _put(thumbnailPath, thumbnail);
      return StoredPhoto(imagePath: imagePath, thumbnailPath: thumbnailPath);
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  Future<void> _put(String path, Uint8List bytes) {
    return _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
            cacheControl: '31536000',
          ),
        )
        .timeout(_uploadTimeout);
  }

  /// The device id is not safe as a file name (on iOS it holds slashes), so it
  /// is encoded. The encoding can be undone, so two photos never share a key.
  static String keyFor(String assetId) {
    return base64Url.encode(utf8.encode(assetId)).replaceAll('=', '');
  }

  static String pathForImage(String userId, String assetId) {
    return '$userId/${keyFor(assetId)}.jpg';
  }

  static String pathForThumbnail(String userId, String assetId) {
    return '$userId/thumbs/${keyFor(assetId)}.jpg';
  }
}

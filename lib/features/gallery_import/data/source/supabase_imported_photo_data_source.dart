import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/gallery_import/data/source/signed_in_user.dart';
import 'package:memorylens/features/gallery_import/domain/entities/device_gallery_photo.dart';
import 'package:memorylens/features/gallery_import/domain/entities/stored_photo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that writes to the foto table. A row there is what marks a
/// photo of the device as imported.
class SupabaseImportedPhotoDataSource {
  /// The most rows the server gives in one answer. Asking for more silently
  /// returns this many, which would make imported photos look new.
  static const pageSize = 1000;

  final SupabaseClient _client = Supabase.instance.client;

  /// Reads the ids page by page, in a fixed order so no row is skipped or
  /// repeated between pages. The row level security of the table only shows
  /// each person their own photos.
  Future<Set<String>> importedAssetIds() async {
    try {
      final ids = <String>{};
      var from = 0;
      while (true) {
        final rows = await _client
            .from('foto')
            .select('asset_id')
            .not('asset_id', 'is', null)
            .order('id')
            .range(from, from + pageSize - 1);
        for (final row in rows) {
          ids.add(row['asset_id'] as String);
        }
        if (rows.length < pageSize) return ids;
        from += pageSize;
      }
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// A photo already recorded is left as it is, so recording twice is safe.
  Future<void> register({
    required DeviceGalleryPhoto photo,
    required StoredPhoto stored,
  }) async {
    try {
      await _client.from('foto').upsert({
        'usuario_id': signedInUserId(_client),
        'asset_id': photo.assetId,
        'url_imagen': stored.imagePath,
        'ruta_miniatura': stored.thumbnailPath,
        'fecha_captura': photo.takenAt?.toUtc().toIso8601String(),
        'origen': 'galeria',
      }, onConflict: 'usuario_id,asset_id', ignoreDuplicates: true);
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }
}

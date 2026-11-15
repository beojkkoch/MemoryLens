import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that reads the photos of Recuerdos from the foto table. The
/// import writes them from its own data source.
class SupabasePhotoDataSource {
  static const bucket = 'fotos';

  /// The most rows the server gives in one answer.
  static const pageSize = 1000;

  /// How long the links of the private bucket work. Opening Recuerdos again
  /// signs new ones.
  static const signedUrlLifetime = Duration(hours: 24);

  final SupabaseClient _client = Supabase.instance.client;

  /// The row level security of the table only lets each person see their own
  /// photos, so no filter by user is needed.
  Future<int> count() async {
    try {
      return await _client.from('foto').count(CountOption.exact);
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// The photos the AI already described, newest first, with signed links to
  /// the image and its thumbnail.
  Future<List<MemoryPhoto>> analyzed() async {
    try {
      final photos = <MemoryPhoto>[];
      var from = 0;
      while (true) {
        final rows = await _client
            .from('foto')
            .select('id, titulo, fecha_captura, url_imagen, ruta_miniatura')
            .eq('estado_analisis', 'listo')
            .order('fecha_captura', ascending: false, nullsFirst: false)
            .order('id')
            .range(from, from + pageSize - 1);
        photos.addAll(await _withLinks(rows));
        if (rows.length < pageSize) return photos;
        from += pageSize;
      }
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// Signs every image and thumbnail of a page in one call. A file that
  /// cannot be signed gets no link, and the screen shows a gray box for it.
  Future<List<MemoryPhoto>> _withLinks(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return const [];
    final paths = <String>{};
    for (final row in rows) {
      paths.add(row['url_imagen'] as String);
      paths.add(_thumbnailPath(row));
    }
    final results = await _client.storage
        .from(bucket)
        .createSignedUrlsResult(paths.toList(), signedUrlLifetime.inSeconds);
    final links = {
      for (final result in results.whereType<SignedUrlSuccess>())
        result.path: result.signedUrl,
    };
    return [
      for (final row in rows)
        MemoryPhoto(
          id: row['id'] as String,
          title: row['titulo'] as String?,
          takenAt: _date(row['fecha_captura']),
          thumbnailUrl: links[_thumbnailPath(row)],
          imageUrl: links[row['url_imagen']],
        ),
    ];
  }

  /// Every import saves a thumbnail; the image itself stands in if one is
  /// missing.
  static String _thumbnailPath(Map<String, dynamic> row) {
    return (row['ruta_miniatura'] ?? row['url_imagen']) as String;
  }

  static DateTime? _date(Object? value) {
    return value is String ? DateTime.tryParse(value)?.toLocal() : null;
  }
}

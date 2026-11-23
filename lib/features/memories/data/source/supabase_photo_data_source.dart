import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that reads the photos of Recuerdos from the foto table. The
/// import writes them from its own data source.
class SupabasePhotoDataSource {
  static const bucket = 'fotos';

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

  /// How many photos the AI already described, for «128 fotos».
  Future<int> countAnalyzed() async {
    try {
      final response = await _client
          .from('foto')
          .select('id')
          .eq('estado_analisis', 'listo')
          .count(CountOption.exact);
      return response.count;
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// One page of the photos the AI already described, newest first, with
  /// signed links to their thumbnails (HU-15). Only the photos of
  /// the page are signed.
  Future<List<MemoryPhoto>> analyzed({
    required int offset,
    required int limit,
  }) async {
    try {
      final rows = await _client
          .from('foto')
          .select('id, titulo, fecha_captura, url_imagen, ruta_miniatura')
          .eq('estado_analisis', 'listo')
          .order('fecha_captura', ascending: false, nullsFirst: false)
          .order('id')
          .range(offset, offset + limit - 1);
      return await _withLinks(rows);
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// The photos the AI described after [since], newest first, whatever day
  /// they were taken. With [takenAfter], only the ones taken after it.
  Future<List<MemoryPhoto>> analyzedSince({
    required DateTime since,
    DateTime? takenAfter,
  }) async {
    try {
      var query = _client
          .from('foto')
          .select('id, titulo, fecha_captura, url_imagen, ruta_miniatura')
          .eq('estado_analisis', 'listo')
          .gt('analizada_en', since.toUtc().toIso8601String());
      if (takenAfter != null) {
        query = query.gt('fecha_captura', takenAfter.toUtc().toIso8601String());
      }
      final rows = await query
          .order('fecha_captura', ascending: false, nullsFirst: false)
          .order('id');
      return await _withLinks(rows);
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// The photos with these ids, in the same order, with signed links to their
  /// thumbnails. The chat shows the photos of an answer with it (HU-22, HU-25).
  /// An id that is not the person's, or no longer exists, is left out.
  Future<List<MemoryPhoto>> byIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    try {
      final rows = await _client
          .from('foto')
          .select('id, titulo, fecha_captura, url_imagen, ruta_miniatura')
          .inFilter('id', ids);
      final photos = {
        for (final photo in await _withLinks(rows)) photo.id: photo,
      };
      return [for (final id in ids) ?photos[id]];
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// Signs every thumbnail of a page in one call; the large image is signed
  /// only when its detail opens (HU-28). A file that cannot be signed gets no
  /// link, and the screen shows a gray box for it.
  Future<List<MemoryPhoto>> _withLinks(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return const [];
    final paths = {for (final row in rows) _thumbnailPath(row)};
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
